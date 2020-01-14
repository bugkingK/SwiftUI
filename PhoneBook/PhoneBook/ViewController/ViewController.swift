//
//  ViewController.swift
//  PhoneBook
//
//  Created by Banaple on 2020/01/14.
//  Copyright © 2020 bugkingK. All rights reserved.
//

import UIKit
import Contacts

public struct Contact {
    var familyName:String
    var givenName:String
    var organizationName:String
    var fullName:String
    /// home, mobile, home fax
    var phoneNumbers:[String]
    var thumbnailImage:UIImage?
    
    init(contact:CNContact) {
        familyName = contact.familyName
        givenName = contact.givenName
        organizationName = contact.organizationName
        fullName = "\(givenName)\(familyName)\(organizationName)"
        phoneNumbers = contact.phoneNumbers.compactMap { (phoneNumber: CNLabeledValue) in
            guard let number = phoneNumber.value.value(forKey: "digits") as? String else { return nil }
            return number
        }
        
        if let thumbnailData = contact.thumbnailImageData {
            thumbnailImage = UIImage(data: thumbnailData)
        }
    }
}


class ViewController: UIViewController {
    
    @IBOutlet private weak var searchBar:UISearchBar!
    @IBOutlet private weak var tableView:UITableView!
    private var header:[String]?
    private var allContacts:[Contact]?
    private var shownContacts:[Contact]?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadData()
        self.passing(query: "")
    }
    
    private func setupLayout() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.searchBar.delegate = self
    }

    private func loadData() {
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactImageDataAvailableKey, CNContactThumbnailImageDataKey, CNContactOrganizationNameKey]
        PhoneBooKit.get(keys: keys) { [unowned self] (isSuccess, err, contacts) in
            if let `err` = err, !isSuccess {
                print(err.localizedDescription)
                return
            }
            
            guard let `contacts` = contacts else {
                return
            }
            
            self.allContacts = contacts.map { Contact(contact: $0) }
        }
    }
    
    private func passing(query:String) {
        guard let allContacts = self.allContacts else {
            return
        }
        
        self.shownContacts = allContacts.filter { $0.fullName.hasPrefix(query) }
        self.header = self.shownContacts!.reduce([]) { (ret, contact) -> Set<String> in
            var `ret` = ret
            ret.insert(contact.fullName.first?.description ?? "")
            return ret
        }.sorted()
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.header?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.header?[section] ?? ""
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let prefix = header?[section] ?? ""
        let filtering = self.allContacts?.filter { $0.fullName.first?.description == prefix }
        
        if self.searchBar.text?.isEmpty == true {
            return filtering?.count ?? 0
        }
        
        return filtering?.filter { $0.fullName.contains(self.searchBar.text!) }.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let prefix = header?[indexPath.section] ?? ""
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ViewControllerCell", for: indexPath) as? ViewControllerCell else {
            return UITableViewCell()
        }
        
        var contact:Contact?
        let filtering = self.allContacts?.filter { $0.fullName.first?.description == prefix }
        if self.searchBar.text?.isEmpty == true {
            contact = filtering?[indexPath.row]
        } else {
            contact = filtering?.filter { $0.fullName.contains(self.searchBar.text!) }[indexPath.row]
        }
        
        cell.fullName.text = contact?.fullName
        let thumbnail = contact?.thumbnailImage ?? UIImage(systemName: "moon.fill")
        cell.thumbnailImage.image = thumbnail
        return cell
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.header
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return self.header?.firstIndex(of: title) ?? 0
    }
}

extension ViewController: UITableViewDelegate {
    
}

extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.passing(query: searchText)
        self.tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}


class ViewControllerCell:UITableViewCell {
    @IBOutlet weak var thumbnailImage:UIImageView!
    @IBOutlet weak var fullName:UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.thumbnailImage.layer.cornerRadius = self.thumbnailImage.frame.height / 2
    }
}
