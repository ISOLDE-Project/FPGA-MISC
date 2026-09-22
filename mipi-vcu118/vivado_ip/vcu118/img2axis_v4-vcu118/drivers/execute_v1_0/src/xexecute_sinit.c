// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2024.2 (64-bit)
// Tool Version Limit: 2024.11
// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
// 
// ==============================================================
#ifndef __linux__

#include "xstatus.h"
#ifdef SDT
#include "xparameters.h"
#endif
#include "xexecute.h"

extern XExecute_Config XExecute_ConfigTable[];

#ifdef SDT
XExecute_Config *XExecute_LookupConfig(UINTPTR BaseAddress) {
	XExecute_Config *ConfigPtr = NULL;

	int Index;

	for (Index = (u32)0x0; XExecute_ConfigTable[Index].Name != NULL; Index++) {
		if (!BaseAddress || XExecute_ConfigTable[Index].Cfg_port_BaseAddress == BaseAddress) {
			ConfigPtr = &XExecute_ConfigTable[Index];
			break;
		}
	}

	return ConfigPtr;
}

int XExecute_Initialize(XExecute *InstancePtr, UINTPTR BaseAddress) {
	XExecute_Config *ConfigPtr;

	Xil_AssertNonvoid(InstancePtr != NULL);

	ConfigPtr = XExecute_LookupConfig(BaseAddress);
	if (ConfigPtr == NULL) {
		InstancePtr->IsReady = 0;
		return (XST_DEVICE_NOT_FOUND);
	}

	return XExecute_CfgInitialize(InstancePtr, ConfigPtr);
}
#else
XExecute_Config *XExecute_LookupConfig(u16 DeviceId) {
	XExecute_Config *ConfigPtr = NULL;

	int Index;

	for (Index = 0; Index < XPAR_XEXECUTE_NUM_INSTANCES; Index++) {
		if (XExecute_ConfigTable[Index].DeviceId == DeviceId) {
			ConfigPtr = &XExecute_ConfigTable[Index];
			break;
		}
	}

	return ConfigPtr;
}

int XExecute_Initialize(XExecute *InstancePtr, u16 DeviceId) {
	XExecute_Config *ConfigPtr;

	Xil_AssertNonvoid(InstancePtr != NULL);

	ConfigPtr = XExecute_LookupConfig(DeviceId);
	if (ConfigPtr == NULL) {
		InstancePtr->IsReady = 0;
		return (XST_DEVICE_NOT_FOUND);
	}

	return XExecute_CfgInitialize(InstancePtr, ConfigPtr);
}
#endif

#endif

