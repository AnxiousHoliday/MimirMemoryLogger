//
//  ViewController.swift
//  MimirMemoryLogger
//
//  Created by amereid on 09/28/2020.
//  Copyright (c) 2020 amereid. All rights reserved.
//

import UIKit
import MimirMemoryLogger

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func takeMemorySnapshotTapped(_ sender: Any) {
        MimirMemoryLogger.saveCurrentSnapshotToFile { (url) -> (Void) in
            guard let url = url else {
                return
            }
            print("Latest memory snapshot location: \(url.absoluteString)")
        }
    }
}

