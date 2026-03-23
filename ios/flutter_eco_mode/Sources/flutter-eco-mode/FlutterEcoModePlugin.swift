import Flutter
import UIKit
import NotificationCenter

protocol EcoModeComponent {
    var batteryLevelListener: DisposableStreamListener { get }
    var batteryStateListener: DisposableStreamListener { get }
    var powerModeListener: DisposableStreamListener { get }
    var connectivityListener: DisposableStreamListener { get }
}

public class FlutterEcoModePlugin: NSObject, FlutterPlugin {
    private static var ecoModeComponent: EcoModeComponent?
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    static public func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()
        let ecoModeImplem = EcoModeImplem()
        
        EcoModeApiSetup.setUp(binaryMessenger: messenger, api: ecoModeImplem)
        ecoModeComponent = ecoModeImplem
        
        ecoModeImplem.batteryLevelListener.register(binaryMessenger: messenger)
        ecoModeImplem.batteryStateListener.register(binaryMessenger: messenger)
        ecoModeImplem.powerModeListener.register(binaryMessenger: messenger)
        ecoModeImplem.connectivityListener.register(binaryMessenger: messenger)
    }
    
    public static func detachFromEngine(for registrar: any FlutterPluginRegistrar) {
        let messenger = registrar.messenger()
        ecoModeComponent?.batteryLevelListener.dispose(binaryMessenger: messenger)
        ecoModeComponent?.batteryStateListener.dispose(binaryMessenger: messenger)
        ecoModeComponent?.powerModeListener.dispose(binaryMessenger: messenger)
        ecoModeComponent?.connectivityListener.dispose(binaryMessenger: messenger)
    }
}
