import 'package:flutter/material.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final Color colorPrimary;
  final Color colorSecondary;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.colorPrimary,
    required this.colorSecondary,
  });
}

class Playlist {
  final String id;
  final String name;
  final String description;
  final List<Song> songs;
  final Color color;

  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.songs,
    required this.color,
  });
}
