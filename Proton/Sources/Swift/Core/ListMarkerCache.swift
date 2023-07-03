//
//  File.swift
//  
//
//  Created by polaris dev on 2023/7/3.
//

import UIKit

struct ListMarkerCache {
    
    private var cacheHash: [String: UIImage] = [:]
    
    mutating func insert(for key: String, value: UIImage) {
        cacheHash[key] = value
    }
    
    func get(for key: String) -> UIImage? {
        return cacheHash[key]
    }
    
}
