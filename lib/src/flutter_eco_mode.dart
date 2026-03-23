import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_eco_mode/src/flutter_eco_mode_platform_interface.dart';
import 'package:flutter_eco_mode/src/messages.g.dart';
import 'package:flutter_eco_mode/src/streams/combine_latest.dart';

const double minEnoughBattery = 10.0;
const double minScoreMidRangeDevice = 0.5;
const double minScoreLowEndDevice = 0.3;
const int minWifiSignalStrength = -70;

/// An implementation of [FlutterEcoModePlatform] that uses pigeon.
class FlutterEcoMode extends FlutterEcoModePlatform {
  final EcoModeApi _api;
  Stream<double>? _batteryLevelStream;
  Stream<BatteryState>? _batteryStateStream;
  Stream<bool>? _batteryModeStream;
  Stream<Connectivity>? _connectivityStream;

  FlutterEcoMode({
    @visibleForTesting EcoModeApi? api,
    @visibleForTesting Stream<double>? batteryLevelStream,
    @visibleForTesting Stream<BatteryState>? batteryStateStream,
    @visibleForTesting Stream<bool>? batteryModeStream,
    @visibleForTesting Stream<Connectivity>? connectivityStream,
  })  : _api = api ?? EcoModeApi(),
        _batteryLevelStream = batteryLevelStream,
        _batteryStateStream = batteryStateStream,
        _batteryModeStream = batteryModeStream,
        _connectivityStream = connectivityStream;

  @override
  Future<String?> getPlatformInfo() async {
    return await _api.getPlatformInfo();
  }

  @override
  Future<double?> getBatteryLevel() async {
    return await _api.getBatteryLevel();
  }

  @override
  Future<bool> isBatteryInLowPowerMode() async {
    return await _api.isBatteryInLowPowerMode();
  }

  @override
  Future<BatteryState> getBatteryState() async {
    return await _api.getBatteryState();
  }

  @override
  Future<ThermalState> getThermalState() async {
    return await _api.getThermalState();
  }

  @override
  Future<int?> getProcessorCount() async {
    return await _api.getProcessorCount();
  }

  @override
  Future<int?> getTotalMemory() async {
    return await _api.getTotalMemory();
  }

  @override
  Future<int> getFreeMemory() async {
    return await _api.getFreeMemory();
  }

  @override
  Future<int> getTotalStorage() async {
    return await _api.getTotalStorage();
  }

  @override
  Future<int> getFreeStorage() async {
    return await _api.getFreeStorage();
  }

  @override
  Future<DeviceRange?> getDeviceRange() async {
    return _api
        .getEcoScore()
        .then<DeviceRange?>((value) {
          if (value == null) {
            throw Exception('Error while getting eco score');
          }
          final range = _buildRange(value);
          return DeviceRange(
            score: value,
            range: range,
            isLowEndDevice: range == DeviceEcoRange.lowEnd,
          );
        })
        .onError((error, stackTrace) {
          log(stackTrace.toString(), error: error);
          return null;
        });
  }

  DeviceEcoRange _buildRange(double score) {
    switch (score) {
      case > minScoreMidRangeDevice:
        return DeviceEcoRange.highEnd;
      case > minScoreLowEndDevice:
        return DeviceEcoRange.midRange;
      default:
        return DeviceEcoRange.lowEnd;
    }
  }

  @override
  Future<bool?> isBatteryEcoMode() async {
    return Future.wait([
          _isNotEnoughBattery(),
          _isBatteryLowPowerMode(),
          _isSeriousAtLeastBatteryState(),
        ])
        .then<bool?>((List<bool?> value) {
          if (value.every((element) => element == null)) {
            throw Exception('Error while getting battery eco mode');
          }
          return value.any((element) => element ?? false);
        })
        .onError((error, stackTrace) {
          log(stackTrace.toString(), error: error);
          return null;
        });
  }

  Future<bool?> _isNotEnoughBattery() async {
    try {
      return Future.wait([
        Future<bool?>.value((await getBatteryLevel())?.isNotEnough),
        Future<bool?>.value((await getBatteryState()).isDischarging),
      ]).then(
        (List<bool?> value) => value.every((bool? element) => element ?? false),
      );
    } catch (error, stackTrace) {
      log(stackTrace.toString(), error: error);
      return null;
    }
  }

  Future<bool?> _isBatteryLowPowerMode() async {
    try {
      return await isBatteryInLowPowerMode();
    } catch (error, stackTrace) {
      log(stackTrace.toString(), error: error);
      return null;
    }
  }

  Future<bool?> _isSeriousAtLeastBatteryState() async {
    try {
      return Future.value((await getThermalState()).isSeriousAtLeast);
    } catch (error, stackTrace) {
      log(stackTrace.toString(), error: error);
      return null;
    }
  }

  @override
  Stream<bool> get lowPowerModeEventStream => _batteryModeStream ??= batteryMode().asBroadcastStream();

  @override
  Stream<double> get batteryLevelEventStream => _batteryLevelStream ??= batteryLevel().asBroadcastStream();

  @override
  Stream<BatteryState> get batteryStateEventStream => _batteryStateStream ??= batteryState().asBroadcastStream();

  @override
  Stream<bool?> get isBatteryEcoModeStream =>
      CombineLatestStream.list([
        _isNotEnoughBatteryStream(),
        lowPowerModeEventStream.withInitialValue(isBatteryInLowPowerMode()),
      ]).map((event) => event.any((element) => element)).asBroadcastStream();

  Stream<bool> _isNotEnoughBatteryStream() =>
      CombineLatestStream.list([
        batteryLevelEventStream.map((event) => event.isNotEnough),
        batteryStateEventStream.map((event) => event.isDischarging),
      ]).map((event) => event.every((element) => element)).asBroadcastStream();

  @override
  Stream<Connectivity> get connectivityStream => _connectivityStream ??= connectivity().asBroadcastStream();

  @override
  Future<Connectivity> getConnectivity() async {
    return await _api.getConnectivity();
  }

  @override
  Future<bool?> hasEnoughNetwork() async {
    try {
      final connectivity = await getConnectivity();
      return connectivity.isEnough;
    } catch (error, stackTrace) {
      log(stackTrace.toString(), error: error);
      return null;
    }
  }

  @override
  Stream<bool?> hasEnoughNetworkStream() {
    return connectivityStream
        .map((event) => event.isEnough)
        .asBroadcastStream();
  }
}

extension _BatteryLevel on double {
  bool get isNotEnough => this < minEnoughBattery;
}

extension on BatteryState {
  bool get isDischarging => this == BatteryState.discharging;
}

extension on ThermalState {
  bool get isSeriousAtLeast =>
      this == ThermalState.serious || this == ThermalState.critical;
}

extension on Connectivity {
  bool? get isEnough =>
      type == ConnectivityType.unknown
          ? null
          : (_isMobileEnoughNetwork ||
              _isWifiEnoughNetwork ||
              type == ConnectivityType.ethernet);

  bool get _isMobileEnoughNetwork => [
    ConnectivityType.mobile5g,
    ConnectivityType.mobile4g,
    ConnectivityType.mobile3g,
  ].contains(type);

  bool get _isWifiEnoughNetwork =>
      ConnectivityType.wifi == type && wifiSignalStrength != null
          ? wifiSignalStrength! >= minWifiSignalStrength
          : false;
}

extension StreamExtensions<T> on Stream<T> {
  Stream<T> withInitialValue(Future<T> value) async* {
    yield await value;
    yield* this;
  }
}
