//
//  MediaResoulution.swift
//  ios
//
//  Created by Andrew Glaze on 7/25/21.
//

import Foundation
import M3U8Kit

extension MediaResoulution: Equatable {
    public static func == (lhs: MediaResoulution, rhs: MediaResoulution) -> Bool {
        if lhs.height == rhs.height && lhs.width == rhs.width {
            return true
        }
        return false
    }
}
