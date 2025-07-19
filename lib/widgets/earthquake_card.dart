import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/earthquake_model.dart';
import '../utils/color_utils.dart';

class EarthquakeCard extends StatelessWidget {
  final EarthquakeModel earthquake;
  final VoidCallback? onTap;

  const EarthquakeCard({
    super.key,
    required this.earthquake,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final color = ColorUtils.getEarthquakeColor(earthquake.magnitude);
    final imagePath = ColorUtils.getEarthquakeImagePath(earthquake.magnitude);
    final intensityDesc = ColorUtils.getIntensityDescription(earthquake.maxIntensity);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Image.asset(
                        imagePath,
                        width: 35,
                        height: 35,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            ColorUtils.getEarthquakeEmoji(earthquake.magnitude),
                            style: const TextStyle(fontSize: 20),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          earthquake.koreanRegionName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '규모: ${earthquake.magnitude.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        intensityDesc,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(earthquake.detectedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '발표: ${dateFormat.format(earthquake.announcedAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}