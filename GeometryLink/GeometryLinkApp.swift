//
//  GeometryLinkApp.swift
//  GeometryLink
//
//  Created by Danilo Campos on 2/6/24.
//

import SwiftUI
import RealityKitContent

@main
struct GeometryLinkApp: App {
    
    
    init() {
        RealityKitContent.InteractiveComponent.registerComponent()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }.windowStyle(.volumetric)
    

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
