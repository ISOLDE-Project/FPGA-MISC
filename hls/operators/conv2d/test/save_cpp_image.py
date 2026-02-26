# import numpy as np

# print("Integer from C++:", cpp_value)

# print("Array info:")
# print(" shape:", cpp_array.shape)
# print(" dtype:", cpp_array.dtype)

import os
import numpy as np
from numpy.testing import assert_allclose 
from PIL import Image


def save_img(fname, tensor):
    img_tensor = np.squeeze(tensor)  # Remove batch dim → [C, H, W]
    img = Image.fromarray(img_tensor.astype(np.uint8), mode='L')  # 'L' = 8-bit pixels, black and white
    save_path=f"{fname}.png"
    img.save(save_path)
    return save_path



work_dir = 'conv2d/test'
current_dir = os.getcwd()

print(f"\nCPP output   shape: { cpp_array.shape}, MIN: { cpp_array.min()}, MAX:{cpp_array.max()}" )



save_path=f"{current_dir}/{work_dir}/cpp_image_{cpp_value}"
saved_path= save_img(save_path, cpp_array)
print(f"\n\n* Output: {saved_path}\n")


    
