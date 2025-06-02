import socket
import numpy as np
import cv2

HOST = '0.0.0.0'
PORT = 5005
WIDTH = 640
HEIGHT = 480

def receive_frame_from_connection(conn):
    # Receive 4-byte frame size
    size_data = conn.recv(4)
    if len(size_data) < 4:
        print("Failed to receive frame size header.")
        return None

    frame_size = int.from_bytes(size_data, byteorder='big')
    print(f"Expecting frame of {frame_size} bytes")

    # Receive frame data
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

    # Convert to NumPy array and reshape
    frame_array = np.frombuffer(received, dtype=np.uint8).reshape((HEIGHT, WIDTH, 1))
    return frame_array

def start_server():
    frame_cnt =0
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_sock:
        server_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server_sock.bind((HOST, PORT))
        server_sock.listen(1)
        print(f"Server listening on {HOST}:{PORT}")

        while True:
            print("Waiting for new connection...")
            conn, addr = server_sock.accept()
            with conn:
                print(f"Connected by {addr}")
                frame = receive_frame_from_connection(conn)
                if frame is not None:
                    print(f"Received frame: shape={frame.shape}, dtype={frame.dtype}")
                    frame_array = np.frombuffer(frame, dtype=np.uint8).reshape((480, 640))
                    # Display with OpenCV
                    cv2.imshow(f"Received Frame:{frame_cnt}", frame_array)
                    frame_cnt+=1
                    key_pressed= cv2.waitKey(1)
                else:
                    print("Failed to receive valid frame.")

if __name__ == "__main__":
    start_server()
