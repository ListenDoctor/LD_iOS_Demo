//
//  Data.swift
//  ListenDoctorIosIntegrationDemo
//
//  Created on 13/11/24.
//

import Foundation

extension FixedWidthInteger {
    var data: Data {
        var value = self
        return Data(bytes: &value, count: MemoryLayout.size(ofValue: value))
    }
}
