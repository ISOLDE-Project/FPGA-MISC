import socket
import cv2
import numpy as np

HOST = '0.0.0.0'
PORT = 5005

def recv_all(conn):
    # First read the frame size
    frame_size = int.from_bytes(conn.recv(4), byteorder='big')

    # Receive frame bytes
    frame_data = b''
    while len(frame_data) < frame_size:
        chunk = conn.recv(4096)
        if not chunk:
            break
        frame_data += chunk

  
    print("Frame received.")
    return frame_data


# Create and bind the socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind((HOST, PORT))
sock.listen(1)
print(f"Listening on {HOST}:{PORT}...")
frame_cnt =0
print("press q to quit\n")
while True:
    print("Waiting for a new connection...")
    conn, addr = sock.accept()
    print(f"Connection from {addr}")

    # Receive the frame data
    frame_data = recv_all(conn)
    conn.close()
    # Convert to numpy array and reshape
    frame_array = np.frombuffer(frame_data, dtype=np.uint8).reshape((480, 640))
    # Display with OpenCV
    cv2.imshow(f"Received Frame:{frame_cnt}", frame_array)
    frame_cnt+=1
    key_pressed= cv2.waitKey(0)& 0xFF
    #cv2.destroyWindow("Received Frame")
    if   key_pressed== ord('q'):
        print("Exit requested. Closing server.")
        break



# Cleanup

sock.close()
