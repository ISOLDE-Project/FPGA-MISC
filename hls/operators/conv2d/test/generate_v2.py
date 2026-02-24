# %%
import os



image_fname   ="grey_1600x1300.jpg"
image_fname_01="grey_1600x1300.jpg"

output_dir = f"{os.getcwd()}/conv2d/test"


# %%


from PIL import Image
import numpy as np

import numpy as np
from PIL import Image

def image_to_tensor(filename, dtype=np.float32, normalize=True, grayscale=False):
    """
    Convert an image to tensor format (1, C, H, W).

    Parameters
    ----------
    filepath : str
        Path to image.
    dtype : numpy dtype
        Output dtype (e.g., np.float32 or np.int32).
    normalize : bool
        If True and dtype is float32, scale to [0, 1].
    grayscale : bool
        If True -> C=1, else C=3 (RGB).

    Returns
    -------
    img_tensor : np.ndarray
        Shape (1, C, H, W)
    """
    filepath=f"{output_dir}/{filename}"
    # Select mode
    mode = 'L' if grayscale else 'RGB'
    # Open and convert image
    image = Image.open(filepath).convert(mode)
    # Convert to NumPy array
    img_np = np.array(image, dtype=dtype)
    # Normalize or clip
    if dtype == np.float32:
        if normalize:
            img_np /= 255.0
    elif dtype == np.int32:
        img_np = np.clip(img_np, 0, 255)
    # Ensure channel dimension exists
    if grayscale:
        # (H, W) -> (1, H, W)
        img_np = np.expand_dims(img_np, axis=0)
    else:
        # (H, W, 3) -> (3, H, W)
        img_np = np.transpose(img_np, (2, 0, 1))
    # Add batch dimension -> (1, C, H, W)
    img_tensor = np.expand_dims(img_np, axis=0)

    return img_tensor
    
def tensor_to_image(img_tensor, filepath, denormalize=True):
    img_np = np.squeeze(img_tensor, axis=0)
    num_channels = img_np.shape[0]
    
    if num_channels == 1:
        img_np = np.squeeze(img_np, axis=0)
        mode = 'L'
    elif num_channels == 3:
        img_np = np.transpose(img_np, (1, 2, 0))
        mode = 'RGB'
    else:
        raise ValueError(f"Unsupported number of channels: {num_channels}")
    
    if img_np.dtype in [np.float32, np.float64]:
        if denormalize:
            img_np = img_np * 255.0
        img_np = np.clip(img_np, 0, 255).astype(np.uint8)
    else:
        img_np = np.clip(img_np, 0, 255).astype(np.uint8)
    
    image = Image.fromarray(img_np, mode=mode)
    image.save(filepath)
    print(f"Image saved to: {filepath}")



# %%
def create_kernel(kernel_size=5):

    channels = 1

    # Create empty kernel: shape [1, channels, kernel_size, kernel_size]
    mean_kernel = np.zeros((1, channels, kernel_size, kernel_size), dtype=np.float32)

    for c in range(channels):
        mean_kernel[0, c, :, :] = 1. / (kernel_size ** 2)

    mean_kernel_q =  pow(2, 8)*mean_kernel
    mean_kernel_q = mean_kernel_q.astype(np.int32)

    return mean_kernel,mean_kernel_q

