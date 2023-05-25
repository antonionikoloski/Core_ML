//
//  data_processor.swift
//  core_ml_emteq
//
//  Created by Antonio Nikoloski on 29.4.23.
//

import Foundation

enum ProcessType {
    case algo
    case plot
}

class DataProcessor {
    var config: [String: Any] // Your configuration dictionary
    var parser: OcoFileParser // Your parser class
    var collectingData: Bool = false
    var allowAlgoProcess: Bool = true
    var queues: [DispatchQueue] = []
    var algoPlotterQueues: [DispatchQueue] = []
    var algoPlotParams: [Any] = [] // Replace 'Any' with the appropriate type
    var data: [[Double]] // Your data array
    var iData: Int
    
    init(config: [String: Any], parser: OcoFileParser) {
        self.config = config
        self.parser = parser
        self.collectingData = false
        self.allowAlgoProcess = true
        self.queues = []
        self.algoPlotterQueues = []
        let maxRows = config["dataframe"] as? [String: Any]
        let maximum = maxRows!["max_rows"]  as? Int
        let numColumns = parser.getColumns()
        self.data = Array(repeating: Array(repeating: Double.nan, count: numColumns), count: maximum!)
        self.iData = 0
        
    }
    
    func getData() {
        // Implement your getData function here
    }
    
    func stopCollectingData() {
        // Implement your stopCollectingData function here
    }
    
    func createProcess(user: WearingAlgo, type: ProcessType, connectToPlotter: Bool = false) {
        if type == .algo, allowAlgoProcess {
            let queue = DispatchQueue(label: "com.example.algoQueue")
            queues.append(queue)
            
            if connectToPlotter {
                let queuePlotter = DispatchQueue(label: "com.example.plotterQueue")
                algoPlotterQueues.append(queuePlotter)
                algoPlotParams.append(user.plot_params)
                
                // Perform user-defined algo process with plotter connected
                queue.async {
                    user.call(queue: queue, queuePlotter: [queuePlotter])
                 }
            } else {
                // Perform user-defined algo process without plotter
                queue.async {
                    user.call(queue: queue)
                }
            }
        } else if type == .plot, allowAlgoProcess {
            allowAlgoProcess = false
            
            // Perform user-defined plot process
            let queue_final = DispatchQueue.global(qos: .userInitiated)

            // Perform user-defined plot process
            queue_final.async {
                user.call(queue: queue_final,queuePlotter: self.algoPlotterQueues)
            }
        }
    }
    
    func saveRecordedData() {
        // Implement your saveRecordedData function here
    }
}

