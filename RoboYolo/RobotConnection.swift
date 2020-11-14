//
//  RobotConnection.swift
//  RoboYolo
//
//  Created by Frank Zane Sand on 11/14/20.
//  
//  Copyright (c) 2017 Takehiko YOSHIDA. All rights reserved.
//

import UIKit
import ExternalAccessory

class RobotConnection: Ev3ConnectionChangedDelegate {
    var connection: Ev3Connection?
    var brick: Ev3Brick?
    
    func setup() -> Bool {
        NotificationCenter.default.addObserver(self, selector: #selector(accessoryConnected), name: NSNotification.Name.EAAccessoryDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(accessoryDisconnected), name: NSNotification.Name.EAAccessoryDidDisconnect, object: nil)
        EAAccessoryManager.shared().registerForLocalNotifications()
        print(EAAccessoryManager.shared().connectedAccessories.count)
        
        let accessory = getEv3Accessory()
        let result : Bool
        if let a = accessory {
            print("Connected.")
            connect(accessory: a)
            result = true
        } else {
            print("Not Connected.")
            result = false
        }
        return result
    }
    
    private func getEv3Accessory() -> EAAccessory? {
        let man = EAAccessoryManager.shared()
        let connected = man.connectedAccessories
        
        for tmpAccessory in connected{
            if Ev3Connection.supportsEv3Protocol(accessory: tmpAccessory){
                return tmpAccessory
            }
        }
        return nil
    }
    
    public func ev3ConnectionChanged(connected: Bool) {
        print(connected)
    }
    
    @objc func accessoryConnected(notification: NSNotification) {
        print("EAController::accessoryConnected")
        
        let connectedAccessory = notification.userInfo![EAAccessoryKey] as! EAAccessory
        
        // check if the device is a ev3
        if !Ev3Connection.supportsEv3Protocol(accessory: connectedAccessory) {
            return
        }
        
        connect(accessory: connectedAccessory)
    }
    
    private func connect(accessory: EAAccessory){
        connection = Ev3Connection(accessory: accessory)
        connection?.connectionChangedDelegates.append(self)
        brick = Ev3Brick(connection: connection!)
        connection?.open()
    }
    
    @objc func accessoryDisconnected(notification: NSNotification) {
        print(#function)
    }
}
