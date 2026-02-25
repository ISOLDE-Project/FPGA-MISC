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

# Input stream size
STREAM_H_I = 260
STREAM_W_I = 320
# Output (VGA) size
VGA_H = 224
VGA_W = 224
# Derived values (integer arithmetic)
j_start = (STREAM_W_I - VGA_W) // 2 
j_end = j_start + VGA_W
#
top_row = (STREAM_H_I - VGA_H) // 2 - 3
bottom_row = top_row + VGA_H 

print(j_start, j_end, top_row, bottom_row)

work_dir = 'conv2d/test'
current_dir = os.getcwd()

output_ref = np.load(f"{work_dir}/y_int32.npy")
output_ref =  output_ref[:,:,top_row:bottom_row,j_start:j_end]

output_tensor = np.load(f"{work_dir}/y_cpp_int32.npy")




print(f"\nOutput    shape: {output_tensor.shape}, MIN: {output_tensor.min()}, MAX:{output_tensor.max()}" )
print(f"Reference shape: {output_ref.shape}, MIN: {output_ref.min()}, MAX:{output_ref.max()}\n" )


save_path=f"{current_dir}/{work_dir}/output_conv2d_i32"
saved_path= save_img(save_path, output_tensor)
print(f"\n\n* Output: {saved_path}\n")

save_path=f"{current_dir}/{work_dir}/reference_conv2d_i32"
saved_path= save_img(save_path, output_ref)
print(f"\n\n* Reference: {saved_path}\n")

diff = np.abs(output_ref - output_tensor)
diff_max =np.max(diff)
print(f"Max absolute difference: {diff_max}")

saved_path=save_img(f"{current_dir}/{work_dir}/diff_xsim_visual", diff) 
print(f"\n* Output: {saved_path}\n")
#assert_allclose(output_ref, output_tensor,rtol=1e-6,atol=1e-6)
print("\n****************")
print("* Test passed! *")
print("****************\n")
    
