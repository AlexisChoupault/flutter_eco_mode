//
//  DisposableStreamListener.swift
//  flutter_eco_mode
//
//  Created by CHOUPAULT Alexis on 02/03/2026.
//

import Flutter

protocol DisposableStreamListener {
    func register(binaryMessenger: FlutterBinaryMessenger)
    func dispose(binaryMessenger: FlutterBinaryMessenger)
}
