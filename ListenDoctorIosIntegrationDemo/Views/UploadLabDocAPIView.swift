//
//  UploadLabDocAPIView.swift
//  ListenDoctorIosIntegrationDemo
//
//  Created on 12/11/24.
//

import SwiftUI

/**
 * A view to upload a medical / lab document to receive a summary
 */
struct UploadLabDocAPIView: View {
    
    @Environment(\.modelContext) private var context
    @EnvironmentObject var apiManager: APIManager
    @EnvironmentObject var recorderManager: AudioManager
    
    @Binding var isDocumentPickerPresented: Bool
    @Binding var selectedDocumentURL: URL?
    @Binding var isConnecting: Bool
    @Binding var summary: String
    
    var body: some View {
        VStack {
            Button {
                
                summary = ""
                isDocumentPickerPresented = true
                
            } label: {
                
                HStack {
                    
                    Spacer()
                    Image(systemName: "document.badge.plus")
                        .font(.largeTitle)
                    
                    Text("Select file")
                    Spacer()
                }
            }
            
            if let selectedDocumentURL,
               let tmpUrl = FileHelper.copyFileToTemporaryDirectory(from: selectedDocumentURL)
            {
                Text("Selected **\(selectedDocumentURL.lastPathComponent)**")
                    .font(.callout)
                    .foregroundColor(.ldGreen)
                
                SendAndProcessButtonView(isProcessing: $isConnecting) {
                    
                    summarizeLabDocument(tmpUrl)
                }
                .disabled(isConnecting)
            }
        }
    }
    
    func summarizeLabDocument(_ url: URL) {
        
        Task {
            
            do {
                isConnecting = true
                defer {
                    isConnecting = false
                }
                let result = try await apiManager.summarizeDocument(fileURL: url, language: UserDefaults.getSelectedLanguage() ?? "EN")
                
                summary = result.summary
                
            } catch {
                
                log(.api, .error, "Error: \(error)")
            }
        }
    }
}

#Preview {
    UploadLabDocAPIView(isDocumentPickerPresented: .constant(false),
                        selectedDocumentURL: .constant(nil),
                        isConnecting: .constant(false),
                        summary: .constant("A summary of the document"))
    .environmentObject(APIManager(apiKey: ListenDoctorIosIntegrationDemoApp.apiKey))
    .environmentObject(AudioManager())
}
