//
//  EPContact.swift
//  EPContacts
//
//  Created by Prabaharan Elangovan on 13/10/15.
//  Copyright © 2015 Prabaharan Elangovan. All rights reserved.
//

import UIKit
import Contacts

public struct EPContact {
    
    static let maxPhoneNumberCount = 5
    public let sectionKey:String
    public var firstName: String
    public var lastName: String
    public var fullName: String?
    public var attributedFullName: NSAttributedString?
    public let nameOrder: CNContactDisplayNameOrder
    public var company: String
    public var thumbnailProfileImage: UIImage?
    public var profileImage: UIImage?
    public var birthday: Date?
    public var birthdayString: String?
    public var contactId: String?
    public var phoneNumbers = [(phoneNumber: String, phoneLabel: String)]()
    public var emails = [(email: String, emailLabel: String )]()
	
    public init (contact: CNContact) {
        
        sectionKey = contact.sectionKey
        firstName = contact.givenName
        lastName = contact.familyName
        company = contact.organizationName
        contactId = contact.identifier
        
        if let thumbnailImageData = contact.thumbnailImageData {
            thumbnailProfileImage = UIImage(data:thumbnailImageData)
        }
        
        if let imageData = contact.imageData {
            profileImage = UIImage(data:imageData)
        }
        
        if let birthdayDate = contact.birthday {
            
            birthday = Calendar(identifier: Calendar.Identifier.gregorian).date(from: birthdayDate)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = EPGlobalConstants.Strings.birdtdayDateFormat
            //Example Date Formats:  Oct 4, Sep 18, Mar 9
            birthdayString = dateFormatter.string(from: birthday!)
        }
        
        var i = 0
		for phoneNumber in contact.phoneNumbers {
            
            var localizedLabel:String?
            
            if let label = phoneNumber.label {
                localizedLabel = CNLabeledValue<NSString>.localizedString(forLabel: label)
            }
            
			guard localizedLabel != nil else { continue }
			let phone = phoneNumber.value.stringValue
			
			phoneNumbers.append((phone,localizedLabel!))
            i = i+1
            if i > EPContact.maxPhoneNumberCount {
                break
            }
		}
		
		for emailAddress in contact.emailAddresses {
			guard let emailLabel = emailAddress.label else { continue }
			let email = emailAddress.value as String
			
			emails.append((email,emailLabel))
		}
        
        nameOrder = CNContactFormatter.nameOrder(for: contact)
        fullName = CNContactFormatter.string(from: contact, style: .fullName)
        attributedFullName =
            CNContactFormatter.attributedString(
                from: contact, style: .fullName, defaultAttributes: nil)
    }
    
    
    
	
    public func displayName() -> String {
        if let fullName = fullName {
            return fullName
        } else {
            switch nameOrder {
            case .givenNameFirst:
                return firstName + " " + lastName
            case .familyNameFirst:
                return lastName + " " + firstName
            default:
                return firstName + " " + lastName
            }
            
        }
    }
    
    public func contactInitials() -> String {
        var initials = String()
		
        let firstChar: Character?
        let secondChar: Character?
        switch nameOrder {
        case .givenNameFirst:
            firstChar = firstName.characters.first
            secondChar = lastName.characters.first
        case .familyNameFirst:
            firstChar = lastName.characters.first
            secondChar = firstName.characters.first
        default:
            firstChar = firstName.characters.first
            secondChar = lastName.characters.first
        }
        
        
		if let firstChar = firstChar {
			initials.append(firstChar)
		}
		
		if let secondChar = secondChar {
			initials.append(secondChar)
		}
		
        return initials
    }
    
}

public extension EPContact {
    
    public var dictionaryRepresentation: [String:Any] {
        
        var dict = [String:Any]()
        dict["sectionKey"] = sectionKey
        dict["firstName"] = firstName
        dict["lastName"] = lastName
        dict["fullName"] = fullName
        //dict["attributedFullName"] = ???
        dict["nameOrder"] = nameOrder.rawValue
        dict["company"] = company
        dict["birthday"] = birthday
        dict["birthdayString"] = birthdayString
        dict["contactId"] = contactId
        dict["phoneNumbers"] = phoneNumbers.map({ (phoneNumber, phoneLabel) -> [String:String] in
            return ["phoneNumber":phoneNumber, "phoneLabel":phoneLabel]
        })
        dict["emails"] = emails.map({ (email, emailLabel) -> [String:String] in
            return ["email":email, "emailLabel":emailLabel]
        })
        
        return dict
    }
    
}

public extension EPContact {
    
    public init?(dict:[String:Any]) {
        
        guard let sectionKey = dict["sectionKey"] as? String else {
            return nil
        }
        self.sectionKey = sectionKey
        
        guard let firstName = dict["firstName"] as? String else {
            return nil
        }
        self.firstName = firstName
        
        guard let lastName = dict["lastName"] as? String else {
            return nil
        }
        self.lastName = lastName
        
        guard let fullName = dict["fullName"] as? String else {
            return nil
        }
        self.fullName = fullName
        
        guard let nameOrderInt = dict["nameOrder"] as? Int else {
            return nil
        }
        
        guard let nameOrder = CNContactDisplayNameOrder(rawValue:nameOrderInt) else {
            return nil
        }
        self.nameOrder = nameOrder
        
        guard let company = dict["company"] as? String else {
            return nil
        }
        self.company = company
        
        guard let birthday = dict["birthday"] as? Date else {
            return nil
        }
        self.birthday = birthday
        
        guard let birthdayString = dict["birthdayString"] as? String else {
            return nil
        }
        self.birthdayString = birthdayString
        
        guard let contactId = dict["contactId"] as? String else {
            return nil
        }
        self.contactId = contactId
        
        guard let phoneNumbersArray = dict["phoneNUmbers"] as? [[String:String]] else {
            return nil
        }
        self.phoneNumbers = phoneNumbersArray.reduce([], {
            
            (result, dict) -> [(phoneNumber:String, phoneLabel:String)] in
            
            guard let phoneNumber = dict["phoneNumber"] else {
                return result
            }
            
            guard let phoneLabel = dict["phoneLabel"] else {
                return result
            }
            
            return result + [(phoneNumber, phoneLabel)]
        })
        
        
        guard let emailsArray = dict["emails"] as? [[String:String]] else {
            return nil
        }
        self.emails = emailsArray.reduce([], {
            
            (result, dict) -> [(email:String, emailLabel:String)] in
            
            guard let email = dict["email"] else {
                return result
            }
            
            guard let emailLabel = dict["emailLabel"] else {
                return result
            }
            
            return result + [(email, emailLabel)]
        })
        
    }
    
}



fileprivate extension CNContact {
    
    var firstLetter: String? {
        
        let sortOrder = CNContactsUserDefaults.shared().sortOrder

        switch sortOrder {
        case .familyName:
            return familyName[0..<1] ?? givenName[0..<1] ?? organizationName[0..<1]
        case .givenName:
            return givenName[0..<1] ?? familyName[0..<1] ?? organizationName[0..<1]
        default:
            return givenName[0..<1] ?? familyName[0..<1] ?? organizationName[0..<1]
        }
        
    }
    
    var sectionKey: String {
        
        if let firstLetter = firstLetter , firstLetter.containsAlphabets() {
            return firstLetter.uppercased()
        } else {
            return "#"
        }
        
    }
    
}



