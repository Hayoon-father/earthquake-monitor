import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/earthquake_model.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  static Future<void> initialize() async {
    // Supabase 초기화는 main.dart에서 실행
    // 여기서는 클라이언트만 사용
  }

  Future<List<EarthquakeModel>> getRecentEarthquakes({int limit = 20}) async {
    try {
      final response = await _client
          .from('earthquakes')
          .select()
          .order('detected_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => EarthquakeModel.fromSupabaseJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch earthquakes from Supabase: $e');
    }
  }

  Future<List<EarthquakeModel>> getEarthquakesByMagnitude({
    double minMagnitude = 5.0,
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('earthquakes')
          .select()
          .gte('magnitude', minMagnitude)
          .order('detected_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => EarthquakeModel.fromSupabaseJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch earthquakes by magnitude: $e');
    }
  }

  Future<String> saveEarthquake(EarthquakeModel earthquake) async {
    try {
      final response = await _client
          .from('earthquakes')
          .upsert(earthquake.toSupabaseJson())
          .select()
          .single();

      return response['id'];
    } catch (e) {
      throw Exception('Failed to save earthquake: $e');
    }
  }

  Future<void> saveEarthquakes(List<EarthquakeModel> earthquakes) async {
    try {
      final data = earthquakes.map((e) => e.toSupabaseJson()).toList();
      
      await _client
          .from('earthquakes')
          .upsert(data);
    } catch (e) {
      throw Exception('Failed to save earthquakes: $e');
    }
  }

  Future<int> getEarthquakeCount() async {
    try {
      final response = await _client
          .from('earthquakes')
          .select('id')
          .count();

      return response.count;
    } catch (e) {
      throw Exception('Failed to get earthquake count: $e');
    }
  }

  Future<List<EarthquakeModel>> getEarthquakesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _client
          .from('earthquakes')
          .select()
          .gte('detected_at', startDate.toIso8601String())
          .lte('detected_at', endDate.toIso8601String())
          .order('detected_at', ascending: false);

      return (response as List)
          .map((json) => EarthquakeModel.fromSupabaseJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch earthquakes by date range: $e');
    }
  }

  Future<bool> earthquakeExists(String eventId) async {
    try {
      final response = await _client
          .from('earthquakes')
          .select('id')
          .eq('event_id', eventId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Failed to check earthquake existence: $e');
    }
  }

  Stream<List<EarthquakeModel>> watchRecentEarthquakes({int limit = 20}) {
    return _client
        .from('earthquakes')
        .stream(primaryKey: ['id'])
        .order('detected_at', ascending: false)
        .limit(limit)
        .map((data) => data
            .map((json) => EarthquakeModel.fromSupabaseJson(json))
            .toList());
  }
}