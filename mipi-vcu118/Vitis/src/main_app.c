///******************************************************************************
//*
//* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
//*
//* Permission is hereby granted, free of charge, to any person obtaining a copy
//* of this software and associated documentation files (the "Software"), to deal
//* in the Software without restriction, including without limitation the rights
//* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//* copies of the Software, and to permit persons to whom the Software is
//* furnished to do so, subject to the following conditions:
//*
//* The above copyright notice and this permission notice shall be included in
//* all copies or substantial portions of the Software.
//*
//* Use of the Software is limited solely to applications:
//* (a) running on a Xilinx device, or
//* (b) that interact with a Xilinx device through a bus or interconnect.
//*
//* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
//* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//* SOFTWARE.
//*
//* Except as contained in this notice, the name of the Xilinx shall not be used
//* in advertising or otherwise to promote the sale, use or other dealings in
//* this Software without prior written authorization from Xilinx.
//*
//******************************************************************************/
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

#include "xil_io.h"

int main() {
    int Status;

    xil_printf("\n\n*************** MIPI CAM VCU118 *************\r\n");
    Xil_ICacheDisable();
    Xil_DCacheDisable();

    initIIC();

    Status = SetupInterruptSystem();
    if (Status != XST_SUCCESS) {
        xil_printf("Interrupt setup failed\r\n");
        return XST_FAILURE;
    }

    Status = InitializeCsiRxSs();
    if (Status != XST_SUCCESS) {
      xil_printf("CSI Rx Ss Init failed status = %x.\r\n", Status);
  	return XST_FAILURE;
    }

    resetIp();
    EnableCSI();

	Status = demosaic();
	if (Status != XST_SUCCESS) {
		xil_printf("\n\rDemosaic Failed \n\r");
		return XST_FAILURE;
	}

	SensorConfig();

	WriteToReg(0x3008, 0x02);

	Sensor_Delay();

	Status = vdma();
		if (Status != XST_SUCCESS) {
	   xil_printf("\n\rVdma Failed \n\r");
	   return XST_FAILURE;
	 }

	dump_s2mm_status(0x44A20000);

	dump_img2axis_status(0x00010000);

	wait_frame(0x44A20000);
	xil_printf("\n\r +++++++++++++ FRAME SENT COMPLETED +++++++++++++\r\n");

	dump_s2mm_status(0x44A20000);
	u8 data = 0;

	ReadCameraReg(0x300A, &data);
	xil_printf("RD_DATA : 0x%02X \r\n", data);

	ReadCameraReg(0x300B, &data);
	xil_printf("RD_DATA : 0x%02X \r\n", data);

//	char s;
//
//	while(1){
//		s = getchar();
//		if(s == 115){
//			stop_vdma();
//			break;
//		}
//	}

    return XST_SUCCESS;
}





