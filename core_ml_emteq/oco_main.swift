import Foundation


struct MainApp {
    static func main() async {
        print("Oco file replay algo tester")
        
          let configPath = getfilePath(forResource: "config", ofType: "yml")
          let configFile = readConfig(from: configPath!)
          let plotterconfigPath = getfilePath(forResource: "expressions", ofType: "yml")
          let configFileplotter = readConfig(from: plotterconfigPath!)
          let filePath = getfilePath(forResource: "test", ofType: "csv")!
        do {
            let ocoFileParserInstance = try OcoFileParser(config: configFile!, filePath: filePath)
            let algo_ml = try ExpressionsRecognitionMlAlgo(config: configFile!, parser: ocoFileParserInstance)
            let dataProcessorInstance = DataProcessor(config: configFile!, parser: ocoFileParserInstance)
            let wearingalgo = WearingAlgo(config: configFile!, parser: ocoFileParserInstance)
           
         //   dataProcessorInstance.createProcess(user: wearingalgo, type: ProcessType.algo)
            ocoFileParserInstance.parse(algo: algo_ml)
            
        }
          catch {
           print("Error initializing OcoFileParser:", error.localizedDescription)
         }
          

    
       
            }
        }
    


