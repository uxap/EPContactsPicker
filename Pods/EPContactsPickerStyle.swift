//
//  EPContactsPickerStyle.swift
//  Pods
//
//  Created by Eddie Hiu-Fung Lau on 28/4/2017.
//
//

import Foundation

public struct EPContactsPickerStyle {
    
    public var rowHeight = CGFloat(60.0)
    public var photoLeftMargin = CGFloat(10.0)
    public var photoRightMargin = CGFloat(10.0)
    public var photoSize = CGSize(width: 40.0, height: 40.0)
    
    public var titleFont = UIFont.systemFont(ofSize: 17.0)
    public var titleColor = UIColor(colorLiteralRed: 85.0/255.0, green: 85.0/255.0, blue: 85.0/255.0, alpha: 1.0)
    public var titleTopMargin = CGFloat(10.0)
    
    public var subtitleFont = UIFont.systemFont(ofSize: 15.0)
    public var subtitleColor = UIColor(colorLiteralRed: 170.0/255.0, green: 170.0/255.0, blue: 170.0/255.0, alpha: 1.0)
    public var subtitleTopMargin = CGFloat(4)
    
    public var cellHighlightColor: UIColor?
    public var cellBackgroundColor = UIColor.white
    public var backgroundColor = UIColor.white
    public var seperatorColor: UIColor?
    public var seperatorStyle: UITableViewCellSeparatorStyle?
    
    public var initialFont = UIFont.systemFont(ofSize: 17)
    public var initialColor = UIColor.white
    public var initialBackgroundColors: [UIColor]?
    
    public var showPicuture = true
    public var showIndexBar = true
    public var showSearchBar = true
    public var showHeader = true
    
    public init() {
    }
    
    var computedPhotoSize: CGSize {
        if showPicuture {
            return photoSize
        } else {
            return CGSize(width: 0, height: photoSize.height)
        }
    }
    
    var computedPhotoRightMargin: CGFloat {
        if showPicuture {
            return photoRightMargin
        } else {
            return 0
        }
    }
    
    
}

public struct EPContactsPickerHeaderStyle {
    
    public var font = UIFont.systemFont(ofSize: 15)
    public var height = CGFloat(25)
    public var backgroundColor = UIColor(white: 0.9, alpha: 1.0)
    public var textColor = UIColor.black
    public var leftMargin = CGFloat(10)
    public var customSectionsSharedHeader:String?
    public var sectionsSharedHeader:String?
    
    
    public init() {}
    
}

public struct EPContactsPickerSearchBarStyle {
    
    public var hasCancelButton = true
    public var noResultsViewBackgroundColor: UIColor?
    public var noResultsViewImage: UIImage?
    public var noResultsViewFont: UIFont?
    public var noResultsViewEmptyText: String?
    public var noResultsViewNoSearchResultsText: String?
    public var noResultsViewTextColor: UIColor?
    public var keyboardAppearance = UIKeyboardAppearance.default
    
    public init(){}
}
