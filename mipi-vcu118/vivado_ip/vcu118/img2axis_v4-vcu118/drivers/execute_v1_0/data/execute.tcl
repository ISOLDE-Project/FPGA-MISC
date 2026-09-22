# ==============================================================
# Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2024.2 (64-bit)
# Tool Version Limit: 2024.11
# Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
# 
# ==============================================================
proc generate {drv_handle} {
    xdefine_include_file $drv_handle "xparameters.h" "XExecute" \
        "NUM_INSTANCES" \
        "DEVICE_ID" \
        "C_S_AXI_CFG_PORT_BASEADDR" \
        "C_S_AXI_CFG_PORT_HIGHADDR"

    xdefine_config_file $drv_handle "xexecute_g.c" "XExecute" \
        "DEVICE_ID" \
        "C_S_AXI_CFG_PORT_BASEADDR"

    xdefine_canonical_xpars $drv_handle "xparameters.h" "XExecute" \
        "DEVICE_ID" \
        "C_S_AXI_CFG_PORT_BASEADDR" \
        "C_S_AXI_CFG_PORT_HIGHADDR"
}

