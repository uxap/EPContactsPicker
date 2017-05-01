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
    
    let maxPhoneNumberCount = 5
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
            if i > maxPhoneNumberCount {
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
