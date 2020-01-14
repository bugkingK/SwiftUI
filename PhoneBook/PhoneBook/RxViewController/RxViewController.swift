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
    
    private var header:[String]?
    private var allContacts:[Contact]?
    private var shownContacts:[Contact]?
    private var disposedBag:DisposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setBind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disposedBag = DisposeBag()
    }
    
    private func setBind() {
        tableView.dataSource = self
        
        searchBar
            .rx.text
            .orEmpty
            .distinctUntilChanged()
            .filter { !$0.isEmpty }
            .subscribe(onNext: { [unowned self] query in
                self.shownContacts = self.allContacts?.filter { $0.fullName.hasPrefix(query) }
                self.tableView.reloadData()
            })
            .disposed(by: disposedBag)
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
            self.header = self.allContacts!.reduce([]) { (ret, contact) -> Set<String> in
                var `ret` = ret
                ret.insert(contact.fullName.first?.description ?? "")
                return ret
            }.sorted()
            
            self.tableView.reloadData()
        }
    }
}

extension RxViewController:UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    
}
