import 'package:flutter/material.dart';

class ColorUtils {
  static Color getEarthquakeColor(double magnitude) {
    if (magnitude < 5.0) {
      return Colors.yellow;
    } else if (magnitude < 7.0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  static String getEarthquakeEmoji(double magnitude) {
    if (magnitude < 5.0) {
      return '🟡';
    } else if (magnitude < 7.0) {
      return '🟠';
    } else {
      return '🔴';
    }
  }

  static String getIntensityDescription(int intensity) {
    switch (intensity) {
      case 0:
        return '무감';
      case 1:
        return '진도 1';
      case 2:
        return '진도 2';
      case 3:
        return '진도 3';
      case 4:
        return '진도 4';
      case 5:
        return '진도 5약';
      case 6:
        return '진도 6약';
      case 7:
        return '진도 7';
      default:
        return '진도 $intensity';
    }
  }
}