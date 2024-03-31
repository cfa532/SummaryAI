//
//  RoundButton.swift
//  SummaryAI
//
//  Created by 超方 on 2024/3/24.
//

import SwiftUI

struct RecorderButton: View {
    @Binding var isRecording: Bool
    let buttonAction: ()->Void
    
    var body: some View {
        Button(action: {
            buttonAction()
        }, label: {
            Text(self.isRecording ? "Stop":"Start")
                .padding(24)
                .font(.title)
                .background(Color.white)
                .foregroundColor(.red)
                .clipShape(Circle())
                .shadow(radius: 5)
        })
    }
}

#Preview {
    //    RoundButton(image: Image(systemName: "stop.circle"))
    RecorderButton(isRecording: .constant(false), buttonAction: {})
}
