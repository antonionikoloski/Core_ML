//
//  StandardScaler.swift
//  core_ml_emteq
//
//  Created by Antonio Nikoloski on 16.5.23.
//

import Foundation

class StandardScaler {
    var mean: [Double] = []
     var standardDeviation: [Double] = []
    
    func fit(data: [[Double]]) {
        // Calculate means and standard deviations for each column in data
        let rowCount = data.count
        let columnCount = data[0].count

        for rowIndex in 0..<columnCount {
            var rowData: [Double] = []
            for columnIndex in 0..<rowCount {
                rowData.append(data[columnIndex][rowIndex])
            }

            let mean = round((rowData.reduce(0, +) / Double(rowCount)) * 1e5) / 1e5
            let variance = rowData.map { pow($0 - mean, 2.0) }.reduce(0, +) / Double(columnCount)
            let stdDev = round(sqrt(variance) * 1e5) / 1e5

            self.mean.append(mean)
            self.standardDeviation.append(stdDev)
        }
    }



    func transform(data: [[Double]]) -> [[Double]] {
        var transformedData: [[Double]] = []
        
        for row in data {
            var newRow: [Double] = []
            for (index, value) in row.enumerated() {
                let newValue = (value - mean[index]) / standardDeviation[index]
                newRow.append(newValue)
            }
            transformedData.append(newRow)
        }

        return transformedData
    }
}
