//
//  Summary.swift
//  SummaryAI
//
//  Created by 超方 on 2024/3/19.
//

import Foundation

struct AudioRecord: Identifiable, Codable {
    var id: UUID
    var recordDate: Date
    var transcript: String
    var summary: String
    
    init(transcript: String, summary: String) {
        self.id = UUID()
        self.recordDate = Date()
        self.transcript = transcript
        self.summary = summary
    }
    
    static let recordDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YY/MM/dd"
        return formatter
    }()
}

extension AudioRecord {
    static let sampleData: [AudioRecord] =
    [
        AudioRecord(transcript: "Vodka is a clear distilled alcoholic beverage. Different varieties originated in Poland, Russia, and Sweden",
                    summary: "Vodka is a clear distilled alcoholic beverage.")
    ]
}
