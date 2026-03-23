import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_eco_mode/flutter_eco_mode.dart';

class EventChannelsTestPage extends StatefulWidget {
  const EventChannelsTestPage({Key? key}) : super(key: key);

  @override
  State<EventChannelsTestPage> createState() => _EventChannelsTestPageState();
}

class _EventChannelsTestPageState extends State<EventChannelsTestPage> {
  final List<String> _events = [];
  late FlutterEcoMode _ecoMode;
  final List<StreamSubscription> _subscriptions = [];
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _ecoMode = FlutterEcoMode();
    _startListening();
  }

  void _addEvent(String event) {
    if (_disposed) return;
    
    setState(() {
      final timestamp = DateTime.now().toString().split('.')[0];
      _events.insert(0, '[$timestamp] $event');
      // Limiter la taille de la liste pour éviter les fuites mémoire
      if (_events.length > 100) {
        _events.removeLast();
      }
    });
  }

  void _startListening() {
    try {
      // Listen to battery level changes with throttling
      _subscriptions.add(
        _ecoMode.batteryLevelEventStream
            .handleError((error) {
              _addEvent('❌ Battery Level Error: $error');
            })
            .listen((value) {
              _addEvent('🔋 Battery Level: ${value.toInt()}%');
            }),
      );

      // Listen to battery state changes
      _subscriptions.add(
        _ecoMode.batteryStateEventStream
            .handleError((error) {
              _addEvent('❌ Battery State Error: $error');
            })
            .listen((value) {
              _addEvent('📊 Battery State: ${value.name}');
            }),
      );

      // Listen to low power mode changes
      _subscriptions.add(
        _ecoMode.lowPowerModeEventStream
            .handleError((error) {
              _addEvent('❌ Low Power Mode Error: $error');
            })
            .listen((value) {
              _addEvent('⚡ Low Power Mode: $value');
            }),
      );

      // Listen to connectivity changes
      _subscriptions.add(
        _ecoMode.connectivityStream
            .handleError((error) {
              _addEvent('❌ Connectivity Error: $error');
            })
            .listen((value) {
              _addEvent('📡 Connectivity: ${value.type.name}');
              if (value.wifiSignalStrength != null) {
                _addEvent('   └─ WiFi Signal: ${value.wifiSignalStrength} dBm');
              }
            }),
      );

      // Listen to battery eco mode changes
      _subscriptions.add(
        _ecoMode.isBatteryEcoModeStream
            .handleError((error) {
              _addEvent('❌ Battery Eco Mode Error: $error');
            })
            .listen((value) {
              _addEvent('🌱 Battery Eco Mode: $value');
            }),
      );
    } catch (e) {
      _addEvent('❌ Error starting listeners: $e');
    }
  }

  void _clearEvents() {
    setState(() {
      _events.clear();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    // Nettoyer toutes les subscriptions
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Channels Test'),
        elevation: 5,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _clearEvents,
                  icon: const Icon(Icons.delete),
                  label: const Text('Clear Events'),
                ),
                const SizedBox(width: 16),
                Text(
                  'Events: ${_events.length}/100',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _events.isEmpty
                ? const Center(
                    child: Text(
                      'Waiting for events...\nTrigger some actions on your device!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      final isError = event.contains('❌');
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[300]!,
                            ),
                          ),
                          color: isError
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.transparent,
                        ),
                        child: Text(
                          event,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: isError ? Colors.red[700] : Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


