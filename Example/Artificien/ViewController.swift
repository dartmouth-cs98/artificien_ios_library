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
                
        let appData: [String: ArtificienDataType] = [
            "age": .Float(15.0),
            "bodyMassIndex": .Float(29.6789),
            "sex": .Float(1.0),
            "stepCount": .Float(5000.0)
        ]
        
        artificien.train(data: appData)
    }
}

// Note: Sometimes the above code will fail, saying that you can't construct `MyPodName`. I've found that simply deleting and retyping the code will make it work. If you continue to have issues, leave a comment below!
