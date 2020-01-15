//
//  RxViewController.swift
//  PhoneBook
//
//  Created by Banaple on 2020/01/14.
//  Copyright © 2020 bugkingK. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Contacts

class RxViewController: UIViewController {
    
    @IBOutlet private weak var searchBar:UISearchBar!
    @IBOutlet private weak var tableView:UITableView!
    
    private var header:[String] = []
    private var allContacts:[Contact] = []
    private var shownContacts:[[Contact]] = []
    private var disposedBag:DisposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setData()
        self.setBind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disposedBag = DisposeBag()
    }
    
    private func setBind() {
        tableView.dataSource = self
        searchBar.delegate = self
        
        searchBar
            .rx.text
            .orEmpty
            .distinctUntilChanged()
            .subscribe(onNext: { [unowned self] query in
                self.searching(query: query)
            })
            .disposed(by: disposedBag)
    }
    
    private func setData() {
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactImageDataAvailableKey, CNContactThumbnailImageDataKey, CNContactOrganizationNameKey]
        PhoneBooKit.get(keys: keys) { [unowned self] (isSuccess, err, contacts) in
            if let `err` = err {
                print(err.localizedDescription)
                return
            }
            
            guard let `contacts` = contacts, isSuccess else {
                return
            }
            
            self.allContacts = contacts.map { Contact(contact: $0) }
            self.searching(query: "")
        }
    }
    
    private func searching(query:String) {
        var shown:[Contact] = self.allContacts
        if query != "" {
            // 초성 검색은 안됨.
            shown = shown.filter { $0.fullName.contains(query) }
        }
        
        var header:Set<String> = []
        shown.forEach {
            header.update(with: KoreanUtil.getInitial($0.fullName) ?? "")
        }
        self.header = header.sorted()
        for (i, query) in self.header.enumerated() {
            self.shownContacts.insert(shown.filter {
                (KoreanUtil.getInitial($0.fullName) ?? "@") == query
            }, at: i)
        }

        self.tableView.reloadData()
    }

}

extension RxViewController:UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.header.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.header[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.shownContacts[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ViewControllerCell", for: indexPath) as? ViewControllerCell else {
            return UITableViewCell()
        }
        
        let item = self.shownContacts[indexPath.section][indexPath.row]
        cell.fullName.text = item.fullName
        cell.thumbnailImage.image = item.thumbnailImage ?? UIImage(systemName: "moon.fill")
        return cell
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.header
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return self.header.firstIndex(of: title) ?? 0
    }
    
}

extension RxViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
