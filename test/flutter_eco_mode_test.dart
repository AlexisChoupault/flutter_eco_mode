import 'dart:async';

import 'package:flutter_eco_mode/src/flutter_eco_mode.dart';
import 'package:flutter_eco_mode/src/flutter_eco_mode_platform_interface.dart';
import 'package:flutter_eco_mode/src/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEcoModeApi extends Mock implements EcoModeApi {}

void main() {
  late StreamController<double> batteryLevelStreamController;
  late StreamController<BatteryState> batteryStateStreamController;
  late StreamController<bool> batteryModeStreamController;
  late StreamController<Connectivity> connectivityStreamController;
  late EcoModeApi ecoModeApi;

  FlutterEcoMode buildEcoMode() => FlutterEcoMode(
    api: ecoModeApi,
    batteryLevelStream: batteryLevelStreamController.stream,
    batteryStateStream: batteryStateStreamController.stream,
    batteryModeStream: batteryModeStreamController.stream,
    connectivityStream: connectivityStreamController.stream,
  );

  setUp(() {
    ecoModeApi = MockEcoModeApi();
    when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) async => 100.0);
    when(
      () => ecoModeApi.getBatteryState(),
    ).thenAnswer((_) async => BatteryState.charging);
    when(
      () => ecoModeApi.isBatteryInLowPowerMode(),
    ).thenAnswer((_) async => false);
    when(
      () => ecoModeApi.getThermalState(),
    ).thenAnswer((_) async => ThermalState.safe);
    when(
      () => ecoModeApi.getConnectivity(),
    ).thenAnswer((_) async => Connectivity(type: ConnectivityType.unknown));
    batteryLevelStreamController = StreamController<double>.broadcast();
    batteryStateStreamController = StreamController<BatteryState>.broadcast();
    batteryModeStreamController = StreamController<bool>.broadcast();
    connectivityStreamController = StreamController<Connectivity>.broadcast();
  });

  tearDown(() {
    batteryLevelStreamController.close();
    batteryStateStreamController.close();
    batteryModeStreamController.close();
    connectivityStreamController.close();
  });

  group('Battery Eco Mode', () {
    group('Future isBatteryEcoMode', () {
      test('should return false initially', () async {
        expect(await buildEcoMode().isBatteryEcoMode(), false);
      });

      test(
        'should return true when not enough battery and discharging',
        () async {
          when(
            () => ecoModeApi.getBatteryLevel(),
          ).thenAnswer((_) async => minEnoughBattery - 1);
          when(
            () => ecoModeApi.getBatteryState(),
          ).thenAnswer((_) async => BatteryState.discharging);
          expect(await buildEcoMode().isBatteryEcoMode(), true);
        },
      );

      test('should return true when battery in low power mode', () async {
        when(
          () => ecoModeApi.isBatteryInLowPowerMode(),
        ).thenAnswer((_) async => true);
        expect(await buildEcoMode().isBatteryEcoMode(), true);
      });

      test('should return true when thermal state is critical', () async {
        when(
          () => ecoModeApi.getThermalState(),
        ).thenAnswer((_) async => ThermalState.critical);
        expect(await buildEcoMode().isBatteryEcoMode(), true);
      });

      test('should return true when thermal state is serious', () async {
        when(
          () => ecoModeApi.getThermalState(),
        ).thenAnswer((_) async => ThermalState.serious);
        expect(await buildEcoMode().isBatteryEcoMode(), true);
      });

      test(
        'should return true when thermal state is serious and battery level is in error',
        () async {
          when(
            () => ecoModeApi.getThermalState(),
          ).thenAnswer((_) async => ThermalState.serious);
          when(
            () => ecoModeApi.getBatteryLevel(),
          ).thenAnswer((_) => Future.error('error battery level'));
          expect(await buildEcoMode().isBatteryEcoMode(), true);
        },
      );

      test(
        'should return false when thermal state is safe and battery level is in error',
        () async {
          when(
            () => ecoModeApi.getThermalState(),
          ).thenAnswer((_) async => ThermalState.safe);
          when(
            () => ecoModeApi.getBatteryLevel(),
          ).thenAnswer((_) => Future.error('error battery level'));
          expect(await buildEcoMode().isBatteryEcoMode(), false);
        },
      );

      test('should return null when impossible to get battery info', () async {
        when(
          () => ecoModeApi.getBatteryLevel(),
        ).thenAnswer((_) => Future.error('error battery level'));
        when(
          () => ecoModeApi.getBatteryState(),
        ).thenAnswer((_) => Future.error('error battery state'));
        when(
          () => ecoModeApi.isBatteryInLowPowerMode(),
        ).thenAnswer((_) => Future.error('error battery low power mode'));
        when(
          () => ecoModeApi.getThermalState(),
        ).thenAnswer((_) => Future.error('error thermal state'));
        expect(await buildEcoMode().isBatteryEcoMode(), null);
      });

      test('should wait all the future to complete the statement', () async {
        when(() => ecoModeApi.getBatteryLevel()).thenAnswer(
          (_) => Future.delayed(const Duration(milliseconds: 100), () => 100.0),
        );
        when(() => ecoModeApi.getBatteryState()).thenAnswer(
          (_) => Future.delayed(
            const Duration(milliseconds: 200),
            () => BatteryState.charging,
          ),
        );
        when(() => ecoModeApi.isBatteryInLowPowerMode()).thenAnswer(
          (_) => Future.delayed(const Duration(milliseconds: 300), () => false),
        );
        when(() => ecoModeApi.getThermalState()).thenAnswer(
          (_) => Future.delayed(
            const Duration(milliseconds: 400),
            () => ThermalState.serious,
          ),
        );
        expect(await buildEcoMode().isBatteryEcoMode(), true);
      });
    });

    group('Stream isBatteryEcoMode', () {
      test('should return false initially', () async {
        final ecoMode = buildEcoMode();
        ecoMode.isBatteryEcoModeStream.listen(
          expectAsync1((event) {
            expect(event, false);
          }, count: 1),
        );
        // Émettre APRÈS avoir attaché le listener
        batteryLevelStreamController.add(100.0);
        batteryStateStreamController.add(BatteryState.charging);
        batteryModeStreamController.add(false);
      });

      test(
        'should return false when not enough battery and charging',
        () async {
          final ecoMode = buildEcoMode();
          ecoMode.isBatteryEcoModeStream.listen(
            expectAsync1((event) {
              expect(event, false);
            }, count: 1),
          );
          batteryLevelStreamController.add(minEnoughBattery - 1);
          batteryStateStreamController.add(BatteryState.charging);
          batteryModeStreamController.add(false);
        },
      );

      test('should return false when enough battery and discharging', () async {
        final ecoMode = buildEcoMode();
        ecoMode.isBatteryEcoModeStream.listen(
          expectAsync1((event) {
            expect(event, false);
          }, count: 1),
        );
        batteryLevelStreamController.add(minEnoughBattery + 1);
        batteryStateStreamController.add(BatteryState.discharging);
        batteryModeStreamController.add(false);
      });

      test(
        'should return true when not enough battery and discharging',
        () async {
          final ecoMode = buildEcoMode();
          ecoMode.isBatteryEcoModeStream.listen(
            expectAsync1((event) {
              expect(event, true);
            }, count: 1),
          );
          batteryLevelStreamController.add(minEnoughBattery - 1);
          batteryStateStreamController.add(BatteryState.discharging);
          batteryModeStreamController.add(false);
        },
      );

      test('should return true when battery in low power mode', () async {
        when(
          () => ecoModeApi.isBatteryInLowPowerMode(),
        ).thenAnswer((_) async => true);
        final ecoMode = buildEcoMode();
        ecoMode.isBatteryEcoModeStream.listen(
          expectAsync1((event) {
            expect(event, true);
          }, count: 1),
        );
        batteryLevelStreamController.add(100.0);
        batteryStateStreamController.add(BatteryState.charging);
        batteryModeStreamController.add(true);
      });
    });
  });

  group('Connectivity', () {
    group('Future hasEnoughNetwork', () {
      test('should return null when connectivity is unknown', () async {
        expect(await buildEcoMode().hasEnoughNetwork(), null);
      });

      void mockConnectivityType(
        ConnectivityType type, {
        int? wifiSignalStrength,
      }) {
        when(() => ecoModeApi.getConnectivity()).thenAnswer(
          (_) => Future.value(
            Connectivity(type: type, wifiSignalStrength: wifiSignalStrength),
          ),
        );
      }

      void assertHasEnoughNetwork(bool? expected) async {
        expect(await buildEcoMode().hasEnoughNetwork(), expected);
      }

      test('should return true when connectivity type is ethernet', () async {
        mockConnectivityType(ConnectivityType.ethernet);
        assertHasEnoughNetwork(true);
      });

      test('should return false when connectivity type is mobile2g', () async {
        mockConnectivityType(ConnectivityType.mobile2g);
        assertHasEnoughNetwork(false);
      });

      test('should return true when connectivity type is mobile3g', () async {
        mockConnectivityType(ConnectivityType.mobile3g);
        assertHasEnoughNetwork(true);
      });

      test('should return true when connectivity type is mobile4g', () async {
        mockConnectivityType(ConnectivityType.mobile4g);
        assertHasEnoughNetwork(true);
      });

      test('should return true when connectivity type is mobile5g', () async {
        mockConnectivityType(ConnectivityType.mobile5g);
        assertHasEnoughNetwork(true);
      });

      test(
        'should return true when connectivity type is WIFI and signal is enough',
        () async {
          mockConnectivityType(
            ConnectivityType.wifi,
            wifiSignalStrength: minWifiSignalStrength,
          );
          assertHasEnoughNetwork(true);
        },
      );

      test(
        'should return false when connectivity type is WIFI and signal is not enough',
        () async {
          mockConnectivityType(
            ConnectivityType.wifi,
            wifiSignalStrength: minWifiSignalStrength - 1,
          );
          assertHasEnoughNetwork(false);
        },
      );

      test(
        'should return false when connectivity type is WIFI and signal is null',
        () async {
          mockConnectivityType(ConnectivityType.wifi);
          assertHasEnoughNetwork(false);
        },
      );
    });

    group('Stream hasEnoughNetwork', () {
      test('should return null when connectivity is unknown', () async {
        final ecoMode = buildEcoMode();
        ecoMode.hasEnoughNetworkStream().listen(
          expectAsync1((event) {
            expect(event, null);
          }, count: 1),
        );
        connectivityStreamController.add(
          Connectivity(type: ConnectivityType.unknown),
        );
      });

      test('should return true when connectivity type is ethernet', () async {
        final ecoMode = buildEcoMode();
        ecoMode.hasEnoughNetworkStream().listen(
          expectAsync1((event) {
            expect(event, true);
          }, count: 1),
        );
        connectivityStreamController.add(
          Connectivity(type: ConnectivityType.ethernet),
        );
      });

      test('should return false when connectivity type is mobile2g', () async {
        final ecoMode = buildEcoMode();
        ecoMode.hasEnoughNetworkStream().listen(
          expectAsync1((event) {
            expect(event, false);
          }, count: 1),
        );
        connectivityStreamController.add(
          Connectivity(type: ConnectivityType.mobile2g),
        );
      });

      test('should return true when connectivity type is mobile3g', () async {
        final ecoMode = buildEcoMode();
        ecoMode.hasEnoughNetworkStream().listen(
          expectAsync1((event) {
            expect(event, true);
          }, count: 1),
        );
        connectivityStreamController.add(
          Connectivity(type: ConnectivityType.mobile3g),
        );
      });

      test('should return true when connectivity type is mobile4g', () async {
        final ecoMode = buildEcoMode();
        ecoMode.hasEnoughNetworkStream().listen(
          expectAsync1((event) {
            expect(event, true);
          }, count: 1),
        );
        connectivityStreamController.add(
          Connectivity(type: ConnectivityType.mobile4g),
        );
      });

      test('should return true when connectivity type is mobile5g', () async {
        final ecoMode = buildEcoMode();
        ecoMode.hasEnoughNetworkStream().listen(
          expectAsync1((event) {
            expect(event, true);
          }, count: 1),
        );
        connectivityStreamController.add(
          Connectivity(type: ConnectivityType.mobile5g),
        );
      });

      test(
        'should return true when connectivity type is wifi and signal is enough',
        () async {
          final ecoMode = buildEcoMode();
          ecoMode.hasEnoughNetworkStream().listen(
            expectAsync1((event) {
              expect(event, true);
            }, count: 1),
          );
          connectivityStreamController.add(
            Connectivity(
              type: ConnectivityType.wifi,
              wifiSignalStrength: minWifiSignalStrength,
            ),
          );
        },
      );

      test(
        'should return false when connectivity type is wifi and signal is not enough',
        () async {
          final ecoMode = buildEcoMode();
          ecoMode.hasEnoughNetworkStream().listen(
            expectAsync1((event) {
              expect(event, false);
            }, count: 1),
          );
          connectivityStreamController.add(
            Connectivity(
              type: ConnectivityType.wifi,
              wifiSignalStrength: minWifiSignalStrength - 1,
            ),
          );
        },
      );

      test(
        'should return false when connectivity type is wifi and signal is null',
        () async {
          final ecoMode = buildEcoMode();
          ecoMode.hasEnoughNetworkStream().listen(
            expectAsync1((event) {
              expect(event, false);
            }, count: 1),
          );
          connectivityStreamController.add(
            Connectivity(type: ConnectivityType.wifi),
          );
        },
      );
    });
  });

  group('Device Range getEcoScore', () {
    test('should return null when get eco score error', () async {
      when(
        () => ecoModeApi.getEcoScore(),
      ).thenAnswer((_) => Future.error('error eco score'));
      expect(await buildEcoMode().getDeviceRange(), null);
    });

    test('should return null when get eco score null', () async {
      when(
        () => ecoModeApi.getEcoScore(),
      ).thenAnswer((_) => Future.value(null));
      expect(await buildEcoMode().getDeviceRange(), null);
    });

    test('should return low end device', () async {
      when(
        () => ecoModeApi.getEcoScore(),
      ).thenAnswer((_) => Future.value(minScoreLowEndDevice));
      final deviceRange = await buildEcoMode().getDeviceRange();
      expect(deviceRange!.score, minScoreLowEndDevice);
      expect(deviceRange.range, DeviceEcoRange.lowEnd);
      expect(deviceRange.isLowEndDevice, true);
    });

    test('should return mid range device', () async {
      when(
        () => ecoModeApi.getEcoScore(),
      ).thenAnswer((_) => Future.value(minScoreMidRangeDevice));
      final deviceRange = await buildEcoMode().getDeviceRange();
      expect(deviceRange!.score, minScoreMidRangeDevice);
      expect(deviceRange.range, DeviceEcoRange.midRange);
      expect(deviceRange.isLowEndDevice, false);
    });

    test('should return high end device', () async {
      when(
        () => ecoModeApi.getEcoScore(),
      ).thenAnswer((_) => Future.value(minScoreMidRangeDevice + 0.1));
      final deviceRange = await buildEcoMode().getDeviceRange();
      expect(deviceRange!.score, minScoreMidRangeDevice + 0.1);
      expect(deviceRange.range, DeviceEcoRange.highEnd);
      expect(deviceRange.isLowEndDevice, false);
    });
  });
}
