class SiteModel {
  final String siteId;
  final String siteName;
  final double latitude;
  final double longitude;
  final String supervisorId;
  final String supervisorName;
  final String status;

  SiteModel({
    required this.siteId,
    required this.siteName,
    required this.latitude,
    required this.longitude,
    required this.supervisorId,
    required this.supervisorName,
    this.status = 'active',
  });

  // Firestore से डेटा रीड करने के लिए
  factory SiteModel.fromMap(Map<String, dynamic> map) {
    return SiteModel(
      siteId: map['siteId'] ?? '',
      siteName: map['siteName'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      supervisorId: map['supervisorId'] ?? '',
      supervisorName: map['supervisorName'] ?? 'Unassigned',
      status: map['status'] ?? 'active',
    );
  }

  // Firestore में डेटा सेव करने के लिए
  Map<String, dynamic> toMap() {
    return {
      'siteId': siteId,
      'siteName': siteName,
      'latitude': latitude,
      'longitude': longitude,
      'supervisorId': supervisorId,
      'supervisorName': supervisorName,
      'status': status,
    };
  }
}