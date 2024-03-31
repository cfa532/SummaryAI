//
//  SummaryAIApp.swift
//  SummaryAI
//
//  Created by 超方 on 2024/3/19.
//

import SwiftUI

@main
struct SummaryAIApp: App {
    @StateObject private var store = TranscriptStore()
    @State private var errorWrapper: ErrorWrapper?
    
    var body: some Scene {
        WindowGroup {
            TranscriptView(store: store)
            .task {
                do {
                    try await store.load()
                } catch {
                    errorWrapper = ErrorWrapper(error: error, guidance: "Data temporarily unavailable")
                }
            }
            .sheet(item: $errorWrapper) {
                store.records = AudioRecord.sampleData
            } content: { wrapper in
                    ErrorView(errorWrapper: wrapper)
            }
        }
    }
}
