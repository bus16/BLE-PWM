//
//  ViewController.swift
//  BLEDemo
//
//  Created by Jindrich Dolezy on 11/04/2018.
//  Copyright © 2018 Dzindra. All rights reserved.
//

import UIKit
import UserNotifications


class DeviceVC: UIViewController {
    
    enum ViewState: Int {
        case disconnected
        case connected
        case ready
    }
    
    var device: BTDevice? {
        didSet {
            navigationItem.title = device?.name ?? "Device"
            device?.delegate = self
        }
    }
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBOutlet weak var dutyLabel: UILabel!
    @IBOutlet weak var enableSwitch: UISwitch!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var serialLabel: UILabel!
    @IBOutlet weak var frequencySlider: UISlider!
    @IBOutlet weak var dutySlider: UISlider!
    
    var viewState: ViewState = .disconnected {
        didSet {
            switch viewState {
            case .disconnected:
                statusLabel.text = "Disconnected"
                enableSwitch.isEnabled = false
                enableSwitch.isOn = false
                frequencySlider.isEnabled = false
                dutySlider.isEnabled = false
                disconnectButton.isEnabled = false
                serialLabel.isHidden = true
            case .connected:
                statusLabel.text = "Probing..."
                enableSwitch.isEnabled = false
                enableSwitch.isOn = false
                frequencySlider.isEnabled = false
                dutySlider.isEnabled = false
                disconnectButton.isEnabled = true
                serialLabel.isHidden = true
            case .ready:
                statusLabel.text = "Ready"
                enableSwitch.isEnabled = true
                disconnectButton.isEnabled = true
                serialLabel.isHidden = false
                frequencySlider.isEnabled = true
                dutySlider.isEnabled = true
                
                if let b = device?.enable {
                    enableSwitch.isOn = b
                }
                if let s = device?.frequency {
                    frequencySlider.value = Float(s)
                    frequencyLabel.text = "Frequency: \(Int((s))) Hz"
                }
                if let s = device?.duty {
                    dutySlider.value = Float(s)
                    dutyLabel.text = "Duty cycle: \(Int((s)))%"
                }
                serialLabel.text = device?.serial ?? "reading..."
            }
        }
    }
    
    deinit {
        device?.disconnect()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewState = .disconnected
    }

    @IBAction func disconnectAction() {
        device?.disconnect()
    }

    @IBAction func enebleChanged(_ sender: Any) {
        device?.enable = enableSwitch.isOn
    }

    @IBAction func frequencyChanged(_ sender: UISlider) {
        let frequency = Int(frequencySlider.value)
        device?.frequency = frequency
        frequencyLabel.text = "Frequency: \(frequency) Hz"
    }
    
    @IBAction func dutyChanged(_ sender: UISlider) {
        let duty = Int(dutySlider.value)
        device?.duty = duty
        dutyLabel.text = "Duty cycle: \(duty)%"
    }
}

extension DeviceVC: BTDeviceDelegate {
    func deviceSerialChanged(value: String) {
        serialLabel.text = value
    }
    
    func deviceFrequencyChanged(value: Int) {
        frequencySlider.value = Float(value)
    }
    
    func deviceDutyChanged(value: Int) {
        dutySlider.value = Float(value)
    }
    
    func deviceConnected() {
        viewState = .connected
    }
    
    func deviceDisconnected() {
        viewState = .disconnected
    }
    
    func deviceReady() {
        viewState = .ready
    }
    
    func deviceEnableChanged(value: Bool) {
        enableSwitch.setOn(value, animated: true)
        
        if UIApplication.shared.applicationState == .background {
            let content = UNMutableNotificationContent()
            content.title = "ESP Blinky"
            content.body = value ? "Now blinking" : "Not blinking anymore"
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    print("DeviceVC: failed to deliver notification \(error)")
                }
            }
        }
    }
    
    
}
