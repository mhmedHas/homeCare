import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/shared/models/care_request.dart';

class CareRequestService {
  final CollectionReference<Map<String, dynamic>> _requestsCollection =
      FirebaseFirestore.instance.collection('careRequests');

  Future<String> createRequest(CareRequest request) async {
    final docRef = _requestsCollection.doc();
    final newRequest = request.copyWith(id: docRef.id);
    await docRef.set(newRequest.toMap());
    return docRef.id;
  }

  Future<CareRequest?> getRequest(String id) async {
    final doc = await _requestsCollection.doc(id).get();
    if (!doc.exists) return null;
    return CareRequest.fromFirestore(doc);
  }

  Future<void> updateRequestStatus(String id, String status) async {
    await _requestsCollection.doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<CareRequest>> getClientRequests(String clientId) async {
    final snapshot = await _requestsCollection
        .where('clientId', isEqualTo: clientId)
        .limit(100)
        .get();
    final requests = snapshot.docs.map(CareRequest.fromFirestore).toList();
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  }

  Future<List<CareRequest>> getOpenRequestsForGovernorates(
    List<String> governorates,
  ) async {
    final values = governorates.where((e) => e.trim().isNotEmpty).toSet().toList();
    if (values.isEmpty) return [];

    final snapshot = await _requestsCollection
        .where('status', isEqualTo: 'open')
        .where('governorate', whereIn: values.take(30).toList())
        .limit(100)
        .get();
    final requests = snapshot.docs.map(CareRequest.fromFirestore).toList();
    requests.sort((a, b) => a.startDate.compareTo(b.startDate));
    return requests;
  }
}

extension CareRequestCopyWith on CareRequest {
  CareRequest copyWith({String? id}) {
    return CareRequest(
      id: id ?? this.id,
      clientId: clientId,
      patientName: patientName,
      patientAge: patientAge,
      patientGender: patientGender,
      careType: careType,
      services: services,
      shiftHours: shiftHours,
      daysCount: daysCount,
      startDate: startDate,
      startTime: startTime,
      governorate: governorate,
      area: area,
      address: address,
      notes: notes,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
