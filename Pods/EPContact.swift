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
    public var firstName: String
    public var lastName: String
    public var fullName: String?
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
			guard let phoneLabel = phoneNumber.label else { continue }
			let phone = phoneNumber.value.stringValue
			
			phoneNumbers.append((phone,phoneLabel))
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
                return lastName + " " + firstName
            }
            
        }
    }
    
    public func contactInitials() -> String {
        var initials = String()
		
		if let firstNameFirstChar = firstName.characters.first {
			initials.append(firstNameFirstChar)
		}
		
		if let lastNameFirstChar = lastName.characters.first {
			initials.append(lastNameFirstChar)
		}
		
        return initials
    }
    
}
