// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2024.2 (64-bit)
// Tool Version Limit: 2024.11
// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
// 
// ==============================================================
/***************************** Include Files *********************************/
#include "xexecute.h"

/************************** Function Implementation *************************/
#ifndef __linux__
int XExecute_CfgInitialize(XExecute *InstancePtr, XExecute_Config *ConfigPtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(ConfigPtr != NULL);

    InstancePtr->Cfg_port_BaseAddress = ConfigPtr->Cfg_port_BaseAddress;
    InstancePtr->IsReady = XIL_COMPONENT_IS_READY;

    return XST_SUCCESS;
}
#endif

void XExecute_Start(XExecute *InstancePtr) {
    u32 Data;

    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XExecute_ReadReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_AP_CTRL) & 0x80;
    XExecute_WriteReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_AP_CTRL, Data | 0x01);
}

u32 XExecute_IsDone(XExecute *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XExecute_ReadReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_AP_CTRL);
    return (Data >> 1) & 0x1;
}

u32 XExecute_IsIdle(XExecute *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XExecute_ReadReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_AP_CTRL);
    return (Data >> 2) & 0x1;
}

u32 XExecute_IsReady(XExecute *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XExecute_ReadReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_AP_CTRL);
    // check ap_start to see if the pcore is ready for next input
    return !(Data & 0x1);
}

void XExecute_EnableAutoRestart(XExecute *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XExecute_WriteReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_AP_CTRL, 0x80);
}

void XExecute_DisableAutoRestart(XExecute *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XExecute_WriteReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_AP_CTRL, 0);
}

void XExecute_Set_data_port(XExecute *InstancePtr, u32 Data) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XExecute_WriteReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_DATA_PORT_DATA, Data);
}

u32 XExecute_Get_data_port(XExecute *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XExecute_ReadReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_DATA_PORT_DATA);
    return Data;
}

void XExecute_Set_frame_cnt(XExecute *InstancePtr, u32 Data) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XExecute_WriteReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_FRAME_CNT_DATA, Data);
}

u32 XExecute_Get_frame_cnt(XExecute *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XExecute_ReadReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_FRAME_CNT_DATA);
    return Data;
}

void XExecute_Set_end_of_stream(XExecute *InstancePtr, u32 Data) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XExecute_WriteReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_END_OF_STREAM_DATA, Data);
}

u32 XExecute_Get_end_of_stream(XExecute *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XExecute_ReadReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_END_OF_STREAM_DATA);
    return Data;
}

void XExecute_InterruptGlobalEnable(XExecute *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XExecute_WriteReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_GIE, 1);
}

void XExecute_InterruptGlobalDisable(XExecute *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XExecute_WriteReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_GIE, 0);
}

void XExecute_InterruptEnable(XExecute *InstancePtr, u32 Mask) {
    u32 Register;

    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Register =  XExecute_ReadReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_IER);
    XExecute_WriteReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_IER, Register | Mask);
}

void XExecute_InterruptDisable(XExecute *InstancePtr, u32 Mask) {
    u32 Register;

    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Register =  XExecute_ReadReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_IER);
    XExecute_WriteReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_IER, Register & (~Mask));
}

void XExecute_InterruptClear(XExecute *InstancePtr, u32 Mask) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XExecute_WriteReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_ISR, Mask);
}

u32 XExecute_InterruptGetEnabled(XExecute *InstancePtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    return XExecute_ReadReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_IER);
}

u32 XExecute_InterruptGetStatus(XExecute *InstancePtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    return XExecute_ReadReg(InstancePtr->Cfg_port_BaseAddress, XEXECUTE_CFG_PORT_ADDR_ISR);
}

