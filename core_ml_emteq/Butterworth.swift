import Foundation
import Numerics
import Surge
import Accelerate


func generateSignal(fs: Double, n: Int) -> [Double] {
    let time = (0..<n).map { Double($0) }
    return time.map { 10 * sin(2 * Double.pi * 5 / fs * $0) + 20 * sin(2 * Double.pi * 12 / fs * $0) }
}


func applyFilter(signal: [Double], b: [Double], a: [Double]) -> [Double] {
    let signalLength = signal.count
    let filterOrder = a.count - 1
    var result = [Double](repeating: 0, count: signalLength)
    
    for i in 0..<signalLength {
        var output = b[0] * signal[i]
        
        for j in 1...filterOrder {
            if i - j >= 0 {
                output += b[j] * signal[i - j] - a[j] * result[i - j]
            }
        }
        
        result[i] = output
    }
    
    return result
}

func applyZeroPhaseFilter(signal: [Double], b: [Double], a: [Double]) -> [Double] {
    let forwardFilteredSignal = applyFilter(signal: signal, b: b, a: a)
    let backwardFilteredSignal = applyFilter(signal: forwardFilteredSignal.reversed(), b: b, a: a)

    return backwardFilteredSignal.reversed()
}
// Parameters

class CSVReader {
    func readCSV(fileName: String, fileType: String) -> [Double]? {
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: fileType) else {
            print("File not found")
            return nil
        }
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.split(separator: "\n")
            
            return lines.compactMap { Double($0) }
        } catch {
            print("Error reading file: \(error.localizedDescription)")
            return nil
        }
    }
}
func applyFilterzi(signal: [Double], b: [Double], a: [Double], zi: [Double]) -> ([Double], [Double]) {
    let filterOrder = a.count - 1
    var result = [Double](repeating: 0, count: signal.count)
    var zf = zi

    for i in 0..<signal.count {
        var output = b[0] * signal[i]

        for j in 1...filterOrder {
            if i >= j {
                output += b[j] * signal[i - j] // input x[n - j]
            }
            if j <= zf.count {
                output -= a[j] * zf[j - 1] // output y[n - j]
            }
        }

        // Shift zf[] array down and insert new output
        for j in stride(from: zf.count - 1, to: 0, by: -1) {
            zf[j] = zf[j - 1]
        }

        zf[0] = output // updating zf[0] based on the current output

        result[i] = output
    }

    return (result, zf)
}


func applyFilterziforpurpose(signal: [Double], b: [Double], a: [Double], zi: [Double]) -> ([Double], [Double]) {
    let filterOrder = a.count - 1
    var result = [Double](repeating: 0, count: signal.count)
    var zf = Array(repeating: 0.0, count: filterOrder)

    // Copy initial conditions to zf, respecting its size
    for i in 0..<min(zi.count, zf.count) {
        zf[i] = zi[i]
    }

    for i in 0..<signal.count {
        var output = b[0] * signal[i]

        for j in 1...filterOrder {
            if i >= j {
                output += b[j] * signal[i - j] // input x[n - j]
            }
            if j <= zf.count {
                output -= a[j] * zf[j - 1] // output y[n - j]
            }
        }

        // Shift zf[] array down and insert new output
        for j in stride(from: zf.count - 1, to: 0, by: -1) {
            zf[j] = zf[j - 1]
        }

        zf[0] = output // updating zf[0] based on the current output

        result[i] = output
    }
    return (result, zf)
}












