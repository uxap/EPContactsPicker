//
//  ViewController2.swift
//  Contacts Picker
//
//  Created by Eddie Hiu-Fung Lau on 28/3/2017.
//  Copyright © 2017 Prabaharan Elangovan. All rights reserved.
//

import Foundation
import UIKit

class ViewController2 : UIViewController {
    
    lazy var contactsPicker: EPContactsPicker = {
        return EPContactsPicker(delegate: self, multiSelection: false)
    }()

    override func viewDidLoad() {
        
        addChildViewController(contactsPicker)
        contactsPicker.view.frame = view.bounds
        contactsPicker.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(contactsPicker.view)
        
    }
    
    override func viewDidLayoutSubviews() {
        
        let top = topLayoutGuide.length
        let bottom = bottomLayoutGuide.length
        contactsPicker.tableView.contentInset = UIEdgeInsetsMake(top, 0, bottom, 0)
        contactsPicker.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(top, 0, bottom, 0)
        
    }
    
}

extension ViewController2: EPPickerDelegate {
    
    func epContactPicker(_: EPContactsPicker, didContactFetchFailed error: NSError) {
        
    }
    
    func epContactPicker(_: EPContactsPicker, didCancel error: NSError) {
        
    }
    func epContactPicker(_: EPContactsPicker, didSelectContact contact: EPContact) {
        print(contact.phoneNumbers)
    }
    
    func epContactPicker(_: EPContactsPicker, didSelectMultipleContacts contacts: [EPContact]) {
        
    }
    
    
}
