import Foundation
import SwiftCSV
import CoreMotion
import CodableCSV

class OcoFileParser: DataParser {
    // Convert OCO recording file to data arrays, given at a fixed rate of 50 Hz

    let config: [String: Any]
    let filePath: String
    var parseInProgress: Bool = false
    var dataFile: [[String: String]]
    var iDataRow: Int = 0

    init(config: [String: Any], filePath: String) throws {
        // Create file parser that converts recording rows to data arrays
        //
        // Parameters
        // ----------
        // config : [String: Any]
        //     Dictionary containing config params
        // file_path : String
        //     Path to recording file

        self.config = config
        self.filePath = filePath
        print(filePath)
        let fileContents = try String(contentsOfFile: filePath)
        let decoder = CSVDecoder { settings in
            settings.headerStrategy = .firstLine
        }
        let csvFile: CSV = try CSV<Named>(url: URL(fileURLWithPath: filePath))
            
            // Access the header and rows
      
        print(csvFile.rows[0])
        
        
        var decodedDataFile = try decoder.decode([[String: String]].self, from: fileContents)
        decodedDataFile = decodedDataFile.map { row in
            var newRow = row
            newRow.removeValue(forKey: "Label")
            return newRow
        }
        self.dataFile = decodedDataFile
//       for (index, row) in dataFile.enumerated() {
//            print("Row \(index):", row)
//       }
     
        super.init()
        // Array that holds the parsed data
        data = Array(repeating: [:], count: dataFile[0].keys.count)
       

        prepareColumns()
    }

    override func prepareColumns() {
        cols = dataFile[0].keys.map { $0 }
          print(cols)
        
        
        
        columnsTimestamp = cols.filter { $0.lowercased().contains("timestamp") }
           columnsAcc = cols.filter { $0.lowercased().contains("accelerometer") }
           columnsGyro = cols.filter { $0.lowercased().contains("gyroscope") }
           columnsMag = cols.filter { $0.lowercased().contains("magnetometer") }
           columnsEuler = cols.filter { $0.lowercased().contains("euler") }
           columnsNav = cols.filter { $0.lowercased().contains("nav") }
           columnsProx = cols.filter { $0.lowercased().contains("prox") }
           columnsPressure = cols.filter { $0.lowercased().contains("pressure") }
        print(columnsProx.count)
          columnsPressure = cols.filter { $0.contains("Pressure") }
    }

    override func parse() {
        // Parse raw bytes and store data in dataframe

        let sleepTime = DispatchTimeInterval.milliseconds(20)
        parseInProgress = true

        while parseInProgress {
            if iDataRow < dataFile.count {
                let row = dataFile[iDataRow]
                putDataArray(row)
                iDataRow += 1
                Thread.sleep(forTimeInterval: 0.02)
            } else {
                stopParsing()
            }
        }
    }

     func putDataArray(_ row: [String: String]) {
        // Add parsed row data to the data array
    }

    override func stopParsing() {
        // Stop receiving and parsing data
        parseInProgress = false
    }
}

