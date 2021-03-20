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
        iter = 0 // swift is 0 indexed, this will ensure only the top classification is checked
    } else if topNSelector == "Top-5" { // Top-5
        iter = 4 // go through the first 5 (0, 1, 2, 3, 4) indeces
    } else if topNSelector == "Top-10" { // Top-10
        iter = 9 // ...
    } else { // Top-N
        iter = resultsLength - 1 // go through all the results
    }
    
    return iter
}
