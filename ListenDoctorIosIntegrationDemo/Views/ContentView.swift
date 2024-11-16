//
//  ContentView.swift
//  ListenDoctorIosIntegrationDemo
//
//  Created on 4/11/24.
//


import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    
    var body: some View {
        
        NavigationStack {
            
            ScrollView {
                
                VStack {
                    
                    Picker("Mode", selection: $demoMode) {
                        
                        ForEach(DemoMode.allCases, id: \.self) { mode in
                            Text(mode.description)
                                .padding(5)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .buttonStyle(.bordered)
                    .tint(.ldGreen)
                    .onChange(of: demoMode) { old, new in
                        
                        allowedContentTypes = new.allowedContentTypes
                        resetDemo()
                    }
                    
                    if isMissingCredentials {
                        
                        MissingCredentialsView()
                    }
                    
                    if !isMissingCredentials, token == nil {
                        
                        Button(action: {
                            
                            fetchTokenWithCredentials()
                            
                        }) {
                            Text("FETCH TOKEN")
                                .frame(maxWidth: .infinity)
                                .padding(5)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isConnecting || token != nil)
                    }
                    
                    Spacer()
                    
                    if let _ = token {
                        
                        switch demoMode {
                        case .summaryTranscriptionFromRecording:
                            
                            UploadFileAPIView(isDocumentPickerPresented: $isDocumentPickerPresented,
                                              selectedDocumentURL: $selectedDocumentURL,
                                              isConnecting: $isConnecting,
                                              summary: $summary,
                                              transcription: $transcription)
                                .environment(recorderManager)
                            
                            if !transcription.isEmpty {
                                
                                Spacer()
                                ResultsView(text: $transcription, title: "Transcription")
                            }
                            
                            if !summary.isEmpty {
                                
                                Spacer()
                                ResultsView(text: $summary, title: "Summary")
                            }
                            
                        case .analyzeLabDocument:
                            
                            UploadLabDocAPIView(isDocumentPickerPresented: $isDocumentPickerPresented,
                                                selectedDocumentURL: $selectedDocumentURL,
                                                isConnecting: $isConnecting,
                                                summary: $summary)
                                .environment(recorderManager)
                                
                            if !summary.isEmpty {
                                
                                Spacer()
                                ResultsView(text: $summary, title: "Lab Results")
                            }
                            
                        case .streamSockets:
                            
                            StreamAudioView(token: $token)
                                .environment(recorderManager)
                                .environment(wsManager)
                                .onChange(of: wsManager.summary) { old, new in
                                    summary = new
                                }
                                .onChange(of: wsManager.transcription) { old, new in
                                    transcription = new
                                }
                            
                            if !wsManager.transcription.isEmpty {
                                
                                Spacer()
                                ResultsView(text: $transcription, title: "Transcription")
                            }
                            
                            if !wsManager.summary.isEmpty {
                                
                                Spacer()
                                ResultsView(text: $summary, title: "Summary")
                            }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.ldBlue)
                .padding()
            }
            .navigationTitle("Listen.Doctor Demo")
            .navigationBarTitleTextColor(.ldBlue)
            .toolbar {
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    
                    Button("Reset", systemImage: "arrow.counterclockwise") {
                        
                        resetDemo()
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        Button("Settings", systemImage: "gearshape") { }
                    }
                }
                
                ToolbarItemGroup(placement: .topBarLeading) {
                    
                    Image("ic_ld_colored")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 85, height: 50)
                }
            }
            .sheet(isPresented: $isDocumentPickerPresented) {
                DocumentPickerView(selectedURL: $selectedDocumentURL, allowedContentTypes: allowedContentTypes)
            }
            .onAppear {
                wsManager = WSManager(url: apiManager.baseURL)
                checkCredentials()
            }
        }
        .tint(.ldBlue)
    }
    
    func fetchTokenWithCredentials() {
        
        isConnecting = true
        Task {
            
            do {
                try await apiManager.authenticate(clientId: ListenDoctorIosIntegrationDemoApp.clientId, clientSecret: ListenDoctorIosIntegrationDemoApp.clientSecret, doctorId: ListenDoctorIosIntegrationDemoApp.doctorId)
                token = apiManager.token
                let templates = try await apiManager.getPublicTemplates()
                let specialities = try await apiManager.getSpecialities()
                
                log(.api, .info, "Templates: \(templates)\n\nSpecialities: \(specialities)")
                
                do {
                    
                    try context.delete(model: Template.self)
                    try context.delete(model: Speciality.self)
                    try context.save()
                    
                } catch {
                    
                    log(.persistency, .error, "Failed to delete old instances of Template and Speciality: \(error)")
                }
                
                templates.values.first?.forEach { context.insert($0) }
                specialities.values.first?.forEach { context.insert($0) }
                
            } catch {
                
                log(.api, .error, "Error: \(error)")
            }
            
            isConnecting = false
        }
    }
    
    /**
     * Checks user defaults for stored credentials otherwise looks for the hardcoded ones and
     * checks if they are not empty
     */
    func checkCredentials() {
        
        let apiKey = UserDefaults.getApiKey() ?? ListenDoctorIosIntegrationDemoApp.apiKey
        let clientId = UserDefaults.getClientID() ?? ListenDoctorIosIntegrationDemoApp.clientId
        let clientsSecret = UserDefaults.getClientSecret() ?? ListenDoctorIosIntegrationDemoApp.clientSecret
        let doctorId = UserDefaults.getDoctorID() ?? ListenDoctorIosIntegrationDemoApp.doctorId
        
        guard
            !apiKey.isEmpty,
            !clientId.isEmpty,
            !clientsSecret.isEmpty,
            !doctorId.isEmpty
        else {
            
            isMissingCredentials = true
            return
        }
        
        isMissingCredentials = false
    }
    
    func resetDemo() {
        
        withAnimation {
            
            isConnecting = false
            token = nil
            wsManager.disconnect()
            recorderManager.stopRecording(success: false)
            summary = ""
            transcription = ""
            selectedDocumentURL = nil
        }
    }
    
    // MARK: - Environment
    @Environment(\.modelContext) private var context
    @EnvironmentObject var apiManager: APIManager
    
    // MARK: - API variables
    @State private var token: String? = nil
    @State private var isMissingCredentials: Bool = false
    
    // MARK: - Stream sockets variables
    @State var wsManager: WSManager!
    var isSocketConnected: Bool { wsManager.isConnected }
    
    // MARK: - Audio recording variables
    @State private var recorderManager = AudioManager()
    
    @State private var transcription: String = ""
    @State private var summary: String = ""
    
    // MARK: - Demo variables
    @State private var demoMode: DemoMode = .summaryTranscriptionFromRecording
    @State private var isConnecting: Bool = false
    
    // MARK: - Document picker variables
    @State private var allowedContentTypes: [UTType] = DemoMode.summaryTranscriptionFromRecording.allowedContentTypes
    @State private var isDocumentPickerPresented = false
    @State private var selectedDocumentURL: URL?
    
    enum DemoMode: CaseIterable {
        case summaryTranscriptionFromRecording
        case streamSockets
        case analyzeLabDocument
        
        var description: String {
            switch self {
            case .summaryTranscriptionFromRecording: "API - Summarize & transcribe audio"
            case .analyzeLabDocument: "API - Analyze a lab document"
            case .streamSockets: "Stream - Summarize & transcribe audio"
            }
        }
        
        var allowedContentTypes: [UTType] {
            switch self {
            case .summaryTranscriptionFromRecording: return [.wav, .mpeg4Audio, .mp3]
            case .analyzeLabDocument: return [.jpeg, .png, .pdf]
            case .streamSockets: return []
            }
        }
    }
}

struct ConnectionView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(APIManager(apiKey: ListenDoctorIosIntegrationDemoApp.apiKey))
    }
}
