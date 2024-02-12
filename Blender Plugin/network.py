import socket
import threading

# Global flag to control the server loop
server_running = False

# Global variable for the server socket
server_socket = None

# Global list of client sockets
clients = []


def tcp_server():
    global server_socket
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    # Set the socket option to reuse the address
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    server_socket.bind(('0.0.0.0', 8765))
    server_socket.listen(5)
    print(server_socket.getsockname())

    global server_running
    server_running = True

    while server_running:
        client_socket, addr = server_socket.accept()
        clients.append(client_socket)
        client_thread = threading.Thread(target=client_handler, args=(client_socket,))
        client_thread.start()
        print(f"Client connected: {addr}")

def client_handler(client_socket):
    try:
        while True:
            data = client_socket.recv(1024)
            if not data:
                break  # Client disconnected
            # Process the data from the client
    except socket.error as e:
        pass  # Handle exceptions
    finally:
        client_socket.close()  # Close client socket
        clients.remove(client_socket)  # Remove from clients list
        print("Client disconnected")

def start_server():
    print("Starting server")
    server_thread = threading.Thread(target=tcp_server)
    server_thread.start()

def stop_server():
    print("Closing server")
    global server_running
    server_running = False

    # Close all client sockets
    for client in clients:
        client.close()
    clients.clear()  # Clear the clients list

    # Close the server socket
    global server_socket
    if server_socket:
        server_socket.close()
        server_socket = None

def broadcast_geometry_update(geometry_json):
    for client in list(clients):
        try:
            client.sendall(geometry_json.encode('utf-8'))
        except Exception as e:
            print(f"Error sending update to client: {e}")
            clients.remove(client)
            client.close()  # Ensure the client socket is closed if sending fails
