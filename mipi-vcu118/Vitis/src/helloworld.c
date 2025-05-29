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
//*
//******************************************************************************/
///***************************** Include Files *********************************/
//
//#include "xparameters.h"
//#include "xiic.h"
//#include "xil_exception.h"
//#include "functions.h"
//#include "sensor_config_pcam.h"
//#include "xstatus.h"
//#include "sleep.h"
//#include "xiic_l.h"
//#include "xil_io.h"
//#include "xil_types.h"
////#include "xv_tpg.h"
//#include "xil_cache.h"
//#include "stdio.h"
//#include "xaxivdma.h"
//
//#define IMG_ADDR 0x81000000
//
///************************** Constant Definitions *****************************/
//
//
//#define PAGE_SIZE   16
//
//
///****************i************ Type Definitions *******************************/
//
//typedef u8 AddressType;
//
///************************** Variable Definitions *****************************/
//
//extern XIic IicAdapter ;	/*  IIC device. */
//extern XAxiVdma AxiVdma;
//
//
///*****************************************************************************/
///**
// *
// * Main function to initialize interop system and read data from AR0330 sensor
//
// * @param  None.
// *
// * @return
// *   - XST_SUCCESS if MIPI Interop was successful.
// *   - XST_FAILURE if MIPI Interop failed.
// *
// * @note   None.
// *
// ******************************************************************************/
//int main() {
//  int Status;
//  int pcam5c_mode = 1;
//  u8 data;
//
//  xil_printf("\n\r******************************************************\n\r");
//  Xil_ICacheDisable();
//  Xil_DCacheDisable();
//
//
//  //Initialize Adapter and Sensor IIC
//  Status = InitIIC();
//  if (Status != XST_SUCCESS) {
//	xil_printf("\n\r IIC initialization Failed \n\r");
//	return XST_FAILURE;
//  }
//  xil_printf("IIC Initializtion Done \n\r");
//
////  //Set up IIC Interrupt Handlers
//  SetupIICIntrHandlers();
//
//  //Initialize Adapter Interrupt System
//  Status = SetupAdapterInterruptSystem(&IicAdapter);
//  if (Status != XST_SUCCESS) {
//    xil_printf("\n\rInterrupt System Initialization Failed \n\r");
//    return XST_FAILURE;
//  }
//  xil_printf("Adapter Interrupt System Initialization Done \n\r");
//
////  microblaze_disable_interrupts();
//
//  //Set Address of Adapter IIC
//  Status =  SetAdapterIICAddress();
//  if (Status != XST_SUCCESS) {
//    xil_printf("\n\rAdapter IIC Address Setup Failed \n\r");
//	return XST_FAILURE;
//  }
//  xil_printf("Adapter IIC Address Set\n\r");
//
//  Status = InitializeCsiRxSs();
//  if (Status != XST_SUCCESS) {
//    xil_printf("CSI Rx Ss Init failed status = %x.\r\n", Status);
//	return XST_FAILURE;
//  }
//
//  resetIp();
//  EnableCSI();
//
//  Status = demosaic();
//  if (Status != XST_SUCCESS) {
//	xil_printf("\n\rDemosaic Failed \n\r");
//	return XST_FAILURE;
//  }
//
//  CamReset();
//
// //Preconifgure Sensor
//  Status = SensorPreConfig(pcam5c_mode);
// if (Status != XST_SUCCESS) {
//	xil_printf("\n\rSensor PreConfiguration Failed \n\r");
//	return XST_FAILURE;
// }
// xil_printf("\n\rSensor is PreConfigured\n\r");
//
//	Status = vdma();
//	if (Status != XST_SUCCESS) {
//   xil_printf("\n\rVdma Failed \n\r");
//   return XST_FAILURE;
// }
//
////  WritetoReg(0x31, 0x03, 0x11);
////  ReadFromReg(0x31, 0x03, &data);
////
////  WritetoReg(0x30, 0x08, 0x82);
////  ReadFromReg(0x30, 0x08, &data);
////
//// RunVDMA(&AxiVdma, XPAR_AXI_VDMA_0_DEVICE_ID, HORIZONTAL_RESOLUTION,
////		  VERTICAL_RESOLUTION, srcBuffer, FRAME_COUNTER, 0);
//
//  WritetoReg(0x30, 0x08, 0x02);
//  ReadFromReg(0x30, 0x08, &data);
//  Sensor_Delay();
//
//  ReadFromReg(0x30,0x0A, data);
//  ReadFromReg(0x30,0x0B, data);
//
//  // for(u16 reg = 0x0000; reg < 0x0010; reg++)
//  // {
//	  // if(ReadFromReg((reg >> 8) & 0xFF, reg & 0xFF, &data) == XST_SUCCESS)
//	  // {
//		  // xil_printf("\r\nRegister 0x%04X: 0x%02X\r\n", reg, data);
//	  // }
//	  // else {
//		  // xil_printf("\r\nERROR: Failed to read register 0x%04X", reg);
//	  // }
//  // }
//  // xil_printf("\n\rPipeline Configuration Completed \n\r");
//
//  return XST_SUCCESS;
//
//}

