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
#include "xil_io.h"
#include "xil_cache.h"
#include "xparameters.h"

#define C2C_BASE_ADDR_INIT      		0xA0000000  // Replace with actual address from Vivado
#define C2C_BASE_ADDR_INPUT_VALUE     	0xA0000010
#define C2C_BASE_ADDR_OUTPUT_OFFSET    	0xA0000018
#define C2C_BASE_ADDR_OUTPUT_VALUE  	0xFFFC0004  // 0x00000000  // Output Address

#define XEXECUTE_CFG_PORT1_ADDR_AP_CTRL             0x00
#define XEXECUTE_CFG_PORT1_ADDR_GIE                 0x04
#define XEXECUTE_CFG_PORT1_ADDR_IER                 0x08
#define XEXECUTE_CFG_PORT1_ADDR_ISR                 0x0c
#define XEXECUTE_CFG_PORT1_ADDR_CFG_PORT1_DATA      0x10
#define XEXECUTE_CFG_PORT1_BITS_CFG_PORT1_DATA      32
#define XEXECUTE_CFG_PORT1_ADDR_CFG_PORT1_ECHO_DATA 0x18
#define XEXECUTE_CFG_PORT1_BITS_CFG_PORT1_ECHO_DATA 32
#define XEXECUTE_CFG_PORT1_ADDR_CFG_PORT1_ECHO_CTRL 0x1c
#define XEXECUTE_CFG_PORT1_ADDR_DATA_PORT_DATA      0x28
#define XEXECUTE_CFG_PORT1_BITS_DATA_PORT_DATA      32

int main()
{
    uint32_t init_value = 0x00000003;
    uint32_t test_value = 0x00000042;
    uint32_t read_value;

    init_platform();
    print("Hello World\n\r");

    //u32 addr_high = (u32) ((u64)C2C_BASE_ADDR_OUTPUT_VALUE >> 32);
    u32 addr_low  = (u32) (C2C_BASE_ADDR_OUTPUT_VALUE & 0xFFFFFFFF);
    Xil_Out32(C2C_BASE_ADDR_INIT + XEXECUTE_CFG_PORT1_ADDR_DATA_PORT_DATA,     addr_low);
    //Xil_Out32(C2C_BASE_ADDR_INIT + XEXECUTE_CFG_PORT1_ADDR_DATA_PORT_DATA+0x4, addr_high);
    Xil_DCacheFlush();  // Ensure write goes through

    if (addr_low != Xil_In32(C2C_BASE_ADDR_INIT + XEXECUTE_CFG_PORT1_ADDR_DATA_PORT_DATA))
    		xil_printf("Bad address low!!!!\n\r");
    xil_printf("0x%08X\n\r", Xil_In32(C2C_BASE_ADDR_INIT + XEXECUTE_CFG_PORT1_ADDR_DATA_PORT_DATA));
    //if (addr_high != Xil_In32(C2C_BASE_ADDR_INIT + XEXECUTE_CFG_PORT1_ADDR_DATA_PORT_DATA+0x4))
    		//xil_printf("Bad address high!!!!\n\r");

    // Test output memory mapping
    Xil_Out32(C2C_BASE_ADDR_OUTPUT_VALUE, 0xDEADBEEF);
    if (Xil_In32(C2C_BASE_ADDR_OUTPUT_VALUE) != 0xDEADBEEF) {
        print("Wrong memory map!!!!!!!!!!\n");
        cleanup_platform();
        return -1;
    }
    print("Successfully write/read memory!\n\r");

    // Write test input value
    print("Trying to write input...\n\r");
    Xil_Out32(C2C_BASE_ADDR_INPUT_VALUE, test_value);
    Xil_DCacheFlush();  // Ensure write goes through
    Xil_In32(C2C_BASE_ADDR_INPUT_VALUE);  // Dummy read to force transaction
    for (volatile int i = 0; i < 100; i++);  // Small delay
    uint32_t confirm_write = Xil_In32(C2C_BASE_ADDR_INPUT_VALUE);
    xil_printf("Confirm write val: 0x%08X\n\r", confirm_write);

    // Write init value
    print("Trying to initialise...\n\r");
    Xil_Out32(C2C_BASE_ADDR_INIT, init_value);
    Xil_DCacheFlush();  // Ensure write goes through
    Xil_In32(C2C_BASE_ADDR_INIT);  // Dummy read to force transaction
    for (volatile int i = 0; i < 100; i++);  // Small delay
    uint32_t confirm_init = Xil_In32(C2C_BASE_ADDR_INIT);
    xil_printf("Confirm init val: 0x%08X\n\r", confirm_init);

    // Read back result from output
    read_value = Xil_In32(C2C_BASE_ADDR_OUTPUT_VALUE);
    xil_printf("HLS Output = 0x%08X\n\r", read_value);
    if (read_value == (0x40 + test_value)) {
        print("You rock! :) \n\r");
    } else {
        print("You suck! :( \n\r");
    }

    cleanup_platform();
    return 0;
}
