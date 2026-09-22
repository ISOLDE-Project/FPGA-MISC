// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2024.2 (64-bit)
// Tool Version Limit: 2024.11
// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
// 
// ==============================================================
#ifndef XEXECUTE_H
#define XEXECUTE_H

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/
#ifndef __linux__
#include "xil_types.h"
#include "xil_assert.h"
#include "xstatus.h"
#include "xil_io.h"
#else
#include <stdint.h>
#include <assert.h>
#include <dirent.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stddef.h>
#endif
#include "xexecute_hw.h"

/**************************** Type Definitions ******************************/
#ifdef __linux__
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
#else
typedef struct {
#ifdef SDT
    char *Name;
#else
    u16 DeviceId;
#endif
    u32 Cfg_port_BaseAddress;
} XExecute_Config;
#endif

typedef struct {
    u32 Cfg_port_BaseAddress;
    u32 IsReady;
} XExecute;

typedef u32 word_type;

/***************** Macros (Inline Functions) Definitions *********************/
#ifndef __linux__
#define XExecute_WriteReg(BaseAddress, RegOffset, Data) \
    Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))
#define XExecute_ReadReg(BaseAddress, RegOffset) \
    Xil_In32((BaseAddress) + (RegOffset))
#else
#define XExecute_WriteReg(BaseAddress, RegOffset, Data) \
    *(volatile u32*)((BaseAddress) + (RegOffset)) = (u32)(Data)
#define XExecute_ReadReg(BaseAddress, RegOffset) \
    *(volatile u32*)((BaseAddress) + (RegOffset))

#define Xil_AssertVoid(expr)    assert(expr)
#define Xil_AssertNonvoid(expr) assert(expr)

#define XST_SUCCESS             0
#define XST_DEVICE_NOT_FOUND    2
#define XST_OPEN_DEVICE_FAILED  3
#define XIL_COMPONENT_IS_READY  1
#endif

/************************** Function Prototypes *****************************/
#ifndef __linux__
#ifdef SDT
int XExecute_Initialize(XExecute *InstancePtr, UINTPTR BaseAddress);
XExecute_Config* XExecute_LookupConfig(UINTPTR BaseAddress);
#else
int XExecute_Initialize(XExecute *InstancePtr, u16 DeviceId);
XExecute_Config* XExecute_LookupConfig(u16 DeviceId);
#endif
int XExecute_CfgInitialize(XExecute *InstancePtr, XExecute_Config *ConfigPtr);
#else
int XExecute_Initialize(XExecute *InstancePtr, const char* InstanceName);
int XExecute_Release(XExecute *InstancePtr);
#endif

void XExecute_Start(XExecute *InstancePtr);
u32 XExecute_IsDone(XExecute *InstancePtr);
u32 XExecute_IsIdle(XExecute *InstancePtr);
u32 XExecute_IsReady(XExecute *InstancePtr);
void XExecute_EnableAutoRestart(XExecute *InstancePtr);
void XExecute_DisableAutoRestart(XExecute *InstancePtr);

void XExecute_Set_data_port(XExecute *InstancePtr, u32 Data);
u32 XExecute_Get_data_port(XExecute *InstancePtr);
void XExecute_Set_frame_cnt(XExecute *InstancePtr, u32 Data);
u32 XExecute_Get_frame_cnt(XExecute *InstancePtr);
void XExecute_Set_end_of_stream(XExecute *InstancePtr, u32 Data);
u32 XExecute_Get_end_of_stream(XExecute *InstancePtr);

void XExecute_InterruptGlobalEnable(XExecute *InstancePtr);
void XExecute_InterruptGlobalDisable(XExecute *InstancePtr);
void XExecute_InterruptEnable(XExecute *InstancePtr, u32 Mask);
void XExecute_InterruptDisable(XExecute *InstancePtr, u32 Mask);
void XExecute_InterruptClear(XExecute *InstancePtr, u32 Mask);
u32 XExecute_InterruptGetEnabled(XExecute *InstancePtr);
u32 XExecute_InterruptGetStatus(XExecute *InstancePtr);

#ifdef __cplusplus
}
#endif

#endif
