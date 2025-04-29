# %%
import os


image_fname="1920x1080-full-hd-nature-landscape.jpg"
#image_fname="testpattern-hd-1080.png"

current_dir = f"{os.getcwd()}/conv2d/test"
image_path=f"{current_dir}/{image_fname}"

# %%

from PIL import Image
import numpy as np

def image_to_tensor(filepath, dtype=np.float32, normalize=True):
    # Open image and convert to RGB
    image = Image.open(filepath).convert('RGB')  # ensures 3 channels

    # Convert to NumPy array (H, W, C)
    img_np = np.array(image, dtype=dtype)

    match dtype:
        case np.float32:
            img_np /= 255.0  # normalize to [0, 1]
        case np.int32:
            img_np =np.clip(img_np,0,255)

    # Transpose to (C, H, W)
    img_np = np.transpose(img_np, (2, 0, 1))

    # Add batch dimension -> (1, C, H, W)
    img_tensor = np.expand_dims(img_np, axis=0)

    return img_tensor  # shape: [1, C, H, W]




# %%
def create_kernel(kernel_size=3):

    channels = 3
    

    # Luminance coefficients for RGB
    luminance = np.array([0.2989, 0.5870, 0.1140], dtype=np.float32)

    # Create empty kernel: shape [1, channels, kernel_size, kernel_size]
    mean_kernel = np.zeros((1, channels, kernel_size, kernel_size), dtype=np.float32)

    # Fill each channel with its luminance spread over the kernel
    for c in range(channels):
        mean_kernel[0, c, :, :] = luminance[c] / (kernel_size ** 2)

    mean_kernel_q =  pow(2, 8)*mean_kernel
    mean_kernel_q = mean_kernel_q.astype(np.int32)

    return mean_kernel,mean_kernel_q

# %%
import torch
import torch.nn as nn
import torchvision.transforms as T
from PIL import Image
import torch.nn.functional as F

def exec_conv2d(np_x,np_w,stride=2,padding=1):
    torch_type= torch.float32
    match np_x.dtype:            
        case np.int32:
            torch_type = torch.int32
    torch_x = torch.from_numpy(np_x).to(torch_type)
    torch_w = torch.from_numpy(np_w).to(torch_type)
#Apply convolution
    output = F.conv2d(
        torch_x,
        torch_w,
        bias=None,
        stride=stride,
        padding=padding
    )
    return output

def serialize(y,x,w,sufix=""):
    np.save(f"{current_dir}/y{sufix}",y)
    np.save(f"{current_dir}/x{sufix}",x)
    np.save(f"{current_dir}/w{sufix}",w)


# %%
import torch
import torch.nn as nn
import torchvision.transforms as T
from PIL import Image
import torch.nn.functional as F


mean_kernel,mean_kernel_q = create_kernel()
np_x= image_to_tensor(image_path)
np_x_q= image_to_tensor(image_path,dtype=np.int32)
output = exec_conv2d(np_x,mean_kernel)
#output =output.clamp(0, 1)
serialize(y=output.numpy(),x=np_x,w=mean_kernel)
#save jpg
output = T.ToPILImage()(output.squeeze(0))
output.save("output_downsampled.jpg")

#
output = exec_conv2d(np_x_q,mean_kernel_q)
#de-scale the kernel values
output =output/(pow(2, 8))
output = output.to(torch.int32)
serialize(y=output.numpy(),x=np_x_q,w=mean_kernel_q,sufix="_int32")
#save jpg
output = T.ToPILImage()(output.squeeze(0).to(torch.uint8))
output.save("output_downsampled_q.jpg")



