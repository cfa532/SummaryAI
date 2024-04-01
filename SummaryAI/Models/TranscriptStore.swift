//
//  TranscriptStore.swift
//  SummaryAI
//
//  Created by 超方 on 2024/3/28.
//

import SwiftUI

@MainActor
class TranscriptStore: ObservableObject {
    
    @Published var records: [AudioRecord] = []
    
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("audioRecords.data")
    }
    
    func load() async throws {
        let task = Task<[AudioRecord], Error> {
            let fileUrl = try Self.fileURL()
            guard let data = try? Data(contentsOf: fileUrl) else {
                return []
            }
            let records = try JSONDecoder().decode([AudioRecord].self, from: data)
            return records
        }
        let records = try await task.value
        self.records = records
    }
    
    func save(records: [AudioRecord]) async throws {
        let task = Task {
            let data = try JSONEncoder().encode(records)
            let outfile = try Self.fileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }
}
