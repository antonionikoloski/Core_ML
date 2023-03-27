import Foundation
import Yams

func readConfig(from file: String) -> [String: Any]? {
    /*
    Read config info from yml file

    Parameters
    ----------
    file : String
        path to yaml config file

    Returns
    -------
    [String: Any]?
        the parsed config
    */
    
    do {
        let ymlFile = try String(contentsOfFile: file, encoding: .utf8)
        if let config = try Yams.load(yaml: ymlFile) as? [String: Any] {
            return config
        }
    } catch {
        print("Can't read config file \(file) | \(error).")
    }
    
    return nil
}

