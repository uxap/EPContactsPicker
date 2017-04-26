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

class ViewController4 : UIViewController {
    
    @IBOutlet var searchButtonItem: UIBarButtonItem!
    lazy var cancelButtonItem: UIBarButtonItem = {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: 60, height: 32)
        button .setTitle("Cancel", for: .normal)
        button.addTarget(self, action: #selector(didTapCancelSearchButton),
                         for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }()
    
    lazy var contactsPicker: EPContactsPicker = {
        let picker = EPContactsPicker(delegate: self, multiSelection: false)
        
        var style = EPContactsPickerStyle()
        style.showSearchBar = false
        picker.style = style
        
        var searchBarStyle = EPContactsPickerSearchBarStyle()
        searchBarStyle.hasCancelButton = false
        picker.searchBarStyle = searchBarStyle
        
        return picker
    }()
    
    var isSearching = false

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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (isSearching) {
            contactsPicker.searchBar.becomeFirstResponder()
        }
    }
    
}

// MARK: - Action
extension ViewController4 {
    
    @IBAction func didTapSearchButton() {
        
        beginSearch(animated: true)
    }
    
    func didTapCancelSearchButton() {
        
        contactsPicker.cancelSearch()
        
    }
    
}

// MARK: - Search
extension ViewController4 {
    
    func beginSearch(animated:Bool) {

        let searchBar = contactsPicker.searchBar
        self.navigationItem.setRightBarButton(cancelButtonItem, animated: animated)
        self.navigationItem.titleView = searchBar
        self.navigationItem.setHidesBackButton(true, animated: animated)
        
        searchBar.becomeFirstResponder()
        isSearching = true
        
        if animated {
            searchBar.alpha = 0
            UIView.animate(withDuration: 0.3, animations: { 
                searchBar.alpha = 1.0
            })
        }
        
    }
    
    func endSearch(animated:Bool) {
        
        let searchBar = contactsPicker.searchBar
        
        let completion: (Bool)->Void = { Bool -> Void in
            
            self.navigationItem.setRightBarButton(self.searchButtonItem, animated: animated)
            self.navigationItem.titleView = nil
            self.navigationItem.setHidesBackButton(false, animated: animated)
            self.isSearching = false
            
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                searchBar.alpha = 0.0
            }, completion: completion )
        } else {
            completion(true)
        }

    }
}

extension ViewController4: EPPickerDelegate {
    
    func epContactPicker(_: EPContactsPicker, didContactFetchFailed error: NSError) {
        
    }
    
    func epContactPicker(_: EPContactsPicker, didCancel error: NSError) {
        
    }
    func epContactPicker(_: EPContactsPicker, didSelectContact contact: EPContact) {
        print(contact.phoneNumbers)

        if (isSearching) {
            endSearch(animated: true)
        }
        
        if contact.phoneNumbers.count > 0 {
            let alert = UIAlertController(title: "Selected Contact", message: contact.phoneNumbers[0].phoneNumber, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    func epContactPicker(_: EPContactsPicker, didSelectMultipleContacts contacts: [EPContact]) {
        
    }
    
    func epContactPickerSearchDidEnd(_: EPContactsPicker) {
        
        endSearch(animated: true)
    }
    
    
}
