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
    @IBAction func takeMemorySnapshotTapped(_ sender: Any) {
        MimirMemoryLogger.saveCurrentSnapshotToFile { (url) -> (Void) in
            guard let url = url else {
                return
            }
            let alert = UIAlertController(title: "Success", message: "Memory snapshot taken successfully, location: \(url.absoluteString)\nLook at console for more details", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            print("Latest memory snapshot location: \(url.absoluteString)")
        }
    }
    
    @IBAction func getAllMemorySnapshotsTapped(_ sender: Any) {
        if let urls = MimirMemoryLogger.getSavedSnapshots() {
            print("URLS of all saved snapshots: \(urls)")
            let alert = UIAlertController(title: "Success", message: "Memory snapshots fetched, locations: \(urls)\nLook at console for more details", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Error", message: "No saved snapshots found - Press the button above to take a memory snapshot first", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

