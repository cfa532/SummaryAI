//
//  Websocket.swift
//  SummaryAI
//
//  Created by 超方 on 2024/4/2.
//

import Foundation

@MainActor
@Observable
class Websocket: NSObject, URLSessionWebSocketDelegate {
    
    private var urlSession: URLSession?
    var task: URLSessionWebSocketTask?
    var message: String = ""
    var errorWrapper: ErrorWrapper? = nil
    
    init(_ url: String) {
        super.init()
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        self.task = urlSession!.webSocketTask(with: URL(string: url)!)
    }
    
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
    }
    
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket disconnected")
    }
    
    func send(_ jsonString: String, errorWrapper: @escaping (_: ErrorWrapper)->Void) {
        task?.send(.string(jsonString)) { error in
            if let error = error {
                print("Websocket.send() failed")
                errorWrapper(ErrorWrapper(error: error, guidance: "Failed to send to Websocket"))
                //                self.errorWrapper = ErrorWrapper(error: error, guidance: "Failed to send to Websocket")
            }
        }
    }
    
    func receive(action: @escaping (_: String) -> Void) {
        // expecting {"type": "result", "answer": "summary content"}
        task?.receive( completionHandler: { result in
            switch result {
            case .failure(let error):
                print("WebSocket received an error: \(error)")
                self.task?.cancel()
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received text: \(text)")
                    if let data = text.data(using: .utf8) {
                        do {
                            if let dict = try JSONSerialization.jsonObject(with: data) as? NSDictionary {
                                if let type = dict["type"] as? String {
                                    if type == "result" {
                                        if let answer = dict["answer"] as? String {
                                            action(answer)
                                            self.task?.cancel()
                                        }
                                    } else {
                                        self.receive(action: action)
                                    }
                                }
                            }
                        } catch {
                            print("Invalid Json string received.")
                            self.task?.cancel()
                        }
                    }
                case .data(let data):
                    print("Received data: \(data)")
                    self.task?.cancel()
                @unknown default:
                    print("Unknown data")
                    self.task?.cancel()
                }
            }
        })
    }
    
    func resume() {
        task?.resume()
    }
    
    func cancel() {
        task?.cancel(with: .goingAway, reason: nil)
    }
}
