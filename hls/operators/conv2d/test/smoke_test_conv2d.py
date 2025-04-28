import numpy as np
from PIL import Image
from numpy.testing import assert_allclose 
import os

current_dir = os.getcwd()
output_tensor = np.load("conv2d/test/y_cpp.npy")
output_ref = np.load("conv2d/test/y.npy")
print("Output shape:", output_tensor.shape)
assert_allclose(output_ref, output_tensor,rtol=1e-6,atol=1e-7)
print("\n****************")
print("* Test passed! *")
print("****************\n")
output_tensor = np.squeeze(output_tensor)  # Remove batch dim → [C, H, W]

# If single-channel (grayscale)
if output_tensor.ndim == 2:
    img = Image.fromarray((output_tensor * 255).astype(np.uint8), mode='L')
    img.save("output.png")
    print(f"output image: {current_dir}/output.png\n")

# If 3 channels (RGB)
elif output_tensor.shape[0] == 3:
    img = np.transpose(output_tensor, (1, 2, 0))  # CHW → HWC
    img = (img * 255).clip(0, 255).astype(np.uint8)
    Image.fromarray(img).save("output.png")
    print(f"output image: {current_dir}/output.png\n")

# If more than 3 channels (e.g., feature maps), visualize first channel
else:
    first_channel = output_tensor[0]
    img = Image.fromarray((first_channel * 255).astype(np.uint8), mode='L')
    img.save("output_first_channel.png")
    print(f"output image: {current_dir}/output_first_channel.png\n")
    
