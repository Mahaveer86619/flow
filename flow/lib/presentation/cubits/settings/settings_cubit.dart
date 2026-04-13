import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/logger/app_logger.dart';
import '../../../data/sources/auth_data_source.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/auth/auth_event_bus.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final AuthCubit _authCubit;
  final AuthDataSource _authSource;
  StreamSubscription? _authSubscription;
  SettingsCubit({required AuthCubit authCubit, AuthDataSource? authSource})
    : _authCubit = authCubit,
      _authSource = authSource ?? AuthDataSource(),
      super(_initial()) {
    _authSubscription = AuthEventBus.settingsLoaded.listen((settings) {
      AppLogger.i('SettingsCubit', 'Remote settings loaded event received');
      loadRemoteSettings(settings);
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

  void loadRemoteSettings(Map<String, dynamic>? settings) {
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

  Future<void> _syncToRemote() async {
    final token = _authCubit.state.token;
    if (token == null) return;

    try {
      final settings = {
        'download_paths': LocalStorage.instance.allPlatformDownloadPaths,
        'theme_mode': LocalStorage.instance.themeModePref,
        'download_quality': LocalStorage.instance.downloadQuality,
        'eq_preset': LocalStorage.instance.eqPreset,
      };
      await _authSource.updateSettings(token, settings);
      AppLogger.d('SettingsCubit', 'Settings synced to remote');
    } catch (e) {
      AppLogger.w('SettingsCubit', 'Failed to sync settings: $e');
    }
  }

  void setThemeMode(ThemeMode mode) {
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      _ => 'dark',
    };
    LocalStorage.instance.saveThemeMode(str);
    emit(state.copyWith(themeMode: mode));
    _syncToRemote();
  }

  void setEqPreset(String preset) {
    LocalStorage.instance.saveEqPreset(preset);
    emit(state.copyWith(eqPreset: preset));
    _syncToRemote();
  }

  void setDownloadQuality(String quality) {
    LocalStorage.instance.saveDownloadQuality(quality);
    emit(state.copyWith(downloadQuality: quality));
    _syncToRemote();
  }

  void setDownloadPath(String? path) {
    if (path == null) return;
    LocalStorage.instance.saveDownloadPath(path);
    emit(state.copyWith(downloadPath: () => path));
    _syncToRemote();
  }

  void clearDownloadPath() {
    LocalStorage.instance.clearDownloadPath();
    emit(state.copyWith(downloadPath: () => null));
    _syncToRemote();
  }
}
