/////******************************************************************************
////*
////* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
////*
////* Permission is hereby granted, free of charge, to any person obtaining a copy
////* of this software and associated documentation files (the "Software"), to deal
////* in the Software without restriction, including without limitation the rights
////* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
////* copies of the Software, and to permit persons to whom the Software is
////* furnished to do so, subject to the following conditions:
////*
////* The above copyright notice and this permission notice shall be included in
////* all copies or substantial portions of the Software.
////*
////* Use of the Software is limited solely to applications:
////* (a) running on a Xilinx device, or
////* (b) that interact with a Xilinx device through a bus or interconnect.
////*
////* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
////* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
////* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
////* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
////* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
////* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
////* SOFTWARE.
////*
////* Except as contained in this notice, the name of the Xilinx shall not be used
////* in advertising or otherwise to promote the sale, use or other dealings in
////* this Software without prior written authorization from Xilinx.
////*
////******************************************************************************/
//
///******************************************************************************
//* Copyright (C) 2018 - 2022 Xilinx, Inc.  All rights reserved.
//* SPDX-License-Identifier: MIT
//*******************************************************************************/
//
///*****************************************************************************/
///**
//*
//* @file xmipi_sp701_example.c
//*
//* <pre>
//* MODIFICATION HISTORY:
//*
//* Ver   Who    Date     Changes
//* ----- ------ -------- --------------------------------------------------
//* X.XX  XX     YY/MM/DD
//* 1.00  RHe    19/09/20 Initial release.
//* </pre>

#include "xparameters.h"
#include "xiic.h"
#include "xil_printf.h"
#include "xil_exception.h"
#include "xintc.h"
#include "sleep.h"

#include "sensor_config_pcam.h"
#include "iic_functions.h"

int main() {
    int Status;

    xil_printf("\n\nStarting I2C Camera ID Read Test...\r\n");


    initIIC();

    xil_printf("PASS:1 \r\n");

    Status = SetupInterruptSystem();
    if (Status != XST_SUCCESS) {
        xil_printf("Interrupt setup failed\r\n");
        return XST_FAILURE;
    }

    xil_printf("PASS:222 \r\n");


    Status = InitializeCsiRxSs();
    if (Status != XST_SUCCESS) {
      xil_printf("CSI Rx Ss Init failed status = %x.\r\n", Status);
  	return XST_FAILURE;
    }

//    resetIp();
    EnableCSI();

    xil_printf("PASS:222 \r\n");

	Status = demosaic();
	if (Status != XST_SUCCESS) {
		xil_printf("\n\rDemosaic Failed \n\r");
		return XST_FAILURE;
	}

	SensorConfig();

	Status = vdma();
		if (Status != XST_SUCCESS) {
	   xil_printf("\n\rVdma Failed \n\r");
	   return XST_FAILURE;
	 }

	u8 data = 0;

	WriteToReg(0x3008, 0x02);
	ReadCameraReg(0x3008, &data);
	xil_printf("RD_DATA : 0x%02X \r\n", data);
	Sensor_Delay();

	ReadCameraReg(0x300A, &data);
	xil_printf("RD_DATA : 0x%02X \r\n", data);

	ReadCameraReg(0x300B, &data);
	xil_printf("RD_DATA : 0x%02X \r\n", data);


    return XST_SUCCESS;
}





