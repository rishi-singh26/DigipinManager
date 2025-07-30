//
//  Item.swift
//  Pinly
//
//  Created by Rishi Singh on 30/07/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
