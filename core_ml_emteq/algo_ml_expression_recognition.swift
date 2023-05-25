//
//  algo_ml_expression_recognition.swift
//  core_ml_emteq
//
//  Created by Antonio Nikoloski on 31.3.23.
//

import Foundation
import CoreML
import Accelerate
import SwiftCSV

class ExpressionsRecognitionMlAlgo {
    var config: [String:Any]
    var model: MLModel?
    var fs: Double = 50.0
    var tModelWin: Double = 0.1
    var nModelWin: Int = 0
    var tDetrendWin: Double = 1
    var nDetrendWin: Int = 0
    var i_data : Int = 0
    var tDetrendMax: Double = 30
    var nDetrendMax: Int = 0
    var detrendOrder: Int = 1
    var parser: OcoFileParser
    var num_detrend_wins : Int = 0
    var b_data : [Double] = [0.06880911,0.86238178,0.06880911]
    var a_data : [Double] = [1.0,0.0,0.0]
    var b_trend : [Double] = [0.00094469,0.00188938,0.00094469]
    var a_trend : [Double] = [1.00000 , -1.91120 , 0.91498]
    var b_proxy : [Double] = [0.00717,0.02150,0.02150,0.00717]
    var a_proxy : [Double] = [1.00000 , -2.12664,1.59582,-0.41184]
    var filteredData: [[Double]] = []
    var data_buffer: [[Double]] = []
    var detrended_data: [[Double]] = []
    var data_filters_zi : [[Double]] = []
    var prox_filters_zi :[[Double]] = []
    var trends : [[Double]] = []
    var trend_filters_zi : [[Double]] = []
    var al : [Double] = [1,-1.91119707,0.91497583]
    var bl : [Double] = [0.00094469,0.00188938,0.00094469]
    var i_detrend : Int = 0
    var i_detrend_win : Int = 0
    var i_model : Int = 0
    var last_prediction : Int = 0
    let config_ml: MLModelConfiguration
    let model_ml: expression_recognition_new_detrend_circular_buffer
    var scaler : StandardScaler?
    init(config: [String: Any], parser: OcoFileParser) throws {
        self.config = config
        self.parser = parser
        self.scaler = StandardScaler()
        nModelWin = Int(fs * tModelWin)
        nDetrendWin = Int(fs * tDetrendWin)
        nDetrendMax = Int(fs * tDetrendMax)
      //  print(nDetrendMax)
        
        num_detrend_wins = nDetrendMax / nDetrendWin
    //    print(nModelWin)
        data_buffer = [[Double]](repeating: [Double](repeating: 0.0, count: 32), count:nDetrendMax)
        filteredData = [[Double]](repeating: [Double](repeating: 0.0, count: 32), count: nDetrendMax)
        detrended_data = [[Double]](repeating: [Double](repeating: 0.0, count: 32), count: nDetrendMax)
        data_filters_zi = [[Double]](repeating: [Double](repeating: 0.0, count: b_data.count - 1), count:32)
        prox_filters_zi = [[Double]](repeating: [Double](repeating: 0.0, count: b_data.count ), count:32)
        trends = [[Double]](repeating: [Double](repeating: 0.0, count:32), count:nDetrendMax)
        trend_filters_zi = [[Double]](repeating: [Double](repeating: 0.0, count:b_trend.count - 1), count:32)
        let filePath = getfilePath(forResource: "calibration", ofType: "csv")!
        config_ml = MLModelConfiguration()
        model_ml = try expression_recognition_new_detrend_circular_buffer(configuration: config_ml)
        calibrate(calibFile: filePath)
        
    }
    
