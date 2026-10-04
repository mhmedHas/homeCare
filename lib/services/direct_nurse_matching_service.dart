import 'package:cloud_firestore/cloud_firestore.dart';

class DirectNurseCandidate {
  final String nurseId;
  final String name;
  final String photoUrl;
  final bool verified;
  final String gender;
  final String specialization;
  final List<String> governorates;
  final List<String> workAreas;
  final List<String> services;
  final int experienceYears;
  final double shiftPrice;
  final int shiftHours;
  final double averageRating;
  final int totalReviews;
  final double matchScore;
  final List<String> matchReasons;

  const DirectNurseCandidate({
    required this.nurseId,
    required this.name,
    required this.photoUrl,
    required this.verified,
    required this.gender,
    required this.specialization,
    required this.governorates,
    required this.workAreas,
    required this.services,
    required this.experienceYears,
    required this.shiftPrice,
    required this.shiftHours,
    required this.averageRating,
    required this.totalReviews,
    required this.matchScore,
    required this.matchReasons,
  });
}

class DirectNurseMatchingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<DirectNurseCandidate>> findBestMatches({
    required String governorate,
    required String area,
    required String careType,
    required String preferredGender,
    required String specialization,
    double? maxBudget,
  }) async {
    final usersSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'nurse')
        .where('isActive', isEqualTo: true)
        .get();

    if (usersSnap.docs.isEmpty) return [];

    final userData = <String, Map<String, dynamic>>{};
    for (final doc in usersSnap.docs) {
      userData[doc.id] = doc.data();
    }

    final nurseIds = userData.keys.toList();
    final profiles = <String, Map<String, dynamic>>{};
    final documents = <String, Map<String, dynamic>>{};

    for (var i = 0; i < nurseIds.length; i += 30) {
      final chunk = nurseIds.sublist(
        i,
        i + 30 > nurseIds.length ? nurseIds.length : i + 30,
      );
      final results = await Future.wait([
        _db
            .collection('nurseProfiles')
            .where(FieldPath.documentId, whereIn: chunk)
            .get(),
        _db
            .collection('nurseDocuments')
            .where(FieldPath.documentId, whereIn: chunk)
            .get(),
      ]);

      final profileSnap =
          results[0] as QuerySnapshot<Map<String, dynamic>>;
      final documentSnap =
          results[1] as QuerySnapshot<Map<String, dynamic>>;

      for (final doc in profileSnap.docs) {
        profiles[doc.id] = doc.data();
      }
      for (final doc in documentSnap.docs) {
        documents[doc.id] = doc.data();
      }
    }

    final governorateKey = _normalize(governorate);
    final areaKey = _normalize(area);
    final careTypeKey = _normalize(careType);
    final specializationKey = _normalize(specialization);

    final candidates = <DirectNurseCandidate>[];

    for (final nurseId in nurseIds) {
      final user = userData[nurseId] ?? <String, dynamic>{};
      final profile = profiles[nurseId] ?? <String, dynamic>{};
      final document = documents[nurseId] ?? <String, dynamic>{};

      final verified = user['isVerified'] == true ||
          profile['isVerified'] == true ||
          document['verificationStatus']?.toString() == 'approved';
      if (!verified) continue;

      final shiftPrice = (profile['expectedPrice'] as num?)?.toDouble() ?? 0;
      if (shiftPrice <= 0) continue;

      final shiftHours = (profile['shiftHours'] as num?)?.toInt() ?? 12;
      if (![6, 12, 24].contains(shiftHours)) continue;

      final gender = profile['gender']?.toString() ?? '';
      if (preferredGender != 'any' && gender != preferredGender) continue;

      if (maxBudget != null && maxBudget > 0 && shiftPrice > maxBudget) {
        continue;
      }

      final governorates = _stringList(
        profile['preferredGovernorates'] ??
            (profile['governorate'] == null
                ? const []
                : [profile['governorate']]),
      );
      final workAreas = _stringList(
        profile['workAreas'] ??
            (profile['area'] == null ? const [] : [profile['area']]),
      );
      final services = _stringList(profile['services']);
      final skills = _stringList(profile['skills']);
      final specializationValue =
          profile['specialization']?.toString().trim() ?? '';

      var score = 0.0;
      final reasons = <String>[];

      final governorateMatch = governorates.any(
        (value) => _normalize(value) == governorateKey,
      );
      if (governorateMatch) {
        score += 25;
        reasons.add('يعمل في محافظتك');
      }

      final areaMatch = areaKey.isEmpty
          ? false
          : workAreas.any((value) {
              final key = _normalize(value);
              return key.contains(areaKey) || areaKey.contains(key);
            });
      if (areaMatch) {
        score += 15;
        reasons.add('يعمل في منطقتك');
      }

      final capabilityText = <String>[
        specializationValue,
        ...services,
        ...skills,
      ].map(_normalize).where((value) => value.isNotEmpty).toList();

      final careMatch = careTypeKey.isEmpty
          ? false
          : capabilityText.any(
              (value) => value.contains(careTypeKey) || careTypeKey.contains(value),
            );
      if (careMatch) {
        score += 20;
        reasons.add('خدماته مناسبة لنوع الرعاية');
      }

      if (specializationKey.isEmpty) {
        score += 10;
      } else if (_normalize(specializationValue).contains(specializationKey) ||
          specializationKey.contains(_normalize(specializationValue))) {
        score += 10;
        reasons.add('التخصص مطابق');
      }

      if (maxBudget == null || maxBudget <= 0) {
        score += 10;
      } else {
        final budgetRatio = (1 - (shiftPrice / maxBudget)).clamp(0, 1);
        score += budgetRatio * 10;
        reasons.add('داخل الميزانية');
      }

      final averageRating =
          (profile['averageRating'] as num?)?.toDouble() ?? 0;
      final totalReviews =
          (profile['totalReviews'] as num?)?.toInt() ?? 0;
      score += (averageRating.clamp(0, 5) / 5) * 10;
      if (averageRating >= 4.5) reasons.add('تقييم مرتفع');

      candidates.add(
        DirectNurseCandidate(
          nurseId: nurseId,
          name: user['name']?.toString().trim().isNotEmpty == true
              ? user['name'].toString().trim()
              : 'ممرض',
          photoUrl: profile['photoUrl']?.toString().trim().isNotEmpty == true
              ? profile['photoUrl'].toString().trim()
              : (user['photoUrl']?.toString().trim() ?? ''),
          verified: true,
          gender: gender,
          specialization: specializationValue,
          governorates: governorates,
          workAreas: workAreas,
          services: [...services, ...skills].toSet().toList(),
          experienceYears:
              (profile['experienceYears'] as num?)?.toInt() ?? 0,
          shiftPrice: shiftPrice,
          shiftHours: shiftHours,
          averageRating: averageRating,
          totalReviews: totalReviews,
          matchScore: score.clamp(0, 100).toDouble(),
          matchReasons: reasons.take(4).toList(),
        ),
      );
    }

    candidates.sort((a, b) {
      final score = b.matchScore.compareTo(a.matchScore);
      if (score != 0) return score;
      return b.averageRating.compareTo(a.averageRating);
    });

    return candidates.take(3).toList();
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _normalize(dynamic value) {
    return value?.toString().trim().toLowerCase() ?? '';
  }
}