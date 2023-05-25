//
//  ViewController.swift
//  core_ml_emteq
//
//  Created by Antonio Nikoloski on 23.3.23.
//

import UIKit
import CoreML
import Foundation
import Accelerate

class ViewController: UIViewController {
    var config: [String: Any]?
    var plotter_config: [String: Any]?
    override func viewDidLoad() {
        super.viewDidLoad()
        runMainApp()
        
        
        // Parameters
        // let fs = 50.0
        //  let n = 1000
        
        // Generate the signal
        //  let signal = generateSignal(fs: fs, n: n)
        
        // Provide the coefficients from Python
        //  let b: [Double] = [0.0913149 , 0.1826298 , 0.0913149]
        //  let a: [Double] = [1,       -0.98240579 , 0.34766539]
        
        // Apply the filter
        //  let filteredSignal = applyFilter(signal: signal, b: b, a: a)
        
        // Print filtered signal
        //print(filteredSignal)
        //print(signal)
        
        //  let bl: [Double] = [0.00094469 ,0.00188938, 0.00094469]
        //  let al: [Double] = [ 1,        -1.91119707 , 0.91497583]
        
        //  let x_trend = applyZeroPhaseFilter(signal: x_trend, b: bl, a: al)
        //   let reader = CSVReader()
        //   if let values = reader.readCSV(fileName: "x_trend", fileType: "csv") {
        //   print("Values: \(values)")
        //       let x_trend = applyZeroPhaseFilter(signal: values, b: bl, a: al)
        //     print(x_trend)
        
        //  } else {
        //     print("Failed to read values from .csv file")
        //  }
        
        
        //        if let configPath = getfilePath(forResource: "config", ofType: "yml") {
        //            if let configFile = readConfig(from: configPath) {
        //                config = configFile
        //            } else {
        //                print("Unable to read configuration.")
        //            }
        //        }
        //        if let plotterconfigPath = getfilePath(forResource: "expressions", ofType: "yml") {
        //            if let configFileplotter = readConfig(from: plotterconfigPath) {
        //                plotter_config = configFileplotter
        //            } else {
        //                print("Unable to read configuration.")
        //            }
        //        }
        //        let filePath = getfilePath(forResource: "test", ofType: "csv")!
        //
        //        do {
        //            let ocoFileParserInstance = try OcoFileParser(config: config!, filePath: filePath)
        //            let dataProcessorInstance = DataProcessor(config: config!, parser: ocoFileParserInstance)
        //
        //        } catch {
        //            print("Error initializing OcoFileParser:", error.localizedDescription)
        //        }
        
    }
    func runMainApp() {
        Task.init {
            await MainApp.main()
        }
        
    }
}
