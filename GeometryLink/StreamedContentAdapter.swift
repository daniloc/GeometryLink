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

struct GeometryData: Decodable {
    let vertices: [[Float]]
    let polygons: [[Int]]
    let name: String
    let rotation: [Float]
}


extension WebSocketClient {
    func deserializeGeometryData(from jsonString: String) -> GeometryData? {
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        do {
            let geometryData = try decoder.decode(GeometryData.self, from: jsonData)
            return geometryData
        } catch {
            print("Error decoding JSON: \(error)")
            return nil
        }
    }

    func createMDLMesh(from geometryData: GeometryData) -> MDLMesh? {
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        let allocator = MTKMeshBufferAllocator(device: device)
        
        // Use vertices directly without applying rotation
        let vertices = geometryData.vertices.map { SIMD3<Float>($0[0], $0[1], $0[2]) }
        
        // Vertex Buffer
        let vertexBuffer = allocator.newBuffer(MemoryLayout<SIMD3<Float>>.stride * vertices.count, type: .vertex)
        let vertexMap = vertexBuffer.map()
        memcpy(vertexMap.bytes, vertices, vertices.count * MemoryLayout<SIMD3<Float>>.stride)
        
        // Index Data
        let indexData = geometryData.polygons.flatMap { $0 }.map { UInt32($0) }
        let indexBuffer = allocator.newBuffer(MemoryLayout<UInt32>.stride * indexData.count, type: .index)
        let indexMap = indexBuffer.map()
        memcpy(indexMap.bytes, indexData, indexData.count * MemoryLayout<UInt32>.stride)
        
        // Creating MDLSubmesh
        let submesh = MDLSubmesh(indexBuffer: indexBuffer, indexCount: indexData.count, indexType: .uInt32, geometryType: .triangles, material: nil)
        
        // Configuring the MDLVertexDescriptor
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<SIMD3<Float>>.stride)
        
        // Creating MDLMesh with the manually configured vertex descriptor
        return MDLMesh(vertexBuffers: [vertexBuffer], vertexCount: vertices.count, descriptor: vertexDescriptor, submeshes: [submesh])
    }


    func exportMeshToUSDZ(mesh: MDLMesh, withName name: String) -> URL? {
        let asset = MDLAsset()
        asset.add(mesh)
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let usdzURL = tempDirectory.appendingPathComponent("\(UUID().uuidString).usdc")
        
        do {
            try asset.export(to: usdzURL)
            return usdzURL
        } catch {
            print("Failed to export USDZ: \(error)")
            return nil
        }
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
            let geometryData = deserializeGeometryData(from: jsonString),
            let mesh = createMDLMesh(from: geometryData),
            let usdzURL = exportMeshToUSDZ(mesh: mesh, withName: geometryData.name),
            var entity = loadEntityFromUSDZ(url: usdzURL) {
            
            // Create a simple grey material
            let greyMaterial = SimpleMaterial(color: .gray, isMetallic: false)
            
            // Iterate through each ModelEntity in the Entity hierarchy and set the grey material
            for modelEntity in entity.children.compactMap({ $0 as? ModelEntity }) {
                modelEntity.model?.materials = [greyMaterial]
            }
            
            return entity
        } else {
            return nil
        }
    }

    // Helper functions mentioned in your snippet would be defined elsewhere in your code.

    
}

extension simd_float4x4 {
    // Constructs a rotation matrix from Euler angles (radians)
    static func makeRotationMatrix(angleRadians: SIMD3<Float>) -> simd_float4x4 {
        let (cx, cy, cz) = (cos(angleRadians.x), cos(angleRadians.y), cos(angleRadians.z))
        let (sx, sy, sz) = (sin(angleRadians.x), sin(angleRadians.y), sin(angleRadians.z))

        let rx = simd_float4x4(SIMD4(1, 0, 0, 0),
                               SIMD4(0, cx, -sx, 0),
                               SIMD4(0, sx, cx, 0),
                               SIMD4(0, 0, 0, 1))

        let ry = simd_float4x4(SIMD4(cy, 0, sy, 0),
                               SIMD4(0, 1, 0, 0),
                               SIMD4(-sy, 0, cy, 0),
                               SIMD4(0, 0, 0, 1))

        let rz = simd_float4x4(SIMD4(cz, -sz, 0, 0),
                               SIMD4(sz, cz, 0, 0),
                               SIMD4(0, 0, 1, 0),
                               SIMD4(0, 0, 0, 1))

        return rz * ry * rx
    }
}
