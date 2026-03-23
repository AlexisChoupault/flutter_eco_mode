//
//  PowerModeListener.swift
//  flutter_eco_mode
//
//  Created by CHOUPAULT Alexis on 27/02/2026.
//

import Flutter

class PowerModeListener: BatteryModeStreamHandler, DisposableStreamListener {
    private var eventSink: FlutterEventSink?
    private var lastSentPowerMode: Bool?
    
    // MARK: - BatteryModeStreamHandler implementation

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        sendUpdate()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(lowPowerModeChanged),
            name: Notification.Name.NSProcessInfoPowerStateDidChange,
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
        BatteryModeStreamHandler.register(with: binaryMessenger, streamHandler: self)
    }
    
    func dispose(binaryMessenger: FlutterBinaryMessenger) {
        cleanUp()
        
        let channelName = "dev.flutter.pigeon.flutter_eco_mode.EcoModeEventChannel.batteryMode"
        FlutterEventChannel(name: channelName, binaryMessenger: binaryMessenger, codec: messagesPigeonMethodCodec).setStreamHandler(nil)
    }
    
    // MARK: - Private methods

    @objc private func lowPowerModeChanged() {
        sendUpdate()
    }

    private func sendUpdate() {
        let isLowPower = EcoBatteryManager.shared.isLowPowerMode()
        
        guard isLowPower != lastSentPowerMode else { return }
        
        lastSentPowerMode = isLowPower
        
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(isLowPower)
        }
    }

    private func cleanUp() {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        lastSentPowerMode = nil
    }
}
