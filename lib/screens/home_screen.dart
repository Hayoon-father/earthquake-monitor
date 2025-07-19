import 'package:flutter/material.dart';
import '../models/earthquake_model.dart';
import '../services/earthquake_sync_service.dart';
import '../widgets/earthquake_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EarthquakeSyncService _syncService = EarthquakeSyncService();
  List<EarthquakeModel> _earthquakes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _fetchEarthquakes();
    await _syncService.startSync(interval: const Duration(minutes: 2));
    
    // 실시간 업데이트 구독
    _syncService.earthquakeStream.listen((earthquakes) {
      if (mounted) {
        setState(() {
          _earthquakes = earthquakes;
        });
      }
    });
  }

  Future<void> _fetchEarthquakes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final earthquakes = await _syncService.getRecentEarthquakes(limit: 20);
      setState(() {
        _earthquakes = earthquakes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('지진 정보'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _syncService.manualSync();
              await _fetchEarthquakes();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              '데이터를 불러올 수 없습니다',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchEarthquakes,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_earthquakes.isEmpty) {
      return const Center(
        child: Text('지진 데이터가 없습니다'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchEarthquakes,
      child: ListView.builder(
        itemCount: _earthquakes.length,
        itemBuilder: (context, index) {
          final earthquake = _earthquakes[index];
          return EarthquakeCard(
            earthquake: earthquake,
            onTap: () {
              _showEarthquakeDetails(context, earthquake);
            },
          );
        },
      ),
    );
  }

  void _showEarthquakeDetails(BuildContext context, EarthquakeModel earthquake) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(earthquake.koreanRegionName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('지진 규모: ${earthquake.magnitude.toStringAsFixed(1)}'),
            const SizedBox(height: 8),
            Text('최대 진도: ${earthquake.maxIntensity}'),
            const SizedBox(height: 8),
            Text('발생 시간: ${earthquake.detectedAt}'),
            const SizedBox(height: 8),
            Text('발표 시간: ${earthquake.announcedAt}'),
            const SizedBox(height: 8),
            Text('원본 지역명: ${earthquake.regionName}', 
                 style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}