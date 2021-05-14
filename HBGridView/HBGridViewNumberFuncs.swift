//
//  HBGridViewNumberFuncs.swift
//
//  Created by Muthu Nedumaran on 22/4/21.
//

import Foundation


func insertComma(inNumber: String, showLakh: Bool, showThousand: Bool ) -> String {
    // First drop all commas
    var newNumber = inNumber.replacingOccurrences(of: ",", with: "")
    // Do the insertion
    if showLakh && newNumber.count > 5 {
        newNumber.insert(",", at: newNumber.index(newNumber.endIndex, offsetBy: -5))
    }
    if (showLakh || showThousand) && newNumber.count > 3 {
        newNumber.insert(",", at: newNumber.index(newNumber.endIndex, offsetBy: -3))
    }
    
    return newNumber
}


func translateNumber(asciiNumber: String, scriptNumbers: [String]) -> String {
    var translated = ""
    for n in asciiNumber {
        if n == "," {
            translated.append(n)
        } else {
            translated.append(scriptNumbers[Int("\(n)")!])
        }
    }
    
    return translated
}
