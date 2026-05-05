import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppRadius {
  static const double small = 4.0;
  static const double medium = 8.0;
  static const double large = 12.0;

  static BorderRadius get smallBorderRadius => BorderRadius.circular(small);
  static BorderRadius get mediumBorderRadius => BorderRadius.circular(medium);
  static BorderRadius get largeBorderRadius => BorderRadius.circular(large);

  static RoundedRectangleBorder get smallShape =>
      RoundedRectangleBorder(borderRadius: smallBorderRadius);
  static RoundedRectangleBorder get mediumShape =>
      RoundedRectangleBorder(borderRadius: mediumBorderRadius);
  static RoundedRectangleBorder get largeShape =>
      RoundedRectangleBorder(borderRadius: largeBorderRadius);
}

class AppConfig {
  static const String appName = 'Flow';
  static const String appStorageSubDir = 'flow';

  static bool get intelligenceActive =>
      dotenv.get('INTELLIGENCE_ACTIVE', fallback: 'true').toLowerCase() ==
      'true';
}
