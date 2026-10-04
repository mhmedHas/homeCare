import 'package:cloud_firestore/cloud_firestore.dart';

class SmartMatchCandidate {
  final String offerId;
  final String nurseId;
  final String nurseName;
  final String photoUrl;
  final bool verified;
  final double offerPrice;
  final double rating;
  final int experienceYears;
  final String specialization;
  final String gender;
  final double matchScore;
  final List<String> matchedReasons;

  const SmartMatchCandidate({
    required this.offerId,
    required this.nurseId,
    required this.nurseName,
    required this.photoUrl,
    required this.verified,
    required this.offerPrice,
    required this.rating,
    required this.experienceYears,
    required this.specialization,
    required this.gender,
    required this.matchScore,
    required this.matchedReasons,
  });
}

class NurseSmartMatchingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<SmartMatchCandidate>> findBestMatches({
    required String requestId,
    String preferredGender = 'any',
    String specialization = '',
    double? maxBudget,
    int? minExperienceYears,
    String specialCondition = '',
  }) async {
    final requestSnap = await _db.collection('careRequests').doc(requestId).get();
    if (!requestSnap.exists) throw StateError('طلب الرعاية غير موجود');

    final request = requestSnap.data() ?? <String, dynamic>{};
    final offersSnap = await _db
        .collection('careOffers')
        .where('requestId', isEqualTo: requestId)
        .get();

    final offers = offersSnap.docs.where((doc) {
      final status = doc.data()['status']?.toString() ?? '';
      return status == 'pending' || status == 'accepted';
    }).toList();

    if (offers.isEmpty) return [];

    final nurseIds = offers
        .map((doc) => doc.data()['nurseId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final users = <String, Map<String, dynamic>>{};
    final profiles = <String, Map<String, dynamic>>{};

    for (var i = 0; i < nurseIds.length; i += 30) {
      final chunk = nurseIds.sublist(
        i,
        i + 30 > nurseIds.length ? nurseIds.length : i + 30,
      );

      final results = await Future.wait([
        _db.collection('users').where(FieldPath.documentId, whereIn: chunk).get(),
        _db.collection('nurseProfiles').where(FieldPath.documentId, whereIn: chunk).get(),
      ]);

      final userSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final profileSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;

      for (final doc in userSnap.docs) {
        users[doc.id] = doc.data();
      }
      for (final doc in profileSnap.docs) {
        profiles[doc.id] = doc.data();
      }
    }

    final requestGovernorate = _normalize(request['governorate']);
    final requestArea = _normalize(request['area']);
    final requestCareType = _normalize(request['careType']);
    final requestServices = (request['services'] is List
            ? (request['services'] as List)
            : const <dynamic>[])
        .map((e) => _normalize(e))
        .where((e) => e.isNotEmpty)
        .toList();

    final conditionTokens = _tokens(specialCondition);
    final specializationTokens = _tokens(specialization);

    final matches = <SmartMatchCandidate>[];

    for (final offer in offers) {
      final offerData = offer.data();
      final nurseId = offerData['nurseId']?.toString() ?? '';
      final user = users[nurseId] ?? <String, dynamic>{};
      final profile = profiles[nurseId] ?? <String, dynamic>{};

      final active = user['isActive'] != false;
      final verified = user['isVerified'] == true ||
          profile['isVerified'] == true ||
          offerData['nurseVerified'] == true;
      if (!active || !verified) continue;

      final gender = profile['gender']?.toString() ?? '';
      if (preferredGender != 'any' &&
          gender != preferredGender) {
        continue;
      }

      final workGovernorates = _stringList(profile['preferredGovernorates']);
      final workAreas = _stringList(profile['workAreas']);
      final services = _stringList(profile['services']);
      final skills = _stringList(profile['skills']);
      final allCapabilities = <String>{
        ...services.map(_normalize),
        ...skills.map(_normalize),
        _normalize(profile['specialization']),
        _normalize(offerData['nurseSpecialization']),
      }..removeWhere((e) => e.isEmpty);

      final offerPrice = (offerData['proposedPrice'] as num?)?.toDouble() ?? 0;
      final rating = (profile['averageRating'] as num?)?.toDouble() ??
          (offerData['nurseRating'] as num?)?.toDouble() ?? 0;
      final experience = (profile['experienceYears'] as num?)?.toInt() ??
          (offerData['nurseExperienceYears'] as num?)?.toInt() ?? 0;
      final nurseSpecialization =
          profile['specialization']?.toString() ??
          offerData['nurseSpecialization']?.toString() ?? '';

      double score = 0;
      final reasons = <String>[];

      if (requestGovernorate.isEmpty ||
          workGovernorates.any((item) => _normalize(item) == requestGovernorate)) {
        score += 20;
        reasons.add('متاح في محافظتك');
      }

      if (requestArea.isEmpty ||
          workAreas.any((item) => _normalize(item).contains(requestArea) || requestArea.contains(_normalize(item)))) {
        score += 15;
        if (requestArea.isNotEmpty) reasons.add('يعمل في منطقتك');
      }

      final careMatch = requestServices.any((service) =>
          allCapabilities.any((capability) => capability.contains(service) || service.contains(capability))) ||
          (requestCareType.isNotEmpty &&
              allCapabilities.any((capability) =>
                  capability.contains(requestCareType) || requestCareType.contains(capability)));
      if (careMatch) {
        score += 15;
        reasons.add('متخصص في نوع الرعاية المطلوبة');
      }

      if (specializationTokens.isEmpty ||
          specializationTokens.every((token) =>
              allCapabilities.any((capability) => capability.contains(token)))) {
        score += 10;
        if (specializationTokens.isNotEmpty) reasons.add('التخصص مناسب');
      }

      if (maxBudget == null || maxBudget <= 0) {
        score += 10;
      } else if (offerPrice > 0 && offerPrice <= maxBudget) {
        score += 10;
        reasons.add('داخل الميزانية');
      }

      if (minExperienceYears == null || minExperienceYears <= 0) {
        score += 10;
      } else if (experience >= minExperienceYears) {
        score += 10;
        reasons.add('يحقق سنوات الخبرة المطلوبة');
      }

      final conditionMatch = conditionTokens.isEmpty ||
          conditionTokens.any((token) =>
              allCapabilities.any((capability) => capability.contains(token)) ||
              _normalize(nurseSpecialization).contains(token));
      if (conditionMatch) {
        score += 10;
        if (conditionTokens.isNotEmpty) reasons.add('لديه مهارات قريبة من الحالة');
      }

      final ratingPart = (rating.clamp(0, 5) / 5) * 10;
      score += ratingPart;
      if (rating >= 4.5) reasons.add('تقييم مرتفع');

      matches.add(
        SmartMatchCandidate(
          offerId: offer.id,
          nurseId: nurseId,
          nurseName: user['name']?.toString().trim().isNotEmpty == true
              ? user['name'].toString()
              : (offerData['nurseName']?.toString() ?? 'ممرض'),
          photoUrl: (profile['photoUrl']?.toString().trim().isNotEmpty == true
                  ? profile['photoUrl'].toString()
                  : (user['photoUrl']?.toString() ?? offerData['nursePhotoUrl']?.toString() ?? ''))
              .trim(),
          verified: true,
          offerPrice: offerPrice,
          rating: rating,
          experienceYears: experience,
          specialization: nurseSpecialization,
          gender: gender,
          matchScore: score.clamp(0, 100).toDouble(),
          matchedReasons: reasons.take(4).toList(),
        ),
      );
    }

    matches.sort((a, b) {
      final scoreCompare = b.matchScore.compareTo(a.matchScore);
      if (scoreCompare != 0) return scoreCompare;
      return b.rating.compareTo(a.rating);
    });

    return matches.take(3).toList();
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return [];
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<String> _tokens(String value) {
    return _normalize(value)
        .split(RegExp(r'[,،\\s]+'))
        .where((token) => token.length >= 2)
        .toList();
  }

  String _normalize(dynamic value) {
    return value?.toString().trim().toLowerCase() ?? '';
  }
}