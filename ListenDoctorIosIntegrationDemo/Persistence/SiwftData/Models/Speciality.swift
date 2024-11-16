//
//  Speciality.swift
//  ListenDoctorIosIntegrationDemo
//
//  Created on 5/11/24.
//

import Foundation
import SwiftData

@Model
final class Speciality: Decodable {
    
    var code: Int
    var prompt: String
    var en: String
    var es: String
    var fr: String
    var de: String
    var it: String
    var ca: String
    var pt: String
    
    // Custom initializer for Decodable conformance
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.code = try container.decode(Int.self, forKey: .code)
        self.prompt = try container.decode(String.self, forKey: .prompt)
        self.en = try container.decode(String.self, forKey: .en)
        self.es = try container.decode(String.self, forKey: .es)
        self.fr = try container.decode(String.self, forKey: .fr)
        self.de = try container.decode(String.self, forKey: .de)
        self.it = try container.decode(String.self, forKey: .it)
        self.ca = try container.decode(String.self, forKey: .ca)
        self.pt = try container.decode(String.self, forKey: .pt)
    }
    
    // Define coding keys to match JSON keys
    enum CodingKeys: String, CodingKey {
        case code
        case prompt
        case en
        case es
        case fr
        case de
        case it
        case ca
        case pt
    }
    
    // Regular initializer for normal instantiation
    init(code: Int, prompt: String, en: String, es: String, fr: String, de: String, it: String, ca: String, pt: String) {
        self.code = code
        self.prompt = prompt
        self.en = en
        self.es = es
        self.fr = fr
        self.de = de
        self.it = it
        self.ca = ca
        self.pt = pt
    }
}
