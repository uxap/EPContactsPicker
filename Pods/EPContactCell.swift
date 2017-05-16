//
//  EPContactCell.swift
//  EPContacts
//
//  Created by Prabaharan Elangovan on 13/10/15.
//  Copyright © 2015 Prabaharan Elangovan. All rights reserved.
//

import UIKit

public class EPContactCell: UITableViewCell {
    
    @IBOutlet weak var photoLeftMargin: NSLayoutConstraint!
    @IBOutlet weak var photoRightMargin: NSLayoutConstraint!
    @IBOutlet weak var photoWidth: NSLayoutConstraint!
    @IBOutlet weak var photoHeight: NSLayoutConstraint!
    @IBOutlet weak var titleTopMargin: NSLayoutConstraint!
    @IBOutlet weak var subtitleTopMargin: NSLayoutConstraint!
    
    @IBOutlet var contactTextLabelCenterAlign: NSLayoutConstraint!
    @IBOutlet public weak var contactTextLabel: UILabel!
    @IBOutlet public weak var contactDetailTextLabel: UILabel!
    @IBOutlet public weak var contactImageView: UIImageView!
    @IBOutlet public weak var contactInitialLabel: UILabel!
    @IBOutlet public weak var contactContainerView: UIView!
    
    var contact: EPContact?
    
    override public func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
        selectionStyle = UITableViewCellSelectionStyle.none
        contactContainerView.layer.masksToBounds = true
        contactContainerView.layer.cornerRadius = contactContainerView.frame.size.width/2
    }
    
    override public func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        contactContainerView.layer.masksToBounds = true
        contactContainerView.layer.cornerRadius = photoWidth.constant/2
    }
    
    func updateInitialsColorForIndexPath(_ indexpath: IndexPath, style:EPContactsPickerStyle? = nil) {
        //Applies color to Initial Label
        let colorArray = style?.initialBackgroundColors ?? [EPGlobalConstants.Colors.amethystColor,EPGlobalConstants.Colors.asbestosColor,EPGlobalConstants.Colors.emeraldColor,EPGlobalConstants.Colors.peterRiverColor,EPGlobalConstants.Colors.pomegranateColor,EPGlobalConstants.Colors.pumpkinColor,EPGlobalConstants.Colors.sunflowerColor]
        let randomValue = (indexpath.row + indexpath.section) % colorArray.count
        contactInitialLabel.backgroundColor = colorArray[randomValue]
        
        if let font = style?.initialFont {
            contactInitialLabel.font = font
        }
        
        if let color = style?.initialColor {
            contactInitialLabel.textColor = color
        }
    }
    
    func updateContactsinUI(_ contact: EPContact, indexPath: IndexPath, subtitleType: SubtitleCellValue, style:EPContactsPickerStyle? = nil) {
        self.contact = contact
        //Update all UI in the cell here
        if let cellHighlightColor = style?.cellHighlightColor {
            let view = UIView()
            view.backgroundColor = cellHighlightColor
            selectedBackgroundView = view
        }
        
        self.contactTextLabel?.text = contact.fullName
        updateSubtitleBasedonType(subtitleType, contact: contact)
        if contact.thumbnailProfileImage != nil {
            self.contactImageView?.image = contact.thumbnailProfileImage
            self.contactImageView.isHidden = false
            self.contactInitialLabel.isHidden = true
        } else {
            self.contactInitialLabel.text = contact.contactInitials()
            updateInitialsColorForIndexPath(indexPath, style: style)
            self.contactImageView.isHidden = true
            self.contactInitialLabel.isHidden = false
        }
    }
    
    func updateSubtitleBasedonType(_ subtitleType: SubtitleCellValue , contact: EPContact) {
        
        switch subtitleType {
            
        case SubtitleCellValue.phoneNumber:
            let phoneNumberCount = contact.phoneNumbers.count
            
            if phoneNumberCount == 1  {
                self.contactDetailTextLabel.text = "\(contact.phoneNumbers[0].phoneNumber)"
            }
            else if phoneNumberCount > 1 {
                self.contactDetailTextLabel.text = "\(contact.phoneNumbers[0].phoneNumber) and \(contact.phoneNumbers.count-1) more"
            }
            else {
                self.contactDetailTextLabel.text = EPGlobalConstants.Strings.phoneNumberNotAvaialable
            }
            contactTextLabelCenterAlign.isActive = false
        case SubtitleCellValue.phoneLabel:
            let phoneNumberCount = contact.phoneNumbers.count
            
            if phoneNumberCount == 1  {
                self.contactDetailTextLabel.text = "\(contact.phoneNumbers[0].phoneLabel)"
            }
            else if phoneNumberCount > 1 {
                self.contactDetailTextLabel.text = "\(contact.phoneNumbers[0].phoneLabel) and \(contact.phoneNumbers.count-1) more"
            }
            else {
                self.contactDetailTextLabel.text = EPGlobalConstants.Strings.phoneNumberNotAvaialable
            }
            contactTextLabelCenterAlign.isActive = false
        case SubtitleCellValue.email:
            let emailCount = contact.emails.count
            
            if emailCount == 1  {
                self.contactDetailTextLabel.text = "\(contact.emails[0].email)"
            }
            else if emailCount > 1 {
                self.contactDetailTextLabel.text = "\(contact.emails[0].email) and \(contact.emails.count-1) more"
            }
            else {
                self.contactDetailTextLabel.text = EPGlobalConstants.Strings.emailNotAvaialable
            }
            self.contactTextLabelCenterAlign.isActive = false
        case SubtitleCellValue.birthday:
            self.contactDetailTextLabel.text = contact.birthdayString
            self.contactTextLabelCenterAlign.isActive = false
        case SubtitleCellValue.organization:
            self.contactDetailTextLabel.text = contact.company
            contactTextLabelCenterAlign.isActive = false
        case .none:
            self.contactDetailTextLabel.text = nil
            contactTextLabelCenterAlign.isActive = true
        }
    }
}
