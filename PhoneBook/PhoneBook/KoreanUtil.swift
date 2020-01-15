//
//  KoreanUtil.swift
//  PhoneBook
//
//  Created by Banaple on 2020/01/15.
//  Copyright © 2020 bugkingK. All rights reserved.
//

import Foundation

public struct KOREAN {
    var initial:String?
    var middle:String?
    var final:String?
}

public class KoreanUtil {
    
    static let BEGIN_UNICODE = 0xAC00
    static let END_UNICODE = 0xD7A3
    
    static public func getInitial(_ string:String) -> String? {
        guard let code = string.decomposedStringWithCanonicalMapping.unicodeScalars.first else {
            return nil
        }
        
        let strInitial = String(code)
        if let nInitial = Int(strInitial), nInitial <= 9 && nInitial >= 0 {
            return "@"
        }
        
        return strInitial
    }
    
    static public func split(_ string:String) {
//        guard let value = UnicodeScalar(string)?.value else {
//            return
//        }
//
//        let x = (value - 0xAC00) / 28 / 21
//        let y = (value - 0xAC00) / 28 % 21
//        let z = (value - 0xAC00) % 28
//
//        if let onset = UnicodeScalar(0x1100 + x) {
//            print(String(onset))
//        }
//        if let nucleus = UnicodeScalar(0x1161 + y) {
//            print(String(nucleus))
//        }
//        if let coda = UnicodeScalar(0x11A6 + 1 + z) {
//            print(String(coda))
//        }
//        print(string.decomposedStringWithCanonicalMapping.unicodeScalars.map{
//            if $0 == nil {
//                print("nil이라면? \($0)")
//            }
//            String($0)
//        })
    }
    
}
