//
//  NotificatironCenter+Extension.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 02/01/26.
//
import UIKit

extension Notification.Name {
    static let teaPlaceDidTapFav = Notification.Name("teaPlaceDidTapFav")
    static let teaPlaceDidTapVisit = Notification.Name("teaPlaceDidTapVisit")
    // We need this to tell DetailVC to revert if API fails
    static let teaPlaceUpdateFailed = Notification.Name("teaPlaceUpdateFailed")
}
