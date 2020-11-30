//
//  ViewController.swift
//  RoboYolo
//
//  Created by Frank Zane Sand on 11/14/20.
//

import UIKit
import AVKit
import Vision



class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    var robotConnection : RobotConnection = RobotConnection()
    var currentClass = "n/a"
    var targetClass = "person"
    
    @IBOutlet weak var CameraView: UIView!
    @IBOutlet weak var ObjectClass: UILabel!
    @IBOutlet weak var Accuracy: UILabel!
    
    var model = YOLOv3().model
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.robotConnection.setup()
        
        let captureSession = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        view.addSubview(CameraView)
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.zanesand.captureQueue"))
        captureSession.addOutput(dataOutput)
        
    }
    
    func ev3Handler(){
        if self.currentClass == self.targetClass {
            self.robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .A, withPower: 100)
        }
        
        if self.currentClass != self.targetClass {
            self.robotConnection.brick?.directCommand.stopMotor(onPorts: .A, withBrake: true)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    
        guard let model = try? VNCoreMLModel(for: model) else { return }

        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            guard let results = finishedReq.results else { return }
            
            guard let firstObservation = results.first else { return }
            
            let current_class = ((firstObservation as AnyObject).labels?[0].identifier as AnyObject) as! String
            let accuracy: Int = Int((firstObservation as AnyObject).confidence * 100)
            
            DispatchQueue.main.async{
                self.ObjectClass.text = current_class
                self.Accuracy.text = "Accuracy: \(accuracy)%"
            }
            
            if self.currentClass != current_class {
                self.currentClass = current_class
            }
            
            if finishedReq.results == nil {
                self.currentClass = "n/a"
            }
            
            print(self.currentClass)
        }
        
        self.ev3Handler()
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }

}