    func calibrate(calibFile: String) {
        let csvFile: CSV = try! CSV<Named>(url: URL(fileURLWithPath: calibFile))
 //       let  prox_cols = self.parser.getProxColumns()
   //     let  nav_cols = self.parser.getNavColumns()
   //     let col_map = self.parser.getColumnsMap()
        let reorderedProxColumns = [
            "Prox/Raw[RightCheek]",
            "Prox/Raw[RightBrow]",
            "Prox/Raw[CentreBottomBrow]",
            "Prox/Raw[CentreTopBrow]",
            "Prox/Raw[LeftBrow]",
            "Prox/Raw[LeftCheek]"
        ]
        let reorderedNavColumns = [
            "Nav/Raw.X[RightCheek]",
            "Nav/Raw.Y[RightCheek]",
            "Nav/Raw.X[RightBrow]",
            "Nav/Raw.Y[RightBrow]",
            "Nav/Raw.X[LeftBrow]",
            "Nav/Raw.Y[LeftBrow]",
            "Nav/Raw.X[RightTemple]",
            "Nav/Raw.Y[RightTemple]",
            "Nav/Raw.X[LeftCheek]",
            "Nav/Raw.Y[LeftCheek]",
            "Nav/Raw.X[LeftTemple]",
            "Nav/Raw.Y[LeftTemple]"
        ]
        let sensor_cols = (reorderedProxColumns + reorderedNavColumns)
        var calibDataArray: [[String: String]] = Array(csvFile.rows)
        for col in reorderedNavColumns {
            var cumsum = 0.0
            for rowIndex in 0..<calibDataArray.count {
                if let value = Double(calibDataArray[rowIndex][col] ?? "") {
                    cumsum += value
                    calibDataArray[rowIndex][col] = String(cumsum)
                }
            }
        }
        for col in reorderedNavColumns {
            for rowIndex in 0..<calibDataArray.count {
                if let stringValue = calibDataArray[rowIndex][col],
                   let value = Double(stringValue) {
                    calibDataArray[rowIndex][col] = String(rawNavToMM(navData: value))
                }
            }
        }
        for col in reorderedProxColumns {
            for rowIndex in 0..<calibDataArray.count {
                if let stringValue = calibDataArray[rowIndex][col],
                   let value = Double(stringValue) {
                    calibDataArray[rowIndex][col] = String(rawProxToMM(proxData: value))
                }
            }
        }
        for col in sensor_cols {
            // Extract column data from calibDataArray
            var columnData: [Double] = []
            for row in calibDataArray {
                if let stringVal = row[col], let doubleVal = Double(stringVal) {
                    columnData.append(doubleVal)
                }
            }
            // Apply zero phase filter
            
            var filteredData = applyZeroPhaseFilter(signal: columnData, b: b_data, a: a_data)
            filteredData[0] = 10.52972059
            filteredData [1] = 10.50184338
            
            let (x_trend,x_detrend) = polynomialWindowFit(x: filteredData, n_win: nDetrendWin)
            let povez = calibDataArray
            for (index, row) in x_detrend.enumerated() {
                if index < filteredData.count {
                    calibDataArray[index][col] = String(x_detrend[index])
                }
            }
            
            var allFeatures: [[Double]] = []
            for iWin in 0..<(calibDataArray.count / nModelWin) {
                let start = iWin * nModelWin
                let end = (iWin + 1) * nModelWin
                if end <= calibDataArray.count {
                    let windowData = Array(calibDataArray[start..<end])
                    let sensorData = windowData.map { row in
                        sensor_cols.compactMap {
                            if let strVal = row[$0], let doubleVal = Double(strVal) {
                                return doubleVal
                            }
                            return nil
                        }
                    }
                                        if let features = calculateFeatures(data: sensorData) {
                        allFeatures.append(features)
                    }
                }
            }
            
            
            scaler?.fit(data: allFeatures)
            
        }
        
        
        
        
        
        
    }
    
    
    
    
    
    
    func filterData(columns: [String]) {
//        // Map columns to their indices
        let columnMap = parser.getColumnsMap()
        let columnIndices = columns.compactMap { columnMap[$0] }
    
       for column in [25,26,27,28,29,30,13,14,15,16,17,18,19,20,21,22,23,24] {
          
           filteredData[i_data][column] = data_buffer[i_data][column]
            

        }
        
       
     //   let proxColumnsIndices = parser.getProxColumns().compactMap { columnMap[$0] }.
      
       for column in [25,26,27,28,29,30] {
//            // Apply proximal filter
          
           let signal = [filteredData[i_data][column]]
           var pom = applyFilterzi(signal: signal, b: b_proxy, a: a_proxy, zi: prox_filters_zi[column])
           let zi = pom.1
           let result = pom.0
           filteredData[self.i_data][column] = result[0]
           prox_filters_zi[column] = zi
       }
        let sig_prov = filteredData
        
        let zg = data_filters_zi
        for column in [25,26,27,28,29,30,13,14,15,16,17,18,19,20,21,22,23,24] {
//            // Apply general filter
        let signal = [filteredData[i_data][column]]
         var pom = applyFilterziforpurpose(signal: signal, b: b_data, a: a_data, zi: data_filters_zi[column])
            let zi = pom.1
            let result = pom.0
            filteredData[self.i_data][column] = result[0]
            data_filters_zi[column] = zi

            
            
        }
        let z = filteredData
        let vv = data_filters_zi
        
        
    }
    
