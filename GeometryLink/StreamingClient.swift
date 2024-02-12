//
//  StreamingClient.swift
//  GeometryLink
//
//  Created by Danilo Campos on 2/6/24.
//

import SwiftUI
import RealityKit

import Foundation


@Observable class WebSocketClient: NSObject, StreamDelegate {
    
    var readStream: Unmanaged<CFReadStream>?
    var writeStream: Unmanaged<CFWriteStream>?
    var inputStream: InputStream?
    var outputStream: OutputStream?
    private var url: URL;
    private var port: UInt32;

    init(url: URL, port: UInt32) {
        self.url = url;
        self.port = port;
    }
    
    var entity: Entity?

    func connect() {
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (url.absoluteString as CFString), port, &readStream, &writeStream);
        print("Opening streams.")
        outputStream = writeStream?.takeRetainedValue()
        inputStream = readStream?.takeRetainedValue()
        outputStream?.delegate = self;
        inputStream?.delegate = self;
        outputStream?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default);
        inputStream?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default);
        outputStream?.open();
        inputStream?.open();
    }
    
    func disconnect(){
        print("Closing streams.");
        inputStream?.close();
        outputStream?.close();
        inputStream?.remove(from: RunLoop.current, forMode: RunLoop.Mode.default);
        outputStream?.remove(from: RunLoop.current, forMode: RunLoop.Mode.default);
        inputStream?.delegate = nil;
        outputStream?.delegate = nil;
        inputStream = nil;
        outputStream = nil;
    }


    func handleMessage(_ message: String) {
        entity = convertGeometry(from: message)
    }

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        print("stream event \(eventCode)")
        switch eventCode {
        case .openCompleted:
            print("Stream opened")
        case .hasBytesAvailable:
            if aStream == inputStream {
                var buffer = Array<UInt8>(repeating: 0, count: 1024 * 16) // Buffer size
                var totalData = Data() // Temporary storage for accumulated data

                while inputStream?.hasBytesAvailable ?? false {
                    let bytesRead = inputStream?.read(&buffer, maxLength: buffer.count) ?? 0
                    if bytesRead > 0 {
                        totalData.append(contentsOf: buffer[0..<bytesRead]) // Append new data
                    }
                }

                if totalData.count > 0, let output = String(data: totalData, encoding: .utf8) {
                    print("server said: \(output)")

                    DispatchQueue.main.async {
                        // Assuming convertGeometry(from:) is a method that processes the complete message
                        self.entity = self.convertGeometry(from: output.trimmingCharacters(in: CharacterSet(charactersIn: "\0")))
                    }
                }
            }
        case .hasSpaceAvailable:
            print("Stream has space available now")
        case .errorOccurred:
            print("\(aStream.streamError?.localizedDescription ?? "")")
        case .endEncountered:
            aStream.close()
            aStream.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
            print("close stream")
        default:
            print("Unknown event")
        }
    }


    func send(message: String){

        let response = "msg:\(message)"
        let buff = [UInt8](message.utf8)
        if let _ = response.data(using: .ascii) {
            outputStream?.write(buff, maxLength: buff.count)
        }

    }

}
