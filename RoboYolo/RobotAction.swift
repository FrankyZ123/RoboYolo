//
//  RobotAction.swift
//  RoboYolo
//
//  Created by Frank Zane Sand on 2/16/21.
//

import Foundation
import Vision

func track(_ robotConnection: RobotConnection, currentDirection: String, bounds: CGRect, bufferSize: CGSize, leftMotor: String, rightMotor: String) -> String {
    /*
    
     The tracking functionality used for this application is simple. It minimizes the
     difference between the center of the screen and the center of the bounding box.
     
     currentDirection is a very basic versioning system to not overload the output stream for the hardware.
     It will prevent sending a command to the hardware if that command is already in action (i.e. if the
     robot is already turning right, we do not need to tell it to turn right again, etc.)
     
    */
    
    // compute the difference between the middle of the screen and the middle of the object
    let xDifference = (bufferSize.height / 2.0) - bounds.midY
    
    // set the threshold; this could be a hyperparameter
    let threshold : CGFloat = 25

    if xDifference > threshold && currentDirection != "right" {
        // speed of 15 was chosen because it was the minimum speed that would still turn the robot
        // this could be a hyperparameter
        turnMotor(robotConnection, motor: leftMotor, power: 15)
        turnMotor(robotConnection, motor: rightMotor, power: -15)
        var currentDirection = "right"
    } else if xDifference < -1 * threshold && currentDirection != "left" {
        turnMotor(robotConnection, motor: leftMotor, power: -15)
        turnMotor(robotConnection, motor: rightMotor, power: 15)
        var currentDirection = "left"
    } else if currentDirection != "stop" {
        stopMotor(robotConnection, motor: leftMotor)
        stopMotor(robotConnection, motor: rightMotor)
        var currentDirection = "stop"
    }
    
    return currentDirection
}

func turnMotor(_ robotConnection: RobotConnection, motor: String, power: Int16) {
    /*
     
     This function is *technically* handling more than it should. A nicer solution here
     would involve a motor dict before calling this function.
     
    */
    if motor == "A" {
        robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .A, withPower: power)
    } else if motor == "B" {
        robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .B, withPower: power)
    } else if motor == "C" {
        robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .C, withPower: power)
    } else { // assume the only other option is "D"
        robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .D, withPower: power)
    }
}

func stopMotor(_ robotConnection: RobotConnection, motor: String) {
    /*
     
     This function is *technically* handling more than it should. A nicer solution here
     would involve a motor dict before calling this function.
     
    */
    if motor == "A" {
        robotConnection.brick?.directCommand.stopMotor(onPorts: .A, withBrake: true)
    } else if motor == "B" {
        robotConnection.brick?.directCommand.stopMotor(onPorts: .B, withBrake: true)
    } else if motor == "C" {
        robotConnection.brick?.directCommand.stopMotor(onPorts: .C, withBrake: true)
    } else { // assume the only other option is "D"
        robotConnection.brick?.directCommand.stopMotor(onPorts: .D, withBrake: true)
    }
}
