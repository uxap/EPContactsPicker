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

class ViewController5 : UIViewController {
    
    lazy var contactsPicker: EPContactsPicker = {
        let picker = EPContactsPicker(delegate: self, multiSelection: false)
        picker.customSections = self
        picker.style = EPContactsPickerStyle()
        // picker.style!.customSectionsSharedHeader = "Custom Sections"
        // picker.style!.sectionsSharedHeader = "Contacts"
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

extension ViewController5: EPPickerDelegate {
    
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

// Custom Sections

extension ViewController5: EPContactsPickerCustomSections {
    
    func setup(tableView:UITableView) {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CustomSectionCell")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomSectionCell", for:indexPath)
        cell.textLabel?.text = "Cell \(indexPath.row)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Custom Section \(section)"
    }
}
