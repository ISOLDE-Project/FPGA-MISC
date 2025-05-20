import os
import numpy as np
from numpy.testing import assert_allclose 
from PIL import Image


def save_img(fname, packed):
  # Ensure array is in uint32
    _, _, H, W = packed.shape
    packed =packed.reshape((H,W))
    packed = packed.astype(np.uint32)

    # === UNPACK RGB ===
    r = (packed >> 16) & 0xFF
    g = (packed >> 8) & 0xFF
    b = packed & 0xFF

    # === STACK INTO RGB IMAGE ===
    img_np = np.stack([r, g, b], axis=-1).astype(np.uint8)

    # === CONVERT TO PIL IMAGE AND SAVE ===
    img = Image.fromarray(img_np, mode='RGB')
    save_path=f"{fname}.png"
    img.save(save_path)
    return save_path

work_dir = 'conv2d/test'
current_dir = os.getcwd()

output_ref = np.load(f"{work_dir}/x_linux_sim_int32.npy")

output_tensor = np.load(f"{work_dir}/y_cpp_int32.npy")


print(f"\nOutput    shape: {output_tensor.shape}, MIN: {output_tensor.min()}, MAX:{output_tensor.max()}" )
print(f"Reference shape: {output_ref.shape}, MIN: {output_ref.min()}, MAX:{output_ref.max()}\n" )


save_path=f"{current_dir}/{work_dir}/output_conv2d_i32"
saved_path= save_img(save_path, output_tensor)
print(f"\n\n* Output: {saved_path}\n")
diff = np.abs(output_ref - output_tensor)
diff_max =np.max(diff)
print(f"Max absolute difference: {diff_max}")

saved_path=save_img(f"{current_dir}/{work_dir}/diff_xsim_visual", diff) 
print(f"\n* Output: {saved_path}\n")
assert_allclose(output_ref, output_tensor,rtol=1e-6,atol=1e-6)
print("\n****************")
print("* Test passed! *")
print("****************\n")
    
