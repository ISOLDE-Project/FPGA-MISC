/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xexecute_hw.h"
#include "xexecute.h"

#define AIML_STUB_0_S_AXI_CFG_PORT1_BASEADDR  0x00A0000000
#define ADDR_RESULT                           0xFFFC0004




int main()
{
    init_platform();
    print("Starting test... \n\r");
    u32 my_cmd = 0x42;
    u32 done =0x0;
    u32 isReady = 0x0;
    volatile u32* pResult=(u32*)ADDR_RESULT;
    *pResult =0xBADCAFE;
    Xil_DCacheFlush();  // Ensure write goes through
    if( *pResult != 0xBADCAFE)
    	print("TEST MEMORY FAILED\n\r");

    u32 addr_high = (u32) ((u64)ADDR_RESULT >> 32);
    u32 addr_low  = (u32) (ADDR_RESULT & 0xFFFFFFFF);
    XExecute_WriteReg(AIML_STUB_0_S_AXI_CFG_PORT1_BASEADDR, XEXECUTE_CFG_PORT1_ADDR_DATA_PORT_DATA,     addr_low);
    XExecute_WriteReg(AIML_STUB_0_S_AXI_CFG_PORT1_BASEADDR, XEXECUTE_CFG_PORT1_ADDR_DATA_PORT_DATA+0x4, addr_high);
//
    XExecute_WriteReg(AIML_STUB_0_S_AXI_CFG_PORT1_BASEADDR, XEXECUTE_CFG_PORT1_ADDR_CFG_PORT1_DATA,     my_cmd);
    //

    XExecute_WriteReg(AIML_STUB_0_S_AXI_CFG_PORT1_BASEADDR, 0x0,0x1);
    Xil_DCacheFlush();  // Ensure write goes through
    done= XExecute_ReadReg(AIML_STUB_0_S_AXI_CFG_PORT1_BASEADDR, 0x0);

    u32 loopback= XExecute_ReadReg(AIML_STUB_0_S_AXI_CFG_PORT1_BASEADDR, XEXECUTE_CFG_PORT1_ADDR_CFG_PORT1_ECHO_DATA);
    u32 result=*pResult;

    if(result != loopback)
    	print("TEST FAILED\n\r");
    if(loopback == (my_cmd+0x40))
    	print("TEST s_AXI: OK\n\r");
	else
		print("TEST s_AIX: FAILED\n\r");

    if(*pResult == (my_cmd+0x40))
    	print("TEST m_AXI: OK\n\r");
	else
		print("TEST m_AIX: FAILED\n\r");

    cleanup_platform();
    return 0;
}
