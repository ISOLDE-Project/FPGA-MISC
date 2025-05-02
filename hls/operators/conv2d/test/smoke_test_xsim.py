
# %%
import os
import numpy as np
from numpy.testing import assert_allclose 
from PIL import Image


work_dir = 'conv2d/test'
current_dir = os.getcwd()

output_ref = np.load(f"{work_dir}/y_int32.npy")
output_tensor = np.fromfile(f"{work_dir}/y_xsim_int32.bin", dtype=np.int32).reshape(output_ref.shape)

img_tensor = np.squeeze(output_tensor)  # Remove batch dim → [C, H, W]
img = Image.fromarray(img_tensor.astype(np.uint8), mode='L')  # 'L' = 8-bit pixels, black and white
save_path=f"{current_dir}/{work_dir}/output_xsim.png"
img.save(save_path)
print(f"\n\n* Output: {save_path}\n")

print(f"Output shape: {output_tensor.shape}, MIN: {output_tensor.min()}, MAX:{output_tensor.max()}\n" )
assert_allclose(output_ref, output_tensor,rtol=1e-6,atol=1e-6)
print("\n****************")
print("* Test passed! *")
print("****************\n")



