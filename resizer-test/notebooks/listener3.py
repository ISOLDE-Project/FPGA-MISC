import socket
import numpy as np
import pygame

HOST = '0.0.0.0'
PORT = 5005
WIDTH = 640
HEIGHT = 480

def receive_frame_from_connection(conn):
    size_data = conn.recv(4)
    if len(size_data) < 4:
        print("Failed to receive frame size header.")
        return None

    frame_size = int.from_bytes(size_data, byteorder='big')
    print(f"Expecting frame of {frame_size} bytes")

    received = bytearray()
    while len(received) < frame_size:
        packet = conn.recv(frame_size - len(received))
        if not packet:
            print("Connection closed prematurely.")
            return None
        received.extend(packet)

    if len(received) != frame_size:
        print("Incomplete frame received.")
        return None

    frame_array = np.frombuffer(received, dtype=np.uint8).reshape((HEIGHT, WIDTH, 1))
    return frame_array

def init_pygame(width, height):
    pygame.init()
    screen = pygame.display.set_mode((width, height))
    pygame.display.set_caption("Received Frame")
    return screen

def show_frame_pygame(screen, frame, frame_cnt):
    # Convert grayscale to RGB by repeating channels
    rgb_frame = np.repeat(frame, 3, axis=2)  # shape: (480, 640, 3)
    surface = pygame.surfarray.make_surface(rgb_frame.swapaxes(0, 1))  # Pygame expects (width, height)
    screen.blit(surface, (0, 0))
    pygame.display.set_caption(f"Received Frame #{frame_cnt}")
    pygame.display.flip()

def start_server():
    frame_cnt = 0
    screen = init_pygame(WIDTH, HEIGHT)

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_sock:
        server_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server_sock.bind((HOST, PORT))
        server_sock.listen(1)
        print(f"Server listening on {HOST}:{PORT}")

        running = True
        while running:
            print("Waiting for new connection...")
            conn, addr = server_sock.accept()
            with conn:
                print(f"Connected by {addr}")
                frame = receive_frame_from_connection(conn)
                if frame is not None:
                    print(f"Received frame: shape={frame.shape}, dtype={frame.dtype}")
                    frame_cnt += 1
                    show_frame_pygame(screen, frame, frame_cnt)
                else:
                    print("Failed to receive valid frame.")

            # Handle window events (e.g., close button)
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False

    pygame.quit()

if __name__ == "__main__":
    start_server()
