import 'package:flutter/material.dart';

class SettingsState {
  final ThemeMode themeMode;
  final String eqPreset;
  final String downloadQuality;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.eqPreset = 'Normal',
    this.downloadQuality = 'High',
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? eqPreset,
    String? downloadQuality,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    eqPreset: eqPreset ?? this.eqPreset,
    downloadQuality: downloadQuality ?? this.downloadQuality,
  );
}
