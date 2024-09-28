import Foundation

class KeywordHandler {
    var keywords: [String: String]
    
    init() {
        keywords = [:]
        mergeCustomKeywords()
    }
    
    func process(_ expression: String) -> String {
        var result = expression
        let pattern = #"\$\[(\w+)\((.*?)\)\](?:\[(\d+)\])?|\$\[(.*?)\](?:\[(\d+)\])?"#
        
        let regex = try! NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: expression, range: NSRange(expression.startIndex..., in: expression))
        
        for match in matches.reversed() {
            if let functionRange = Range(match.range(at: 1), in: expression),
               let argumentRange = Range(match.range(at: 2), in: expression) {
                // Handle functions like upper()
                let functionName = String(expression[functionRange])
                let argument = String(expression[argumentRange])
                
                // Recursively process the argument first
                let processedArgument = process("$[\(argument)]")
                let processedResult = callFunction(functionName, argument: processedArgument)
                
                // Check for optional padding
                var paddedResult = processedResult
                if let paddingRange = Range(match.range(at: 3), in: expression) {
                    let paddingStr = String(expression[paddingRange])
                    if let padding = Int(paddingStr) {
                        paddedResult = padString(processedResult, toLength: padding)
                    }
                }
                
                // Replace the matched string in result
                let fullMatchRange = Range(match.range, in: result)!
                result.replaceSubrange(fullMatchRange, with: paddedResult)
            } else if let keywordRange = Range(match.range(at: 4), in: expression) {
                // Handle regular keyword replacements
                let keyword = String(expression[keywordRange])
                
                // Retrieve and execute the closure for the keyword
                let value = customKeywords[keyword]?() ?? keyword
                
                // Check for optional padding
                var paddedValue = value
                if let paddingRange = Range(match.range(at: 5), in: expression) {
                    let paddingStr = String(expression[paddingRange])
                    if let padding = Int(paddingStr) {
                        paddedValue = padString(value, toLength: padding)
                    }
                }
                
                // Replace the matched string in result
                let fullMatchRange = Range(match.range, in: result)!
                result.replaceSubrange(fullMatchRange, with: paddedValue)
            }
        }
        
        // Remove any remaining unmatched $[...] patterns
        let cleanPattern = #"\$\[(.*?)\]"#
        result = result.replacingOccurrences(of: cleanPattern, with: "$1", options: .regularExpression)
        
        return result
    }
    
    func padString(_ string: String, toLength length: Int) -> String {
        if string.count < length {
            // Pad the string with spaces at the end
            return string + String(repeating: " ", count: length - string.count)
        } else if string.count > length {
            // Trim the string to the specified length
            return String(string.prefix(length))
        } else {
            return string
        }
    }
    
    func callFunction(_ functionName: String, argument: String) -> String {
        switch functionName {
        case "Upper":
            return Upper(argument) // Calls upper() from StringFunctions.swift
        case "Lower":
            return Lower(argument) // Calls lower() from StringFunctions.swift
        case "Month":
            return Month(argument) // Calls monthname() from StringFunctions.swift
        case "Weekday":
            return Weekday(argument) // Calls monthname() from StringFunctions.swift
        case "ThisWeekDay":
            return ThisWeekDay(argument)
        case "ThisWeekMonth":
            return ThisWeekMonth(argument)
        case "ThisWeekYear":
            return ThisWeekYear(argument)
        case "isToday":
            return isToday(argument)
        default:
            return argument // No transformation if function is unknown
        }
    }
    
    func mergeCustomKeywords() {
        // Merge custom keywords from StringFunctions.swift with existing keywords
        for (key, value) in customKeywords {
            keywords[key] = value() // Call the closure to get the actual String value
        }
    }
    
    func updateKeywords(_ newKeywords: [String: String]) {
        for (key, _) in newKeywords {
            keywords[key] = newKeywords[key] ?? ""
        }
    }
}
