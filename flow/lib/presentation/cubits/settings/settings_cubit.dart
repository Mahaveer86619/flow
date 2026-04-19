import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/network/download_service.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/auth/auth_event_bus.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  StreamSubscription? _authSubscription;
  
  SettingsCubit({required AuthCubit authCubit})
    : super(_initial()) {
    _authSubscription = AuthEventBus.settingsLoaded.listen((settings) {
      AppLogger.i('SettingsCubit', 'Settings loaded event received');
      loadSettings(settings);
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

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

  void loadSettings(Map<String, dynamic>? settings) {
    if (settings == null) return;

    final downloadPaths = settings['download_paths'] as Map<String, dynamic>?;
    if (downloadPaths != null) {
      LocalStorage.instance.saveAllDownloadPaths(downloadPaths);
    }

    final theme = settings['theme_mode'] as String?;
    if (theme != null) LocalStorage.instance.saveThemeMode(theme);

    final quality = settings['download_quality'] as String?;
    if (quality != null) LocalStorage.instance.saveDownloadQuality(quality);

    final preset = settings['eq_preset'] as String?;
    if (preset != null) LocalStorage.instance.saveEqPreset(preset);

    // Refresh state from updated LocalStorage
    final s = LocalStorage.instance;
    emit(
      state.copyWith(
        themeMode: _parseTheme(s.themeModePref),
        eqPreset: s.eqPreset,
        downloadQuality: s.downloadQuality,
        downloadPath: () => s.downloadPath,
      ),
    );
  }

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
    final oldPath = LocalStorage.instance.downloadPath;
    LocalStorage.instance.saveDownloadPath(path);
    emit(state.copyWith(downloadPath: () => path));

    if (oldPath != null && oldPath != path) {
      DownloadService.instance.moveDownloads(oldPath, path);
    }
  }

  void clearDownloadPath() {
    LocalStorage.instance.clearDownloadPath();
    emit(state.copyWith(downloadPath: () => null));
  }
}
