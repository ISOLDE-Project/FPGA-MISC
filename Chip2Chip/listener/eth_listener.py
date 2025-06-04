import socket
import numpy as np
import cv2

# Server settings
HOST = "0.0.0.0"
PORT = 9999

# Frame details (match sender's config)
HEIGHT, WIDTH, CHANNELS = 480, 160, 4
FRAME_SIZE = HEIGHT * WIDTH * CHANNELS

# Start server
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind((HOST, PORT))
sock.listen(1)
print(f"[Listener] Listening on port {PORT}...")

conn, addr = sock.accept()
print(f"[Listener] Connection from {addr}")

frame_counter = 0  # Initialize frame count

try:
    while True:
        frame_data = bytearray()
        while len(frame_data) < FRAME_SIZE:
            packet = conn.recv(FRAME_SIZE - len(frame_data))
            if not packet:
                print("[Listener] Connection closed by sender.")
                break
            frame_data.extend(packet)

        if len(frame_data) != FRAME_SIZE:
            print(f"[Listener] Incomplete frame ({len(frame_data)} bytes). Skipping...")
            continue

        # Reshape packed image: 480 rows × 160 groups × 4 channels = 640 pixels per row
        frame = np.frombuffer(frame_data, dtype=np.uint8).reshape((480, 160, 4))
        gray = frame.reshape((480, 640))

        # Overlay frame counter
        frame_counter += 1
        display = cv2.cvtColor(gray, cv2.COLOR_GRAY2BGR)  # Convert to BGR for colored text
        cv2.putText(display, f"Frame: {frame_counter}", (10, 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

        # Display
        cv2.imshow("Live Frame", display)

        # Exit on 'q' key
        if cv2.waitKey(1) & 0xFF == ord('q'):
            print("[Listener] Exit requested by user.")
            break

except Exception as e:
    print(f"[Listener] Error: {e}")

finally:
    conn.close()
    sock.close()
    cv2.destroyAllWindows()
    print("[Listener] Closed connection and window.")



'''
import socket
import numpy as np
import cv2

# Server settings
HOST = "0.0.0.0"
PORT = 9999

# Frame details (match sender's config)
HEIGHT, WIDTH, CHANNELS = 480, 160, 4
FRAME_SIZE = HEIGHT * WIDTH * CHANNELS

# Start server
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind((HOST, PORT))
sock.listen(1)
print(f"[Listener] Listening on port {PORT}...")

conn, addr = sock.accept()
print(f"[Listener] Connection from {addr}")

try:
    while True:
        frame_data = bytearray()
        while len(frame_data) < FRAME_SIZE:
            packet = conn.recv(FRAME_SIZE - len(frame_data))
            if not packet:
                print("[Listener] Connection closed by sender.")
                break
            frame_data.extend(packet)

        if len(frame_data) != FRAME_SIZE:
            print(f"[Listener] Incomplete frame ({len(frame_data)} bytes). Skipping...")
            continue

        # Reshape packed image: 480 rows × 160 groups × 4 channels = 640 pixels per row
        frame = np.frombuffer(frame_data, dtype=np.uint8).reshape((480, 160, 4))
        gray = frame.reshape((480, 640))
    	
        # Optional: resize to VGA if you want to apply interpolation (not required)
        # gray = cv2.resize(gray, (640, 480), interpolation=cv2.INTER_LINEAR)

        # Display
        cv2.imshow("Live Frame", gray)

        # Exit on 'q' key
        if cv2.waitKey(1) & 0xFF == ord('q'):
            print("[Listener] Exit requested by user.")
            break

except Exception as e:
    print(f"[Listener] Error: {e}")

finally:
    conn.close()
    sock.close()
    cv2.destroyAllWindows()
    print("[Listener] Closed connection and window.")
'''


'''
import socket
import struct
import numpy as np
import cv2

HOST = '0.0.0.0'
PORT = 9999
IMG_SHAPE = (480, 160, 4)
NUM_BYTES = np.prod(IMG_SHAPE)

# Set up TCP listener
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind((HOST, PORT))
sock.listen(1)
conn, addr = sock.accept()
print(f"Connected by {addr}")

while True:
    # Read the 4-byte length header
    length_data = conn.recv(4)
    if not length_data:
        break
    expected_len = struct.unpack("<I", length_data)[0]
    
    # Receive the full image
    data = b''
    while len(data) < expected_len:
        packet = conn.recv(expected_len - len(data))
        if not packet:
            break
        data += packet
    
    # Convert to NumPy array and display
    frame = np.frombuffer(data, dtype=np.uint8).reshape(IMG_SHAPE)
    rgb_frame = frame[:, :, :3]  # drop alpha if present
    rgb_frame = cv2.cvtColor(rgb_frame, cv2.COLOR_RGB2BGR)  # OpenCV uses BGR
    
    cv2.imshow("Live Frame", rgb_frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

conn.close()
cv2.destroyAllWindows()
'''
