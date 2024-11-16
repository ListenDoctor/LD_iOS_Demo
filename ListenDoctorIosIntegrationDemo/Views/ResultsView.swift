//
//  SummaryView.swift
//  ListenDoctorIosIntegrationDemo
//
//  Created on 12/11/24.
//

import SwiftUI

/**
 * A view to display a transcription or a summary
 */
struct ResultsView: View {
    
    @Binding var text: String
    @State var title: String = ""
    @State private var markdownText: LocalizedStringKey = ""
    
    var body: some View {
        VStack {
            Text(title)
                .font(.title)
                .fontWeight(.semibold)
                .padding(.vertical, 10)
                .foregroundColor(.ldBlue)
            
            Text(markdownText)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 10)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onChange(of: text) { old, new in
            markdownText = LocalizedStringKey(new.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        .onAppear {
            markdownText = LocalizedStringKey(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}

#Preview {
    ResultsView(text: .constant("This is a summary"), title: "Summary")
}
