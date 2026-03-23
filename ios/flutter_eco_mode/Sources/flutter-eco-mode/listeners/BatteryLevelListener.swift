//
//  BatteryLevelListener.swift
//  flutter_eco_mode
//
//  Created by CHOUPAULT Alexis on 27/02/2026.
//

import Flutter

class BatteryLevelListener: BatteryLevelStreamHandler, DisposableStreamListener {
    private var eventSink: FlutterEventSink?
    private var lastSentLevel: Double?
    
    // MARK: - BatteryLevelStreamHandler implementation

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        sendUpdate()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryLevelChanged),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        cleanUp()
        return nil
    }
    
    // MARK: - DisposableStreamListener implementation
    
    func register(binaryMessenger: FlutterBinaryMessenger) {
        BatteryLevelStreamHandler.register(with: binaryMessenger, streamHandler: self)
    }
    
    func dispose(binaryMessenger: FlutterBinaryMessenger) {
        cleanUp()
        
        let channelName = "dev.flutter.pigeon.flutter_eco_mode.EcoModeEventChannel.batteryLevel"
        FlutterEventChannel(name: channelName, binaryMessenger: binaryMessenger, codec: messagesPigeonMethodCodec).setStreamHandler(nil)
    }
    
    // MARK: - Private methods

    @objc private func batteryLevelChanged() {
        sendUpdate()
    }

    private func sendUpdate() {
        let currentLevel = EcoBatteryManager.shared.getBatteryLevel()
        
        guard currentLevel != lastSentLevel else { return }
        
        lastSentLevel = currentLevel
        
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(currentLevel)
        }
    }
    
    private func cleanUp() {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        lastSentLevel = nil
    }
}
