# Prototype: Sync Blender mesh to Vision Pro with gesture handling



https://github.com/daniloc/GeometryLink/assets/213358/702011d1-5c38-4697-8b04-843f1576f416



This project uses WebSockets to transmit the selected mesh in Blender to Vision Pro, with interactive gestures.

## Usage

- Install `Blender Plugin.zip` as an add-on in Blender
- Edit `connect()` in `ContentView.swift` with the hostname of the machine running Blender
- Build/Run to Simulator or a Vision Pro device
- Select a mesh in Blender. It should appear in the Vision Pro volume. You can grab and scale it with your hands.

## ⚠️☣️ The python code is bad!

I've shipped almost no python in my life. The add-in is the product of extended collaboration with an LLM and **should be re-written by someone who knows how to write python network code**.

**Do not reuse the python code**. Feel free to open a PR with replacement, non-toxic python code.

## Pipline

### Server
- Mesh is selected in Blender
- The mesh is converted locally to USD
- USD file is converted to base64 string and sent over WebSocket

### Client
- base64 string is received and converted back into USD file
- USD file is imported as a RealityKit entity and attached as a child to an anchor entity

## Known issues

- There's a bit of a hang on closing Blender, owing the bad python code
- Can't figure out how to make Bonjour work, but partial implementations are included; the service is broadcasting, but none of the details seem to populate. PR's welcome there too.
- There's an upper limit on mesh complexity; chunking or some other strategy should be implemented to allow bigger files to be transferred over WebSocket
- I'm sure there's a better way to manage package dependencies in Blender's python; feel free to propose one!

## Missing Apple code

Gesture handling borrows heavily from a file that used to exist at this URL but has since vanished:

https://developer.apple.com/documentation/realitykit/transforming-realitykit-entities-with-gestures

The docs/project had a bug around programmatically attaching the gesture, so maybe they're reworking it.
