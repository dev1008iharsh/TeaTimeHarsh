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
        return self.filter { !$0.isWhitespace }
    }
}
