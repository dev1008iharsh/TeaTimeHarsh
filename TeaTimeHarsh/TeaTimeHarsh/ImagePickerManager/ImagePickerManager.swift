import UIKit
import PhotosUI // For PHPicker
import Photos   // For Permissions

@MainActor
final class ImagePickerManager: NSObject {
    
    // Singleton Instance
    static let shared = ImagePickerManager()
    
    // Private properties
    private var completion: ((Result<[UIImage], Error>) -> Void)?
    private weak var presentationController: UIViewController?
    
    // ---------------------------------------------------------
    // MARK: - 🔐 PART 1: Permission (Only for Saving)
    // ---------------------------------------------------------
    
    func checkPermissionForSaving(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        let level: PHAccessLevel = .addOnly
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: level)
        
        switch currentStatus {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: level) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        completion(true)
                    } else {
                        completion(false)
                        self.showSettingsAlert(on: viewController)
                    }
                }
            }
        case .denied, .restricted:
            completion(false)
            showSettingsAlert(on: viewController)
        @unknown default:
            completion(false)
        }
    }
    
    private func showSettingsAlert(on viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Access Required",
            message: "Please allow access to Photos in Settings to save items.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        viewController.present(alert, animated: true)
    }

    // ---------------------------------------------------------
    // MARK: - 📸 PART 2: The Picking Functions
    // ---------------------------------------------------------

    // 1. Single Image
    func pickSingleImage(from viewController: UIViewController, completion: @escaping (UIImage?) -> Void) {
        self.pickMediaCustom(
            from: viewController,
            selectionLimit: 1,
            filter: PHPickerFilter.images // ✅ Fixed: Explicit Type
        ) { result in
            switch result {
            case .success(let images): completion(images.first)
            case .failure: completion(nil)
            }
        }
    }
    
    // 2. Multiple Images
    func pickMultipleImages(from viewController: UIViewController, limit: Int = 5, completion: @escaping ([UIImage]) -> Void) {
        self.pickMediaCustom(
            from: viewController,
            selectionLimit: limit,
            filter: PHPickerFilter.images // ✅ Fixed: Explicit Type
        ) { result in
            switch result {
            case .success(let images): completion(images)
            case .failure: completion([])
            }
        }
    }
    
    // 3. Master Custom Function
    // ⚠️ I removed 'mode' from arguments to fix the iOS 17 error.
    func pickMediaCustom(
        from viewController: UIViewController,
        selectionLimit: Int = 1,
        filter: PHPickerFilter = PHPickerFilter.images, // ✅ Fixed: Explicit Type
        selectionStyle: PHPickerConfiguration.Selection = .default,
        representationMode: PHPickerConfiguration.AssetRepresentationMode = .compatible,
        completion: @escaping (Result<[UIImage], Error>) -> Void
    ) {
        self.completion = completion
        self.presentationController = viewController
        
        var config = PHPickerConfiguration()
        config.selectionLimit = selectionLimit
        config.filter = filter
        config.preferredAssetRepresentationMode = representationMode
        
        // iOS 15 Check
        if #available(iOS 15.0, *) {
            config.selection = selectionStyle
        }
        
        // iOS 17 Check (Internal Only)
        // If you are on iOS 17, it will use default mode.
        // We don't expose this parameter to avoid crashes on older iOS.
        if #available(iOS 17.0, *) {
            config.mode = .default
        }
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        viewController.present(picker, animated: true)
    }
}

// ---------------------------------------------------------
// MARK: - ⚙️ PART 3: Delegate
// ---------------------------------------------------------
extension ImagePickerManager: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard !results.isEmpty else {
            let error = NSError(domain: "UserCancelled", code: -1, userInfo: nil)
            self.completion?(.failure(error))
            self.cleanup()
            return
        }
        
        var selectedImages: [UIImage] = []
        let group = DispatchGroup()
        
        for result in results {
            let provider = result.itemProvider
            if provider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    defer { group.leave() }
                    if let image = image as? UIImage {
                        selectedImages.append(image)
                    }
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            if !selectedImages.isEmpty {
                self.completion?(.success(selectedImages))
            } else {
                let error = NSError(domain: "LoadFailed", code: -1, userInfo: nil)
                self.completion?(.failure(error))
            }
            self.cleanup()
        }
    }
    
    private func cleanup() {
        self.completion = nil
        self.presentationController = nil
    }
}
