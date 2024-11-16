//
//  UploadFileAPIView.swift
//  ListenDoctorIosIntegrationDemo
//
//  Created on 12/11/24.
//

import SwiftUI
import SwiftData

/**
 * A view to make a recording or upload an audio file to receive a transcription and a summary of it
 */
struct UploadFileAPIView: View {
    
    @Environment(\.modelContext) private var context
    @EnvironmentObject var apiManager: APIManager
    @EnvironmentObject var recorderManager: AudioManager
    
    @Binding var isDocumentPickerPresented: Bool
    @Binding var selectedDocumentURL: URL?
    
    @Binding var isConnecting: Bool
    @Binding var summary: String
    @Binding var transcription: String
    
    enum UploadType {
        case recording
        case document
    }
    @State private var uploadType: UploadType = .recording
    
    var body: some View {
        VStack {
            
            HStack {
                
                Button {
                    
                    withAnimation {
                        uploadType = .recording
                        if recorderManager.isRecording {
                            recorderManager.stopRecording(success: true)
                            recorderManager.isRecording = false
                        } else {
                            transcription = ""
                            summary = ""
                            recorderManager.startRecordingToFile()
                            recorderManager.isRecording = true
                        }
                    }
                    
                } label: {
                    
                    VStack {
                        
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "waveform.badge.microphone")
                                .symbolRenderingMode(.multicolor)
                                .symbolEffect(.variableColor.iterative.hideInactiveLayers.nonReversing, options: recorderManager.isRecording ? .repeat(.periodic) : .nonRepeating, value: recorderManager.isRecording)
                                .font(.largeTitle)
                            
                            Text(recorderManager.isRecording ? "Tap again to finish" : "Record audio")
                            Spacer()
                        }
                        Spacer()
                    }
                }
                
                Spacer()
                
                Button {
                    
                    withAnimation {
                        uploadType = .document
                        transcription = ""
                        summary = ""
                        isDocumentPickerPresented = true
                    }
                    
                } label: {
                    
                    VStack {
                        
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "document.badge.plus")
                                .font(.largeTitle)
                            
                            Text("Select file")
                            Spacer()
                        }
                        Spacer()
                    }
                }
                .disabled(recorderManager.isRecording)
            }
            .buttonStyle(.borderedProminent)
            
            if !recorderManager.isRecording,
               recorderManager.recordingUrl != nil,
               uploadType == .recording
            {
                Text("Recording ready to sent")
                    .font(.callout)
                    .foregroundColor(.ldGreen)
                
                SendAndProcessButtonView(isProcessing: $isConnecting) {
                    
                    isConnecting = true
                    recorderManager.playRecordedFile()
                    sendAudioFileForTranscription()
                }
                .disabled(isConnecting)
                
            } else if let selectedDocumentURL,
                      let tmpUrl = FileHelper.copyFileToTemporaryDirectory(from: selectedDocumentURL),
                        uploadType == .document
            {
                
                Text("Selected **\(selectedDocumentURL.lastPathComponent)**")
                    .font(.callout)
                    .foregroundColor(.ldGreen)
                
                SendAndProcessButtonView(isProcessing: $isConnecting) {
                    
                    isConnecting = true
                    sendAudioFileForTranscription(tmpUrl)
                }
                .disabled(isConnecting)
            }
        }
        .onChange(of: uploadType) { oldValue, newValue in
            
            transcription = ""
            summary = ""
        }
    }
    
    func sendAudioFileForTranscription(_ url: URL? = nil) {
        
        Task {
            
            do {
                
                let specialityCode = UserDefaults.getSelectedSpeciality() ?? 0
                let specialityPredicate = FetchDescriptor<Speciality>(predicate: #Predicate { $0.code == specialityCode })
                let speciality = try context.fetch(specialityPredicate).first
                
                guard let speciality else {
                    
                    return
                }
                
                let df = DateFormatter()
                df.dateFormat = "dd MMMM yyyy, HH:mm"
                let response = try await apiManager.processAudio(fileURL: url ?? recorderManager.recordingUrl,
                                                                 prompt: speciality.prompt,
                                                                 language: UserDefaults.getSelectedLanguage() ?? "EN",
                                                                 speciality: speciality.code,
                                                                 category: "V",
                                                                 datetime: df.string(from: Date.now))
                
                summary = response.summary
                transcription = response.transcription
                isConnecting = false
                
            } catch {
                
                log(.persistency, .error, "Error : \(error)")
            }
        }
    }
}

#Preview {
    
    UploadFileAPIView(isDocumentPickerPresented: .constant(false),
                      selectedDocumentURL: .constant(nil),
                      isConnecting: .constant(false),
                      summary: .constant("A summary"),
                      transcription: .constant("A transcription"))
        .environmentObject(APIManager(apiKey: ListenDoctorIosIntegrationDemoApp.apiKey))
        .environmentObject(AudioManager())
        .frame(height: 200)
}
