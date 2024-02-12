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
    
    @State var client = WebSocketClient(url: URL(string: "ws://10.0.1.247:8765")!)
    @State var oldEntity: Entity?
    @State var anchor: Entity?

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    

    var body: some View {
        VStack {
            RealityView { content in
                // Add the initial RealityKit content
                if let anchorScene = try? await Entity(named: "Anchor", in: realityKitContentBundle) {
                    content.add(anchorScene)
                    self.anchor = anchorScene.findEntity(named: "InteractionAnchor")
                }
            } update: { content in

                if let entity = client.entity, entity.parent == nil {
                    entity.setParent(self.anchor)
                    entity.setPosition([0,0,0], relativeTo: self.anchor)
                    entity.setScale([0.1,0.1,0.1], relativeTo: self.anchor)
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
        .onChange(of: self.client.entity, { oldValue, newValue in
            oldValue?.removeFromParent()
        })
        .onAppear {
            client.connect()
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
