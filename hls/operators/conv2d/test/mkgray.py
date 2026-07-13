#!/usr/bin/env python3
import sys
from PIL import Image

def rgb_to_grayscale(input_path, output_path):
    """Convert an RGB PNG image to grayscale PNG."""
    img = Image.open(input_path)
    grayscale_img = img.convert('L')
    grayscale_img.save(output_path)
    print(f"Converted: {input_path} → {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input.png> <output.png>")
        sys.exit(1)
    
    rgb_to_grayscale(sys.argv[1], sys.argv[2])
