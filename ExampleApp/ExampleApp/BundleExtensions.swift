//
//  BundleExtensions.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 18/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation

extension Bundle {
    func dataFromFile(_ fileName: String, fileExtension: String) -> Data? {
        guard let file = self.url(forResource: fileName, withExtension: fileExtension) else {
            return nil
        }
        let data = try? Data(contentsOf: file)
        return data
    }

    func jsonFromFile(_ fileName: String) -> [String: Any]? {
        guard let data = dataFromFile(fileName, fileExtension: "json"),
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        else {
            return nil
        }
        return json
    }
}
