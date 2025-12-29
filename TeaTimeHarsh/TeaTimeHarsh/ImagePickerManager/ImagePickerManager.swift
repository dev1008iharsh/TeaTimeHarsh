//
//  ImagePickerManager.swift
//  Api Harsh Darji
 
import UIKit
import PhotosUI

 
// This protects your class and makes it thread-safe for UI work.
@MainActor
class ImagePickerManager: NSObject {
    
    typealias ImageCompletion = ((UIImage?) -> Void)
    
    // We don't need 'weak' here if we are careful, but weak is safer for ViewControllers
    private weak var presentationController: UIViewController?
    private var imageCompletion: ImageCompletion?
    
    private var isPickerPresented = false
    
    init(presentationController: UIViewController) {
        self.presentationController = presentationController
        super.init()
    }
    
    // 2. This function is now explicitly on the Main Actor
    func selectImage(completion: @escaping ImageCompletion) {
        self.imageCompletion = completion
        presentImagePicker()
    }
    
    private func presentImagePicker() {
        guard let validVC = presentationController, !isPickerPresented else { return }
        
        isPickerPresented = true
        
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        
        validVC.present(picker, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ImagePickerManager: PHPickerViewControllerDelegate {
    
    // This delegate method is automatically called on the Main Actor by UIKit
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        self.isPickerPresented = false
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider else {
            imageCompletion?(nil)
            return
        }
        
        if provider.canLoadObject(ofClass: UIImage.self) {
            
            // ⚠️ CRITICAL NOTE:
            // loadObject performs work on a BACKGROUND thread.
            // Even though our class is @MainActor, this closure leaves the VIP section.
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                
                // 3. We MUST jump back to the Main Actor to touch 'self'
                // because 'self' is isolated to the Main Actor.
                Task { @MainActor [weak self] in
                    if let image = image as? UIImage {
                        self?.imageCompletion?(image)
                    } else {
                        self?.imageCompletion?(nil)
                    }
                }
            }
        } else {
            imageCompletion?(nil)
        }
    }
}
