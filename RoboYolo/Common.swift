//
//  Common.swift
//  RoboYolo
//
//  Created by Frank Zane Sand on 3/19/21.
//
//  File to contain non-specific code.

import Foundation

// pretty simple conversion function to handle the Top-N selector
// on the Homescreen
func returnIter(topNSelector: String, resultsLength: Int) -> Int {
    var iter = 0
    
    if topNSelector == "Top-1" { // Top-1
        iter = 1
    } else if topNSelector == "Top-5" { // Top-5
        iter = 5
    } else if topNSelector == "Top-10" { // Top-10
        iter = 10
    } else { // Top-N
        iter = resultsLength - 1
    }
    
    return iter
}
