/*
File adapted from: https://developer.apple.com/documentation/vision/recognizing_objects_in_live_capture
*/

import UIKit
import AVFoundation
import Vision

class YOLOViewController: CameraViewController {
    
    private var detectionOverlay: CALayer! = nil
    
    var direction: String = "n/a"
    
    // Vision parts
    private var requests = [VNRequest]()
    
    var model = YOLOv3().model
    
    @discardableResult
    func setupVision() -> NSError? {
        // Setup Vision parts
        let error: NSError! = nil
        guard let model = try? VNCoreMLModel(for: model) else { return nil }
        
        do {
            let objectRecognition = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    if let results = request.results {
                        self.drawVisionRequestResults(results)
                    }
                })
            })
            self.requests = [objectRecognition]
        } catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }
        
        return error
    }
    
    func drawVisionRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        
        // by default, we're going to take the top observation in results
        // which is the most confident object bounding box returned
        
        if results.count > 0 {
            let topObservation = results.first as! VNRecognizedObjectObservation
            
            let iter = returnIter()
            
            // for loop will go from 1 to the number of classes we want to look at
            
            for index in 1...iter {
                if (topObservation.labels[index].identifier == self.targetClass &&

            // accuracy of prediction is the confidence of the object * confidence of the label
            // https://developer.apple.com/documentation/vision/vnrecognizedobjectobservation

                    self.accuracyThreshold >= topObservation.labels[index].confidence * topObservation.confidence) {

                    let objectBounds = VNImageRectForNormalizedRect(topObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))

                    self.ev3Handler(objectBounds)
                    
                    let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
                    
                    detectionOverlay.addSublayer(shapeLayer)
                    
                    break
                } else {
                    self.stopMotors()
                }
            }
        }
        
        self.updateLayerGeometry()
        CATransaction.commit()
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let exifOrientation = exifOrientationFromDeviceOrientation()
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    override func setupAVCapture() {
        super.setupAVCapture()
        
        // setup Vision parts
        setupLayers()
        updateLayerGeometry()
        setupVision()
        
        // start the capture
        startCaptureSession()
    }
    
    func setupLayers() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: bufferSize.width,
                                         height: bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    
    func updateLayerGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: scale))
        // center the layer
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.borderWidth = 10
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        shapeLayer.name = "Found Object"
        return shapeLayer
    }
    
    func ev3Handler(_ bounds: CGRect) {
        let xDifference = (bufferSize.height / 2.0) - bounds.midY
        
        let threshold : CGFloat = 25
        
        if xDifference > threshold {
            print("right")
            self.direction = "left"
        } else if xDifference < -1 * threshold {
            print("left")
            self.direction = "right"
        } else {
            print("n/a")
            self.direction = "n/a"
        }
        
        if self.direction == "right" {
            self.turnRight()
        } else if self.direction == "left" {
            self.turnLeft()
        } else {
            self.stopMotors()
        }
    }
    
    func turnRight() {
        self.turnLeftMotor(-15)
        self.turnRightMotor(15)
    }
    
    func turnLeft() {
        self.turnLeftMotor(15)
        self.turnRightMotor(-15)
    }
    
    func stopMotors() {
        self.stopRightMotor()
        self.stopLeftMotor()
    }
    
    func turnRightMotor(_ power: Int16) {
        if self.rightMotor == "A" {
            self.robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .A, withPower: power)
        } else if self.rightMotor == "B" {
            self.robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .B, withPower: power)
        } else if self.rightMotor == "C" {
            self.robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .C, withPower: power)
        } else if self.rightMotor == "D" {
            self.robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .D, withPower: power)
        } else {
            print("Ahhhh everything's broken!") // bad example of a use case failing silently if the user inputs the wrong motor value
        }
    }
    
    func turnLeftMotor(_ power: Int16) {
        if self.leftMotor == "A" {
            self.robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .A, withPower: power)
        } else if self.leftMotor == "B" {
            self.robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .B, withPower: power)
        } else if self.leftMotor == "C" {
            self.robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .C, withPower: power)
        } else if self.leftMotor == "D" {
            self.robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .D, withPower: power)
        } else {
            print("Ahhhh everything's broken!") // bad example of a use case failing silently if the user inputs the wrong motor value
        }
    }
    
    func stopRightMotor() {
        if self.rightMotor == "A" {
            self.robotConnection.brick?.directCommand.stopMotor(onPorts: .A, withBrake: true)
        } else if self.rightMotor == "B" {
            self.robotConnection.brick?.directCommand.stopMotor(onPorts: .B, withBrake: true)
        } else if self.rightMotor == "C" {
            self.robotConnection.brick?.directCommand.stopMotor(onPorts: .C, withBrake: true)
        } else if self.rightMotor == "D" {
            self.robotConnection.brick?.directCommand.stopMotor(onPorts: .D, withBrake: true)
        } else {
            print("Ahhhh everything's broken!") // bad example of a use case failing silently if the user inputs the wrong motor value
        }
    }
    
    func stopLeftMotor() {
        if self.leftMotor == "A" {
            self.robotConnection.brick?.directCommand.stopMotor(onPorts: .A, withBrake: true)
        } else if self.leftMotor == "B" {
            self.robotConnection.brick?.directCommand.stopMotor(onPorts: .B, withBrake: true)
        } else if self.leftMotor == "C" {
            self.robotConnection.brick?.directCommand.stopMotor(onPorts: .C, withBrake: true)
        } else if self.leftMotor == "D" {
            self.robotConnection.brick?.directCommand.stopMotor(onPorts: .D, withBrake: true)
        } else {
            print("Ahhhh everything's broken!") // bad example of a use case failing silently if the user inputs the wrong motor value
        }
    }
    
    func returnIter() -> Int {
        var iter = 0
        
        if self.topNSelector == "Top-1" {
            iter = 1
        } else if self.topNSelector == "Top-5" {
            iter = 5
        } else { // "Top-10"
            iter = 10
        }
        
        return iter
    }
}
