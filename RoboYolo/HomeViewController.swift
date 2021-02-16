//
//  HomeViewController.swift
//  RoboYolo
//
//  Created by Frank Zane Sand on 2/15/21.
//

import UIKit

class HomeViewController: UIViewController {
    @IBOutlet weak var TargetClass: UITextField!
    
    @IBAction func HomeToCameraSegueClicked(_ sender: Any) {
        self.performSegue(withIdentifier: "HomeToCameraSegue", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! CameraViewController
        vc.targetClass = self.TargetClass.text!
    }
}
