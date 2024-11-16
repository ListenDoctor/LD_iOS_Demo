//
//  MissingCredentialsView.swift
//  ListenDoctorIosIntegrationDemo
//
//  Created on 12/11/24.
//


import Foundation
import SwiftUI

/**
 * Subview to display a message when credentials are missing so the user can go to Settings to set them.
 */
struct MissingCredentialsView: View {
    var body: some View {
        VStack {
            Text("Missing credentials. Make sure to **set all** your credentials in Settings")
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.red)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.red, lineWidth: 2)
                )
                
            
            NavigationLink(destination: SettingsView()) {
                Text("Go to Settings")
                    .frame(maxWidth: .infinity)
                    .padding(5)
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
   MissingCredentialsView()
}
