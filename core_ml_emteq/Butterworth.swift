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


// Parameters


