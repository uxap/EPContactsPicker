//
//  EPContactsPickerCustomSections.swift
//  Pods
//
//  Created by Eddie Hiu-Fung Lau on 1/7/2017.
//
//

import Foundation

public protocol EPContactsPickerCustomSections: UITableViewDataSource, UITableViewDelegate {
    func setup(_ contactsPicker:EPContactsPicker, tableView:UITableView)
}


