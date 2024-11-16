//
//  DocumentPicker.swift
//  ListenDoctorIosIntegrationDemo
//
//  Created on 6/11/24.
//


import SwiftUI
import UniformTypeIdentifiers
import UIKit

/**
 * A view that allows the user to select a file from the device's file system.
 */
struct DocumentPickerView: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    var allowedContentTypes: [UTType]

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPickerView

        init(_ pickerController: DocumentPickerView) {
            self.parent = pickerController
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let selectedURL = urls.first else { return }
            parent.selectedURL = selectedURL
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.selectedURL = nil
        }
    }
}
