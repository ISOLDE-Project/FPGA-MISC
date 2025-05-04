
# %%

import os
import numpy as np
from numpy.testing import assert_allclose 
from PIL import Image

def save_img(fname, tensor):
    img_tensor = np.squeeze(tensor)  # Remove batch dim → [C, H, W]
    img = Image.fromarray(img_tensor.astype(np.uint8), mode='L')  # 'L' = 8-bit pixels, black and white
    save_path=f"{fname}.png"
    img.save(save_path)

work_dir = 'conv2d/test'
current_dir = os.getcwd()

expected = np.load(f"{work_dir}/y_int32.npy")
output_tensor = np.fromfile(f"{work_dir}/y_xsim_int32.bin", dtype=np.int32).reshape(expected.shape)

diff = np.abs(expected - output_tensor)
diff_max =np.max(diff)
print(f"Max absolute difference: {diff_max}")
save_img(f"{current_dir}/{work_dir}/diff_xsim_visual", diff) 

img_tensor = np.squeeze(output_tensor)  # Remove batch dim → [C, H, W]
img = Image.fromarray(img_tensor.astype(np.uint8), mode='L')  # 'L' = 8-bit pixels, black and white
save_path=f"{current_dir}/{work_dir}/output_xsim.png"
img.save(save_path)
print(f"\n\n* Output: {save_path}\n")

print(f"Output shape:   {output_tensor.shape}, MIN: {output_tensor.min()}, MAX:{output_tensor.max()}" )
print(f"Expected shape: {expected.shape}\n")
diff = np.abs(expected - output_tensor)
diff_max =np.max(diff)
print(f"Max absolute difference: {diff_max}")

save_img(f"{current_dir}/{work_dir}/diff_xsim_visual", diff) 
assert_allclose(expected, output_tensor,rtol=1e-6,atol=1e-6)
print("\n****************")
print("* Test passed! *")
print("****************\n")



