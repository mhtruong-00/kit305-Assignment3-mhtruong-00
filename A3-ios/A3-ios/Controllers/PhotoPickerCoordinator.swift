// With support from GitHub Copilot
import UIKit
import PhotosUI

protocol PhotoPickerDelegate: AnyObject {
    func photoPickerDidSelectImage(_ image: UIImage)
    func photoPickerDidCancel()
}

class PhotoPickerCoordinator: NSObject {
    weak var delegate: PhotoPickerDelegate?
    weak var presenter: UIViewController?

    func presentPicker(from viewController: UIViewController) {
        self.presenter = viewController
        if #available(iOS 14.0, *) {
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = 1
            configuration.filter = .images
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            viewController.present(picker, animated: true)
        } else {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            viewController.present(picker, animated: true)
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
@available(iOS 14.0, *)
extension PhotoPickerCoordinator: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else {
            delegate?.photoPickerDidCancel()
            return
        }
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            DispatchQueue.main.async {
                if let image = object as? UIImage {
                    self?.delegate?.photoPickerDidSelectImage(image)
                } else {
                    self?.delegate?.photoPickerDidCancel()
                }
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate (iOS 13 fallback)
extension PhotoPickerCoordinator: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                                didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            delegate?.photoPickerDidSelectImage(image)
        } else {
            delegate?.photoPickerDidCancel()
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        delegate?.photoPickerDidCancel()
    }
}
