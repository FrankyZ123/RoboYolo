//
//  PhotoViewController.swift
//  sample_of_ev3ios
//
//  Created by Frank Zane Sand on 10/11/20.
//  Copyright © 2020 Takehiko YOSHIDA. All rights reserved.
//

import UIKit
import AVFoundation
import ImageIO

class PhotoViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    let captureSession = AVCaptureSession()
    
    var currentColor = "n/a"
    
    var robotConnection : RobotConnection = RobotConnection()
    
    var previewLayer:CALayer!
    var captureDevice:AVCaptureDevice!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupRobotConnection()
        prepareCamera()
        beginSession()

        // Do any additional setup after loading the view.
    }
    
    func setupRobotConnection() {
        self.robotConnection.setup()
    }
    
    
    
    func prepareCamera() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        let availableDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: AVMediaType.video,
            position: .back).devices
        
        if availableDevices.count != 0 {
                captureDevice = availableDevices.first
        }
    }
    
    func beginSession() {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            
            captureSession.addInput(captureDeviceInput)
        } catch {
            print(error.localizedDescription)
        }
        
        
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        self.previewLayer = previewLayer
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.layer.frame
            
        captureSession.startRunning()
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey):NSNumber(value:kCVPixelFormatType_32BGRA)]
        
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }
        
        captureSession.commitConfiguration()
        
        let queue = DispatchQueue(label: "com.zanesand.captureQueue")
        dataOutput.setSampleBufferDelegate(self, queue: queue)
    }
    
    func ev3Handler(_ nextColor: String) {
        if nextColor != self.currentColor {
            if nextColor == "red" {
                self.robotConnection.brick?.directCommand.stopMotor(onPorts: .A, withBrake: true)
                self.robotConnection.brick?.directCommand.stopMotor(onPorts: .B, withBrake: true)
            } else if nextColor == "green" {
                self.robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .A, withPower: 100)
                self.robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .B, withPower: 100)
            } else if nextColor == "blue" {
                self.robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .A, withPower: -100)
                self.robotConnection.brick?.directCommand.turnMotorAtPower(onPorts: .B, withPower: -100)
            }
            self.currentColor = nextColor
        }
        
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let attachments = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault,
                                                        target: pixelBuffer,
                                                        attachmentMode: CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)) as? [CIImageOption: Any]
        let ciImage = CIImage(cvImageBuffer: pixelBuffer, options: attachments)
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        
        let context = CIContext()
        let inputImage = ciImage
        let extent = inputImage.extent
        let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: inputExtent])!
        
        let outputImage = filter.outputImage!
        
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: CIFormat.RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        
        let red_unnormalized = CGFloat(bitmap[0]) / 255.0
        let green_unnormalized = CGFloat(bitmap[1]) / 255.0
        let blue_unnormalized = CGFloat(bitmap[2]) / 255.0
        let sum_unnormalized = red_unnormalized + green_unnormalized + blue_unnormalized
        
        let red = red_unnormalized / sum_unnormalized
        let green = green_unnormalized / sum_unnormalized
        let blue = blue_unnormalized / sum_unnormalized
        
        print(red, green, blue)
        
        let threshold = CGFloat(0.5)
        
        var nextColor = "n/a"
        
        if red > green && red > blue && red > threshold {
            nextColor = "red"
        } else {
            if green > red && green > blue && green > threshold {
                nextColor = "green"
            } else {
                if blue > red && blue > green && blue > CGFloat(0.35) {
                    nextColor = "blue"
                } else {
                    nextColor = "n/a"
                }
            }
        }
        
        print(nextColor)
        
        ev3Handler(nextColor)
        
    }
}
