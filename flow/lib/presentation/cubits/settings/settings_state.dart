import 'package:flutter/material.dart';

class SettingsState {
  final ThemeMode themeMode;
  final String eqPreset;
  final String downloadQuality;
  final String? downloadPath;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.eqPreset = 'Normal',
    this.downloadQuality = 'High',
    this.downloadPath,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? eqPreset,
    String? downloadQuality,
    String? Function()? downloadPath,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    eqPreset: eqPreset ?? this.eqPreset,
    downloadQuality: downloadQuality ?? this.downloadQuality,
    downloadPath: downloadPath != null ? downloadPath() : this.downloadPath,
  );
}
