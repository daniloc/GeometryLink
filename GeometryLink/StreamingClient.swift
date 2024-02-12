//
//  StreamingClient.swift
//  GeometryLink
//
//  Created by Danilo Campos on 2/6/24.
//

import SwiftUI
import RealityKit

import Foundation


@Observable class WebSocketClient: NSObject, URLSessionDelegate {
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var url: URL

    init(url: URL) {
        self.url = url
    }
    
    var entity: Entity?

    func connect() {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webSocketTask = session.webSocketTask(with: url)
        print("Connecting to WebSocket.")
        webSocketTask?.resume()

        receiveMessage()
    }
    
    func disconnect() {
        print("Disconnecting WebSocket.")
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Error in receiving message: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received string: \(text)")
                    DispatchQueue.main.async {
                        // Assuming convertGeometry(from:) is a method that processes the complete message
                        self?.entity = self?.convertGeometry(from: text)
                    }
                    self?.receiveMessage() // Listen for the next message
                case .data(let data):
                    print("Received data: \(data)")
                    self?.receiveMessage() // Listen for the next message
                @unknown default:
                    fatalError()
                }
            }
        }
    }

    func send(message: String) {
        webSocketTask?.send(.string(message)) { error in
            if let error = error {
                print("Error in sending message: \(error)")
            }
        }
    }
}
