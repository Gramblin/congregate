import 'package:flutter/material.dart';

/// One "author" of stories (community or business) in the horizontal strip.
class StoryItem {
  const StoryItem({
    required this.id,
    required this.name,
    required this.gradient,
    required this.pageCount,
  });

  final String id;
  final String name;
  final List<Color> gradient;

  /// Number of individual story pages under this author.
  final int pageCount;
}
