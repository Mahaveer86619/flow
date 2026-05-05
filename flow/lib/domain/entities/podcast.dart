import 'package:flutter/foundation.dart';

@immutable
class Podcast {
  final String id;
  final String title;
  final String? publisher;
  final String? thumbnailUrl;
  final String? description;

  const Podcast({
    required this.id,
    required this.title,
    this.publisher,
    this.thumbnailUrl,
    this.description,
  });
}
