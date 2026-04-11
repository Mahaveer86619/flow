import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/storage/local_storage.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(_initial());

  static SettingsState _initial() {
    final s = LocalStorage.instance;
    return SettingsState(
      themeMode: _parseTheme(s.themeModePref),
      eqPreset: s.eqPreset,
      downloadQuality: s.downloadQuality,
      downloadPath: s.downloadPath,
    );
  }

  static ThemeMode _parseTheme(String v) => switch (v) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };

  void setThemeMode(ThemeMode mode) {
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      _ => 'dark',
    };
    LocalStorage.instance.saveThemeMode(str);
    emit(state.copyWith(themeMode: mode));
  }

  void setEqPreset(String preset) {
    LocalStorage.instance.saveEqPreset(preset);
    emit(state.copyWith(eqPreset: preset));
  }

  void setDownloadQuality(String quality) {
    LocalStorage.instance.saveDownloadQuality(quality);
    emit(state.copyWith(downloadQuality: quality));
  }

  void setDownloadPath(String? path) {
    if (path == null) return;
    LocalStorage.instance.saveDownloadPath(path);
    emit(state.copyWith(downloadPath: path));
  }
}
