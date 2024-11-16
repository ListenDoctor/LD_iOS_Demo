//
//  StreamAudioView.swift
//  ListenDoctorIosIntegrationDemo
//
//  Created on 12/11/24.
//

import SwiftUI
import SwiftData

/**
 * View to stream audio and get a transcription from the server
 */
struct StreamAudioView: View {
    
    @Environment(\.modelContext) private var context
    @EnvironmentObject var apiManager: APIManager
    @EnvironmentObject var recorderManager: AudioManager
    @EnvironmentObject var wsManager: WSManager
    
    @Binding var token: String?
    
    @State private var isWaitingResults = false
    @State private var animating = false
    
    var body: some View {
        VStack {
            if !wsManager.isConnected {
                Button(action: {
                    
                    withAnimation {
                        connectToStream()
                    }
                    
                }) {
                    Text("CONNECT SOCKET")
                        .frame(maxWidth: .infinity)
                        .padding(5)
                        .foregroundColor(.white)
                }
                .disabled(wsManager.isConnected)
            }
            
            if wsManager.isConnected {
                
                if wsManager.isInRoom {
                    
                    Button(action: {
                        
                        withAnimation {
                            
                            if recorderManager.isRecording {
                                
                                endStreamSession()
                                
                            } else {
                                
                                wsManager.summary = ""
                                wsManager.transcription = ""
                                openStreamSession()
                            }
                        }
                    }) {
                        
                        HStack {
                            
                            Spacer()
                            Image(systemName: "waveform.badge.microphone")
                                .symbolRenderingMode(.multicolor)
                                .symbolEffect(.variableColor.iterative.hideInactiveLayers.nonReversing, options: recorderManager.isRecording ? .repeat(.periodic) : .nonRepeating, value: recorderManager.isRecording)
                                .font(.largeTitle)
                            
                            Text(recorderManager.isRecording ? "Tap again to finish" : "Record audio")
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isWaitingResults)
                    .onChange(of: recorderManager.buffer) { oldValue, newValue in
                        
                        guard let last = newValue.last else { return }
                        sendChunk(last)
                    }
                    
                    if recorderManager.isRecording {
                        Text("Chunks count: \(recorderManager.buffer.count)")
                            .font(.callout)
                            .foregroundColor(.ldGreen)
                    }
                    
                    if isWaitingResults {
                        
                        SendAndProcessButtonView(isProcessing: $animating) { }
                        .disabled(true)
                        .onAppear {
                            animating = true
                        }
                    }
                }
            }
        }
        .onChange(of: wsManager.summary) { oldValue, newValue in
            
            isWaitingResults = false
            recorderManager.stopRecording(success: true)
            animating = false
        }
    }
    
    func connectToStream() {
        
        wsManager.connect(token ?? "<? Token>")
    }
    
    func openStreamSession() {
        
        do {
            
            let specialityCode = UserDefaults.getSelectedSpeciality() ?? 0
            let specialityPredicate = FetchDescriptor<Speciality>(predicate: #Predicate { $0.code == specialityCode })
            let speciality = try context.fetch(specialityPredicate).first
            
            guard let speciality else {
                
                return
            }
            
            let df = DateFormatter()
            df.dateFormat = "dd MMMM yyyy, HH:mm"
            
            recorderManager.startAudioStream()
            recorderManager.isRecording = true
            
            wsManager.startNewStream(username: UserDefaults.getDoctorID() ?? "?",
                                     fileExtension: ".\(AudioManager.AUDIO_FILE_FORMAT)",
                                     language: UserDefaults.getSelectedLanguage() ?? "EN",
                                     prompt: speciality.prompt,
                                     speciality: speciality.en,
                                     category: "V")
            
        } catch {
            
            log(.persistency, .error, "Error fetching speciality: \(error)")
            endStreamSession()
        }
    }
    
    func endStreamSession() {
        
        wsManager.endStream()
        recorderManager.stopRecording(success: true)
        recorderManager.isRecording = false
        isWaitingResults = true
    }
    
    func sendChunk(_ chunk: Data) {
        
        wsManager.sendAudioChunk(chunk)
    }
}

#Preview {
    StreamAudioView(token: .constant("<A TOKEN>"))
        .environmentObject(APIManager(apiKey: ListenDoctorIosIntegrationDemoApp.apiKey))
        .environmentObject(AudioManager())
        .environment(WSManager(url: URL(string: "https://www.google.es")!))
}
