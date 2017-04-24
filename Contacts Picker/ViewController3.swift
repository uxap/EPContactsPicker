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

class ViewController3 : UIViewController {
    
    lazy var style: EPContactPickerStyle = {
        
        var style = EPContactPickerStyle()
        
        style.rowHeight = 75
        style.photoLeftMargin = 16
        style.photoRightMargin = 16
        style.photoSize = CGSize(width: 42, height: 42)
        style.titleTopMargin = 17
        style.titleFont = UIFont.boldSystemFont(ofSize: 14)
        style.titleColor = UIColor.white
        style.subtitleTopMargin = 6
        style.subtitleFont = UIFont.systemFont(ofSize: 14)
        style.subtitleColor = UIColor.white.withAlphaComponent(0.6)
        
        style.backgroundColor = UIColor(colorLiteralRed: 14.0/255.0, green: 15.0/255.0, blue: 26.0/255.0, alpha: 1.0)
        style.cellBackgroundColor = style.backgroundColor
        style.seperatorColor = UIColor.white.withAlphaComponent(0.08)
        
        style.initialBackgroundColors = [
            UIColor(rgb: 0xff2366),
            UIColor(rgb: 0xfd51d9),
            UIColor(rgb: 0xe92c81),
            UIColor(rgb: 0x56b2ba),
            UIColor(rgb: 0x0b78e3),
            UIColor(rgb: 0xface15),
            UIColor(rgb: 0x8d8de8),
            UIColor(rgb: 0x6859ea),
            UIColor(rgb: 0x7ed321)
        ]
        
        style.showIndexBar = false
        style.showSearchBar = false
        
        return style
    }()
    
    lazy var headerStyle: EPContactPickerHeaderStyle = {
        
        var style = EPContactPickerHeaderStyle()
        style.backgroundColor = UIColor(colorLiteralRed: 25.0/255.0, green: 26.0/255.0, blue: 37.0/255.0, alpha: 1.0)
        style.textColor = UIColor.white
        style.leftMargin = 16
        
        return style
        
    }()
    
    lazy var contactsPicker: EPContactsPicker = {
        let picker = EPContactsPicker(delegate: self, multiSelection: false)
        picker.style = self.style
        picker.headerStyle = self.headerStyle
        return picker
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

extension ViewController3: EPPickerDelegate {
    
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

fileprivate extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}