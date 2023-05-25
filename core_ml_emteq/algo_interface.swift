
import Foundation

class AlgoInterface {
    var config: [String: Any]
    var parser: OcoFileParser
    var process_data: Bool = false
    var i_frame: Int = 0
    var plot_params: [String: Any?] = [
        "sig_name": nil,
        "row": -1,
        "col": -1,
        "ymin": nil,
        "ymax": nil,
        "label": nil,
        "ylabel": nil,
        "title": nil,
        "color": nil
    ]
    
    var data_queue: DispatchQueue!
    var plot_queue: DispatchQueue!
    
    init(config: [String: Any], parser: OcoFileParser) {
        self.config = config
        self.parser = parser
    }
    
    func call(queue: DispatchQueue, queuePlotter: [DispatchQueue] = []) {
        self.data_queue = queue
        self.plot_queue = queuePlotter.isEmpty ? nil : queuePlotter[0]
        
        run()
        
        self.data_queue = nil
        self.plot_queue = nil
    }
    
    func run() {
        self.process_data = true
        
        while self.process_data {
            // Replace the following line with actual data retrieval from your data_queue
            let data: Any? = nil
            if data == nil {
                self.stop()
            } else {
                self.process(data: data!)
            }
            
            self.i_frame += 1
        }
    }
    
    func process(data: Any) {
        fatalError("process method not implemented")
    }
    
    func stop() {
        self.process_data = false
    }
    
    func set_plot_params(
        sig_name: Any? = nil,
        row: Int = -1,
        col: Int = -1,
        ymin: Any? = nil,
        ymax: Any? = nil,
        label: Any? = nil,
        ylabel: Any? = nil,
        title: Any? = nil,
        color: Any? = nil
    ) {
        self.plot_params = [
            "sig_name": sig_name,
            "row": row,
            "col": col,
            "ymin": ymin,
            "ymax": ymax,
            "label": label,
            "ylabel": ylabel,
            "title": title,
            "color": color
        ]
    }
}
