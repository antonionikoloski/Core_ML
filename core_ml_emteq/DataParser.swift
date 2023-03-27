import Foundation

class DataParser {
    // Base class for preparing data from Bluetooth or file streams
    
    var data: [[String: Double]]
    var columnsTimestamp: [String]
    var columnsAcc: [String]
    var columnsGyro: [String]
    var columnsMag: [String]
    var columnsEuler: [String]
    var columnsNav: [String]
    var columnsProx: [String]
    var columnsPressure: [String]
    var cols: [String]
    var colsMap: [String: Int]
    
    init() {
        data = []
        columnsTimestamp = []
        columnsAcc = []
        columnsGyro = []
        columnsMag = []
        columnsEuler = []
        columnsNav = []
        columnsProx = []
        columnsPressure = []
        cols = []
        colsMap = [:]
    }
    
    func prepareColumns() {
        // Method that prepares the required columns
        // This method should be overridden in subclasses.
        fatalError("prepareColumns() method is not implemented")
    }
    
    func prepareColumnsMap() {
        // Prepare map columns names -> numbers
        colsMap = Dictionary(uniqueKeysWithValues: zip(cols, cols.indices))
    }
    
    func parse() {
        // Parse method that continuously parses data from the stream
        // This method should be overridden in subclasses.
        fatalError("parse() method is not implemented")
    }
    
    func putDataArray(_ data: [String: Double]) {
        // Add parsed data to the data array
        self.data.append(data)
    }
    
    func stopParsing() {
        // Stop the parser
        // This method should be overridden in subclasses.
        fatalError("stopParsing() method is not implemented")
    }
    
    func getColumns() -> [String] {
        return cols
    }
    
    func getColumnsMap() -> [String: Int] {
        return colsMap
    }
    
    func getNavColumns() -> [String] {
        return columnsNav
    }
    
    func getProxColumns() -> [String] {
        return columnsProx
    }
    
    func getAccColumns() -> [String] {
        return columnsAcc
    }
    
    func getGyroColumns() -> [String] {
        return columnsGyro
    }
    
    func getMagColumns() -> [String] {
        return columnsMag
    }
    
    func getEulerColumns() -> [String] {
        return columnsEuler
    }
    
    func getPresColumns() -> [String] {
        return columnsPressure
    }
    
    func getTimeColumns() -> [String] {
        return columnsTimestamp
    }
}