//#include "xparameters.h"
//#include "xiic.h"
//#include "xil_printf.h"
//#include "sleep.h"
//
//#define IIC_DEVICE_ID      XPAR_IIC_0_DEVICE_ID
//#define OV5640_I2C_ADDRESS 0x3C  // 7-bit address
//
//XIic IicInstance;
//
//int main() {
//    int Status;
//    u8 WriteBuffer[2];
//    u8 ReadBuffer[1];
//    u16 RegAddr;
//
//    xil_printf("I2C Test Starting...\r\n");
//
//    // Initialize IIC
//    Status = XIic_Initialize(&IicInstance, IIC_DEVICE_ID);
//    if (Status != XST_SUCCESS) {
//        xil_printf("IIC Initialization failed\r\n");
//        return XST_FAILURE;
//    }
//
//    // Set IIC address to OV5640
//    XIic_SetAddress(&IicInstance, XII_ADDR_TO_SEND_TYPE, OV5640_I2C_ADDRESS);
//
//    // Disable Global Interrupt (if previously enabled)
//    XIic_IntrGlobalDisable(&IicInstance);
//
//    // Example: read ID registers 0x300A and 0x300B from OV5640
//    u16 ids[] = { 0x300A, 0x300B  };
//
//    for (int i = 0; i < 2; i++) {
//        RegAddr = ids[i];
//        WriteBuffer[0] = (RegAddr >> 8) & 0xFF;
//        WriteBuffer[1] = RegAddr & 0xFF;
//
//        // Send register address
//        Status = XIic_Send(IicInstance.BaseAddress, OV5640_I2C_ADDRESS, WriteBuffer, 2, XIIC_REPEATED_START);
//        if (Status != 2) {
//            xil_printf("Failed to send reg 0x%04X\r\n", RegAddr);
//            continue;
//        }
//
//        // Read 1 byte from register
//        Status = XIic_Recv(IicInstance.BaseAddress, OV5640_I2C_ADDRESS, ReadBuffer, 1, XIIC_STOP);
//        if (Status != 1) {
//            xil_printf("Failed to read reg 0x%04X\r\n", RegAddr);
//            continue;
//        }
//
//        xil_printf("Register 0x%04X = 0x%02X\r\n", RegAddr, ReadBuffer[0]);
//        usleep(10000);
//    }
//
//    xil_printf("I2C Test Finished\r\n");
//
//    return 0;
//}
//

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//#include "xparameters.h"
//#include "xiic.h"
//#include "xil_exception.h"
////#include "functions.h"
//#include "sensor_config_pcam.h"
//#include "xstatus.h"
//#include "sleep.h"
//#include "xiic_l.h"
//#include "xil_io.h"
//#include "xil_types.h"
//#include "xil_cache.h"
//#include "stdio.h"
//#include "xaxivdma.h"
//#include "xil_printf.h"
//#include "xintc.h"
//#include "sleep.h"
//
////#include "new_function.c"
//
//#include "sensor_driver.h"
//
//typedef uint8_t  u8;
//typedef uint16_t u16;
//
//#define IIC_DEVICE_ID  XPAR_IIC_0_DEVICE_ID
//#define INTC_DEVICE_ID XPAR_INTC_0_DEVICE_ID
//#define IIC_INTR_ID    XPAR_INTC_0_IIC_0_VEC_ID
//#define OV5640_I2C_ADDR 0x3C
//
//// External IIC and Interrupt controller instances
//XIic IicInstance;
//XIntc Intc;
//
//#define IMG_ADDR 0x81000000
//
//int main() {
//    int Status;
//    u8 id_high = 0, id_low = 0;
//    u8 rd_data = 0;
//
//    xil_printf("\n\nStarting I2C Camera ID Read Test...\r\n");
//
//    Status = XIic_Initialize(&IicInstance, IIC_DEVICE_ID);
//    if (Status != XST_SUCCESS) {
//        xil_printf("IIC Init failed\r\n");
//        return XST_FAILURE;
//    }
//
//    XIic_SetAddress(&IicInstance, XII_ADDR_TO_SEND_TYPE, OV5640_I2C_ADDR);
//    XIic_SetRecvHandler(&IicInstance, &IicInstance, IicRecvHandler);
//    XIic_SetSendHandler(&IicInstance, &IicInstance, IicSendHandler);
//    XIic_SetStatusHandler(&IicInstance, &IicInstance, IicStatusHandler);
//
//    xil_printf("\n\n PASS: Starting I2C Camera ID Read Test...\r\n");
//
//    Status = SetupInterruptSystem();
//    if (Status != XST_SUCCESS) {
//        xil_printf("Interrupt setup failed\r\n");
//        return XST_FAILURE;
//    }
//
//    xil_printf("\n\n PASS: Setup Interrupt\r\n");
//
//    // Read ID high byte (0x300A)
//    Status = ReadFromReg(0x300A, &id_high);
//    if (Status != XST_SUCCESS) {
//        xil_printf("Failed to read register 0x300A\r\n");
//        return XST_FAILURE;
//    }
//
//    xil_printf("\n\n PASS: Readfrom\r\n");
//
//    // Read ID low byte (0x300B)
//    Status = ReadFromReg(0x300B, &id_low);
//    if (Status != XST_SUCCESS) {
//        xil_printf("Failed to read register 0x300B\r\n");
//        return XST_FAILURE;
//    }
//
//    xil_printf("OV5640 Camera ID: 0x%02X 0x%02X\r\n", id_high, id_low);
//
//    if (id_high == 0x56 && id_low == 0x40) {
//        xil_printf("Camera ID Read Successful!\r\n");
//    } else {
//        xil_printf("Unexpected Camera ID. Check I2C wiring or address.\r\n");
//    }
//
//    Status = ReadFromReg(0x5036, &rd_data);
//    if (Status != XST_SUCCESS) {
//        xil_printf("Failed to read register 0x5036\r\n");
//        return XST_FAILURE;
//    }
//
//    u8 read_back = 0;
//    u8 test_val = 0x42;
//
//    xil_printf("rd_data: 0x%02X \r\n", rd_data);
//
//	Status = WriteToReg(0x3008, test_val); // Replace 0x300C with a writable register
//	    if (Status == XST_SUCCESS) {
//	        xil_printf("Write 0x%02X -> Reg 0x3008, Read back: 0x%02X\r\n", test_val);
//	    } else {
//	        xil_printf("WriteThenRead failed.\r\n");
//	    }
//
//    test_val = 0x55;
//    read_back = 0;
//    rd_data = 0;
//
//    Status = ReadFromReg(0x5036, &rd_data);
//    if (Status != XST_SUCCESS) {
//        xil_printf("Failed to read register 0x5036\r\n");
//        return XST_FAILURE;
//    }
//
//    xil_printf("rd_data: 0x%02X \r\n", rd_data);
//
//
//    return XST_SUCCESS;
//}

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
    u8 id_high = 0, id_low = 0;

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





