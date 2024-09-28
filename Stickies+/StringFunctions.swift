// StringFunctions.swift

import Foundation

// Define string transformation functions
func Upper(_ input: String) -> String {
    return input.uppercased()
}

func Lower(_ input: String) -> String {
    return input.lowercased()
}

func Month(_ input: String) -> String {
    // Convert input to an integer, defaulting to 1 (January) if conversion fails
    let monthNumber = Int(input) ?? 1
    let formatter = DateFormatter()
    
    // Check if the month number is within the valid range (1 to 12)
    if monthNumber >= 1 && monthNumber <= 12 {
        return formatter.monthSymbols[monthNumber - 1]
    } else {
        // Return a default message for out-of-range values
        return "Invalid Month"
    }
}

func Weekday(_ input: String) -> String {
    // Create a DateFormatter to parse the input date string
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMddyyyy"
    
    // Convert the input string to a Date object
    guard let date = dateFormatter.date(from: input) else {
        return "Invalid date" // Return a default value if the date string is invalid
    }
    
    // Create another DateFormatter to get the weekday name
    dateFormatter.dateFormat = "EEEE" // EEEE gives the full name of the weekday
    
    // Return the name of the weekday
    return dateFormatter.string(from: date)
}

import Foundation

func ThisWeekDay(_ weekdayString: String) -> String {
    // Try to convert the input string to an integer
    guard let weekdayNumber = Int(weekdayString), weekdayNumber >= 0 && weekdayNumber <= 7 else {
        return "Invalid weekday number"
    }

    let calendar = Calendar.current
    let currentDate = Date()
    
    // Determine the current weekday as an integer (1 for Sunday to 7 for Saturday)
    let currentWeekday = calendar.component(.weekday, from: currentDate)
    
    // Calculate the difference between the desired weekday and the current weekday
    let dayDifference = weekdayNumber - (currentWeekday - 1)
    
    // Get the target date by adding the difference to the current date
    if let targetDate = calendar.date(byAdding: .day, value: dayDifference, to: currentDate) {
        // Format the target date as day of the month
        let dayOfMonth = calendar.component(.day, from: targetDate)
        return String(dayOfMonth)
    } else {
        return "Date calculation error"
    }
}

func ThisWeekMonth(_ weekdayString: String) -> String {
    // Try to convert the input string to an integer
    guard let weekdayNumber = Int(weekdayString), weekdayNumber >= 0 && weekdayNumber <= 6 else {
        return "Invalid weekday number"
    }

    let calendar = Calendar.current
    let currentDate = Date()
    
    // Determine the current weekday as an integer (1 for Sunday to 7 for Saturday)
    let currentWeekday = calendar.component(.weekday, from: currentDate)
    
    // Calculate the difference between the desired weekday and the current weekday
    let dayDifference = weekdayNumber - (currentWeekday - 1)
    
    // Get the target date by adding the difference to the current date
    if let targetDate = calendar.date(byAdding: .day, value: dayDifference, to: currentDate) {
        // Format the target date as day of the month
        let Month = calendar.component(.month, from: targetDate)
        return String(Month)
    } else {
        return "Date calculation error"
    }
}

func ThisWeekYear(_ weekdayString: String) -> String {
    // Try to convert the input string to an integer
    guard let weekdayNumber = Int(weekdayString), weekdayNumber >= 0 && weekdayNumber <= 6 else {
        return "Invalid weekday number"
    }

    let calendar = Calendar.current
    let currentDate = Date()
    
    // Determine the current weekday as an integer (1 for Sunday to 7 for Saturday)
    let currentWeekday = calendar.component(.weekday, from: currentDate)
    
    // Calculate the difference between the desired weekday and the current weekday
    let dayDifference = weekdayNumber - (currentWeekday - 1)
    
    // Get the target date by adding the difference to the current date
    if let targetDate = calendar.date(byAdding: .day, value: dayDifference, to: currentDate) {
        
        // Format the target date as day of the month
        let Year = calendar.component(.year, from: targetDate)
        return String(Year)
    } else {
        return "Date calculation error"
    }
}


func isToday(_ inputDate: String) -> String {
    // Create a DateFormatter to parse the input date string
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd.MM.yyyy"
    
    // Convert the input string to a Date object
    guard let inputDateObj = dateFormatter.date(from: inputDate) else {
        return "" // Return empty string if the input date is invalid
    }
    
    // Get today's date in the same format
    let currentDate = Date()
    let todayDateString = dateFormatter.string(from: currentDate)
    
    // Check if the formatted input date matches today's date
    return todayDateString == inputDate ? "*" : ""
}

func ThisWeekDate(_ weekdayString: String) -> String {
    // Try to convert the input string to an integer
    guard let weekdayNumber = Int(weekdayString), weekdayNumber >= 0 && weekdayNumber <= 6 else {
        return "Invalid weekday number"
    }

    let calendar = Calendar.current
    let currentDate = Date()
    
    // Determine the current weekday as an integer (1 for Sunday to 7 for Saturday)
    let currentWeekday = calendar.component(.weekday, from: currentDate)
    
    // Calculate the difference between the desired weekday and the current weekday
    let dayDifference = weekdayNumber - (currentWeekday - 1)
    
    // Get the target date by adding the difference to the current date
    if let targetDate = calendar.date(byAdding: .day, value: dayDifference, to: currentDate) {
        // Format the target date as dd.MM.yyyy
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        return dateFormatter.string(from: targetDate)
    } else {
        return "Date calculation error"
    }
}


// Define default keywords in a dictionary
var customKeywords: [String: () -> String] = [
    "date.day": {
        let currentDate = Date()
        let calendar = Calendar.current
        let day = calendar.component(.day, from: currentDate)
        return String(day)
    },
    "date.month": {
        let currentDate = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: currentDate)
        return String(month)
    },
    "date.year": {
        let currentDate = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentDate)
        return String(year)
    },
    "time.now": {
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .medium // Customize the time format as needed
        return formatter.string(from: currentDate)
    },
    // Add the new keyword for the current date
    "date.now": {
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy" // Customize the date format as needed
        return formatter.string(from: currentDate)
    }
]

// Function to retrieve a custom keyword if it exists and execute the closure
func getCustomKeyword(_ key: String) -> String? {
    return customKeywords[key]?() // Call the closure if it exists and return the result
}

