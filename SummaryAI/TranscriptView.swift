//
//  ContentView.swift
//  SummaryAI
//
//  Created by 超方 on 2024/3/19.
//

import SwiftUI
import AVFoundation

struct TranscriptView: View {
    @StateObject var store: TranscriptStore
    @State private var isRecording = false
    @State private var errorWrapper: ErrorWrapper? = nil

    private let recorderTimer : RecorderTimer = RecorderTimer()
    private let speechRecognizer = SpeechRecognizer()
    
    var body: some View {
//        Text("Summary AI")
//            .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
//            .padding(.top)
        NavigationStack {
            List($store.records) { $record in
                NavigationLink(destination: DetailView(record: $record)) {
                    Text(record.summary)
                }
            }
            .navigationTitle("Summary AI")
            .navigationBarTitleDisplayMode(.inline)
        }
        //        .padding()
        
        RecorderButton(isRecording: $isRecording) {
            isRecording.toggle()
            if isRecording {
                print("start timer")
                recorderTimer.delegate = self
                recorderTimer.startTimer() {
                    
                    // body of isSilent()
                    print("audio level=", SpeechRecognizer.currentLevel)
                    if SpeechRecognizer.currentLevel < 0.1 {
                        return true
                    } else {
                        return false
                    }
                }
//                speechRecognizer.startTranscribing()
            } else {
                print("stop recordering")
                speechRecognizer.stopTranscribing()
                recorderTimer.stopTimer()
            }
        }
    }
}

extension TranscriptView: TimerDelegate {
    func timerStopped() {
        isRecording = false
        
        // check if today's record exists
        let curDate = AudioRecord.recordDateFormatter.string(from: Date())
        if var curRecord = store.records.first(where: {curDate == AudioRecord.recordDateFormatter.string(from: $0.recordDate)}) {
            curRecord.transcript += speechRecognizer.transcript
        } else {
            let curRecord = AudioRecord(transcript: speechRecognizer.transcript, summary: "summary of the day")
            store.records.insert(curRecord, at: 0)
        }
        Task {
            do {
                try await store.save(records: store.records)
            } catch {
                errorWrapper = ErrorWrapper(error: error, guidance: "Try to save again later")
            }
        }
    }
}

#Preview {
    TranscriptView(store: TranscriptStore())
}
