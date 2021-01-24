//
//  ViewController.swift
//  Artificien
//
//  Created by shreyas.v.agnihotri@gmail.com on 01/18/2021.
//  Copyright (c) 2021 shreyas.v.agnihotri@gmail.com. All rights reserved.
//

import UIKit
import Artificien

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let obj = Artificien(pointlessParam: "doesn't really matter")
        obj.temp()
    }
}

// Note: Sometimes the above code will fail, saying that you can't construct `MyPodName`. I've found that simply deleting and retyping the code will make it work. If you continue to have issues, leave a comment below!
