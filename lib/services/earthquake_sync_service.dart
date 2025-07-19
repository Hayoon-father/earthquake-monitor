import 'dart:async';
import 'dart:developer';
import '../models/earthquake_model.dart';
import 'jma_api_service.dart';
import 'supabase_service.dart';

class EarthquakeSyncService {
  static final EarthquakeSyncService _instance = EarthquakeSyncService._internal();
  factory EarthquakeSyncService() => _instance;
  EarthquakeSyncService._internal();

  final JmaApiService _jmaService = JmaApiService();
  final SupabaseService _supabaseService = SupabaseService();
  
  Timer? _syncTimer;
  bool _isRunning = false;
  
  StreamController<List<EarthquakeModel>>? _earthquakeController;
  Stream<List<EarthquakeModel>>? _earthquakeStream;

  Stream<List<EarthquakeModel>> get earthquakeStream {
    _earthquakeController ??= StreamController<List<EarthquakeModel>>.broadcast();
    _earthquakeStream ??= _earthquakeController!.stream;
    return _earthquakeStream!;
  }

  Future<void> startSync({Duration interval = const Duration(minutes: 1)}) async {
    if (_isRunning) return;

    _isRunning = true;
    log('Starting earthquake sync service...');

    // 즉시 한 번 동기화 실행
    await _syncEarthquakes();

    // 주기적 동기화 시작
    _syncTimer = Timer.periodic(interval, (timer) async {
      await _syncEarthquakes();
    });
  }

  Future<void> stopSync() async {
    if (!_isRunning) return;

    _isRunning = false;
    _syncTimer?.cancel();
    _syncTimer = null;
    
    log('Stopped earthquake sync service');
  }

  Future<void> _syncEarthquakes() async {
    try {
      log('Syncing earthquakes...');
      
      // JMA API에서 최신 데이터 가져오기
      final jmaEarthquakes = await _jmaService.fetchLatestEarthquakes(limit: 50);
      
      if (jmaEarthquakes.isEmpty) {
        log('No earthquake data received from JMA');
        return;
      }

      // 새로운 데이터만 필터링
      final newEarthquakes = <EarthquakeModel>[];
      
      for (final earthquake in jmaEarthquakes) {
        final exists = await _supabaseService.earthquakeExists(earthquake.eventId);
        if (!exists) {
          newEarthquakes.add(earthquake);
        }
      }

      // 새로운 데이터가 있으면 Supabase에 저장
      if (newEarthquakes.isNotEmpty) {
        await _supabaseService.saveEarthquakes(newEarthquakes);
        log('Saved ${newEarthquakes.length} new earthquakes');
        
        // 스트림으로 업데이트 알림
        _notifyEarthquakeUpdate();
      } else {
        log('No new earthquakes to sync');
      }

    } catch (e) {
      log('Error during earthquake sync: $e');
    }
  }

  Future<void> _notifyEarthquakeUpdate() async {
    try {
      final earthquakes = await _supabaseService.getRecentEarthquakes(limit: 20);
      _earthquakeController?.add(earthquakes);
    } catch (e) {
      log('Error notifying earthquake update: $e');
    }
  }

  Future<void> manualSync() async {
    await _syncEarthquakes();
  }

  Future<List<EarthquakeModel>> getRecentEarthquakes({int limit = 20}) async {
    try {
      // Supabase에서 데이터 조회
      final supabaseEarthquakes = await _supabaseService.getRecentEarthquakes(limit: limit);
      
      // 데이터가 없으면 JMA API에서 가져와서 저장
      if (supabaseEarthquakes.isEmpty) {
        final jmaEarthquakes = await _jmaService.fetchLatestEarthquakes(limit: limit);
        if (jmaEarthquakes.isNotEmpty) {
          await _supabaseService.saveEarthquakes(jmaEarthquakes);
          return jmaEarthquakes;
        }
      }
      
      return supabaseEarthquakes;
    } catch (e) {
      log('Error getting recent earthquakes: $e');
      // 에러 시 JMA API에서 직접 가져오기
      return await _jmaService.fetchLatestEarthquakes(limit: limit);
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _earthquakeController?.close();
    _isRunning = false;
  }
}