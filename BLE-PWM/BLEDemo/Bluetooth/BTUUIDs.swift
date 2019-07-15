//
//  BTUUIDs.swift
//  BLEDemo
//
//  Created by Jindrich Dolezy on 28/11/2018.
//  Copyright © 2018 Dzindra. All rights reserved.
//

import CoreBluetooth


struct BTUUIDs {
    static let enable = CBUUID(string: "df7812b2-372c-4a18-bf23-b3c7bf8d2d1c")
    static let frequency = CBUUID(string: "30d70343-6a3f-450b-8dd1-a927f9f3e4fa")
    static let duty = CBUUID(string: "f60c9a2b-d01a-4137-be49-1faa2ac098a6")
    static let service = CBUUID(string: "6d8f85c9-d8f8-412f-95ff-a5134788caeb")
    
    static let infoService = CBUUID(string: "180a")
    static let infoManufacturer = CBUUID(string: "2a29")
    static let infoName = CBUUID(string: "2a24")
    static let infoSerial = CBUUID(string: "2a25")
}
