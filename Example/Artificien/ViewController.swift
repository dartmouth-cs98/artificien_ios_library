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
        
        let artificien = Artificien(nodeAddress: "blah")
        artificien.train(trainingData: ["hello": 400], validationData: ["val": 23.5])
    }
}

// Note: Sometimes the above code will fail, saying that you can't construct `MyPodName`. I've found that simply deleting and retyping the code will make it work. If you continue to have issues, leave a comment below!
