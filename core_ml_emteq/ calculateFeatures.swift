import Accelerate

func calculateFeatures(data: [[Double]]) -> [Double] {
    let rows = data.count
    let cols = data[0].count

    var features: [Double] = []

    for col in 0..<cols {
        var columnData = [Double](repeating: 0.0, count: rows)
        for row in 0..<rows {
            columnData[row] = data[row][col]
        }

        var meanValue = 0.0
        vDSP_meanvD(columnData, 1, &meanValue, vDSP_Length(rows))

        var diffSquared = columnData.map { pow($0 - meanValue, 2) }
        var sumOfDiffSquared = 0.0
        vDSP_sveD(diffSquared, 1, &sumOfDiffSquared, vDSP_Length(rows))
        let stdValue = sqrt(sumOfDiffSquared / Double(rows))

        let minValue = columnData.min()!
        let maxValue = columnData.max()!
        let rangeValue = abs(maxValue - minValue)

        let q75Value = columnData.quantile(0.75)
        let q25Value = columnData.quantile(0.25)
        let iqrValue = q75Value - q25Value
	    
        
        let kurtosisValue = columnData.kurtosis()
        let skewnessValue = columnData.skewness()
        
        var rmsValue = 0.0
        vDSP_rmsqvD(columnData, 1, &rmsValue, vDSP_Length(rows))

        let currentFeatures = [
            meanValue,
            stdValue,
            minValue,
            maxValue,
            rangeValue,
            iqrValue,
            rmsValue
        ]
        
        features.append(contentsOf: currentFeatures)
    }

    return features
}

extension Array where Element == Double {
    func quantile(_ p: Double) -> Double {
        let sorted = self.sorted()
        let index = Int(Double(count) * p)
        return sorted[index]
    }
    func standardDeviation() -> Double {
           let count = self.count
           let mean = self.reduce(0, +) / Double(count)
           let sumOfSquaredDifferences = self.map { pow($0 - mean, 2) }.reduce(0, +)
           return sqrt(sumOfSquaredDifferences / Double(count - 1))
       }

       func kurtosis() -> Double {
           let count = self.count
           let mean = self.reduce(0, +) / Double(count)
           let stdDev = standardDeviation()
           let sumOfFourthPowerDifferences = self.map { pow(($0 - mean) / stdDev, 4) }.reduce(0, +)
           return sumOfFourthPowerDifferences / Double(count) - 3
       }

       func skewness() -> Double {
           let count = self.count
           let mean = self.reduce(0, +) / Double(count)
           let stdDev = standardDeviation()
           let sumOfThirdPowerDifferences = self.map { pow(($0 - mean) / stdDev, 3) }.reduce(0, +)
           return sumOfThirdPowerDifferences / Double(count)
       }
}


