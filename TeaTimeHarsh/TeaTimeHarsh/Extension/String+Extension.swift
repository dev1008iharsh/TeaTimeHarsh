//
//  String+Extension.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 30/12/25.
//
import UIKit
extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var removeAllSpaces: String {
        return filter { !$0.isWhitespace }
    }

    var isNumeric: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }

    var isValidWebsite: Bool {
        // Regex Breakdown:
        // ^(http|https)://  -> (Optional) Must start with http:// or https://
        // (www\.)?          -> (Optional) Can have www.
        // [A-Za-z0-9.-]+    -> Domain name (letters, numbers, dots, or dashes)
        // \.[A-Za-z]{2,}    -> Top-level domain (e.g., .com, .in) min 2 letters

        let regex = "^((http|https)://)?(www\\.)?[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"

        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: self)
    }
}