    func updateTrends(cols: [String]) {
        
        for col in [25,26,27,28,29,30,13,14,15,16,17,18,19,20,21,22,23,24]  {
            // find polynomial coefficients
            let sigLen = i_detrend_win * nDetrendWin
            
            let xPoly = Array(0..<sigLen + nDetrendWin).map { Double($0) }
            var yPoly: [Double] = []
            for i in 0..<(sigLen + nDetrendWin) {
                yPoly.append(Double(data_buffer[i][col]))
            }
            let xTrendCoefs = linearFit(xPoly, yPoly)
            
            // calculate trend using found polynomial coefficients
            let xTrend = Array(sigLen..<sigLen + nDetrendWin).map {Double($0)}
            var trend = polyval(xTrend, xTrendCoefs)
         
            // apply low-pass filter to smooth the trend
            let filterResult = applyFilterzi(signal: trend, b: b_trend, a: a_trend, zi: trend_filters_zi[col])
            trend = filterResult.0
            trend_filters_zi[col] = filterResult.1
            
            // store the trend
            for (index, value) in trend.enumerated() {
                trends[index][col] = value
            }
           
        }
    }

    
    func detrendSignals(columns: [String]) {
 //       let dividend = i_detrend_win - 1
 //       let positiveDividend = dividend < 0 ? dividend + num_detrend_wins : dividend
 //       let i_trend = ((positiveDividend % num_detrend_wins) * nDetrendWin + i_detrend)
        //becareful with this value
       
        let  i_trend = pythonLikeMod((i_detrend_win - 1), num_detrend_wins) * nDetrendWin + i_detrend
       
          for col in [25,26,27,28,29,30,13,14,15,16,17,18,19,20,21,22,23,24] {
              detrended_data[i_data][col] = filteredData[i_data][col] - trends[i_trend][col]
          }
     
    }
    
    
    func rawNavToMM(navData: Double) -> Double {
        let cpi = 911.23 * 4.01
        let inchToMM = 25.4
        return navData / cpi * inchToMM
    }
    func rawProxToMM(proxData: Double) -> Double {
        let a: Double = 31.4
        let b: Double = -0.001399
        let c: Double = 14.14
        let d: Double = -9.446e-05
        let expArgument1: Double = b * proxData
        let expArgument2: Double = d * proxData
        let proxDataConverted: Double = a * exp(expArgument1) + c * exp(expArgument2)
        return proxDataConverted
    }
    func linearFit(_ x: [Double], _ y: [Double]) -> (slope: Double, intercept: Double) {
        precondition(x.count == y.count, "x and y must have the same size")
        let sum1 = x.enumerated().reduce(0, { $0 + $1.element * y[$1.offset] })
        let sum2 = x.reduce(0, +)
        let sum3 = y.reduce(0, +)
        let sum4 = x.reduce(0, { $0 + $1 * $1 })
        let count = Double(x.count)
        let denominator = sum4 - (sum2 * sum2 / count)
        let slope = (sum1 - (sum2 * sum3 / count)) / denominator
        let intercept = (sum3 - slope * sum2) / count
        return (slope, intercept)
    }
    
