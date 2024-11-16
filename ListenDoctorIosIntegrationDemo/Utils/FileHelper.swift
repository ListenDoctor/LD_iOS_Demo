//
//  FileHelper.swift
//  ListenDoctorIosIntegrationDemo
//
//  Created on 12/11/24.
//

import Foundation
import UniformTypeIdentifiers

struct FileHelper {
    
    static func getAppDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    static func copyFileToTemporaryDirectory(from originalURL: URL) -> URL? {
        
        let fileManager = FileManager.default
        
        // Check if we can access the file securely
        guard originalURL.startAccessingSecurityScopedResource() else {
            log(.files, .error, "Unable to access security-scoped resource.")
            return nil
        }
        
        defer {
            // Stop accessing the resource after we're done
            originalURL.stopAccessingSecurityScopedResource()
        }
        
        // Generate a unique URL in the temporary directory
        let temporaryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(originalURL.pathExtension)
        
        do {
            // Copy the file to the temporary location
            try fileManager.copyItem(at: originalURL, to: temporaryURL)
            return temporaryURL
        } catch {
            log(.files, .error, "Failed to copy file to temporary directory: \(error)")
            return nil
        }
    }
    
    static func deleteFile(at url: URL) {
        
        let fileManager = FileManager.default
        
        do {
            // Remove the file at the specified URL
            try fileManager.removeItem(at: url)
        } catch {
            log(.files, .error, "Failed to delete file at URL: \(url)")
        }
    }
    
    static func mimeType(for url: URL) -> String? {
        // Obtain the file extension from the URL
        let fileExtension = url.pathExtension
        
        // Ensure the file extension is not empty
        guard !fileExtension.isEmpty else { return nil }
        
        // Create a UTType from the file extension
        if let utType = UTType(filenameExtension: fileExtension) {
            // Retrieve the MIME type from the UTType
            return utType.preferredMIMEType
        }
        
        return nil
    }
}
