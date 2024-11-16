//
//  ListenDoctorIosIntegrationDemoApp.swift
//  ListenDoctorIosIntegrationDemo
//
//  Created on 4/11/24.
//

import SwiftUI
import SwiftData

@main
struct ListenDoctorIosIntegrationDemoApp: App {
    
    static let apiKey = "<YOUR_API_KEY>"
    static let clientId = "<YOUR_CLIENT_ID>"
    static let clientSecret = "<YOUR_CLIENT_SECRET>"
    static let doctorId = "<YOUR_DOCTOR_ID>"
    
    @StateObject private var apiManager = APIManager(apiKey: ListenDoctorIosIntegrationDemoApp.apiKey)
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Speciality.self, Template.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @MainActor
    static let previewContainer: ModelContainer = {
        do {
            
            let schema = Schema([
                Template.self,
                Speciality.self,
            ])
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: configuration)
            
            for i in 1...5 {
                
                let mockTemplate = Template(guid: UUID().uuidString,
                                            name: "Sample Template \(i)",
                                            template: "This is a sample template",
                                            speciality: i,
                                            category: "General", created: Int(Date.now.timeIntervalSince1970))
                container.mainContext.insert(mockTemplate)
                
                let mockSpeciality = Speciality(code: i, prompt: "MEDICAL", en: "Sample \(i)", es: "Ejemplo \(i)", fr: "Exemple \(i)", de: "Beispiel \(i)", it: "Esempio \(i)", ca: "Exemple \(i)", pt: "Exemplo \(i)")
                container.mainContext.insert(mockSpeciality)
            }
            return container
        } catch {
            fatalError("Failed to create preview container: \(error.localizedDescription)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(apiManager)
        }
        .modelContainer(sharedModelContainer)
    }
}

