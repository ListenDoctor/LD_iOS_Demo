//
//  Template.swift
//  ListenDoctorIosIntegrationDemo
//
//  Created on 5/11/24.
//

import Foundation
import SwiftData

@Model
final class Template: Decodable {
    
    var guid: String?
    var name: String
    var template: String
    var speciality: Int
    var category: String
    var created: Int
    
    init(guid: String?, name: String, template: String, speciality: Int, category: String, created: Int) {
        self.guid = guid
        self.name = name
        self.template = template
        self.speciality = speciality
        self.category = category
        self.created = created
    }
    
    // Custom Decodable conformance
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.guid = try container.decodeIfPresent(String.self, forKey: .guid)
        self.name = try container.decode(String.self, forKey: .name)
        self.template = try container.decode(String.self, forKey: .template)
        self.speciality = try container.decode(Int.self, forKey: .speciality)
        self.category = try container.decode(String.self, forKey: .category)
        self.created = try container.decode(Int.self, forKey: .created)
    }
    
    // Define the CodingKeys to match property names
    enum CodingKeys: String, CodingKey {
        case guid
        case name
        case template
        case speciality
        case category
        case created
    }
}
