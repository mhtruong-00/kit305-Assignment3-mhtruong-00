// With support from GitHub Copilot
import UIKit

extension UITextField {
    func addDoneInputAccessory(target: Any?, action: Selector) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: target, action: action)
        toolbar.items = [flexSpace, doneButton]
        inputAccessoryView = toolbar
    }
}
