//
//  ContactsModel.swift
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
        if fullName.count == 0 {
            fullName = "이름없음"
        }
        phoneNumbers = contact.phoneNumbers.compactMap { (phoneNumber: CNLabeledValue) in
            guard let number = phoneNumber.value.value(forKey: "digits") as? String else { return nil }
            return number
        }
        
        if let thumbnailData = contact.thumbnailImageData {
            thumbnailImage = UIImage(data: thumbnailData)
        }
    }
}


public class PhoneBooKit: NSObject {
    
    enum PhoneBooKitError:Error {
        /// 사진앱 접근 허용을 안한 상태.
        case restricted
        /// unable to fetch contacts
        case unableFetch
    }
    
    static private func checkAuthorizationWithHandler(completion: @escaping(_ success:Bool)->()) {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            completion(true)
        case .notDetermined:
            CNContactStore().requestAccess(for: .contacts) { (success, err) in
                self.checkAuthorizationWithHandler(completion: completion)
            }
        case .denied, .restricted:
            completion(false)
        default:
            assert(false, "Err - Invalid path.")
            break
        }
    }

    /**
    사용자의 연락처에 접근하여 연락처 정보를 가져옵니다. Privacy - Contacts Usage Description 을 추가해주세요.
    - parameters:
        - key: Contact의 유형, .fullName, .phoneticFullName가 있다.
        - completion: success, error, contacts, success가 실패했을 경우 restricted, unableFetch가 존재.
    */
    static public func get(keys:[String], completion:((Bool, Error?, [CNContact]?)->())?) {
        self.checkAuthorizationWithHandler { (success) in
            var arrContact:[CNContact]?
            if !success {
                completion?(success, PhoneBooKitError.restricted, arrContact)
                return
            }
            
            let store = CNContactStore()
            let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
            
            do {
                try store.enumerateContacts(with: request, usingBlock: { (contact, stop) in
                    if arrContact == nil {
                        arrContact = []
                    }
                    
                    arrContact?.append(contact)
                })
                completion?(success, nil, arrContact)
            } catch {
                completion?(false, PhoneBooKitError.unableFetch, arrContact)
            }
        }
    }
}
