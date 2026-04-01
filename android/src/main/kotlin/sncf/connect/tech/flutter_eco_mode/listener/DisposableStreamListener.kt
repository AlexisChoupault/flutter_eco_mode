package sncf.connect.tech.flutter_eco_mode.listener

import io.flutter.plugin.common.BinaryMessenger

interface DisposableStreamListener {
    fun register(binaryMessenger: BinaryMessenger)
    fun dispose(binaryMessenger: BinaryMessenger)
}
