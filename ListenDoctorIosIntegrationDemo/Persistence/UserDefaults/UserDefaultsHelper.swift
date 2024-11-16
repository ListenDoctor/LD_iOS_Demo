//
//  UserDefaultsHelper.swift
//  ListenDoctorIosIntegrationDemo
//
//  Created on 6/11/24.
//

import Foundation

extension UserDefaults {
    
    enum Key {
        case apiKey
        case clientID
        case clientSecret
        case doctorID
        case selectedTemplate
        case selectedSpeciality
        case selectedLanguage
        
        var value: String {
            switch self {
            case .apiKey: return "ld_apikey"
            case .clientID: return "ld_clientid"
            case .clientSecret: return "ld_clientsecret"
            case .doctorID: return "ld_doctorid"
            case .selectedTemplate: return "ld_template"
            case .selectedSpeciality: return "ld_speciality"
            case .selectedLanguage: return "ld_lang"
            }
        }
    }
}

extension UserDefaults {
    
    static func setApiKey(_ apiKey: String) {
        UserDefaults.standard.set(apiKey, forKey: Key.apiKey.value)
    }
    
    static func getApiKey() -> String? {
        return UserDefaults.standard.string(forKey: Key.apiKey.value)
    }
    
    static func removeApiKey() {
        UserDefaults.standard.removeObject(forKey: Key.apiKey.value)
    }
    
    static func setClientID(_ clientID: String) {
        UserDefaults.standard.set(clientID, forKey: Key.clientID.value)
    }
    
    static func getClientID() -> String? {
        return UserDefaults.standard.string(forKey: Key.clientID.value)
    }
    
    static func removeClientID() {
        UserDefaults.standard.removeObject(forKey: Key.clientID.value)
    }
    
    static func setClientSecret(_ clientSecret: String) {
        UserDefaults.standard.set(clientSecret, forKey: Key.clientSecret.value)
    }
    
    static func getClientSecret() -> String? {
        return UserDefaults.standard.string(forKey: Key.clientSecret.value)
    }
    
    static func removeClientSecret() {
        UserDefaults.standard.removeObject(forKey: Key.clientSecret.value)
    }
    
    static func setDoctorID(_ doctorID: String) {
        UserDefaults.standard.set(doctorID, forKey: Key.doctorID.value)
    }
    
    static func getDoctorID() -> String? {
        return UserDefaults.standard.string(forKey: Key.doctorID.value)
    }
    
    static func removeDoctorID() {
        UserDefaults.standard.removeObject(forKey: Key.doctorID.value)
    }
    
    static func setSelectedTemplate(_ templateID: String) {
        UserDefaults.standard.set(templateID, forKey: Key.selectedTemplate.value)
    }
    
    static func getSelectedTemplate() -> String? {
        return UserDefaults.standard.string(forKey: Key.selectedTemplate.value)
    }
    
    static func removeSelectedTemplate() {
        UserDefaults.standard.removeObject(forKey: Key.selectedTemplate.value)
    }
    
    static func setSelectedSpeciality(_ specialityID: Int) {
        UserDefaults.standard.set(specialityID, forKey: Key.selectedSpeciality.value)
    }
    
    static func getSelectedSpeciality() -> Int? {
        return UserDefaults.standard.integer(forKey: Key.selectedSpeciality.value)
    }
    
    static func removeSelectedSpeciality() {
        UserDefaults.standard.removeObject(forKey: Key.selectedSpeciality.value)
    }
    
    static func setSelectedLanguage(_ language: String) {
        UserDefaults.standard.set(language, forKey: Key.selectedLanguage.value)
    }
    
    static func getSelectedLanguage() -> String? {
        return UserDefaults.standard.string(forKey: Key.selectedLanguage.value)
    }
    
    static func removeSelectedLanguage() {
        UserDefaults.standard.removeObject(forKey: Key.selectedLanguage.value)
    }
}
