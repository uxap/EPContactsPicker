//
//  ViewController2.swift
//  Contacts Picker
//
//  Created by Eddie Hiu-Fung Lau on 28/3/2017.
//  Copyright © 2017 Prabaharan Elangovan. All rights reserved.
//

import Foundation
import UIKit
import UXContactsPicker

class ViewController2 : UIViewController {
    
    lazy var contactsPicker: EPContactsPicker = {
        return EPContactsPicker(delegate: self, multiSelection: false)
    }()

    override func viewDidLoad() {
        
        addChild(contactsPicker)
        contactsPicker.view.frame = view.bounds
        contactsPicker.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(contactsPicker.view)
        
    }
    
    override func viewDidLayoutSubviews() {
        
        let top = topLayoutGuide.length
        let bottom = bottomLayoutGuide.length
        contactsPicker.tableView.contentInset = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        contactsPicker.tableView.scrollIndicatorInsets = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        
    }
    
}

extension ViewController2: EPPickerDelegate {
    
    func epContactPicker(_: EPContactsPicker, didContactFetchFailed error: NSError) {
        
    }
    
    func epContactPicker(_: EPContactsPicker, didCancel error: NSError) {
        
    }
    func epContactPicker(_: EPContactsPicker, didSelectContact contact: EPContact) {
        print(contact.phoneNumbers)
        
        if contact.phoneNumbers.count > 0 {
            let alert = UIAlertController(title: "Selected Contact", message: contact.phoneNumbers[0].phoneNumber, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        
    }
    
    func epContactPicker(_: EPContactsPicker, didSelectMultipleContacts contacts: [EPContact]) {
        
    }
    
    
}
