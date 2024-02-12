//
//  StreamedContentAdapter.swift
//  GeometryLink
//
//  Created by Danilo Campos on 2/6/24.
//

import RealityKit
import Foundation
import ModelIO
import MetalKit
import simd


extension WebSocketClient {
    func deserializeGeometryData(from base64String: String) -> URL? {

        if let decodedData = Data(base64Encoded: base64String) {
            // Use the temporary directory and generate a unique filename using UUID
            let tmpDirectory = FileManager.default.temporaryDirectory
            let uuidFileName = UUID().uuidString + ".usd"
            let usdFilePath = tmpDirectory.appendingPathComponent(uuidFileName)

            do {
                // Write the decoded Data to the USD file in the temporary directory
                try decodedData.write(to: usdFilePath)
                print("USD file saved successfully at \(usdFilePath)")
                return usdFilePath
            } catch {
                print("Error saving USD file: \(error)")
            }
        } else {
            print("Error decoding base64 string")
            return nil
        }
        
        return nil
    }

    
    func loadEntityFromUSDZ(url: URL) -> Entity? {
        do {
            let entity = try Entity.load(contentsOf: url)
            return entity
        } catch {
            print("Failed to load Entity from USDZ: \(error)")
            return nil
        }
    }
    
    func convertGeometry(from jsonString: String) -> Entity? {
        if
            let geometryDataURL = deserializeGeometryData(from: jsonString),
            let entity = loadEntityFromUSDZ(url: geometryDataURL),
            let child = entity.children.first
        {
            
            return child
        } else {
            return nil
        }
    }
    
}
