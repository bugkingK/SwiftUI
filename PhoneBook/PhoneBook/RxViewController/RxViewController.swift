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
import RxDataSources
import Contacts

struct SectionOfContacts {
    var header: String
    var items: [Item]
}

extension SectionOfContacts: SectionModelType {
    typealias Item = Contact

    init(original: SectionOfContacts, items: [Item]) {
        self = original
        self.items = items
    }
}

class RxViewController: UIViewController {
    
    @IBOutlet private weak var searchBar:UISearchBar!
    @IBOutlet private weak var tableView:UITableView!
    
    private var allContacts:[Contact] = []
    private var sections: BehaviorRelay<[SectionOfContacts]> = BehaviorRelay(value:[])
    private var disposedBag:DisposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setBind()
        self.setData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disposedBag = DisposeBag()
    }
    
    private func setBind() {
        searchBar.delegate = self
        searchBar.rx.text
            .orEmpty
            .debounce(RxTimeInterval.seconds(1), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [unowned self] query in
                self.searching(query: query)
            })
            .disposed(by: disposedBag)
        
        let dataSource = RxTableViewSectionedReloadDataSource<SectionOfContacts>(
            configureCell: { dataSource, tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ViewControllerCell", for: indexPath) as? ViewControllerCell else {
                return UITableViewCell()
            }
            
            cell.fullName.text = item.fullName
            cell.thumbnailImage.image = item.thumbnailImage ?? UIImage(systemName: "moon.fill")
            return cell
        })
        
        dataSource.titleForHeaderInSection = { dataSource, index in
            return dataSource.sectionModels[index].header
        }
        
        dataSource.sectionIndexTitles = { dataSource in
            return dataSource.sectionModels.map { $0.header }
        }
        
        dataSource.sectionForSectionIndexTitle = { dataSource, title, index in
            return dataSource.sectionModels.map { $0.header }.firstIndex(of: title) ?? 0
        }
        
        sections
            .bind(to: tableView.rx.items(dataSource: dataSource))
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
            shown = shown.filter { $0.fullName.lowercased().contains(query.lowercased()) }
        }
        
        var header:Set<String> = []
        shown.forEach {
            header.update(with: KoreanUtil.getInitial($0.fullName) ?? "")
        }
        
        var sections:[SectionOfContacts] = []
        for head in header.sorted() {
            sections.append(SectionOfContacts(header: head, items:
                shown.filter { (KoreanUtil.getInitial($0.fullName) ?? "@") == head }
            ))
        }
        
        self.sections.accept(sections)
        self.tableView.reloadData()
    }
}

extension RxViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
