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
    
    static let BEGIN_UNICODE:UInt32 = 0xAC00
    static let END_UNICODE:UInt32 = 0xD7A3
    static private let initialConsonantArray = [
        "ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"
    ]
    static private let medialConsonantArray = [
        "ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ", "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ", "ㅣ"
    ]
    static private let finalConsonantArray = [
        " ", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ", "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ", "ㅄ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"
    ]
    
    static public func isInitial(_ string:String) -> Bool {
        for unicode in string.unicodeScalars {
            if !initialConsonantArray.contains(String(unicode)) {
                return false
            }
        }
        return true
    }
    
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
    
    static public func getInitials(_ string:String) -> String {
        var ret:String = ""
        
        for unicode in string.unicodeScalars {
            if self.isInitial(String(unicode)) {
                ret.append(String(unicode))
                continue
            }
            
            let unicodeValue = unicode.value
            if !(unicodeValue >= BEGIN_UNICODE && unicodeValue <= END_UNICODE) {
                continue
            }
            
            let firstCodeValue = (unicodeValue - BEGIN_UNICODE) / 28 / 21
            ret.append(initialConsonantArray[Int(firstCodeValue)])
        }
        
        return ret
    }
    
}
