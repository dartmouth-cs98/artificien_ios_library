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
        let appData: [String: Float] = [
            "age": 15,
            "bodyMassIndex": 20,
            "sex": 1,
            "stepCount": 5000
        ]
        artificien.train(data: appData)
    }
}
