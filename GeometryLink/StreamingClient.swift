import SwiftUI
import RealityKit
import Foundation
import Network

@Observable class WebSocketClient: NSObject, URLSessionDelegate, NetServiceBrowserDelegate, NetServiceDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private var browser: NWBrowser?
    private var resolver: NWConnection?
    private var session: URLSession?

    override init() {
        super.init()
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
    }
    
    var entity: Entity?

    func startDiscovery() {
            let parameters = NWParameters()
            parameters.includePeerToPeer = true
            let browser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: "local"), using: parameters)
            
            browser.stateUpdateHandler = { newState in
                switch newState {
                case .ready:
                    print("Browser ready")
                case .failed(let error):
                    print("Browser failed with \(error)")
                default:
                    break
                }
            }
            
            browser.browseResultsChangedHandler = { results, changes in
                for result in results {
                    switch result.endpoint {
                    case let .service(name: name, type: _, domain: _, interface: _):
                        if name == "BlenderGeometryLink" {
                            self.resolve(endpoint: result.endpoint)
                        }
                    default:
                        continue
                    }
                }
            }
            
            self.browser = browser
            browser.start(queue: .main)
        }
        
    func resolve(endpoint: NWEndpoint) {
        let resolver = NWConnection(to: endpoint, using: .tcp)
        let timeoutInterval = 10.0  // 10 seconds
        let timeoutWorkItem = DispatchWorkItem {
            resolver.cancel()
            print("Connection attempt timed out.")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutInterval, execute: timeoutWorkItem)

        resolver.stateUpdateHandler = { state in
            switch state {
            case .ready:
                timeoutWorkItem.cancel()  // Cancel the timeout if the connection becomes ready
                print("Resolved: \(resolver.endpoint)")
                // Proceed with connection setup...
            case .failed(let error):
                print("Resolution failed with error: \(error)")
            default:
                break
            }
        }
        resolver.start(queue: .main)
    }
        
        func connect(url: URL) {
            webSocketTask = session?.webSocketTask(with: url)
            print("Connecting to WebSocket at \(url).")
            webSocketTask?.resume()
            receiveMessage()
        }
    
    func connectDirectly(to host: String, port: UInt16) {
        disconnect()
        guard let url = URL(string: "ws://\(host):\(port)") else {
            print("Invalid URL")
            return
        }
        connect(url: url)
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
