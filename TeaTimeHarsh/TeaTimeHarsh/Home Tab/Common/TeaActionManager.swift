//
//  TeaActionManager.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/12/25.
//

import UIKit

class TeaActionManager {
    // The manager needs to know which screen (ViewController) it is working on
    private weak var viewController: UIViewController?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    // MARK: - 🔐 Permission Helper (Static)

    static func canModify(place: TeaPlace) -> Bool {
        // Ensure Constants.Strings.currentUserID exists in your project
        return place.createdByUserId == Constants.Strings.currentUserID
    }

    // MARK: - 1. Share Logic 📤

    func performShare(place: TeaPlace, sourceView: UIView) {
        let text = generateShareText(for: place)

        // Image Download & Share Logic
        if let imgString = place.imageURL, let url = URL(string: imgString) {
            downloadAndShareImage(url: url, text: text, sourceView: sourceView) // share both
        } else {
            presentShareSheet(items: [text], sourceView: sourceView) // share only text
        }
    }

    // MARK: - 2. Delete Logic 🗑️

    func performDelete(place: TeaPlace, onSuccess: @escaping () -> Void) {
        guard TeaActionManager.canModify(place: place) else { return }
        guard let vc = viewController else { return }

        AlertHelper.showConfirmationAlert(
            title: "Delete Place?",
            message: "Are you sure? This cannot be undone.",
            vc: vc,
            rightBtnTitle: "Delete",
            rightBtnStyle: .destructive,
            leftBtnTitle: "Cancel",
            leftBtnStyle: .cancel,
            rightAction: { [weak self] _ in
                guard let self = self else { return }

                self.executeDeleteAPI(placeID: place.id) {
                    // 1. Notify caller (e.g. remove from array)
                    onSuccess()

                    // 2. Navigate back to Home 🚀
                    self.viewController?.navigationController?.popToRootViewController(animated: true)
                }
            },
            leftAction: { _ in }
        )
    }

    // MARK: - 3. Edit Logic ✏️

    func performEdit(place: TeaPlace, onSuccess: @escaping () -> Void) {
        guard TeaActionManager.canModify(place: place) else { return }
        guard let vc = viewController else { return }

        // Ensure "AddPlaceVC" exists in your Storyboard
        let addVC = vc.storyboard?.instantiateViewController(withIdentifier: "AddPlaceVC") as! AddPlaceVC
        addVC.screenMode = .edit(place)

        // 👇 Handle what happens after saving
        addVC.onPlaceAdded = { _ in
            // 1. Notify caller to refresh data
            onSuccess()

            // 2. Navigate back to Home 🚀
            vc.navigationController?.popToRootViewController(animated: true)
        }

        vc.navigationController?.pushViewController(addVC, animated: true)
    }

    // MARK: - Internal Helpers (Private) 🛠️

    private func executeDeleteAPI(placeID: String, onSuccess: @escaping () -> Void) {
        LoaderManager.shared.startLoading()

        Task {
            // Defer ensures loading stops regardless of success/failure
            defer {
                Task { @MainActor in LoaderManager.shared.stopLoading() }
            }

            do {
                try await FirebaseManager.shared.deletePlace(placeId: placeID)

                await MainActor.run {
                    HapticHelper.success()
                    onSuccess()
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                    HapticHelper.error()
                }
            }
        }
    }

    private func downloadAndShareImage(url: URL, text: String, sourceView: UIView) {
        LoaderManager.shared.startLoading()
        Task {
            defer { Task { @MainActor in LoaderManager.shared.stopLoading() } }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                await MainActor.run {
                    // Share Image + Text if image exists, otherwise just Text
                    let items: [Any] = UIImage(data: data) != nil ? [text, UIImage(data: data)!] : [text]
                    self.presentShareSheet(items: items, sourceView: sourceView)
                }
            } catch {
                await MainActor.run { self.presentShareSheet(items: [text], sourceView: sourceView) }
            }
        }
    }

    private func presentShareSheet(items: [Any], sourceView: UIView) {
        guard let vc = viewController else { return }
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // iPad Crash Fix
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }
        HapticHelper.heavy()
        vc.present(activityVC, animated: true)
    }

    private func showAlert(title: String, message: String) {
        guard let vc = viewController else { return }
        AlertHelper.showAlert(title: title, message: message, vc: vc)
    }

    private func generateShareText(for place: TeaPlace) -> String {
        var timingText = "N/A"
        if let open = place.openingTime, let close = place.closingTime {
            timingText = "\(open) - \(close)"
        } else if let open = place.openingTime {
            timingText = "Opens at \(open)"
        }

        // 🛠️ Correct Google Maps Link Generation
        var mapLink = "Link Not Available"
        if let lat = place.latitude, let long = place.longitude {
            mapLink = "https://www.google.com/maps/search/?api=1&query=\(lat),\(long)"
        }

        return """
        📍 Place Details

        🏷️ Name: \(place.name)
        📌 Location: \(place.location ?? "N/A")
        📞 Phone: \(place.phone ?? "N/A")
        ⭐️ Rating: \(String(format: "%.1f", place.rating ?? 0.0))

        ⏰ Timing: \(timingText)
        🗓️ Holiday: \(place.holiday ?? "Open All Days")

        🌏 Map View: \(mapLink)

        _Shared via \(UtilsProject.getAppName) App \(Constants.Strings.developerEmail)_
        """
    }
}
