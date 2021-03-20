//
// File adapted from: https://developer.apple.com/documentation/vision/recognizing_objects_in_live_capture
//

import UIKit
import AVFoundation
import Vision

class YOLOViewController: CameraViewController {
    // setup the detection overlay object, this is what we will draw bounding boxes on
    private var detectionOverlay: CALayer! = nil
    
    // set a class wide variable for the direction the EV3 is currently moving in
    var currentDirection: String = ""
    
    // Vision parts
    private var requests = [VNRequest]()
    
    // load the YOLOv3 model
    var model = YOLOv3().model
    
    func setupVision() {
        // Setup Vision parts
        guard let model = try? VNCoreMLModel(for: model) else { return }
        
        // this is the meet of the application
        // it places in a swift dispatch queue the result detecting function
        // which in turn handles the tracking functionality
        let objectRecognition = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
            DispatchQueue.main.async(execute: {
                // perform all the UI updates on the main queue
                if let results = request.results {
                    self.detectResults(results)
                }
            })
        })
        self.requests = [objectRecognition]
    }
    
    func detectResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        
        // by default, we're going to take the top observation in results
        // which is the most confident object bounding box returned
        
        // this is an example of hidden complexity that would need to be
        // better modularized for a more technical audience because currently
        // this will never bound more than one object in a frame
        
        if results.count > 0 { // if there is an object in the frame
            // take the most confident object observation
            let topObservation = results.first as! VNRecognizedObjectObservation
            
            // determine how many classifications to look through
            let iter = returnIter(topNSelector: self.topNSelector, resultsLength: topObservation.labels.count)
            
            // for loop will search the sorted labels list
            // from most confident class prediction to
            // N most confident class prediction, where N is
            // taken as input from the user "Top-N Selector"
            
            for index in 0...iter {
                
                if (
                    
                    // if the classification matches user class
                    topObservation.labels[index].identifier == self.targetClass
                        
                    &&

                    // the confidence of that (object, class) is greater than user threshold
                    // accuracy of prediction is the confidence of the object * confidence of the label
                    // https://developer.apple.com/documentation/vision/vnrecognizedobjectobservation

                    topObservation.labels[index].confidence * topObservation.confidence >= self.accuracyThreshold) {
                    // compute the objectBounds
                    let objectBounds = VNImageRectForNormalizedRect(topObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
                    
                    // given the objectBounds and bufferSize, determine whether to go left or right
                    self.currentDirection = track(
                        self.robotConnection,
                        currentDirection: self.currentDirection,
                        bounds: objectBounds,
                        bufferSize: bufferSize,
                        leftMotor: self.leftMotor,
                        rightMotor: self.rightMotor
                    )
                    
                    // create the bounding box
                    let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
                    
                    // add the bounding box
                    detectionOverlay.addSublayer(shapeLayer)
                    
                    // if the target class is found, we want to exit from the for loop
                    break
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
}
