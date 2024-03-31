//
//  AudioRecorder.swift
//  SummaryAI
//
//  Created by 超方 on 2024/3/20.
//

import Foundation
import AVFoundation

class AudioRecorder: Observable {
    
    static let recordingSettings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
    static let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    var speechRecognizer = SpeechRecognizer()
    var mic: AVAudioRecorder?
    var timer: Timer?
//    var startTimer: (() -> Void)?
    
    func setupRecorder(_ fileName: String) {
        let audioFilename = AudioRecorder.documentPath.appendingPathComponent(fileName)
        do {
            mic = try AVAudioRecorder(url: audioFilename, settings: AudioRecorder.recordingSettings)
            mic?.prepareToRecord()
        } catch {
            print("Problem setting up audio recorder")
        }
    }
    
    func startRecording() {
        if mic?.isRecording == nil {
            setupRecorder( String(Int(Date().timeIntervalSince1970)) + ".m4a" )
            mic?.record()

            let startTimer = {
                var silenceTimespan = 0.0
                let timeInterval = 1.0
                self.timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
                    self.mic?.updateMeters()
                    let power = self.mic?.averagePower(forChannel: 0)
                    
                    if power! < -30 {        // adjust the value as needed
                        silenceTimespan += timeInterval
                        if silenceTimespan > 300 {
                            print("No conversation detected for 5 mins")
                            self.mic?.stop()
                            
                            // send the recording file to voice-text conversion
                        }
                    } else {
                        silenceTimespan = 0.0
                        // restart recording if stopped internally, with a new file name
                        if self.mic?.isRecording == nil {
                            self.setupRecorder( String(Int(Date().timeIntervalSince1970)) + ".m4a" )
                            self.mic?.record()
                        }
                    }
                }
            }
            startTimer()
        }
    }
    
    func stopRecording() {
        mic?.stop()
        timer?.invalidate()
        timer = nil
        
        // send the recording file to voice-text conversion
    }
}
