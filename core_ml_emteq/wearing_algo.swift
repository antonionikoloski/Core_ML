
import Foundation
class WearingAlgo: AlgoInterface {
    var wearing_threshold: Int = 20
    var num_sensors_under_threshold: Int = 3

    override init(config: [String:Any], parser: OcoFileParser) {
        super.init(config: config, parser: parser)
        set_plot_params(sig_name: "algo-wearing", ymin: -1, ymax: 2, title: "Wearing", color: "C3")
        
    }

    func raw_prox_to_mm(_ prox_data: Double) -> Double {
        let a = 31.4
        let b = -0.001399
        let c = 14.14
        let d = -9.446e-05
        let exp_argument_1 = b * prox_data
        let exp_argument_2 = d * prox_data
        let prox_data_mm = a * exp(exp_argument_1) + c * exp(exp_argument_2)
        return prox_data_mm
    }

    override func process(data: Any) {
        guard let data = data as? [Double] else {
            fatalError("Invalid data format")
        }

        let prox_cols = parser.getProxColumns()// Replace with appropriate method call to get proximity columns
        let col_map = parser.getColumnsMap() // Replace with appropriate method call to get columns map

        var num_under_threshold = prox_cols.count

        for col in prox_cols {
            let index = col_map[col] // Replace with appropriate method call to get the index from col_map
            let raw_prox = data[index!]
            let prox_mm = raw_prox_to_mm(raw_prox)
            if prox_mm > Double(wearing_threshold) {
                num_under_threshold -= 1
            }
        }

        let wearing = num_under_threshold >= num_sensors_under_threshold

        // Replace the following line with an appropriate method to send data to the plotter
        // plot_queue.put((i_frame, wearing))
    }      }
