import Foundation


func readContentOfFile(fileURL: URL) -> String? {
    do {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        return content
        
    } catch {
        print("Error reading file: \(error.localizedDescription)")
        return nil
    }
}

func parseArrays(content: String) -> [[Double]]? {
    let arrayStrings = content.components(separatedBy: "array0")
    var arrays: [[Double]] = []

    for (index, arrayString) in arrayStrings.enumerated() {
        if index == 0 {
            continue
        }

        let cleanedArrayString = arrayString
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let rows = cleanedArrayString.components(separatedBy: "\n").filter { !$0.isEmpty }
        var oneDimensionalArray: [Double] = []
        
        for row in rows {
            let values = row.split(separator: " ").compactMap { Double($0) }
            oneDimensionalArray.append(contentsOf: values)
        }
        
        arrays.append(oneDimensionalArray)
    }

    return arrays
}

func parseArraysoutput(from text: String) -> [[Double]] {
    let lines = text.components(separatedBy: .newlines)
    var bigArray: [[Double]] = []

    for line in lines {
        if line.contains("array0 = ") {
            if let firstOpenBracket = line.firstIndex(of: "["),
               let secondOpenBracket = line[line.index(after: firstOpenBracket)...].firstIndex(of: "["),
               let firstCloseBracket = line[line.index(after: secondOpenBracket)...].firstIndex(of: "]") {
                let startIndex = line.index(secondOpenBracket, offsetBy: 1)
                let endIndex = line.index(firstCloseBracket, offsetBy: -1)
                let range = startIndex...endIndex

                let numbersString = line[range]
                let numbers = numbersString.components(separatedBy: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
                bigArray.append(numbers)
            }
        }
    }

    return bigArray
}
func readTextFile() -> String? {
    if let fileURL = Bundle.main.url(forResource: "output_python", withExtension: "txt") {
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            return content
        } catch {
            print("Error reading file: \(error)")
        }
    }
    return nil
}
func countElementsNotSatisfyingCondition(allFeatures: [[Double]], bigArray: [[Double]], eps: Double) -> Int {
    let smallerArray = allFeatures.count < bigArray.count ? allFeatures : bigArray
    var countNotSatisfyingCondition = 0

    for (index, smallArray) in smallerArray.enumerated() {
        let allFeaturesArray = allFeatures[index]
        let bigArrayArray = bigArray[index]

        for i in 0..<smallArray.count {
            let x1 = allFeaturesArray[i]
            let x2 = bigArrayArray[i]

            if abs(x1 - x2) <= eps {
                countNotSatisfyingCondition += 1
            }
        }
    }

    return countNotSatisfyingCondition
}
