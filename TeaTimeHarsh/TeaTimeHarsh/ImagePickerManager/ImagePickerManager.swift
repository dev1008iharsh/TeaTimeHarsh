//
//  ImagePickerManager.swift
//  Api Harsh Darji
 
import UIKit
import PhotosUI


class ImagePickerManager: NSObject {
   
    typealias ImageCompletion = ((UIImage?) -> Void)
    
    private weak var presentationController: UIViewController?
    private var imageCompletion: ImageCompletion?
    
    private var isPickerPresented = false
    
    init(presentationController: UIViewController) {
        self.presentationController = presentationController
        super.init()
    }
    
    func selectImage(completion: @escaping ImageCompletion) {
        self.imageCompletion = completion
        
        if checkPhotoLibraryPermission() {
            presentImagePicker()
        } else {
            requestPhotoLibraryPermission()
        }
    }
    
    private func presentImagePicker() {
        guard !isPickerPresented else {
                   return // Avoid presenting picker if already presented
               }
               
               isPickerPresented = true // Set flag to true before presenting
        
        let configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        presentationController?.present(picker, animated: true, completion: nil)
    }
    
    private func checkPhotoLibraryPermission() -> Bool {
        let status = PHPhotoLibrary.authorizationStatus()
        return status == .authorized
    }
    
    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self?.presentImagePicker()
                } else {
                    self?.showPermissionDeniedMessage()
                }
            }
        }
    }
    
    private func showPermissionDeniedMessage() {
        print("Permission denied")
        
        guard let vcName = presentationController else { return }
        Utility.shared.showCustomConfirmAlert(title: "Media Access Permission Denied", message: "Please grant permission to access photos in settings.", rightSideActionName: "Open Settings", leftSideActionName: "Cancel", viewController: vcName) { settingAction in
            
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        } leftAction: { cancelAction in
            print("cancle")
        }
    }
}

extension ImagePickerManager: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let provider = results.first?.itemProvider else {
            imageCompletion?(nil)
            return
        }
        
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                DispatchQueue.main.async {
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
