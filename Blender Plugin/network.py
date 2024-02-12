import asyncio
import websockets
import json
import threading

# A set of connected WebSocket clients
clients = set()

# Server object
server = None
# Event loop for the server
loop = None

async def register_client(websocket):
    print("Client connected")
    clients.add(websocket)

async def unregister_client(websocket):
    clients.remove(websocket)

async def handle_client(websocket, path):
    # Register client connection
    await register_client(websocket)
    try:
        async for message in websocket:
            # Here you can process incoming messages if needed
            print(f"Received message from client: {message}")
    except websockets.exceptions.ConnectionClosed as e:
        print(f"Client disconnected with error: {e}")
    finally:
        # Unregister and clean up client connection
        await unregister_client(websocket)

async def broadcast_geometry_update_async(geometry_json):
    print(f"Attempting geometry update to {len(clients)} clients")
    if clients:  # Check if there are any clients connected
        print(f"Broadcasting geometry update {geometry_json} to {len(clients)} clients")
        await asyncio.wait([client.send(geometry_json) for client in clients])

def start_server():
    print("Starting WebSocket server")
    
    def run_event_loop():
        global server, loop

        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        start_server_coro = websockets.serve(handle_client, '0.0.0.0', 8765, reuse_port=True)
        server = loop.run_until_complete(start_server_coro)

        try:
            loop.run_forever()
        except KeyboardInterrupt:
            pass
        finally:
            loop.run_until_complete(stop_server())
            loop.close()

    # Run the event loop in a separate thread
    threading.Thread(target=run_event_loop).start()

def stop_server():
    if loop is not None and server is not None:
        asyncio.run_coroutine_threadsafe(stop_server_coroutine(), loop)

async def stop_server_coroutine():
    print("Closing WebSocket server")
    server.close()
    await server.wait_closed()

    # Attempt to close all client connections
    for websocket in clients:
        await websocket.close(reason='Server shutdown')
    clients.clear()

    # Stop the event loop
    loop.stop()

def broadcast_geometry_update(geometry_json):
    print("checking for active loop for broadcast")
    if loop is not None:
        print("loop active; calling async broadcast")
        asyncio.run_coroutine_threadsafe(broadcast_geometry_update_async(geometry_json), loop)