    // Polynomial Window Fit function
    func polynomialWindowFit(x: [Double], n_win: Int) ->(xTrend: [Double], xDetrend: [Double]) {
        var xTrendCoefs: [(Double, Double)] = []
        var i_win = 0
        while i_win < x.count - n_win {
            let abe = Array(x[0..<i_win + n_win])
            let xRange = Array(0..<n_win+i_win).map(Double.init)
            let coef = linearFit(xRange, abe)
            xTrendCoefs.append(coef)
            i_win += n_win
        }
        var nWinLastDiff = false
        if x.count != (i_win - n_win)
        {
            nWinLastDiff = true
            let nWinLast = x.count - (i_win - n_win)
            let xRange = Array(0..<x.count).map(Double.init)
            let coef = linearFit(xRange, x)
            xTrendCoefs.append(coef)
        }
        var xTrend: [Double] = Array(repeating: 0.0, count: n_win)
        for iWin in 0..<(xTrendCoefs.count - 1) {
            let coef = xTrendCoefs[iWin]
            if iWin == xTrendCoefs.count - 2 && nWinLastDiff {
                if (iWin + 1) * n_win < x.count {
                    let xRange = Array((iWin + 1) * n_win..<x.count).map(Double.init)
                    xTrend += polyval(xRange, coef)
                }
            } else {
                if (iWin + 1) * n_win + n_win <= x.count {
                    let xRange = Array((iWin + 1) * n_win..<(iWin + 1) * n_win + n_win).map(Double.init)
                    xTrend += polyval(xRange, coef)
                }
            }
        }
        var filteredx_trend = applyZeroPhaseFilter(signal: xTrend, b: bl, a: al)
        var x_detrend = subtractSignals(x, filteredx_trend)
        
        return (xTrend , x_detrend)
    }
    func polyval(_ x: [Double], _ coefficients: (Double, Double)) -> [Double] {
        let (slope, intercept) = coefficients
        return x.map { slope * $0 + intercept }
    }
    func subtractSignals(_ x: [Double], _ xTrend: [Double]) -> [Double] {
        guard x.count == xTrend.count else {
            fatalError("Signals must be the same length")
        }
        return zip(x, xTrend).map(-)
    }
    
