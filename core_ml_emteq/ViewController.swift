//
//  ViewController.swift
//  core_ml_emteq
//
//  Created by Antonio Nikoloski on 23.3.23.
//

import UIKit
import CoreML
class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let filePath = Bundle.main.path(forResource: "config", ofType: "yml") {
            // Read the configuration file
            guard let  config = readConfig(from: filePath) else { return  }
            
            do {
                guard let filePath_csv = Bundle.main.path(forResource: "test", ofType: "csv") else { return  }
                // Create an instance of the OcoFileParser class
                let ocoFileParser = try OcoFileParser(config: config, filePath: filePath_csv)

                // Call the parse method
                ocoFileParser.parse()

                // Optionally, you can call other methods on the ocoFileParser instance
                // For example: ocoFileParser.stopParsing()
            } catch {
                print("Error initializing OcoFileParser: \(error.localizedDescription)")
            }
        }
        
        
    }
}
