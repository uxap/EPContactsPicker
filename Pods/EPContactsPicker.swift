//
//  EPContactsPicker.swift
//  EPContacts
//
//  Created by Prabaharan Elangovan on 12/10/15.
//  Copyright © 2015 Prabaharan Elangovan. All rights reserved.
//

import UIKit

public protocol EPPickerDelegate {
	func epContactPicker(_: EPContactsPicker, didContactFetchFailed error: NSError)
    func epContactPicker(_: EPContactsPicker, didCancel error: NSError)
    func epContactPicker(_: EPContactsPicker, didSelectContact contact: EPContact)
	func epContactPicker(_: EPContactsPicker, didSelectMultipleContacts contacts: [EPContact])
    func epContactPickerSearchDidEnd(_: EPContactsPicker)
}

public extension EPPickerDelegate {
	func epContactPicker(_: EPContactsPicker, didContactFetchFailed error: NSError) { }
	func epContactPicker(_: EPContactsPicker, didCancel error: NSError) { }
	func epContactPicker(_: EPContactsPicker, didSelectContact contact: EPContact) { }
	func epContactPicker(_: EPContactsPicker, didSelectMultipleContacts contacts: [EPContact]) { }
    func epContactPickerSearchDidEnd(_: EPContactsPicker) { }
}

public enum SubtitleCellValue{
    case phoneNumber
    case email
    case birthday
    case organization
}

