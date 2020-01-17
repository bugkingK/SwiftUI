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
//import KoreanKit

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
    
    private var koreanKit:KoreanKit = KoreanKit()
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
        searchBar.rx
            .searchButtonClicked
            .subscribe(onNext: { [unowned self] in
                self.searchBar.resignFirstResponder()
            })
            .disposed(by: disposedBag)
        
        searchBar.rx.text
            .orEmpty
            .debounce(RxTimeInterval.microseconds(7), scheduler: MainScheduler.instance)
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
        let `query` = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query != "" {
            if !koreanKit.isSyllable(query) {
                shown = shown.filter { $0.fullName.lowercased().contains(query) }
            } else {
                shown = shown.filter {
                    koreanKit.split($0.fullName.lowercased()).contains(koreanKit.split(query))
                }
            }
        }
        
        var header:Set<String> = []
        shown.forEach {
            let t = koreanKit.first($0.fullName) ?? ""
            if t == "친" {
                print("-----------")
                print(koreanKit.first($0.fullName))
            }
            header.update(with: t)
        }
        
        var sections:[SectionOfContacts] = []
        for head in header.sorted() {
            sections.append(SectionOfContacts(header: head, items:
                shown.filter { (koreanKit.first($0.fullName) ?? "@") == head }
            ))
        }
        
        self.sections.accept(sections)
        self.tableView.reloadData()
    }
}

extension KoreanKit {
    
    func first(_ query:String, syllable:Syllable = .initial) -> String? {
        let prev = String(query.first ?? Character(""))
        guard let first = self.split(prev, syllable: syllable).first else {
            return nil
        }
        
        let strFirst = String(first)
        if let nFirst = Int(strFirst), nFirst <= 9 && nFirst >= 0 {
            return "@"
        }
        
        return strFirst
    }
}

//
//  KoreanKit.swift
//  KoreanKit
//
//  Created by BugkingK on 2020/01/16.
//  Copyright © 2020 bugkingK. All rights reserved.
//

import Foundation

public class KoreanKit {
    
    public enum Syllable:Int { case initial = 0, medial, final }
    
    private let arrConsonant:[[String.Element]] = [
        ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"],
        ["ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ", "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ", "ㅣ"],
        ["", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ", "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ", "ㅄ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    ]
    
    public init() { }
    // 친구 어쩌구가 제대로 분해가 안돼..
    public func split(_ query:String, syllable:Syllable = .initial) -> String {
        
        

        
        
        let unicodeVal = UnicodeScalar(query)?.value
        guard let value = unicodeVal else { return query }
        if (value < 0xAC00 || value > 0xD7A3) {
            return query
        }   // 한글아니면 반환
        let last = (value - 0xAC00) % 28                        // 종성인지 확인
        let str = last > 0 ? "을" : "를"      // 받침있으면 을 없으면 를 반환
        
        
        
        var syl:String = ""
        
        
        
        
        
        for scalar in query.unicodeScalars {
            print(scalar)
//            let strScalar = String(scalar)
//
//
//            print(arrConsonant[syllable.rawValue].contains(strScalar))
//
//            if !arrConsonant[syllable.rawValue].contains(strScalar) {
//                continue
//            }
//
//            syl.append(strScalar)
            
//            let unicode = scalar.value
//            if !(unicode >= 0xAC00 && unicode <= 0xD7A3) {
//                syl.append(String(scalar))
//                continue
//            }
//
//            let index = Int(unicode - 0xAC00)
//            switch syllable {
//                case .initial:  syl.append(arrConsonant[0][index/28/21])
//                case .medial:   syl.append(arrConsonant[1][(index/28%21)])
//                case .final:    syl.append(arrConsonant[2][index%28])
//            }
        }
        
        return syl
    }
    
    public func isSyllable(_ query:String.Element, syllable:Syllable = .initial) -> Bool {
//        return self.arrConsonant[syllable.rawValue].contains(self.split(String(query), syllable: syllable))
        return true
    }
    
    public func isSyllable(_ query:String, syllable:Syllable = .initial) -> Bool {
        for unicode in query.unicodeScalars {
            return self.isSyllable(Character(unicode), syllable: syllable)
        }
        return true
    }
}
