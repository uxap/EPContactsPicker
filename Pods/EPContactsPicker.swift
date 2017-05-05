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
    func epContactPickerShouldAutoDismiss(_: EPContactsPicker) -> Bool
}

public extension EPPickerDelegate {
    func epContactPicker(_: EPContactsPicker, didContactFetchFailed error: NSError) { }
    func epContactPicker(_: EPContactsPicker, didCancel error: NSError) { }
    func epContactPicker(_: EPContactsPicker, didSelectContact contact: EPContact) { }
    func epContactPicker(_: EPContactsPicker, didSelectMultipleContacts contacts: [EPContact]) { }
    func epContactPickerSearchDidEnd(_: EPContactsPicker) { }
    func epContactPickerShouldAutoDismiss(_: EPContactsPicker) -> Bool { return true }
}

public enum SubtitleCellValue{
    case none
    case phoneNumber
    case phoneLabel
    case email
    case birthday
    case organization
}

open class EPContactsPicker: UIViewController, UISearchResultsUpdating, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    
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
    
    open var tableView: UITableView!
    open var contactDelegate: EPPickerDelegate?
    public var dataSource:EPContactsDataSource = EPDefaultDataSource()
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
    
    lazy var emptyViewLabel: UILabel = {
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
    
    lazy var emptyView:UIView = {
        [unowned self] in
        
        let v = UIView(frame: self.view.bounds)
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        v.backgroundColor =
            self.searchBarStyle?.noResultsViewBackgroundColor ?? UIColor(white:0.9, alpha:1.0)
        
        self.emptyViewLabel.frame = v.bounds
        v.addSubview(self.emptyViewLabel)
        return v
        
    }()
    
    var showsEmptyView = false {
        didSet {
            
            guard isViewLoaded else {
                return
            }
            
            if showsEmptyView {
                emptyView.frame = view.bounds
                view.addSubview(emptyView)
                
                emptyViewLabel.backgroundColor =
                    searchBarStyle?.noResultsViewBackgroundColor ?? UIColor(white:0.9, alpha:1.0)
                emptyViewLabel.textColor =
                    searchBarStyle?.noResultsViewTextColor ?? UIColor.gray
                emptyViewLabel.font = searchBarStyle?.noResultsViewFont ?? UIFont.systemFont(ofSize: 20)
                
                if resultSearchController.isActive {
                    emptyViewLabel.text = "No Results"
                } else {
                    emptyViewLabel.text = "No Contacts"
                }
            } else {
                emptyView.removeFromSuperview()
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
    
    var isEmpty:Bool {
        return orderedContacts.isEmpty
    }
    
    // MARK: - Lifecycle Methods
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        
        self.title = EPGlobalConstants.Strings.contactsTitle
        
        registerContactCell()
        inititlizeBarButtons()
        initializeSearchBar()
        reloadContacts()
        
        if let style = style {
            setupTable(style: style)
        }
        
        showsEmptyView = isEmpty
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
        
        setupEmptyViewLabel()
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
        self.init(nibName: nil, bundle: nil)
        self.multiSelectEnabled = multiSelection
        contactDelegate = delegate
    }
    
    convenience public init(delegate: EPPickerDelegate?, multiSelection : Bool, subtitleCellType: SubtitleCellValue) {
        self.init(nibName: nil, bundle: nil)
        self.multiSelectEnabled = multiSelection
        contactDelegate = delegate
        subtitleCellValue = subtitleCellType
    }
    
    // MARK: - Style
    
    func setupTable(style:EPContactsPickerStyle) {
        tableView.backgroundColor = style.backgroundColor
        tableView.separatorColor = style.seperatorColor
        tableView.separatorStyle = style.seperatorStyle ?? .singleLine
        
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
        
        cell.contactTextLabel.font = style.titleFont
        cell.contactTextLabel.textColor = style.titleColor
        cell.contactDetailTextLabel.font = style.subtitleFont
        cell.contactDetailTextLabel.textColor = style.subtitleColor
        
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
    }
    
    func setupEmptyViewLabel() {
        
        guard isViewLoaded else {
            return
        }
        
        emptyViewLabel.backgroundColor =
            searchBarStyle?.noResultsViewBackgroundColor ?? UIColor(white:0.9, alpha:1.0)
        emptyViewLabel.textColor =
            searchBarStyle?.noResultsViewTextColor ?? UIColor.gray
        emptyViewLabel.font = searchBarStyle?.noResultsViewFont ?? UIFont.systemFont(ofSize: 20)
    }
    
    
    // MARK: - Contact Operations
    
    open func reloadContacts() {
        
        
        orderedContacts = [:]
        sortedContactKeys = []
        
        
        
        dataSource.loadContacts(self, completion: {
            
            [weak self] error in
            
            guard let weakSelf = self else {
                return
            }
            
            //self.tableView.endUpdates()
            weakSelf.showsEmptyView = weakSelf.isEmpty
            weakSelf.tableView.reloadData()
            
        }) { [weak self] contact in
            
            guard let weakSelf = self else {
                return
            }
            
            let key = contact.sectionKey
            
            if let _ /* section */ = weakSelf.sortedContactKeys.index(of: key) {
                
                let _ /* row */ = weakSelf.orderedContacts[key]!.count
                weakSelf.orderedContacts[key]?.append(contact)
                //weakSelf.tableView.insertRows(at: [IndexPath(row: row, section: section)], with: .fade)
                
                
            } else {
                
                weakSelf.orderedContacts[key] = [contact]
                weakSelf.sortedContactKeys.append(key)
                let _ /* section */ = weakSelf.sortedContactKeys.index(of: key)!
                //weakSelf.tableView.insertSections(IndexSet(integer: section), with: .fade)
                //print("(\(section),\(key))")
                
            }
            
        }
        
    }
    
    
    // MARK: - Table View DataSource
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        if showSearchResults { return 1 }
        return sortedContactKeys.count
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showSearchResults { return filteredContacts.count }
        if let contactsForSection = orderedContacts[sortedContactKeys[section]] {
            return contactsForSection.count
        }
        return 0
    }
    
    // MARK: - Table View Delegates
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
            guard let contactsForSection = orderedContacts[sortedContactKeys[indexPath.section]] else {
                fatalError()
            }
            
            contact = contactsForSection[indexPath.row]
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
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
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
            
            let autoDismiss = self.contactDelegate?.epContactPickerShouldAutoDismiss(self) ?? true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                
                if self.presentingViewController != nil && autoDismiss {
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
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let style = style {
            return style.rowHeight
        } else {
            return 60.0
        }
    }
    
    open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if showSearchResults { return 0 }
        tableView.scrollToRow(at: IndexPath(row: 0, section: index), at: UITableViewScrollPosition.top , animated: false)
        return sortedContactKeys.index(of: title)!
    }
    
    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if let style = style {
            cell.backgroundColor = style.cellBackgroundColor
        }
    }
    
    open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        if showSearchResults { return nil }
        
        if style?.showIndexBar ?? true {
            return sortedContactKeys
        } else {
            return nil
        }
    }
    
    open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if !(style?.showHeader ?? true) {
            return nil
        }
        
        if showSearchResults {
            if showsEmptyView { return nil }
            else { return "Search Results" }
        }
        return sortedContactKeys[section]
    }
    
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
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
            return nil
        }
    }
    
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if let headerStyle = headerStyle,
            let _ = self.tableView(tableView, titleForHeaderInSection: section) {
            return headerStyle.height
        } else {
            return CGFloat(0)
        }
    }
    
    open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if showSearchResults {
            return false
        }
        
        guard let contactsForSection = orderedContacts[sortedContactKeys[indexPath.section]] else {
            fatalError()
        }
        
        let contact = contactsForSection[indexPath.row]
        return dataSource.canDelete(contact: contact)
        
    }
    
    open func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
    }
    
    open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    open func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
    }
    
    open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        let key = sortedContactKeys[indexPath.section]
        guard var contactsForSection = orderedContacts[key] else {
            fatalError()
        }
        let contact = contactsForSection[indexPath.row]
        
        dataSource.delete(contact: contact) {
            [weak self]
            error in
            
            guard let weakSelf = self else {
                return
            }
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
                tableView.setEditing(false, animated: true)
                
            } else {
                
                contactsForSection.remove(at: indexPath.row)
                if contactsForSection.count > 0 {
                    weakSelf.orderedContacts[key]
                        = contactsForSection
                    
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                    
                } else {
                    weakSelf.orderedContacts.removeValue(forKey: key)
                    weakSelf.sortedContactKeys.remove(at:indexPath.section)
                    
                    tableView.deleteSections(
                        IndexSet(integer: indexPath.section),
                        with: .automatic)
                }
                
                weakSelf.showsEmptyView = weakSelf.isEmpty
                
            }
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
                self.showsEmptyView = self.filteredContacts.count == 0 && searchText.characters.count > 0
                self.tableView.reloadData()
                
            })
            
        }
    }
    
    open func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
            self.contactDelegate?.epContactPickerSearchDidEnd(self)
            self.showsEmptyView = self.isEmpty
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
        showsEmptyView = self.isEmpty
        
    }
}
