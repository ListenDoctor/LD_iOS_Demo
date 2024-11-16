//
//  SendAndProcessButtonView.swift
//  ListenDoctorIosIntegrationDemo
//
//  Created on 13/11/24.
//

import SwiftUI

/**
 * A fancy button to show for sending and processing actions.
 */
struct SendAndProcessButtonView: View {
    
    @Binding var isProcessing: Bool
    @State var action: () -> Void = {}
    
    var body: some View {
        
        Button(action: {
            
            withAnimation {
                action()
            }
            
        }) {
            
            HStack {
                Spacer()
                Image(systemName: !isProcessing ? "paperplane" : "circle.hexagonpath")
                    .font(.largeTitle)
                    .symbolEffect(.rotate.byLayer, options: isProcessing ? .repeat(.periodic) : .nonRepeating, value: isProcessing)
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(isProcessing ? .ldBlue : .white)
                
                Text(isProcessing ? "Processing..."  : "Send & process")
                    .padding(5)
                    .foregroundColor(isProcessing ? .ldBlue : .white)
                Spacer()
            }
        }
    }
}

#Preview {
    SendAndProcessButtonView(isProcessing: .constant(true))
}
