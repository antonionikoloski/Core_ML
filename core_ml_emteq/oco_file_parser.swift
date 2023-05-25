import Foundation
import SwiftCSV
import CoreMotion
import CodableCSV

class OcoFileParser: DataParser {
    // Convert OCO recording file to data arrays, given at a fixed rate of 50 Hz
    var iDataRow: Int = 0
    var timer: Timer?
    let config: [String: Any]
    let filePath: String
    var parseInProgress: Bool = false
    var dataFile:   CSV<Named>
    init(config: [String: Any], filePath: String) throws {
        // Create file parser that converts recording rows to data arrays
        //
        // Parameters
        // ----------
        // config : [String: Any]
        //     Dictionary containing config params
        // file_path : String
        // Path to recording file
        self.config = config
        self.filePath = filePath
        
        let fileContents = try String(contentsOfFile: filePath)
        let decoder = CSVDecoder { settings in
            settings.headerStrategy = .firstLine
        }
        let csvFile: CSV = try CSV<Named>(url: URL(fileURLWithPath: filePath))
            
            // Access the header and rows
      

        
        var decodedDataFile = try decoder.decode([[String: String]].self, from: fileContents)
        decodedDataFile = decodedDataFile.map { row in
            var newRow = row
            newRow.removeValue(forKey: "Label")
            return newRow
        }
    //   let modifiedCsvFile = try CSV(rows: modifiedRows)
    self.dataFile = csvFile

    
       //  Convert the csvFile object to an array of dictionaries with named keys
        // Get the header (column names) and rows of the csvFile object
       //  Get the header (column names) and rows of the csvFile object
      

       
     
        super.init()
        // Array that holds the parsed data
        data = Array(repeating: [:], count: dataFile.rows[0].keys.count)
       

        prepareColumns()
        prepareColumnsMap()
    }

    override func prepareColumns() {
        cols = dataFile.rows[0].keys.map { $0 }
          
        
        
        
        columnsTimestamp = cols.filter { $0.lowercased().contains("timestamp") }
           columnsAcc = cols.filter { $0.lowercased().contains("accelerometer") }
           columnsGyro = cols.filter { $0.lowercased().contains("gyroscope") }
           columnsMag = cols.filter { $0.lowercased().contains("magnetometer") }
           columnsEuler = cols.filter { $0.lowercased().contains("euler") }
           columnsNav = cols.filter { $0.lowercased().contains("nav") }
           columnsProx = cols.filter { $0.lowercased().contains("prox") }
           columnsPressure = cols.filter { $0.lowercased().contains("pressure") }
    }
    func prepareColumnsMap()
    {
        let header = dataFile.header
        
        for (index,column) in header.enumerated()
        {
            self.colsMap[column] = index
        }
    }

  override  func parse(algo: ExpressionsRecognitionMlAlgo) {
         
          timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] timer in
              guard let self = self else { return }
              var data =  self.dataFile.rows[self.iDataRow]
             
              do {
                  try algo.process(&data)
              } catch {
                  print("Failed to process data: \(error)")
                  timer.invalidate()
                  return
              }
              self.iDataRow += 1
              // stop the timer when no more data
              if self.iDataRow >= self.dataFile.rows.count{
                  timer.invalidate()
              }
              
              
             
             
          }
          
          // Add the timer to the current run loop
          RunLoop.current.add(timer!, forMode: .default)
          RunLoop.current.run()
      }
  

     func putDataArray(_ row: [String: String]) {
        // Add parsed row data to the data array
    }

    override func stopParsing() {
        // Stop receiving and parsing data
        parseInProgress = false
    }
    func getColumns() -> Int {
        return dataFile.rows.count
    }
}

