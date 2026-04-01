//
//  EcoBatteryManager.swift
//  flutter_eco_mode
//
//  Created by CHOUPAULT Alexis on 27/02/2026.
//

import UIKit

class EcoBatteryManager {
    static let shared = EcoBatteryManager()
    
    private init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    func getBatteryLevel() -> Double {
        let level = UIDevice.current.batteryLevel
        return level >= 0 ? Double(level * 100) : 0.0
    }
    
    func getBatteryState() -> BatteryState {
        switch UIDevice.current.batteryState {
        case .charging: return .charging
        case .full: return .full
        case .unplugged: return .discharging
        case .unknown: return .unknown
        @unknown default: return .unknown
        }
    }
    
    func isLowPowerMode() -> Bool {
        return ProcessInfo.processInfo.isLowPowerModeEnabled
    }
}
