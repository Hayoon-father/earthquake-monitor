import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/earthquake_model.dart';
import '../services/earthquake_sync_service.dart';
import '../widgets/earthquake_card.dart';
import '../utils/color_utils.dart';

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
        child: Text(
          '지진 데이터가 없습니다',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchEarthquakes,
      child: Column(
        children: [
          // 최신 지진 정보 (화면의 절반)
          _buildLatestEarthquakeSection(),
          // 이전 지진 정보 목록
          Expanded(
            child: _buildHistoricalEarthquakesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestEarthquakeSection() {
    if (_earthquakes.isEmpty) return const SizedBox.shrink();
    
    final latestEarthquake = _earthquakes.first;
    final backgroundColor = ColorUtils.getBackgroundColor(latestEarthquake.magnitude);
    final color = ColorUtils.getEarthquakeColor(latestEarthquake.magnitude);
    final emoji = ColorUtils.getEarthquakeEmoji(latestEarthquake.magnitude);
    final dateFormat = DateFormat('yyyy년 MM월 dd일 HH:mm');
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.4, // 화면의 40%
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: color.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '최신 지진 정보',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              emoji,
              style: const TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 16),
            Text(
              latestEarthquake.koreanRegionName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '규모 ',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  latestEarthquake.magnitude.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '최대 진도: ${ColorUtils.getIntensityDescription(latestEarthquake.maxIntensity)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '발생: ${dateFormat.format(latestEarthquake.detectedAt)}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '발표: ${dateFormat.format(latestEarthquake.announcedAt)}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricalEarthquakesList() {
    if (_earthquakes.length <= 1) {
      return const Center(
        child: Text(
          '과거 지진 데이터가 없습니다',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // 최신을 제외한 나머지 지진들
    final historicalEarthquakes = _earthquakes.skip(1).toList();
    
    // 날짜별로 그룹화
    final Map<String, List<EarthquakeModel>> groupedByDate = {};
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    for (final earthquake in historicalEarthquakes) {
      final dateKey = dateFormat.format(earthquake.detectedAt);
      if (!groupedByDate.containsKey(dateKey)) {
        groupedByDate[dateKey] = [];
      }
      groupedByDate[dateKey]!.add(earthquake);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedByDate.length,
      itemBuilder: (context, index) {
        final dateKey = groupedByDate.keys.elementAt(index);
        final earthquakesForDate = groupedByDate[dateKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _formatDateHeader(dateKey),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            ...earthquakesForDate.map((earthquake) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EarthquakeCard(
                earthquake: earthquake,
                onTap: () {
                  _showEarthquakeDetails(context, earthquake);
                },
              ),
            )),
          ],
        );
      },
    );
  }

  String _formatDateHeader(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate == today) {
      return '오늘';
    } else if (targetDate == yesterday) {
      return '어제';
    } else {
      return DateFormat('MM월 dd일 (E)', 'ko_KR').format(date);
    }
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