import socket

def tcp_client():
    # Create a socket object
    client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    # Connect to the server
    # Make sure the host and port match what your Blender add-on is using
    host = 'localhost'
    port = 8765  # The port number should match the one used by your Blender add-on's server
    client.connect((host, port))

    try:
        while True:
            # Receive data from the server
            data = client.recv(4096)
            if not data:
                break  # Server closed the connection

            # Print the received data
            print("Received:", data.decode('utf-8'))
    finally:
        # Clean up the connection
        client.close()

if __name__ == '__main__':
    tcp_client()
