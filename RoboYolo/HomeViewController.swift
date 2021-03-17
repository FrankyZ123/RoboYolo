//
//  HomeViewController.swift
//  RoboYolo
//
//  Created by Frank Zane Sand on 2/15/21.
//

import UIKit

class HomeViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var TargetClass: UITextField!
    @IBOutlet weak var AccuracyThreshold: UITextField!
    @IBOutlet weak var LeftMotor: UITextField!
    @IBOutlet weak var RightMotor: UITextField!
    @IBOutlet weak var topNSelector: UISegmentedControl!
    
    @IBAction func HomeToCameraSegueClicked(_ sender: Any) {
        self.performSegue(withIdentifier: "HomeToCameraSegue", sender: self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.view.endEditing(true)
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.TargetClass.delegate = self
        self.AccuracyThreshold.delegate = self
        self.LeftMotor.delegate = self
        self.RightMotor.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! CameraViewController
        vc.targetClass = self.TargetClass.text!
        vc.accuracyThreshold = Float(self.AccuracyThreshold.text!)!
        vc.leftMotor = self.LeftMotor.text!
        vc.rightMotor = self.RightMotor.text!
        vc.topNSelector = self.topNSelector.titleForSegment(at: self.topNSelector.selectedSegmentIndex)!
    }
}
