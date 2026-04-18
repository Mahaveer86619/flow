import 'package:flutter/material.dart';

class AppRadius {
  static const double small = 4.0;
  static const double medium = 8.0;
  static const double large = 12.0;

  static BorderRadius get smallBorderRadius => BorderRadius.circular(small);
  static BorderRadius get mediumBorderRadius => BorderRadius.circular(medium);
  static BorderRadius get largeBorderRadius => BorderRadius.circular(large);

  static RoundedRectangleBorder get smallShape => RoundedRectangleBorder(borderRadius: smallBorderRadius);
  static RoundedRectangleBorder get mediumShape => RoundedRectangleBorder(borderRadius: mediumBorderRadius);
  static RoundedRectangleBorder get largeShape => RoundedRectangleBorder(borderRadius: largeBorderRadius);
  
  static const String emoji1 = 'ಥ_ಥ';
  static const String emoji2 = '╰(*°▽°*)╯';
  static const String emoji3 = '>_<';
  
}
