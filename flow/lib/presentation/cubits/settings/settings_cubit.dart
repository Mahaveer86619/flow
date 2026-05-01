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
      cacheBudgetMB: s.cacheBudgetMB,
      downloadFormat: s.downloadFormat,
      downloadBitrate: s.downloadBitrate,
      streamingMode: _parseStreamingMode(s.streamingMode),
    );
  }

  static ThemeMode _parseTheme(String v) => switch (v) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };

  static StreamingMode _parseStreamingMode(String v) => switch (v) {
    'relayFromPeer' => StreamingMode.relayFromPeer,
    'hybridPreferLocal' => StreamingMode.hybridPreferLocal,
    _ => StreamingMode.standalone,
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

    final budget = settings['cache_budget_mb'] as int?;
    if (budget != null) LocalStorage.instance.saveCacheBudgetMB(budget);

    final format = settings['download_format'] as String?;
    if (format != null) LocalStorage.instance.saveDownloadFormat(format);

    final bitrate = settings['download_bitrate'] as int?;
    if (bitrate != null) LocalStorage.instance.saveDownloadBitrate(bitrate);

    final sMode = settings['streaming_mode'] as String?;
    if (sMode != null) LocalStorage.instance.saveStreamingMode(sMode);

    // Refresh state from updated LocalStorage
    final s = LocalStorage.instance;
    emit(
      state.copyWith(
        themeMode: _parseTheme(s.themeModePref),
        eqPreset: s.eqPreset,
        downloadQuality: s.downloadQuality,
        downloadPath: () => s.downloadPath,
        cacheBudgetMB: () => s.cacheBudgetMB,
        downloadFormat: s.downloadFormat,
        downloadBitrate: s.downloadBitrate,
        streamingMode: _parseStreamingMode(s.streamingMode),
      ),
    );
  }

  void setStreamingMode(StreamingMode mode) {
    LocalStorage.instance.saveStreamingMode(mode.name);
    emit(state.copyWith(streamingMode: mode));
  }


  void setCacheBudgetMB(int? mb) {
    LocalStorage.instance.saveCacheBudgetMB(mb);
    emit(state.copyWith(cacheBudgetMB: () => mb));
  }

  void setDownloadFormat(String format) {
    LocalStorage.instance.saveDownloadFormat(format);
    emit(state.copyWith(downloadFormat: format));
  }

  void setDownloadBitrate(int bitrate) {
    LocalStorage.instance.saveDownloadBitrate(bitrate);
    emit(state.copyWith(downloadBitrate: bitrate));
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
