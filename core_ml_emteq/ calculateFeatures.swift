import Accelerate

func calculateFeatures(data: [[Double]]) -> [Double]? {
    guard !data.isEmpty, !data[0].isEmpty else {
        print("Error: The input data is empty or has empty subarrays.")
        return nil
    }

    let rows = data.count
    let cols = data[0].count

    for row in data {
        if row.count != cols {
            print("Error: The input data contains inconsistent column sizes.")
            return nil
        }
    }

    var features: [Double] = []

    for col in 0..<cols {
        var columnData = [Double](repeating: 0.0, count: rows)
        for row in 0..<rows {
            columnData[row] = data[row][col]
        }

        guard let minValue = columnData.min(), let maxValue = columnData.max() else {
            print("Error: Unable to calculate min and max values.")
            return nil
        }

        var meanValue = 0.0
        vDSP_meanvD(columnData, 1, &meanValue, vDSP_Length(rows))

        var diffSquared = columnData.map { pow($0 - meanValue, 2) }
        var sumOfDiffSquared = 0.0
        vDSP_sveD(diffSquared, 1, &sumOfDiffSquared, vDSP_Length(rows))
        
        guard rows > 1 else {
            print("Error: Not enough data points to calculate standard deviation.")
            return nil
        }
        let stdValue = sqrt(sumOfDiffSquared / Double(rows))

        let rangeValue = abs(maxValue - minValue)

        guard let q75Value = columnData.quantile(0.75), let q25Value = columnData.quantile(0.25) else {
            print("Error: Unable to calculate quantiles.")
            return nil
        }
        let iqrValue = q75Value - q25Value

        //let kurtosisValue = columnData.kurtosis()
       // let skewnessValue = columnData.skewness()

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
    func quantile(_ p: Double) -> Double? {
        guard !isEmpty else {
            print("Error: Cannot calculate quantile for an empty array.")
            return nil
        }
        
        guard p >= 0 && p <= 1 else {
            print("Error: The quantile parameter must be in the range [0, 1].")
            return nil
        }
        
        let sorted = self.sorted()
        let index = Int(Double(count) * p)
        return sorted[index]
    }
    
    func standardDeviation() -> Double? {
        guard !isEmpty else {
            print("Error: Cannot calculate standard deviation for an empty array.")
            return nil
        }
        
        guard count > 1 else {
            print("Error: Not enough data points to calculate standard deviation.")
            return nil
        }
        
        let mean = self.reduce(0, +) / Double(count)
        let sumOfSquaredDifferences = self.map { pow($0 - mean, 2) }.reduce(0, +)
        return sqrt(sumOfSquaredDifferences / Double(count - 1))
    }

    func kurtosis() -> Double? {
        guard let stdDev = standardDeviation(), stdDev != 0 else {
            print("Error: Cannot calculate kurtosis with an undefined or zero standard deviation.")
            return nil
        }
        
        let mean = self.reduce(0, +) / Double(count)
        let sumOfFourthPowerDifferences = self.map { pow(($0 - mean) / stdDev, 4) }.reduce(0, +)
        return sumOfFourthPowerDifferences / Double(count) - 3
    }

    func skewness() -> Double? {
        guard let stdDev = standardDeviation(), stdDev != 0 else {
            print("Error: Cannot calculate skewness with an undefined or zero standard deviation.")
            return nil
        }
        
        let mean = self.reduce(0, +) / Double(count)
        let sumOfThirdPowerDifferences = self.map { pow(($0 - mean) / stdDev, 3) }.reduce(0, +)
        return sumOfThirdPowerDifferences / Double(count)
    }
}



