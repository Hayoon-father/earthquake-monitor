import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/earthquake_model.dart';

class JmaApiService {
  static const String _baseUrl = 'https://www.jma.go.jp/bosai/quake/data/list.json';

  Future<List<EarthquakeModel>> fetchEarthquakeData() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        
        return jsonData
            .map((json) => EarthquakeModel.fromJmaJson(json))
            .toList();
      } else {
        throw Exception('Failed to load earthquake data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching earthquake data: $e');
    }
  }

  Future<List<EarthquakeModel>> fetchLatestEarthquakes({int limit = 10}) async {
    final earthquakes = await fetchEarthquakeData();
    
    earthquakes.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    
    return earthquakes.take(limit).toList();
  }
}