import 'package:flutter/material.dart';

enum StreamingMode { standalone, relayFromPeer, hybridPreferLocal }

class SettingsState {
  final ThemeMode themeMode;
  final String eqPreset;
  final String downloadQuality;
  final String? downloadPath;
  final int? cacheBudgetMB;
  final String downloadFormat;
  final int downloadBitrate;
  final StreamingMode streamingMode;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.eqPreset = 'Normal',
    this.downloadQuality = 'High',
    this.downloadPath,
    this.cacheBudgetMB = 500,
    this.downloadFormat = 'mp3',
    this.downloadBitrate = 192,
    this.streamingMode = StreamingMode.standalone,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? eqPreset,
    String? downloadQuality,
    String? Function()? downloadPath,
    int? Function()? cacheBudgetMB,
    String? downloadFormat,
    int? downloadBitrate,
    StreamingMode? streamingMode,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    eqPreset: eqPreset ?? this.eqPreset,
    downloadQuality: downloadQuality ?? this.downloadQuality,
    downloadPath: downloadPath != null ? downloadPath() : this.downloadPath,
    cacheBudgetMB: cacheBudgetMB != null ? cacheBudgetMB() : this.cacheBudgetMB,
    downloadFormat: downloadFormat ?? this.downloadFormat,
    downloadBitrate: downloadBitrate ?? this.downloadBitrate,
    streamingMode: streamingMode ?? this.streamingMode,
  );
}


