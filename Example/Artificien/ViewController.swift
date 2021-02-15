//
//  ViewController.swift
//  Artificien
//
//  Created by Shreyas Agnihotri on 01/18/2021.
//  Copyright (c) 2021 Shreyas Agnihotri. All rights reserved.
//

import UIKit
import Artificien

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let artificien = Artificien(chargeDetection: false, wifiDetection: false)
        let trainDict: [String: Float] = [
            "age": 15,
            "bodyMassIndex": 20,
            "sex": 1
        ]
        let valDict: [String: Float] = [
            "stepCount": 5000
        ]
        artificien.train(trainingData: trainDict, validationData: valDict)
    }
}

// Note: Sometimes the above code will fail, saying that you can't construct `MyPodName`. I've found that simply deleting and retyping the code will make it work. If you continue to have issues, leave a comment below!