open class EPContactsPicker: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    
    public struct DataSource: EPContactsDataSource {}
    
    class CustomSearchBar: UISearchBar {
        
        override func setShowsCancelButton(_ showsCancelButton: Bool, animated: Bool) {
            super.setShowsCancelButton(false, animated:false)
        }
    }
    
    class CustomSearchController: UISearchController {
        
        lazy var _searchBar: CustomSearchBar = {
            //[unowned self] in
            let customSearchBar = CustomSearchBar(frame: CGRect.zero)
            return customSearchBar
        }()
        
        override var searchBar: UISearchBar {
            get {
                return _searchBar
            }
        }
    }
    
    
    // MARK: - Properties
    
    open var contactDelegate: EPPickerDelegate?
    public var dataSource = DataSource()
    var resultSearchController = UISearchController()
    var orderedContacts = [String: [EPContact]]() //Contacts ordered in dicitonary alphabetically
    var sortedContactKeys = [String]()
    
    var selectedContacts = [EPContact]()
    var filteredContacts = [EPContact]()
    
    var subtitleCellValue = SubtitleCellValue.phoneNumber
    var multiSelectEnabled: Bool = false //Default is single selection contact
    
    public var searchBar: UISearchBar {
        return resultSearchController.searchBar
    }
    
    var noResultLabel: UILabel!
    var showsNoResults = false {
        didSet {
            if showsNoResults {
                noResultLabel.frame = view.bounds
                view.addSubview(noResultLabel)
                tableView.isScrollEnabled = false
            } else {
                noResultLabel.removeFromSuperview()
                tableView.isScrollEnabled = true
            }
        }
    }
    var showSearchResults: Bool {
        return
            resultSearchController.isActive &&
            filteredContacts.count >= 0 &&
            resultSearchController.searchBar.text?.characters.count ?? 0 > 0
    }
    
    public var style: EPContactsPickerStyle? {
        didSet {
            if isViewLoaded {
                if let style = style {
                    setupTable(style: style)
                }
                tableView.reloadData()
            }
        }
    }
    
    public var headerStyle: EPContactsPickerHeaderStyle? = EPContactsPickerHeaderStyle() {
        didSet {
            if isViewLoaded {
                tableView.reloadData()
            }
        }
    }
    
    public var searchBarStyle: EPContactsPickerSearchBarStyle? {
        didSet {
            initializeSearchBar()
        }
    }
    
    // MARK: - Lifecycle Methods
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = EPGlobalConstants.Strings.contactsTitle

        registerContactCell()
        inititlizeBarButtons()
        initializeSearchBar()
        reloadContacts()
        
        if let style = style {
            setupTable(style: style)
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //tableView.reloadData()
        if tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0 {
            
            let scrollTo = IndexPath(row: 0, section: 0)
            tableView.scrollToRow(at: scrollTo, at: .top, animated: false)
        }
        
        if let selectedRows = tableView.indexPathsForSelectedRows {
            
            selectedRows.forEach { selectedRow in
                tableView.deselectRow(at: selectedRow, animated: false)
            }
        }
        
    }
    
    func initializeSearchBar() {
        
        noResultLabel = {
            [unowned self] in
            
            let label = UILabel(frame: self.view.bounds)
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            label.backgroundColor =
                self.searchBarStyle?.noResultsViewBackgroundColor ?? UIColor(white:0.9, alpha:1.0)
            label.textColor =
                self.searchBarStyle?.noResultsViewTextColor ?? UIColor.gray
            
            label.font = self.searchBarStyle?.noResultsViewFont ?? UIFont.systemFont(ofSize: 20)
            label.textAlignment = .center
            label.isUserInteractionEnabled = true
            label.text = "No Results"
            return label
        }()
        
        resultSearchController = {
            [unowned self] in
            
            let controller:UISearchController = {
                
                if self.searchBarStyle?.hasCancelButton ?? true {
                    return UISearchController(searchResultsController: nil)
                } else {
                    return CustomSearchController(searchResultsController: nil)
                }
               
            }()
            
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()
            controller.searchBar.delegate = self
            controller.searchBar.keyboardAppearance =
                self.searchBarStyle?.keyboardAppearance ?? .default
            
            if self.style?.showSearchBar ?? true {
                self.tableView.tableHeaderView = controller.searchBar
            } else {
                controller.hidesNavigationBarDuringPresentation = false
            }
            return controller
        } ()
    }
    
    func inititlizeBarButtons() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(onTouchCancelButton))
        self.navigationItem.leftBarButtonItem = cancelButton
        
        if multiSelectEnabled {
            let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(onTouchDoneButton))
            self.navigationItem.rightBarButtonItem = doneButton
            
        }
    }
    
    fileprivate func registerContactCell() {
        
        let podBundle = Bundle(for: self.classForCoder)
        if let bundleURL = podBundle.url(forResource: EPGlobalConstants.Strings.bundleIdentifier, withExtension: "bundle") {
            
            if let bundle = Bundle(url: bundleURL) {
                
                let cellNib = UINib(nibName: EPGlobalConstants.Strings.cellNibIdentifier, bundle: bundle)
                tableView.register(cellNib, forCellReuseIdentifier: "Cell")
            }
            else {
                assertionFailure("Could not load bundle")
            }
        }
        else {
            
            let cellNib = UINib(nibName: EPGlobalConstants.Strings.cellNibIdentifier, bundle: nil)
            tableView.register(cellNib, forCellReuseIdentifier: "Cell")
        }
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Initializers
  
    convenience public init(delegate: EPPickerDelegate?) {
        self.init(delegate: delegate, multiSelection: false)
    }
    
    convenience public init(delegate: EPPickerDelegate?, multiSelection : Bool) {
        self.init(style: .plain)
        self.multiSelectEnabled = multiSelection
        contactDelegate = delegate
    }

    convenience public init(delegate: EPPickerDelegate?, multiSelection : Bool, subtitleCellType: SubtitleCellValue) {
        self.init(style: .plain)
        self.multiSelectEnabled = multiSelection
        contactDelegate = delegate
        subtitleCellValue = subtitleCellType
    }
    
    // MARK: - Style
    
    func setupTable(style:EPContactsPickerStyle) {
        tableView.backgroundColor = style.backgroundColor
        tableView.separatorColor = style.seperatorColor
        
        if (!style.showSearchBar) {
            tableView.tableHeaderView = nil
        } else {
            initializeSearchBar()
        }
    }
    
    func setupCell(cell:EPContactCell, style:EPContactsPickerStyle) {
        
        cell.photoLeftMargin.constant = style.photoLeftMargin
        cell.photoRightMargin.constant = style.computedPhotoRightMargin
        cell.photoWidth.constant = style.computedPhotoSize.width
        cell.photoHeight.constant = style.computedPhotoSize.height
        cell.titleTopMargin.constant = style.titleTopMargin
        cell.subtitleTopMargin.constant = style.subtitleTopMargin
        cell.contactDetailTextLabel.isHidden = !style.showSubtitle
        
        cell.contactTextLabel.font = style.titleFont
        cell.contactTextLabel.textColor = style.titleColor
        cell.contactDetailTextLabel.font = style.subtitleFont
        cell.contactDetailTextLabel.textColor = style.subtitleColor
        
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
    }
    
    
    // MARK: - Contact Operations
  
      open func reloadContacts() {
        
        tableView.beginUpdates()
        
        
        dataSource.loadContacts(self, completion: { error in

            self.tableView.endUpdates()
            
        }) { [weak self] contact in
            
            guard let weakSelf = self else {
                return
            }
            
            let key = contact.sectionKey
            
            if let section = weakSelf.sortedContactKeys.index(of: key) {
            
                let row = weakSelf.orderedContacts[key]!.count
                weakSelf.orderedContacts[key]?.append(contact)
                
                weakSelf.tableView.insertRows(at: [IndexPath(row: row, section: section)], with: .fade)
                //print("  (\(section),\(row))")

                
            } else {
                
                weakSelf.orderedContacts[key] = [contact]
                weakSelf.sortedContactKeys.append(key)

                /*
                weakSelf.sortedContactKeys.sort(by: { lhs, rhs -> Bool in
                    
                    if lhs == "#" {
                        return false
                    }
                    if rhs == "#" {
                        return true
                    }
                    return lhs < rhs
                    
                })
                */
                
                let section = weakSelf.sortedContactKeys.index(of: key)!
                weakSelf.tableView.insertSections(IndexSet(integer: section), with: .fade)
                //print("(\(section),\(key))")
                
            }
            
        }
        
      }
  
    
    // MARK: - Table View DataSource
    
    override open func numberOfSections(in tableView: UITableView) -> Int {
        if showSearchResults { return 1 }
        return sortedContactKeys.count
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showSearchResults { return filteredContacts.count }
        if let contactsForSection = orderedContacts[sortedContactKeys[section]] {
            return contactsForSection.count
        }
        return 0
    }

    // MARK: - Table View Delegates

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! EPContactCell
        cell.accessoryType = UITableViewCellAccessoryType.none
        
        if let style = style {
            setupCell(cell: cell, style: style)
        }
        
        //Convert CNContact to EPContact
		let contact: EPContact
        
        if showSearchResults {
            contact = filteredContacts[(indexPath as NSIndexPath).row]
        } else {
			guard let contactsForSection = orderedContacts[sortedContactKeys[(indexPath as NSIndexPath).section]] else {
				assertionFailure()
				return UITableViewCell()
			}

			contact = contactsForSection[(indexPath as NSIndexPath).row]
        }
		
        if multiSelectEnabled  && selectedContacts.contains(where: { $0.contactId == contact.contactId }) {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        }
        
        if !multiSelectEnabled {
            cell.selectionStyle = .default
        } else {
            cell.selectionStyle = .none
        }
		
        cell.updateContactsinUI(contact, indexPath: indexPath, subtitleType: subtitleCellValue, style: style)
        return cell
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! EPContactCell
        let selectedContact =  cell.contact!
        if multiSelectEnabled {
            //Keeps track of enable=ing and disabling contacts
            if cell.accessoryType == UITableViewCellAccessoryType.checkmark {
                cell.accessoryType = UITableViewCellAccessoryType.none
                selectedContacts = selectedContacts.filter(){
                    return selectedContact.contactId != $0.contactId
                }
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
                selectedContacts.append(selectedContact)
            }
        }
        else {
            //Single selection code
            
            var delay = 0.0
            if resultSearchController.isActive {
                cancelSearch()
                
                if (style?.showSearchBar ?? true) {
                    delay = 0.7
                }
            }
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                
                if self.presentingViewController != nil {
                    self.dismiss(animated: true, completion: {
                        DispatchQueue.main.async {
                            self.contactDelegate?.epContactPicker(self, didSelectContact: selectedContact)
                        }
                    })
                } else {
                    DispatchQueue.main.async {
                        self.contactDelegate?.epContactPicker(self, didSelectContact: selectedContact)
                    }
                }
                
            }
            
            
        }
    }
    
    override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let style = style {
            return style.rowHeight
        } else {
            return 60.0
        }
    }
    
    override open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if showSearchResults { return 0 }
        tableView.scrollToRow(at: IndexPath(row: 0, section: index), at: UITableViewScrollPosition.top , animated: false)        
        return sortedContactKeys.index(of: title)!
    }
    
    override open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if let style = style {
            cell.backgroundColor = style.cellBackgroundColor
        }
    }
    
    override  open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        if showSearchResults { return nil }
        
        if style?.showIndexBar ?? true {
            return sortedContactKeys
        } else {
            return nil
        }
    }
    
    override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if showSearchResults {
            if showsNoResults { return nil }
            else { return "Search Results" }
        }
        return sortedContactKeys[section]
    }
    
    override open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if let headerStyle = headerStyle,
            let text = self.tableView(tableView, titleForHeaderInSection: section) {
            
            let view =
                UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.height, height: headerStyle.height))
            
            view.backgroundColor = headerStyle.backgroundColor
            view.autoresizingMask = [.flexibleWidth]
            
            let label = UILabel(frame: CGRect(x: headerStyle.leftMargin, y: 0, width: tableView.frame.size.height, height: headerStyle.height))
            label.autoresizingMask = [.flexibleWidth]
            view.addSubview(label)
            
            label.text = text
            label.textColor = headerStyle.textColor
            
            return view
            
        } else {
            return super.tableView(tableView, viewForHeaderInSection: section)
        }
    }
    
    override open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if let headerStyle = headerStyle,
            let _ = self.tableView(tableView, titleForHeaderInSection: section) {
            return headerStyle.height
        } else {
            return super.tableView(tableView, heightForHeaderInSection: section)
        }
    }
    
    // MARK: - Button Actions
    
    func onTouchCancelButton() {
        contactDelegate?.epContactPicker(self, didCancel: NSError(domain: "EPContactPickerErrorDomain", code: 2, userInfo: [ NSLocalizedDescriptionKey: "User Canceled Selection"]))
        dismiss(animated: true, completion: nil)
    }
    
    func onTouchDoneButton() {
        contactDelegate?.epContactPicker(self, didSelectMultipleContacts: selectedContacts)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Search Actions
    
    open func updateSearchResults(for searchController: UISearchController)
    {
        if let searchText = resultSearchController.searchBar.text , searchController.isActive {
            
            dataSource.searchContacts(searchText: searchText, completion: { result in
                
                self.filteredContacts = result
                self.showsNoResults = self.filteredContacts.count == 0 && searchText.characters.count > 0
                self.tableView.reloadData()
                
            })
            
        }
    }
    
    open func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
            self.contactDelegate?.epContactPickerSearchDidEnd(self)
            self.showsNoResults = false
        })
    }
    
}

// MARK: public method
extension EPContactsPicker {
    
    public func cancelSearch() {
        
        guard resultSearchController.isActive else {
            return
        }
        
        resultSearchController.isActive = false
        tableView.reloadData()
        contactDelegate?.epContactPickerSearchDidEnd(self)
        showsNoResults = false
        
    }
}
