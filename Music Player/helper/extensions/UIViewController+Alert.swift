//
//  UIViewController+Alert.swift
//  Music Player
//
//  Created by 岡本拓也 on 2016/01/02.
//  Copyright © 2016年 Sem. All rights reserved.
//

import UIKit



extension UIViewController {

    func showTextFieldDialog(_ title: String, message: String, placeHolder: String, okButtonTitle: String, didTapOkButton: @escaping ((String?) -> Void)) {

        let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //print("Pushed CANCEL")
        })

        var inputTextField: UITextField?

        alertController.addAction(UIAlertAction(title: okButtonTitle, style: .default) { action -> Void in
            didTapOkButton(inputTextField?.text)
        })

        alertController.addTextField { textField -> Void in
            inputTextField = textField
            textField.placeholder = placeHolder
        }

        present(alertController, animated: true, completion: nil)
    }
    
    
    func errorAlert(_ title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let otherAction = UIAlertAction(title: "OK", style: .default) { action in }
        alertController.addAction(otherAction)
        present(alertController, animated: true, completion: nil)
    }
}