# %%
def image_to_GRAY(path, image_fname, suffix):
    """
    Convert grayscale image to int32 format with 4 pixels per int32.
    Packing format: 0xPPPPPPPP where each P is an 8-bit pixel value.
    """
    # === LOAD AND CONVERT IMAGE TO GRAYSCALE ===
    img = Image.open(f"{path}/{image_fname}").convert('L')  # 'L' = grayscale
    img_np = np.array(img)  # Shape: (H, W), dtype=uint8
    
    H, W = img_np.shape
    
    # === FLATTEN IMAGE ===
    gray_flat = img_np.flatten().astype(np.uint32)
    
    # === PAD IF NECESSARY ===
    # We need length to be multiple of 4 for packing
    num_pixels = len(gray_flat)
    remainder = num_pixels % 4
    if remainder != 0:
        padding = 4 - remainder
        gray_flat = np.pad(gray_flat, (0, padding), mode='constant', constant_values=0)
        print(f"Padded {padding} pixels to make total divisible by 4")
    
    # === PACK 4 PIXELS INTO INT32 ===
    # Format: pixel0 | pixel1 | pixel2 | pixel3
    # Most significant byte = pixel0, least significant = pixel3
    num_int32 = len(gray_flat) // 4
    packed = np.zeros(num_int32, dtype=np.uint32)
    
    for i in range(num_int32):
        pixel0 = gray_flat[i * 4 + 0]
        pixel1 = gray_flat[i * 4 + 1]
        pixel2 = gray_flat[i * 4 + 2]
        pixel3 = gray_flat[i * 4 + 3]
        
        # Pack: [pixel0][pixel1][pixel2][pixel3]
        packed[i] = (pixel0 << 24) | (pixel1 << 16) | (pixel2 << 8) | pixel3
    
    # === SAVE TO BINARY FILE ===
    packed_flat = packed.flatten().astype(np.uint32)
    packed_flat.tofile(f"{path}/x_xsim_int32_{suffix}.bin")
    
    # === SAVE ORIGINAL IMAGE SHAPE FOR RECONSTRUCTION ===
    # Save as (1, 1, H, W) tensor format
    img_tensor = np.expand_dims(np.expand_dims(img_np, axis=0), axis=0).astype(np.uint32)
    np.save(f"{path}/x_linux_sim_int32_{suffix}.npy", img_tensor)
    
    print(f"Grayscale image shape: {H}x{W}")
    print(f"Total pixels: {num_pixels}")
    print(f"Packed into {num_int32} int32 values")
    print(f"Saved to: {path}/x_xsim_int32_{suffix}.bin")
    
    return packed, (H, W)


def GRAY_to_image(path, suffix, original_shape):
    """
    Unpack int32 binary file back to grayscale image.
    
    Parameters:
    -----------
    path : str
        Directory path
    suffix : str
        File suffix
    original_shape : tuple
        (H, W) original image dimensions
    """
    # === LOAD PACKED DATA ===
    packed = np.fromfile(f"{path}/x_xsim_int32_{suffix}.bin", dtype=np.uint32)
    
    H, W = original_shape
    num_pixels = H * W
    
    # === UNPACK INT32 TO PIXELS ===
    gray_flat = np.zeros(len(packed) * 4, dtype=np.uint8)
    
    for i in range(len(packed)):
        val = packed[i]
        gray_flat[i * 4 + 0] = (val >> 24) & 0xFF  # pixel0
        gray_flat[i * 4 + 1] = (val >> 16) & 0xFF  # pixel1
        gray_flat[i * 4 + 2] = (val >> 8) & 0xFF   # pixel2
        gray_flat[i * 4 + 3] = val & 0xFF          # pixel3
    
    # === TRIM PADDING AND RESHAPE ===
    gray_flat = gray_flat[:num_pixels]
    img_np = gray_flat.reshape(H, W)
    
    # === SAVE AS IMAGE ===
    img = Image.fromarray(img_np, mode='L')
    img.save(f"{path}/reconstructed_{suffix}.png")
    print(f"Reconstructed image saved to: {path}/reconstructed_{suffix}.png")
    
    return img_np

# %%
import torch
import torch.nn as nn
import torchvision.transforms as T
from PIL import Image
import torch.nn.functional as F

def exec_conv2d(np_x,np_w,stride=5,padding=0):
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
    np.save(f"{output_dir}/y{sufix}",y)
    np.save(f"{output_dir}/x{sufix}",x)
    np.save(f"{output_dir}/w{sufix}",w)

