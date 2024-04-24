//
//  Extension+Array.swift
//  OTFMagicBox
//
//  Created by Waqas Khadim on 07/09/2023.
//

import Sodium

extension Array {
    func splitFile() -> (left: [Element], right: [Element]) {
            let size = self.count
            let splitIndex = SecretStream.XChaCha20Poly1305.HeaderBytes
            let leftSplit = self[0 ..< splitIndex]
            let rightSplit = self[splitIndex ..< size]
     
            return (left: Array(leftSplit), right: Array(rightSplit))
        }
}
