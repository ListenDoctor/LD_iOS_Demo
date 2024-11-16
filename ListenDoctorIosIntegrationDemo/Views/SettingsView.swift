//
//  SettingsView.swift
//  ListenDoctorIosIntegrationDemo
//
//  Created on 6/11/24.

import SwiftUI
import SwiftData

/**
 * A view that allows the user to configure the application settings.
 */
struct SettingsView: View {
    
    @AppStorage(UserDefaults.Key.apiKey.value) private var apiKey: String = ListenDoctorIosIntegrationDemoApp.apiKey
    @AppStorage(UserDefaults.Key.clientID.value) private var clientId: String = ListenDoctorIosIntegrationDemoApp.clientId
    @AppStorage(UserDefaults.Key.clientSecret.value) private var clientSecret: String = ListenDoctorIosIntegrationDemoApp.clientSecret
    @AppStorage(UserDefaults.Key.doctorID.value) private var doctorId: String = ListenDoctorIosIntegrationDemoApp.doctorId
    
    @State private var selectedTemplate: Template? = nil
    @AppStorage("ld_template") private var currentTemplateID: String = ""
    
    @State private var selectedSpeciality: Speciality? = nil
    @AppStorage("ld_speciality") private var currentSpecialityID: Int = 0
    
    @AppStorage("ld_lang") private var selectedLanguage: String = "EN"
    
    @Query var templates: [Template]
    @Query var specialities: [Speciality]
    
    let languages = [
        ("English", "EN"),
        ("Spanish", "ES"),
        ("French", "FR"),
        ("German", "DE"),
        ("Italian", "IT"),
        ("Catalan", "CA"),
        ("Portuguese", "PT")
    ]
    
    var body: some View {
        Form {
            Section(header: Text("Credentials"),
                    footer: Text("These are needed to authenticate your requests. Go to https://api-beta.listen.doctor/developers for more info").multilineTextAlignment(.leading))
            {
                LabeledContent {
                    SecureField("Copy here your APIKey", text: $apiKey)
                } label: {
                    Text("API Key")
                }
                
                LabeledContent {
                    TextField("Copy here your Client ID", text: $clientId)
                } label: {
                    Text("Client ID")
                }
                
                LabeledContent {
                    SecureField("Copy here your Client Secret", text: $clientSecret)
                } label: {
                    Text("Client Secret")
                }
                
                LabeledContent {
                    TextField("Copy here your Doctor ID", text: $doctorId)
                } label: {
                    Text("Doctor ID")
                }
            }
            .multilineTextAlignment(.trailing)
            .textFieldStyle(.automatic)
            
            Section(header: Text("Preferences")) {
                Picker("Template", selection: $selectedTemplate) {
                    Text("None").tag(nil as Template?)
                    ForEach(templates) { template in
                        Text(template.name)
                            .tag(template as Template?)
                    }
                }
                .pickerStyle(.menu)
                
                Picker("Speciality", selection: $selectedSpeciality) {
                    Text("None").tag(nil as Speciality?)
                    ForEach(specialities) { speciality in
                        Text("\(speciality.en)")
                            .tag(speciality as Speciality?)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedSpeciality) { oldValue, newValue in
            
                    currentSpecialityID = newValue?.code ?? 0
                }
                
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(languages, id: \.1) { language in
                        Text("\(language.0) - \(language.1)")
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            
            selectedTemplate = templates.first(where: { $0.guid == currentTemplateID }) ?? templates.first
            selectedSpeciality = specialities.first(where: { $0.code == currentSpecialityID }) ?? specialities.first
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(ListenDoctorIosIntegrationDemoApp .previewContainer)
}