    func process(_ data: inout [String: String]) throws {
        // Print incoming data
        

        // Get prox and nav columns
        let proxColumns = parser.getProxColumns()
        let navColumns = parser.getNavColumns() 
        let columnMap = parser.getColumnsMap()
//
//        // Current sample index
         i_data = (i_detrend_win % num_detrend_wins) * nDetrendWin + i_detrend
        let i_data_pom = i_data
//
//        // Convert raw data to mm
        for column in navColumns {
            let value = data[column]!
            let gem = Double(value)
            let vel = rawNavToMM(navData: gem!)
           data[column] = String(vel)
           
        }
        
//
       for column in proxColumns {
            let value = data[column]
           let pom_value = Double(value!)
           data[column] = String(rawProxToMM(proxData: pom_value!))
//
       }
//
//        // Store data in buffer
        let sensorColumns = proxColumns + navColumns
        let vem = data_buffer
        for column in sensorColumns {
           if let value = Double(data[column] ?? "0") {
               self.data_buffer[self.i_data][columnMap[column]!] = value
           }
      }
        
        
//        // Nav sensors cum sum adjust
        let iPrev = (i_data - 1 + data_buffer.count) % data_buffer.count

        for column in navColumns {
            if let columnIndex = columnMap[column] {
                self.data_buffer[i_data][columnIndex] += self.data_buffer[iPrev][columnIndex]
            }
        }
        let pom = self.data_buffer
        
//         Apply filter
        filterData(columns: sensorColumns)
//
//        // Detrend signals
        detrendSignals(columns: sensorColumns)
//
//        // Give new prediction if we fill up the model window
        if i_model == nModelWin - 1 {
          
            let start = i_data - nModelWin + 1
            let adjustedStart = start < 0 ? detrended_data.count + start : start
            let end = i_data + 1
          
            let detrendedDataSlice = Array(detrended_data[adjustedStart..<end])
            let sens_help = [25,26,27,28,29,30,13,14,15,16,17,18,19,20,21,22,23,24]
            let selectedData = detrendedDataSlice.map { row in
                sens_help.map { row[$0] }
            }
            let features = calculateFeatures(data: selectedData)
            
            let cleanedFeatures = features.map { $0.map { $0.isNaN ? 0.0 : $0 } }
        //    let transformedFeatures = scaler.transform(data: cleanedFeatures)
            let input_features = expression_recognition_new_detrend_circular_bufferInput(Nav_Raw_X_RightCheek_mean: cleanedFeatures![0], Nav_Raw_X_RightCheek_std: cleanedFeatures![1], Nav_Raw_X_RightCheek_min: cleanedFeatures![2], Nav_Raw_X_RightCheek_max: cleanedFeatures![3], Nav_Raw_X_RightCheek_range: cleanedFeatures![4], Nav_Raw_X_RightCheek_iqr: cleanedFeatures![5], Nav_Raw_X_RightCheek_rms: cleanedFeatures![6], Nav_Raw_Y_RightCheek_mean: cleanedFeatures![7], Nav_Raw_Y_RightCheek_std: cleanedFeatures![8], Nav_Raw_Y_RightCheek_min: cleanedFeatures![9], Nav_Raw_Y_RightCheek_max: cleanedFeatures![10], Nav_Raw_Y_RightCheek_range: cleanedFeatures![11], Nav_Raw_Y_RightCheek_iqr: cleanedFeatures![12], Nav_Raw_Y_RightCheek_rms: cleanedFeatures![13], Nav_Raw_X_RightBrow_mean: cleanedFeatures![14], Nav_Raw_X_RightBrow_std: cleanedFeatures![15], Nav_Raw_X_RightBrow_min: cleanedFeatures![16], Nav_Raw_X_RightBrow_max: cleanedFeatures![17], Nav_Raw_X_RightBrow_range: cleanedFeatures![18], Nav_Raw_X_RightBrow_iqr: cleanedFeatures![19], Nav_Raw_X_RightBrow_rms: cleanedFeatures![20], Nav_Raw_Y_RightBrow_mean: cleanedFeatures![21], Nav_Raw_Y_RightBrow_std: cleanedFeatures![22], Nav_Raw_Y_RightBrow_min: cleanedFeatures![23], Nav_Raw_Y_RightBrow_max: cleanedFeatures![24], Nav_Raw_Y_RightBrow_range: cleanedFeatures![25], Nav_Raw_Y_RightBrow_iqr: cleanedFeatures![26], Nav_Raw_Y_RightBrow_rms: cleanedFeatures![27], Nav_Raw_X_LeftBrow_mean: cleanedFeatures![28], Nav_Raw_X_LeftBrow_std: cleanedFeatures![29], Nav_Raw_X_LeftBrow_min: cleanedFeatures![30], Nav_Raw_X_LeftBrow_max: cleanedFeatures![31], Nav_Raw_X_LeftBrow_range: cleanedFeatures![32], Nav_Raw_X_LeftBrow_iqr: cleanedFeatures![33], Nav_Raw_X_LeftBrow_rms: cleanedFeatures![34], Nav_Raw_Y_LeftBrow_mean: cleanedFeatures![35], Nav_Raw_Y_LeftBrow_std: cleanedFeatures![36], Nav_Raw_Y_LeftBrow_min: cleanedFeatures![37], Nav_Raw_Y_LeftBrow_max: cleanedFeatures![38], Nav_Raw_Y_LeftBrow_range: cleanedFeatures![39], Nav_Raw_Y_LeftBrow_iqr: cleanedFeatures![40], Nav_Raw_Y_LeftBrow_rms: cleanedFeatures![41], Nav_Raw_X_RightTemple_mean: cleanedFeatures![42], Nav_Raw_X_RightTemple_std: cleanedFeatures![43], Nav_Raw_X_RightTemple_min: cleanedFeatures![44], Nav_Raw_X_RightTemple_max: cleanedFeatures![45], Nav_Raw_X_RightTemple_range: cleanedFeatures![46], Nav_Raw_X_RightTemple_iqr: cleanedFeatures![47], Nav_Raw_X_RightTemple_rms: cleanedFeatures![48], Nav_Raw_Y_RightTemple_mean: cleanedFeatures![49], Nav_Raw_Y_RightTemple_std: cleanedFeatures![50], Nav_Raw_Y_RightTemple_min: cleanedFeatures![51], Nav_Raw_Y_RightTemple_max: cleanedFeatures![52], Nav_Raw_Y_RightTemple_range: cleanedFeatures![53], Nav_Raw_Y_RightTemple_iqr: cleanedFeatures![54], Nav_Raw_Y_RightTemple_rms: cleanedFeatures![55], Nav_Raw_X_LeftCheek_mean: cleanedFeatures![56], Nav_Raw_X_LeftCheek_std: cleanedFeatures![57], Nav_Raw_X_LeftCheek_min: cleanedFeatures![58], Nav_Raw_X_LeftCheek_max: cleanedFeatures![59], Nav_Raw_X_LeftCheek_range: cleanedFeatures![60], Nav_Raw_X_LeftCheek_iqr: cleanedFeatures![61], Nav_Raw_X_LeftCheek_rms: cleanedFeatures![62], Nav_Raw_Y_LeftCheek_mean: cleanedFeatures![63], Nav_Raw_Y_LeftCheek_std: cleanedFeatures![64], Nav_Raw_Y_LeftCheek_min: cleanedFeatures![65], Nav_Raw_Y_LeftCheek_max: cleanedFeatures![66], Nav_Raw_Y_LeftCheek_range: cleanedFeatures![67], Nav_Raw_Y_LeftCheek_iqr: cleanedFeatures![68], Nav_Raw_Y_LeftCheek_rms: cleanedFeatures![69], Nav_Raw_X_LeftTemple_mean: cleanedFeatures![70], Nav_Raw_X_LeftTemple_std: cleanedFeatures![71], Nav_Raw_X_LeftTemple_min: cleanedFeatures![72], Nav_Raw_X_LeftTemple_max: cleanedFeatures![73], Nav_Raw_X_LeftTemple_range: cleanedFeatures![74], Nav_Raw_X_LeftTemple_iqr: cleanedFeatures![75], Nav_Raw_X_LeftTemple_rms: cleanedFeatures![76], Nav_Raw_Y_LeftTemple_mean: cleanedFeatures![77], Nav_Raw_Y_LeftTemple_std: cleanedFeatures![78], Nav_Raw_Y_LeftTemple_min: cleanedFeatures![79], Nav_Raw_Y_LeftTemple_max: cleanedFeatures![80], Nav_Raw_Y_LeftTemple_range: cleanedFeatures![81], Nav_Raw_Y_LeftTemple_iqr: cleanedFeatures![82], Nav_Raw_Y_LeftTemple_rms: cleanedFeatures![83], Prox_Raw_RightCheek_mean: cleanedFeatures![84], Prox_Raw_RightCheek_std: cleanedFeatures![85], Prox_Raw_RightCheek_min: cleanedFeatures![86], Prox_Raw_RightCheek_max: cleanedFeatures![87], Prox_Raw_RightCheek_range: cleanedFeatures![88], Prox_Raw_RightCheek_iqr: cleanedFeatures![89], Prox_Raw_RightCheek_rms: cleanedFeatures![90], Prox_Raw_RightBrow_mean: cleanedFeatures![91], Prox_Raw_RightBrow_std: cleanedFeatures![92], Prox_Raw_RightBrow_min: cleanedFeatures![93], Prox_Raw_RightBrow_max: cleanedFeatures![94], Prox_Raw_RightBrow_range: cleanedFeatures![95], Prox_Raw_RightBrow_iqr: cleanedFeatures![96], Prox_Raw_RightBrow_rms: cleanedFeatures![97], Prox_Raw_CentreBottomBrow_mean: cleanedFeatures![98], Prox_Raw_CentreBottomBrow_std: cleanedFeatures![99], Prox_Raw_CentreBottomBrow_min: cleanedFeatures![100], Prox_Raw_CentreBottomBrow_max: cleanedFeatures![101], Prox_Raw_CentreBottomBrow_range: cleanedFeatures![102], Prox_Raw_CentreBottomBrow_iqr: cleanedFeatures![103], Prox_Raw_CentreBottomBrow_rms: cleanedFeatures![104], Prox_Raw_CentreTopBrow_mean: cleanedFeatures![105], Prox_Raw_CentreTopBrow_std: cleanedFeatures![106], Prox_Raw_CentreTopBrow_min: cleanedFeatures![107], Prox_Raw_CentreTopBrow_max: cleanedFeatures![108], Prox_Raw_CentreTopBrow_range: cleanedFeatures![109], Prox_Raw_CentreTopBrow_iqr: cleanedFeatures![110], Prox_Raw_CentreTopBrow_rms: cleanedFeatures![111], Prox_Raw_LeftBrow_mean: cleanedFeatures![112], Prox_Raw_LeftBrow_std: cleanedFeatures![113], Prox_Raw_LeftBrow_min: cleanedFeatures![114], Prox_Raw_LeftBrow_max: cleanedFeatures![115], Prox_Raw_LeftBrow_range: cleanedFeatures![116], Prox_Raw_LeftBrow_iqr: cleanedFeatures![117], Prox_Raw_LeftBrow_rms: cleanedFeatures![118], Prox_Raw_LeftCheek_mean: cleanedFeatures![119], Prox_Raw_LeftCheek_std: cleanedFeatures![120], Prox_Raw_LeftCheek_min: cleanedFeatures![121], Prox_Raw_LeftCheek_max: cleanedFeatures![122], Prox_Raw_LeftCheek_range: cleanedFeatures![123], Prox_Raw_LeftCheek_iqr: cleanedFeatures![124], Prox_Raw_LeftCheek_rms: cleanedFeatures![125])
            let output =  try model_ml.prediction(input: input_features)
            
                  
     

            let text = output.expression
            print(text)
            let path = "/Users/antonionikoloski/Desktop/output_pom.txt"
            writeIntegerToFile(number: Int(text), atPath: path)
           i_model = 0
       }
        else {
            i_model += 1
        }
//
//        // Update trends
            i_detrend += 1
        if i_detrend == nDetrendWin {
            updateTrends(cols: sensorColumns)
            i_detrend = 0
            i_detrend_win += 1
           if i_detrend_win == num_detrend_wins {
                i_detrend_win -= 1
//                // Shift data
               data_buffer = data_buffer.map { Array($0[nDetrendWin...]) }
               filteredData = filteredData.map { Array($0[nDetrendWin...]) }
               detrended_data = detrended_data.map { Array($0[nDetrendWin...]) }

         }
        }
    }
    func pythonLikeMod(_ a: Int, _ n: Int) -> Int {
        let remainder = a % n
        return remainder >= 0 ? remainder : remainder + n
    }
    func writeIntegerToFile(number: Int, atPath path: String) {
        let text = "\(number)\n" // Convert integer to string and add newline
        let data = text.data(using: .utf8)!
        
        if FileManager.default.fileExists(atPath: path) {
            if let fileHandle = FileHandle(forWritingAtPath: path) {
                // Append to existing file
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                print("Can't open fileHandle \(path)")
            }
        } else {
            // Create new file
            FileManager.default.createFile(atPath: path, contents: data, attributes: nil)
        }
    }

}
                                 
                                 
                
                                 




