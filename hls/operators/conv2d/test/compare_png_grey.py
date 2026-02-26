import os
import sys
from PIL import Image
import numpy as np


def load_image_as_array(path):
    """
    Load grayscale image into a NumPy array.
    """
    img = Image.open(path).convert("L")   # L = 8-bit grayscale
    return np.array(img)


def compare_images(img1_path, img2_path):

    
    current_dir = os.getcwd()
    work_dir = f"{current_dir}/conv2d/test"
    
    arr1 = load_image_as_array(f"{work_dir}/{img1_path}")
    arr2 = load_image_as_array(f"{work_dir}/{img2_path}")
    print(f"*** {img1_path} vs. {img2_path} report ***")
    print("Image 1 shape:", arr1.shape)
    print("Image 2 shape:", arr2.shape)

    # Ensure same size
    if arr1.shape != arr2.shape:
        print("😒 😒ERROR: Images have different dimensions.")
        return

    # Convert to signed type to avoid uint8 overflow
    arr1 = arr1.astype(np.int32)
    arr2 = arr2.astype(np.int32)

    diff = np.abs(arr1 - arr2)

    max_diff = diff.max()
    mean_diff = diff.mean()

    identical_pixels = np.sum(arr1 == arr2)
    total_pixels = arr1.size
    identical_ratio = identical_pixels / total_pixels * 100.0
    

    print("Max pixel difference:", max_diff)
    print("Mean absolute difference:", mean_diff)
    print(f"Identical pixels: {identical_pixels}/{total_pixels} ({identical_ratio:.2f}%)")

    if max_diff == 0:
        print("✅ Images are identical.")
    else:
        print("😒 😒Images differ.")

    # Optional: save visual diff image (scaled for visibility)
    vis = np.clip(diff * 4, 0, 255).astype(np.uint8)
    vis_path= f"{work_dir}/{img1_path}-{img2_path}-diff.png"
    Image.fromarray(vis).save(vis_path)
    print(f"Saved diff image: {vis_path}")
    print(f"*** {img1_path} vs. {img2_path} ********")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage:")
        print("  python compare_png_gray.py image1.png image2.png")
        sys.exit(1)

    compare_images(sys.argv[1], sys.argv[2])