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

  static Widget _imageErrorBuilder(BuildContext context, Object error, StackTrace? stackTrace) {
    return const Icon(
      Icons.info_outline,
      size: 100,
      color: Colors.grey,
    );
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Image(
              image: AssetImage('assets/images/earthquake_safety.png'),
              width: 200,
              height: 200,
              errorBuilder: _imageErrorBuilder,
            ),
            const SizedBox(height: 24),
            Text(
              '현재 지진 데이터가 없습니다',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '안전한 상태입니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🏠 책상 아래로 대피하여 안전을 확보하세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
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
    final imagePath = ColorUtils.getEarthquakeImagePath(latestEarthquake.magnitude);
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
        image: DecorationImage(
          image: AssetImage(imagePath),
          alignment: Alignment.center,
          opacity: 0.15,
          fit: BoxFit.contain,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Text(
              '최신 지진 정보',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                shadows: [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 3,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Image.asset(
              imagePath,
              width: 100,
              height: 100,
              errorBuilder: (context, error, stackTrace) {
                return Text(
                  ColorUtils.getEarthquakeEmoji(latestEarthquake.magnitude),
                  style: const TextStyle(fontSize: 50),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              latestEarthquake.koreanRegionName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 3,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '규모 ',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[600],
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ],
                  ),
                ),
                Text(
                  latestEarthquake.magnitude.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '최대 진도: ${ColorUtils.getIntensityDescription(latestEarthquake.maxIntensity)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '발생: ${dateFormat.format(latestEarthquake.detectedAt)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                shadows: [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
            ),
            Text(
              '발표: ${dateFormat.format(latestEarthquake.announcedAt)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                shadows: [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
            ),
            ],
          ),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateHeader(dateKey),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${earthquakesForDate.length}\uac74',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...earthquakesForDate.map((earthquake) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EarthquakeCard(
                earthquake: earthquake,
                onTap: () {
                  _showEarthquakeDetails(context, earthquake);
                },
              ),
            )),
            const SizedBox(height: 16),
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
      return '오늘 (${DateFormat('yyyy년 MM월 dd일').format(date)})';
    } else if (targetDate == yesterday) {
      return '어제 (${DateFormat('yyyy년 MM월 dd일').format(date)})';
    } else {
      return DateFormat('yyyy년 MM월 dd일').format(date);
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