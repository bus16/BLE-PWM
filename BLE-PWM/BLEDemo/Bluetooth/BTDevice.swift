//
//  BTDevice.swift
//  BLEDemo
//
//  Created by Jindrich Dolezy on 11/04/2018.
//  Copyright © 2018 Dzindra. All rights reserved.
//

import Foundation
import CoreBluetooth


protocol BTDeviceDelegate: class {
    func deviceConnected()
    func deviceReady()
    func deviceEnableChanged(value: Bool)
    func deviceFrequencyChanged(value: Int)
    func deviceDutyChanged(value: Int)
    func deviceSerialChanged(value: String)
    func deviceDisconnected()
}

class BTDevice: NSObject {
    private let peripheral: CBPeripheral
    private let manager: CBCentralManager
    private var enableChar: CBCharacteristic?
    private var frequencyChar: CBCharacteristic?
    private var dutyChar: CBCharacteristic?
    private var _enable: Bool = false
    private var _frequency: Int = 50
    private var _duty: Int = 50
    
    weak var delegate: BTDeviceDelegate?
    var enable: Bool {
        get {
            return _enable
        }
        set {
            guard _enable != newValue else { return }
            
            _enable = newValue
            if let char = enableChar {
                peripheral.writeValue(Data(bytes: [_enable ? 1 : 0]), for: char, type: .withResponse)
            }
        }
    }
    var frequency: Int {
        get {
            return _frequency
        }
        set {
            guard _frequency != newValue else { return }
            
            _frequency = newValue
            if let char = frequencyChar {
                peripheral.writeValue(Data(bytes: [UInt8(_frequency)]), for: char, type: .withResponse)
            }
        }
    }
    var duty: Int {
        get {
            return _duty
        }
        set {
            guard _duty != newValue else { return }
            
            _duty = newValue
            if let char = dutyChar {
                peripheral.writeValue(Data(bytes: [UInt8(_duty)]), for: char, type: .withResponse)
            }
        }
    }
    var name: String {
        return peripheral.name ?? "Unknown device"
    }
    var detail: String {
        return peripheral.identifier.description
    }
    private(set) var serial: String?
    
    init(peripheral: CBPeripheral, manager: CBCentralManager) {
        self.peripheral = peripheral
        self.manager = manager
        super.init()
        self.peripheral.delegate = self
    }
    
    func connect() {
        manager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        manager.cancelPeripheralConnection(peripheral)
    }
}

extension BTDevice {
    // these are called from BTManager, do not call directly
    
    func connectedCallback() {
        peripheral.discoverServices([BTUUIDs.service, BTUUIDs.infoService])
        delegate?.deviceConnected()
    }
    
    func disconnectedCallback() {
        delegate?.deviceDisconnected()
    }
    
    func errorCallback(error: Error?) {
        print("Device: error \(String(describing: error))")
    }
}


extension BTDevice: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Device: discovered services")
        peripheral.services?.forEach {
            print("  \($0)")
            if $0.uuid == BTUUIDs.infoService {
                peripheral.discoverCharacteristics([BTUUIDs.infoSerial], for: $0)
            } else if $0.uuid == BTUUIDs.service {
                peripheral.discoverCharacteristics([BTUUIDs.enable, BTUUIDs.frequency, BTUUIDs.duty], for: $0)
            } else {
                peripheral.discoverCharacteristics(nil, for: $0)
            }
            
        }
        print()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Device: discovered characteristics")
        service.characteristics?.forEach {
            print("   \($0)")
            
            if $0.uuid == BTUUIDs.enable {
                self.enableChar = $0
                peripheral.readValue(for: $0)
                peripheral.setNotifyValue(true, for: $0)
            } else if $0.uuid == BTUUIDs.frequency {
                self.frequencyChar = $0
                peripheral.readValue(for: $0)
            } else if $0.uuid == BTUUIDs.duty {
                self.dutyChar = $0
                peripheral.readValue(for: $0)
            } else if $0.uuid == BTUUIDs.infoSerial {
                peripheral.readValue(for: $0)
            }
        }
        print()
        
        delegate?.deviceReady()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Device: updated value for \(characteristic)")
        
        if characteristic.uuid == enableChar?.uuid, let b = characteristic.value?.parseBool() {
            _enable = b
            delegate?.deviceEnableChanged(value: b)
        }
        if characteristic.uuid == frequencyChar?.uuid, let s = characteristic.value?.parseInt() {
            _frequency = Int(s)
            delegate?.deviceFrequencyChanged(value: _frequency)
        }
        if characteristic.uuid == dutyChar?.uuid, let s = characteristic.value?.parseInt() {
            _duty = Int(s)
            delegate?.deviceDutyChanged(value: _duty)
        }
        if characteristic.uuid == BTUUIDs.infoSerial, let d = characteristic.value {
            serial = String(data: d, encoding: .utf8)
            if let serial = serial {
                delegate?.deviceSerialChanged(value: serial)
            }
        }
    }
}


