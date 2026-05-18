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

    /// Presents an action sheet letting the user choose between camera and
    /// photo library — matching the Android RoomDetails capture/gallery buttons.
    func presentPicker(from viewController: UIViewController) {
        self.presenter = viewController
        let cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        let sheet = UIAlertController(title: "Add Photo", message: nil, preferredStyle: .actionSheet)
        if cameraAvailable {
            sheet.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
                self?.presentCamera(from: viewController)
            })
        }
        sheet.addAction(UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
            self?.presentLibrary(from: viewController)
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.delegate?.photoPickerDidCancel()
        })
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX,
                                        y: viewController.view.bounds.midY,
                                        width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        viewController.present(sheet, animated: true)
    }

    // MARK: - Sources

    private func presentCamera(from vc: UIViewController) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        vc.present(picker, animated: true)
    }

    private func presentLibrary(from vc: UIViewController) {
        if #available(iOS 14.0, *) {
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = 1
            configuration.filter = .images
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            vc.present(picker, animated: true)
        } else {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            vc.present(picker, animated: true)
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
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
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

// MARK: - UIImagePickerControllerDelegate (camera & iOS 13 fallback)
extension PhotoPickerCoordinator: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                                didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let edited = info[.editedImage] as? UIImage {
            delegate?.photoPickerDidSelectImage(edited)
        } else if let image = info[.originalImage] as? UIImage {
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
