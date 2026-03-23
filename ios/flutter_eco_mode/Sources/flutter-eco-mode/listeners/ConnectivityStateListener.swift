//
//  ConnectivityStateListener.swift
//  flutter_eco_mode
//
//  Created by CHOUPAULT Alexis on 27/02/2026.
//

import Flutter
import Foundation

class ConnectivityStateListener: ConnectivityStreamHandler, DisposableStreamListener {
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        cleanUp()
        return nil
    }
    
    func register(binaryMessenger: any FlutterBinaryMessenger) {
        ConnectivityStreamHandler.register(with: binaryMessenger, streamHandler: self)
    }
    
    func dispose(binaryMessenger: any FlutterBinaryMessenger) {
        cleanUp()
        
        let channelName = "dev.flutter.pigeon.flutter_eco_mode.EcoModeEventChannel.connectivity"
        FlutterEventChannel(name: channelName, binaryMessenger: binaryMessenger, codec: messagesPigeonMethodCodec).setStreamHandler(nil)
    }
    
    private func cleanUp() {
        
    }
}
