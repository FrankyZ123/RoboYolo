//
//  HomeViewController.swift
//  RoboYolo
//
//  Created by Frank Zane Sand on 2/15/21.
//

import UIKit

class HomeViewController: UIViewController, UITextFieldDelegate {
    // these fives lines pull data from the View screen into the code
    @IBOutlet weak var TargetClass: UITextField!
    @IBOutlet weak var AccuracyThreshold: UITextField!
    @IBOutlet weak var LeftMotor: UITextField!
    @IBOutlet weak var RightMotor: UITextField!
    @IBOutlet weak var topNSelector: UISegmentedControl!
    
    // this is what transitions from the home screen to the camera view (i.e. the "Run" button)
    @IBAction func HomeToCameraSegueClicked(_ sender: Any) {
        self.performSegue(withIdentifier: "HomeToCameraSegue", sender: self)
    }
    
    // this ensures the keyboard minimizes when the user hits "return"
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.view.endEditing(true)
        return true
    }
    
    // function called after the home screen loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // these ensure the 4 text-based input fields above call the overridden textFieldShouldReturn
        self.TargetClass.delegate = self
        self.AccuracyThreshold.delegate = self
        self.LeftMotor.delegate = self
        self.RightMotor.delegate = self
    }
    
    // this ports the data input on the homescreen to the CameraViewController
    // which in turn allows the YOLOViewController to inherit this data
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // set target view
        let vc = segue.destination as! CameraViewController
        
        // set the variables in the target view to the input values from the user
        vc.targetClass = self.TargetClass.text!
        vc.accuracyThreshold = Float(self.AccuracyThreshold.text!)!
        vc.leftMotor = self.LeftMotor.text!
        vc.rightMotor = self.RightMotor.text!
        
        // unpack the top-n selector segment to get the text (title) value
        vc.topNSelector = self.topNSelector.titleForSegment(at: self.topNSelector.selectedSegmentIndex)!
    }
}
