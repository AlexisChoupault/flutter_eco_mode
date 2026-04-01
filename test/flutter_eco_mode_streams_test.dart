import 'dart:async';

import 'package:flutter_eco_mode/src/flutter_eco_mode.dart';
import 'package:flutter_eco_mode/src/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEcoModeApi extends Mock implements EcoModeApi {}

void main() {
  late StreamController<double> batteryLevelStreamController;
  late StreamController<BatteryState> batteryStateStreamController;
  late StreamController<bool> batteryModeStreamController;
  late EcoModeApi ecoModeApi;

  FlutterEcoMode buildEcoMode() => FlutterEcoMode(
    api: ecoModeApi,
    batteryLevelStream: batteryLevelStreamController.stream,
    batteryStateStream: batteryStateStreamController.stream,
    batteryModeStream: batteryModeStreamController.stream,
  );

  setUp(() {
    ecoModeApi = MockEcoModeApi();
    batteryLevelStreamController = StreamController<double>.broadcast();
    batteryStateStreamController = StreamController<BatteryState>.broadcast();
    batteryModeStreamController = StreamController<bool>.broadcast();
  });

  tearDown(() {
    batteryLevelStreamController.close();
    batteryStateStreamController.close();
    batteryModeStreamController.close();
  });

  group('Individual Streams Tests', () {
    group('batteryLevelEventStream', () {
      test('should emit battery level events', () async {
        final ecoMode = buildEcoMode();
        final emittedValues = <double>[];

        ecoMode.batteryLevelEventStream.listen((value) {
          emittedValues.add(value);
        });

        batteryLevelStreamController.add(100.0);
        batteryLevelStreamController.add(75.5);
        batteryLevelStreamController.add(50.0);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(emittedValues, [100.0, 75.5, 50.0]);
      });

      test('should be broadcast stream', () async {
        final ecoMode = buildEcoMode();
        final listener1Values = <double>[];
        final listener2Values = <double>[];

        final subscription1 = ecoMode.batteryLevelEventStream.listen((value) {
          listener1Values.add(value);
        });

        batteryLevelStreamController.add(90.0);

        final subscription2 = ecoMode.batteryLevelEventStream.listen((value) {
          listener2Values.add(value);
        });

        batteryLevelStreamController.add(80.0);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(listener1Values, [90.0, 80.0]);
        expect(listener2Values, [80.0]);

        subscription1.cancel();
        subscription2.cancel();
      });

      test('should handle rapid successive events', () async {
        final ecoMode = buildEcoMode();
        final emittedValues = <double>[];

        ecoMode.batteryLevelEventStream.listen((value) {
          emittedValues.add(value);
        });

        for (int i = 100; i > 0; i--) {
          batteryLevelStreamController.add(i.toDouble());
        }

        await Future.delayed(const Duration(milliseconds: 200));

        expect(emittedValues.length, 100);
        expect(emittedValues.first, 100.0);
        expect(emittedValues.last, 1.0);
      });

      test('should handle boundary values', () async {
        final ecoMode = buildEcoMode();
        final emittedValues = <double>[];

        ecoMode.batteryLevelEventStream.listen((value) {
          emittedValues.add(value);
        });

        batteryLevelStreamController.add(0.0);
        batteryLevelStreamController.add(100.0);
        batteryLevelStreamController.add(0.1);
        batteryLevelStreamController.add(99.9);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(emittedValues, [0.0, 100.0, 0.1, 99.9]);
      });
    });

    group('batteryStateEventStream', () {
      test('should emit battery state events', () async {
        final ecoMode = buildEcoMode();
        final emittedValues = <BatteryState>[];

        ecoMode.batteryStateEventStream.listen((value) {
          emittedValues.add(value);
        });

        batteryStateStreamController.add(BatteryState.charging);
        batteryStateStreamController.add(BatteryState.discharging);
        batteryStateStreamController.add(BatteryState.full);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(emittedValues, [
          BatteryState.charging,
          BatteryState.discharging,
          BatteryState.full,
        ]);
      });

      test('should emit all battery states', () async {
        final ecoMode = buildEcoMode();
        final emittedValues = <BatteryState>[];

        ecoMode.batteryStateEventStream.listen((value) {
          emittedValues.add(value);
        });

        batteryStateStreamController.add(BatteryState.unknown);
        batteryStateStreamController.add(BatteryState.charging);
        batteryStateStreamController.add(BatteryState.discharging);
        batteryStateStreamController.add(BatteryState.full);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(emittedValues, [
          BatteryState.unknown,
          BatteryState.charging,
          BatteryState.discharging,
          BatteryState.full,
        ]);
      });

      test('should handle duplicate consecutive states', () async {
        final ecoMode = buildEcoMode();
        final emittedValues = <BatteryState>[];

        ecoMode.batteryStateEventStream.listen((value) {
          emittedValues.add(value);
        });

        batteryStateStreamController.add(BatteryState.discharging);
        batteryStateStreamController.add(BatteryState.discharging);
        batteryStateStreamController.add(BatteryState.charging);
        batteryStateStreamController.add(BatteryState.charging);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(emittedValues, [
          BatteryState.discharging,
          BatteryState.discharging,
          BatteryState.charging,
          BatteryState.charging,
        ]);
      });

      test('should be broadcast stream', () async {
        final ecoMode = buildEcoMode();
        final listener1Values = <BatteryState>[];
        final listener2Values = <BatteryState>[];

        final subscription1 = ecoMode.batteryStateEventStream.listen((value) {
          listener1Values.add(value);
        });

        batteryStateStreamController.add(BatteryState.charging);

        final subscription2 = ecoMode.batteryStateEventStream.listen((value) {
          listener2Values.add(value);
        });

        batteryStateStreamController.add(BatteryState.discharging);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(listener1Values, [
          BatteryState.charging,
          BatteryState.discharging,
        ]);
        expect(listener2Values, [BatteryState.discharging]);

        subscription1.cancel();
        subscription2.cancel();
      });
    });

    group('lowPowerModeEventStream', () {
      test('should emit low power mode events', () async {
        final ecoMode = buildEcoMode();
        final emittedValues = <bool>[];

        ecoMode.lowPowerModeEventStream.listen((value) {
          emittedValues.add(value);
        });

        batteryModeStreamController.add(false);
        batteryModeStreamController.add(true);
        batteryModeStreamController.add(false);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(emittedValues, [false, true, false]);
      });

      test('should handle rapid toggles', () async {
        final ecoMode = buildEcoMode();
        final emittedValues = <bool>[];

        ecoMode.lowPowerModeEventStream.listen((value) {
          emittedValues.add(value);
        });

        for (int i = 0; i < 10; i++) {
          batteryModeStreamController.add(i.isEven);
        }

        await Future.delayed(const Duration(milliseconds: 100));

        expect(emittedValues.length, 10);
      });

      test('should be broadcast stream', () async {
        final ecoMode = buildEcoMode();
        final listener1Values = <bool>[];
        final listener2Values = <bool>[];

        final subscription1 = ecoMode.lowPowerModeEventStream.listen((value) {
          listener1Values.add(value);
        });

        batteryModeStreamController.add(false);

        final subscription2 = ecoMode.lowPowerModeEventStream.listen((value) {
          listener2Values.add(value);
        });

        batteryModeStreamController.add(true);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(listener1Values, [false, true]);
        expect(listener2Values, [true]);

        subscription1.cancel();
        subscription2.cancel();
      });

      test('should emit same value consecutively', () async {
        final ecoMode = buildEcoMode();
        final emittedValues = <bool>[];

        ecoMode.lowPowerModeEventStream.listen((value) {
          emittedValues.add(value);
        });

        batteryModeStreamController.add(true);
        batteryModeStreamController.add(true);
        batteryModeStreamController.add(true);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(emittedValues, [true, true, true]);
      });

      test('should handle stream cancellation', () async {
        final ecoMode = buildEcoMode();
        final emittedValues = <bool>[];

        final subscription = ecoMode.lowPowerModeEventStream.listen((value) {
          emittedValues.add(value);
        });

        batteryModeStreamController.add(false);
        batteryModeStreamController.add(true);

        await Future.delayed(const Duration(milliseconds: 50));

        subscription.cancel();

        batteryModeStreamController.add(false);

        await Future.delayed(const Duration(milliseconds: 50));

        // Should only have the first two values
        expect(emittedValues, [false, true]);
      });
    });

    group('Multiple streams coordination', () {
      test('should emit from multiple streams independently', () async {
        final ecoMode = buildEcoMode();
        final batteryLevelValues = <double>[];
        final batteryStateValues = <BatteryState>[];
        final lowPowerValues = <bool>[];

        ecoMode.batteryLevelEventStream.listen((value) {
          batteryLevelValues.add(value);
        });
        ecoMode.batteryStateEventStream.listen((value) {
          batteryStateValues.add(value);
        });
        ecoMode.lowPowerModeEventStream.listen((value) {
          lowPowerValues.add(value);
        });

        batteryLevelStreamController.add(90.0);
        batteryStateStreamController.add(BatteryState.discharging);
        batteryModeStreamController.add(true);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(batteryLevelValues, [90.0]);
        expect(batteryStateValues, [BatteryState.discharging]);
        expect(lowPowerValues, [true]);
      });
    });
  });
}
