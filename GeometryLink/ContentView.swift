//
//  ContentView.swift
//  GeometryLink
//
//  Created by Danilo Campos on 2/6/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @State private var enlarge = false
    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false
    
    @State var client = WebSocketClient(url: URL(string: "10.0.1.247")!, port: 8765)
    @State var oldEntity: Entity?
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    

    var body: some View {
        VStack {
            RealityView { content in
                // Add the initial RealityKit content
                if let entity = client.entity {
                    content.add(entity)
                }
            } update: { content in

                content.entities.removeAll()

                if let entity = client.entity, entity.parent == nil {
                    content.add(entity)
                }
                

            }
            .installGestures()
            
            
            VStack (spacing: 12) {
                Toggle("Enlarge RealityView Content", isOn: $enlarge)
                    .font(.title)

                Toggle("Show ImmersiveSpace", isOn: $showImmersiveSpace)
                    .font(.title)
            }
            
            .frame(width: 360)
            .padding(36)
            .glassBackgroundEffect()

        }
        .onChange(of: showImmersiveSpace) { _, newValue in
            Task {
                if newValue {
                    switch await openImmersiveSpace(id: "ImmersiveSpace") {
                    case .opened:
                        immersiveSpaceIsShown = true
                    case .error, .userCancelled:
                        fallthrough
                    @unknown default:
                        immersiveSpaceIsShown = false
                        showImmersiveSpace = false
                    }
                } else if immersiveSpaceIsShown {
                    await dismissImmersiveSpace()
                    immersiveSpaceIsShown = false
                }
            }
        }
        .onChange(of: self.client.entity, { oldValue, newValue in
            oldEntity?.removeFromParent()
            
            let component = InteractiveComponent()
            newValue?.components.set(component)
            newValue?.components.set(InputTargetComponent(allowedInputTypes: .all))
            newValue?.components.set(CollisionComponent(shapes: [.generateBox(size: [1,1,1])]))
            
        })
        .onAppear {
            client.connect()
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
