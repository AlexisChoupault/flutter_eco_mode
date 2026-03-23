//
//  BatteryStateListener.swift
//  flutter_eco_mode
//
//  Created by CHOUPAULT Alexis on 27/02/2026.
//

import Flutter

class BatteryStateListener: BatteryStateStreamHandler, DisposableStreamListener {
    private var eventSink: FlutterEventSink?
    private var lastSentState: BatteryState?
    
    // MARK: - BatteryStateStreamHandler implementation

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        sendUpdate()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryStateChanged),
            name: UIDevice.batteryStateDidChangeNotification,
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
        BatteryStateStreamHandler.register(with: binaryMessenger, streamHandler: self)
    }
    
    func dispose(binaryMessenger: FlutterBinaryMessenger) {
        cleanUp()
        
        let channelName = "dev.flutter.pigeon.flutter_eco_mode.EcoModeEventChannel.batteryState"
        FlutterEventChannel(name: channelName, binaryMessenger: binaryMessenger, codec: messagesPigeonMethodCodec).setStreamHandler(nil)
    }
    
    // MARK: - Private methods

    @objc private func batteryStateChanged() {
        sendUpdate()
    }

    private func sendUpdate() {
        let currentState = EcoBatteryManager.shared.getBatteryState()
        
        guard currentState != lastSentState else { return }
        
        lastSentState = currentState
        
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(currentState)
        }
    }
    
    private func cleanUp() {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        lastSentState = nil
    }
}
