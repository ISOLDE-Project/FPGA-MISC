import socket
import cv2

HOST = '0.0.0.0'
PORT = 5005

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind((HOST, PORT))
sock.listen(1)

conn, addr = sock.accept()
print(f"Connection from {addr}")

# First read the frame size
frame_size = int.from_bytes(conn.recv(4), byteorder='big')

# Receive frame bytes
frame_data = b''
while len(frame_data) < frame_size:
    chunk = conn.recv(4096)
    if not chunk:
        break
    frame_data += chunk

conn.close()
print("Frame received.")

# Convert back to numpy array
import numpy as np
frame_array = np.frombuffer(frame_data, dtype=np.uint8).reshape((480, 640))

# Optionally display or save
#from PIL import Image
#Image.fromarray(frame_array, mode='L').save('received_frame.png')


cv2.imshow("Received Frame", frame_array)
cv2.waitKey(0)  # Wait for a key press
cv2.destroyAllWindows()