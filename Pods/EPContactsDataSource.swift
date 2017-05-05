//
//  EPContactsDataSource.swift
//  Pods
//
//  Created by Eddie Hiu-Fung Lau on 27/4/2017.
//
//

import Foundation
import Contacts

public protocol EPContactsDataSource {
    
    func loadContacts(_ contactPicker: EPContactsPicker,
                      completion: ((Error?)->Void)?,
                      contactLoadedHandler: ((EPContact)->Void)? )
    
    func searchContacts(searchText:String, completion: @escaping ([EPContact])->Void )
    
    
    func canDelete(contact:EPContact) -> Bool
    func delete(contact:EPContact, completion: ((Error?)->Void)? )
    
}

public extension EPContactsDataSource {
    
    func loadContacts(_ contactPicker: EPContactsPicker,
                      completion: ((Error?)->Void)?,
                      contactLoadedHandler: ((EPContact)->Void)? ) {
        
        let contactsStore = CNContactStore()
        let error = NSError(domain: "EPContactPickerErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "No Contacts Access"])
        
        switch CNContactStore.authorizationStatus(for: CNEntityType.contacts) {
        case CNAuthorizationStatus.denied, CNAuthorizationStatus.restricted:
            //User has denied the current app to access the contacts.
            
            let productName = Bundle.main.infoDictionary!["CFBundleName"]!
            
            let alert = UIAlertController(title: "Unable to access contacts", message: "\(productName) does not have access to contacts. Kindly enable it in privacy settings ", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {  action in
                contactPicker.contactDelegate?.epContactPicker(contactPicker, didContactFetchFailed: error)
                completion?(error)
                contactPicker.dismiss(animated: true, completion: nil)
            })
            alert.addAction(okAction)
            contactPicker.present(alert, animated: true, completion: nil)
            
        case CNAuthorizationStatus.notDetermined:
            //This case means the user is prompted for the first time for allowing contacts
            contactsStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (granted, error) -> Void in
                //At this point an alert is provided to the user to provide access to contacts. This will get invoked if a user responds to the alert
                if  (!granted ){
                    DispatchQueue.main.async(execute: { () -> Void in
                        completion?(error)
                    })
                }
                else{
                    self.loadContacts(contactPicker, completion: completion, contactLoadedHandler: contactLoadedHandler)
                }
            })
            
        case  CNAuthorizationStatus.authorized:
            //Authorization granted by user for this app.
            
            backgroundThread {
            
                let contactFetchRequest = CNContactFetchRequest(keysToFetch: self.allowedContactKeys)
                let sortOrder = CNContactsUserDefaults.shared().sortOrder
                contactFetchRequest.sortOrder = sortOrder
                
                do {
                    try contactsStore.enumerateContacts(with: contactFetchRequest, usingBlock: { (contact, stop) -> Void in
                        
                        //Ordering contacts based on alphabets in firstname
                        
                        mainThread {
                            contactLoadedHandler?(EPContact(contact: contact))
                        }
                        
                    })
                    
                    mainThread {
                        completion?(nil)
                    }
                    
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
                
            }
            
        }
            
    }
    
    func searchContacts(searchText:String, completion: @escaping ([EPContact])->Void ) {
        
        let contactsStore = CNContactStore()
        let predicate: NSPredicate
        if searchText.characters.count > 0 {
            predicate = CNContact.predicateForContacts(matchingName: searchText)
            
            do {
                let filteredContacts = try contactsStore.unifiedContacts(matching: predicate,
                                                                         keysToFetch: allowedContactKeys)
                    .map { contact -> EPContact in
                        return EPContact(contact: contact)
                }
                
                completion(filteredContacts)
            } catch {
                print("Error!")
            }
        } else {
            //predicate = CNContact.predicateForContactsInContainer(withIdentifier: contactsStore.defaultContainerIdentifier())
            completion([])
        }
        
        
    }
    
    var allowedContactKeys: [CNKeyDescriptor] {
        
        //We have to provide only the keys which we have to access. We should avoid unnecessary keys when fetching the contact. Reducing the keys means faster the access.
        return [CNContactNamePrefixKey as CNKeyDescriptor,
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor,
                CNContactBirthdayKey as CNKeyDescriptor,
                CNContactImageDataKey as CNKeyDescriptor,
                CNContactThumbnailImageDataKey as CNKeyDescriptor,
                CNContactImageDataAvailableKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                CNContactFormatter.descriptorForRequiredKeys(for: .phoneticFullName)
        ]
    }
    
    func canDelete(contact:EPContact) -> Bool { return false }
    func delete(contact:EPContact, completion: ((Error?)->Void)? ) {
        let error = NSError(domain: "EPContactPickerErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not supported"])
        completion?(error)
    }
}

fileprivate var enableThreading = false
fileprivate func backgroundThread(_ thread: @escaping ()->Void) {
    if enableThreading {
        DispatchQueue.global(qos: .background).async(execute: thread)
    } else {
        thread()
    }
}

fileprivate func mainThread(_ thread: @escaping ()->Void) {
    if enableThreading {
        DispatchQueue.main.async(execute: thread)
    } else {
        thread()
    }
}

