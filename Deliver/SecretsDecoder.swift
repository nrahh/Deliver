//
//  SecretsDecoder.swift
//  Deliver
//
//  Created by asd on 7/17/26.
//

import Foundation

enum Secrets {
    static var mongodbAPIKey: String {
        guard let key = Bundle.main.infoDictionary?["MONGODB_API_KEY"] as? String else {
            fatalError("mongodb api key not found")
        }
        return key
    }
}
