//
//  SingleSelectionMenuBuilder.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 29/12/25.
//

import UIKit

struct SingleSelectionMenuBuilder {

    static func makeMenu(
        title: String,
        items: [String],
        selectedItem: String?,
        onSelect: @escaping (String) -> Void
    ) -> UIMenu {

        let actions = items.map { item in
            UIAction(
                title: item,
                state: item == selectedItem ? .on : .off
            ) { _ in
                onSelect(item)
            }
        }

        return UIMenu(
            title: title,
            options: [.singleSelection],
            children: actions
        )
    }
}
