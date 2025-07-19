import '../utils/region_translator.dart';

class EarthquakeModel {
  final String id;
  final String eventId;
  final DateTime detectedAt;
  final String regionName;
  final double magnitude;
  final int maxIntensity;
  final DateTime announcedAt;
  final DateTime createdAt;

  EarthquakeModel({
    required this.id,
    required this.eventId,
    required this.detectedAt,
    required this.regionName,
    required this.magnitude,
    required this.maxIntensity,
    required this.announcedAt,
    required this.createdAt,
  });

  // 한국어로 번역된 지역명 반환
  String get koreanRegionName => RegionTranslator.translateRegion(regionName);

  factory EarthquakeModel.fromJmaJson(Map<String, dynamic> json) {
    return EarthquakeModel(
      id: '',
      eventId: json['eid'] ?? '',
      detectedAt: DateTime.parse(json['at'] ?? ''),
      regionName: json['anm'] ?? '',
      magnitude: double.tryParse(json['mag']?.toString() ?? '0') ?? 0.0,
      maxIntensity: int.tryParse(json['maxi']?.toString() ?? '0') ?? 0,
      announcedAt: DateTime.parse(json['rdt'] ?? ''),
      createdAt: DateTime.now(),
    );
  }

  factory EarthquakeModel.fromSupabaseJson(Map<String, dynamic> json) {
    return EarthquakeModel(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? '',
      detectedAt: DateTime.parse(json['detected_at'] ?? ''),
      regionName: json['region_name'] ?? '',
      magnitude: double.tryParse(json['magnitude']?.toString() ?? '0') ?? 0.0,
      maxIntensity: int.tryParse(json['max_intensity']?.toString() ?? '0') ?? 0,
      announcedAt: DateTime.parse(json['announced_at'] ?? ''),
      createdAt: DateTime.parse(json['created_at'] ?? ''),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'event_id': eventId,
      'detected_at': detectedAt.toIso8601String(),
      'region_name': regionName,
      'magnitude': magnitude,
      'max_intensity': maxIntensity,
      'announced_at': announcedAt.toIso8601String(),
    };
  }
}