def image_to_RGB(path,image_fname,suffix):
    # === LOAD AND CONVERT IMAGE TO RGB ===
    img = Image.open(f"{path}/{image_fname}").convert('RGB') 
    img_np = np.array(img)  # Shape: (H, W, 3), dtype=uint8

    # === PACK RGB TO INT32 ===
    # Format: 0x00RRGGBB (most significant byte can be 0)
    r = img_np[:, :, 0].astype(np.uint32)
    g = img_np[:, :, 1].astype(np.uint32)
    b = img_np[:, :, 2].astype(np.uint32)
    rgb_packed = (r << 16) | (g << 8) | b  # Shape: (H, W)

    rgb_flat = rgb_packed.flatten().astype(np.uint32)

    # === SAVE TO BINARY FILE ===
    #rgb_flat.tofile(f"{path}/{image_fname}_{rgb_packed.shape[0]}x{rgb_packed.shape[1]}_RGB.bin")
    rgb_flat.tofile(f"{path}/x_xsim_int32_{suffix}.bin")
    np.save(f"{path}/x_linux_sim_int32{suffix}",np.expand_dims(np.expand_dims(rgb_packed, axis=0), axis=0))

def write_shape_defines(np_o, np_i,np_w,stride, padding, path,fname="shapes.inc"):
    """
    Writes shape macros to a text file based on the shapes of np_i and np_o.
    
    Assumes shapes are in the form (channels, height, width).
    """
    if np_i.ndim != 4 or np_o.ndim != 4:
        raise ValueError("Both np_i and np_o must be 3-dimensional (N, C, H, W).")
    if np_w.ndim != 4 :
        raise ValueError("np_w must be 4-dimensional (M, C, H, W).")

    with open(f"{path}/{fname}", 'w') as f:
        f.write(f"/*\n* GENERATED FILE! \n*/\n")
        f.write(f"/*\n*  Frame\n*/\n")
        f.write(f"#define CHANNELS_I  {np_i.shape[1]}\n")
        f.write(f"#define HEIGHT_I    {np_i.shape[2]}\n")
        f.write(f"#define WIDTH_I     {np_i.shape[3]}\n\n")
        f.write(f"/*\n*  Convolution output\n*/\n")
        f.write(f"#define CHANNELS_O  {np_o.shape[1]}\n")
        f.write(f"#define HEIGHT_O    {np_o.shape[2]}\n")
        f.write(f"#define WIDTH_O     {np_o.shape[3]}\n\n")
        f.write(f"/*\n*  Kernel\n*/\n")
        f.write(f"#define FEATURES_W  {np_w.shape[0]}\n")
        f.write(f"#define CHANNELS_W  {np_w.shape[1]}\n")
        f.write(f"#define HEIGHT_W    {np_w.shape[2]}\n")
        f.write(f"#define WIDTH_W     {np_w.shape[3]}\n")
        f.write(f"/*\n*  Convolution params\n*/\n")
        f.write(f"#define CONV_STRIDE      {stride}\n")
        f.write(f"#define CONV_PADDING     {padding}\n")

# %%
import torch
import torch.nn as nn
import torchvision.transforms as T
from PIL import Image
import torch.nn.functional as F




#
def gen_test_i32(image_path,suffix):
    kernel_size=5
    stride=5
    grayscale=True
    np_x_q= image_to_tensor(image_path,dtype=np.int32,grayscale=grayscale)
    _,mean_kernel_q = create_kernel(kernel_size=kernel_size)
    output = exec_conv2d(np_x_q,mean_kernel_q,stride=stride)
    #de-scale the kernel values
    output =output/(pow(2, 8))
    output = output.to(torch.int32)
    serialize(y=output.numpy(),x=np_x_q,w=mean_kernel_q,sufix=f"_int32{suffix}")
    np_x_q.tofile(f"{output_dir}/x_int32{suffix}.bin")
    mean_kernel_q.tofile(f"{output_dir}/w_int32.bin")
    #xsim test values
    image_to_GRAY(path=output_dir,image_fname=image_fname,suffix=suffix)
    write_shape_defines( output, np_x_q, mean_kernel_q,stride,0,path=f"{output_dir}/..")
    #save jpg
    output = T.ToPILImage()(output.squeeze(0).to(torch.uint8))
    output.save(f"{output_dir}/output_q_{suffix}.jpg")

gen_test_i32(image_fname,'')
gen_test_i32(image_fname_01,'_01')
