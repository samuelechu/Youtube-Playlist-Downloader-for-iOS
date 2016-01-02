//
//  UIViewController+Alert.swift
//  Music Player
//
//  Created by 岡本拓也 on 2016/01/02.
//  Copyright © 2016年 Sem. All rights reserved.
//

import UIKit



extension UIViewController {

    func showTextFieldDialog(title: String, message: String, placeHolder: String, okButtonTitle: String, didTapOkButton: ((String?) -> Void)) {

        let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            //print("Pushed CANCEL")
        })

        var inputTextField: UITextField?

        alertController.addAction(UIAlertAction(title: okButtonTitle, style: .Default) { action -> Void in
            didTapOkButton(inputTextField?.text)
        })

        alertController.addTextFieldWithConfigurationHandler { textField -> Void in
            inputTextField = textField
            textField.placeholder = placeHolder
        }

        presentViewController(alertController, animated: true, completion: nil)
    }
    
    
    func errorAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let otherAction = UIAlertAction(title: "OK", style: .Default) { action in }
        alertController.addAction(otherAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
}