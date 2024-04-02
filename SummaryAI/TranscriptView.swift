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
    @Binding var errorWrapper: ErrorWrapper?
    
    private let recorderTimer = RecorderTimer()
    private let speechRecognizer = SpeechRecognizer()
    private let websocket = Websocket("ws://52.221.183.236:8505")
    
    var body: some View {
//        Text("Summary AI")
//            .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
//            .padding(.top)
        NavigationStack {
            List(store.records) { record in
                NavigationLink(destination: DetailView(record: record)) {
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
                speechRecognizer.startTranscribing()
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
        
        // body of action() closure
        isRecording = false
        sendToAI(speechRecognizer.transcript) { summary in
            
            // check if today's record exists
            let curDate: String = AudioRecord.recordDateFormatter.string(from: Date())
            Task {
                if let index = store.records.firstIndex(where: {curDate == AudioRecord.recordDateFormatter.string(from: $0.recordDate)}) {
                    //            index.transcript +=  speechRecognizer.transcript    // doesn't work
                    store.records[index].transcript += speechRecognizer.transcript
                    store.records[index].summary = summary
                } else {
                    let curRecord = AudioRecord(transcript: speechRecognizer.transcript, summary: curDate+": "+summary)
                    store.records.insert(curRecord, at: 0)
                }
                do {
                    try await store.save(records: store.records)
                } catch {
                    errorWrapper = ErrorWrapper(error: error, guidance: "Try to save again later")
                }
            }
        }
    }
    
    func sendToAI(_ rawText: String, action: @escaping (_: String)->Void) {
        do {
            // Convert the dictionary to Data
            let msg = ["input":["query": "重复一遍下面的话。 "+rawText], "parameters":["llm":"openai","temperature":"0.0"]] as [String : Any]
            //            let msg = ["input":["query": "提取下述文字的摘要，并添加适当标点符号。如果无法提取，就回答无法提取。 "+rawText], "parameters":["llm":"openai","temperature":"0.0"]] as [String : Any]
            let jsonData = try JSONSerialization.data(withJSONObject: msg)
            
            // Convert the Data to String
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
                websocket.send(jsonString) { error in
                    errorWrapper = error
                }
                websocket.receive(action: action)
                websocket.resume()
            }
        } catch {
            print("Error converting dictionary to string: \(error)")
        }
    }
    
    //    let dict: JSONDictionary = ["foo": 1, "bar": 2, "baz": 3]
    //    let dictAsString = asString(jsonDictionary: dict)
}

#Preview {
    TranscriptView(store: TranscriptStore(), errorWrapper: .constant(.emptyError))
}
