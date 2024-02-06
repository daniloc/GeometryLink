//
//  GeometryLinkApp.swift
//  GeometryLink
//
//  Created by Danilo Campos on 2/6/24.
//

import SwiftUI

@main
struct GeometryLinkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }.windowStyle(.volumetric)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
