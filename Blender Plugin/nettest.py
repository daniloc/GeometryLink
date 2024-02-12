import asyncio
import websockets

async def websocket_client():
    uri = "ws://localhost:8765"  # Update this with your server's URI
    async with websockets.connect(uri) as websocket:
        try:
            while True:
                # Wait for a message from the server
                data = await websocket.recv()
                print("Received:", data)
        except websockets.exceptions.ConnectionClosed:
            print("Connection to server closed")

if __name__ == '__main__':
    asyncio.run(websocket_client())
