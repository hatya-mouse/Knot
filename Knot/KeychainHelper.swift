//
//  KeychainHelper.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/15.
//

import Foundation
import Security

let accessGroup = "com.hatya.Knot"

struct KeychainHelper {
    /// Stores the given data with the key to the keychain.
    static func save(key: String, data: String) {
        guard let bytes = data.data(using: .utf8) else { return }

        let deleteQuery =
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: key,
                kSecAttrAccessGroup: accessGroup,
            ] as CFDictionary
        SecItemDelete(deleteQuery)

        let addQuery =
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: key,
                kSecAttrAccessGroup: accessGroup,
                kSecValueData: bytes,
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
            ] as CFDictionary
        SecItemAdd(addQuery, nil)
    }

    /// Loads the data with the given key.
    static func load(key: String) -> String? {
        let getQuery =
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: key,
                kSecAttrAccessGroup: accessGroup,
                kSecReturnData: true,
            ] as CFDictionary

        var item: AnyObject?
        let status = SecItemCopyMatching(getQuery, &item)

        if status == errSecSuccess, let data = item as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    /// Checks if the data with the given exists and it is accessible.
    static func exists(key: String) -> Bool {
        let matchQuery =
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: key,
                kSecAttrAccessGroup: accessGroup,
                kSecReturnData: true,
            ] as CFDictionary

        let status = SecItemCopyMatching(matchQuery, nil)
        return status == errSecSuccess
    }
}
