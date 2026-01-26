import 'dart:convert';
import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateConfig {
  final String minVersion;
  final String maxVersion;
  final String title;
  final String titleKm;
  final String message;
  final String messageKm;
  final String storeUrl;
  final bool mandatory;

  UpdateConfig({
    required this.minVersion,
    required this.maxVersion,
    required this.title,
    required this.titleKm,
    required this.message,
    required this.messageKm,
    required this.storeUrl,
    required this.mandatory,
  });

  String getLocalizedTitle(String locale) {
    if (locale == 'km') {
      return titleKm.isNotEmpty ? titleKm : title;
    }
    return title;
  }

  String getLocalizedMessage(String locale) {
    if (locale == 'km') {
      return messageKm.isNotEmpty ? messageKm : message;
    }
    return message;
  }

  factory UpdateConfig.fromJson(Map<String, dynamic> json) {
    return UpdateConfig(
      minVersion: json['min_version']?.toString() ?? '0.0.0',
      maxVersion: json['max_version']?.toString() ?? '0.0.0',
      title: json['title'] ?? 'Force Update',
      titleKm: json['title_km'] ?? 'Force Update',
      message: json['message'] ?? 'Your app request to update now',
      messageKm: json['message_km'] ?? 'Your app request to update now',
      storeUrl: json['store_url'] ?? '',
      mandatory: json['mandatory'] ?? true,
    );
  }
}

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> init() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    
    // Set default empty structure to avoid errors
    await _remoteConfig.setDefaults({
      "force_update": jsonEncode({
        "android": {
          "min_version": "1.0.0",
          "max_version": "1.0.0",
          "title": "Force Update",
          "message": "Your app request to update now",
          "store_url": "",
          "mandatory": true
        },
        "ios": {
          "min_version": "1.0.0",
          "max_version": "1.0.0",
          "title": "Force Update",
          "message": "Your app request to update now",
          "store_url": "",
          "mandatory": true
        }
      })
    });

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      print('Remote Config fetch failed: $e');
    }
  }

  Future<UpdateConfig?> checkUpdate() async {
    final String configJson = _remoteConfig.getString("force_update");
    debugPrint("remoteConfig: $configJson");
    if (configJson.isEmpty) return null;

    try {
      final Map<String, dynamic> data = jsonDecode(configJson);
      final String platformKey = Platform.isAndroid ? 'android' : 'ios';
      
      if (!data.containsKey(platformKey)) return null;
      
      final Map<String, dynamic> platformData = data[platformKey];
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      final String minVersion = platformData['min_version']?.toString() ?? '0.0.0';
      final String maxVersion = platformData['max_version']?.toString() ?? '0.0.0';

      final currentV = _parseVersion(currentVersion);
      final minV = _parseVersion(minVersion);
      final maxV = _parseVersion(maxVersion);

      // New Logic: Show update if min_version <= current <= max_version
      final bool isWithinRange = _compareVersions(currentV, minV) >= 0 && 
                                _compareVersions(currentV, maxV) <= 0;

      if (!isWithinRange) return null;

      return UpdateConfig(
        minVersion: minVersion,
        maxVersion: maxVersion,
        title: platformData['title'] ?? 'Force Update',
        titleKm: platformData['title_km'] ?? '',
        message: platformData['message'] ?? 'Your app request to update now',
        messageKm: platformData['message_km'] ?? '',
        storeUrl: platformData['store_url'] ?? '',
        mandatory: platformData['mandatory'] ?? true,
      );
    } catch (e) {
      print('Error parsing remote config: $e');
      return null;
    }
  }

  bool _shouldUpdate(String current, String min, String max) {
    try {
      final currentV = _parseVersion(current);
      final minV = _parseVersion(min);
      final maxV = _parseVersion(max);

      // If current version is less than min_version, definitely update if mandatory
      // If current version is between min and max, show update?
      // User says: "specific app version range between min and max version"
      
      // Standard interpretation:
      // If current < min -> Mandatory update
      // If min <= current < max -> Optional update OR mandatory if config says so.
      
      // I will check if current < max. If so, it needs an update.
      // The "mandatory" flag in the JSON then decides if they can dismiss it.
      
      return _compareVersions(currentV, maxV) < 0;
    } catch (e) {
      return false;
    }
  }

  List<int> _parseVersion(String v) {
    try {
      // Handle versions like "1.0.0", "1.0", or "1"
      final parts = v.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      while (parts.length < 3) {
        parts.add(0);
      }
      return parts.take(3).toList();
    } catch (e) {
      return [0, 0, 0];
    }
  }

  int _compareVersions(List<int> v1, List<int> v2) {
    for (int i = 0; i < 3; i++) {
      int a = i < v1.length ? v1[i] : 0;
      int b = i < v2.length ? v2[i] : 0;
      if (a < b) return -1;
      if (a > b) return 1;
    }
    return 0;
  }
}
