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
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence.
            let topLabelObservation = objectObservation.labels[0].identifier
            
            if topLabelObservation == self.targetClass {
                let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
                
                self.ev3Handler(objectBounds)
                
                let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
                
                detectionOverlay.addSublayer(shapeLayer)
            } else {
                self.robotConnection.brick?.directCommand.stopMotor(onPorts: .A, withBrake: true)
                self.robotConnection.brick?.directCommand.stopMotor(onPorts: .D, withBrake: true)
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
        
        print(xDifference)
        print(bounds.midY)
        
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
        self.robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .A, withPower: 12)
        self.robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .D, withPower: -12)
    }
    
    func turnLeft() {
        self.robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .A, withPower: -12)
        self.robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .D, withPower: 12)
    }
    
    func stopMotors() {
        self.robotConnection.brick?.directCommand.stopMotor(onPorts: .A, withBrake: true)
        self.robotConnection.brick?.directCommand.stopMotor(onPorts: .D, withBrake: true)
    }
}
