#include "xparameters.h"
#include "xiic.h"
#include "xil_printf.h"
#include "xil_exception.h"
#include "xintc.h"
#include "sleep.h"
#include "sensor_config_pcam.h"
#include <stdint.h>
#include "xstatus.h"
#include "xaxivdma.h"
#include "xil_types.h"
#include "xcsiss.h"

#include "xv_demosaic.h"

#ifdef XPAR_INTC_0_DEVICE_ID
 #include "xintc.h"
#else
 #include "xscugic.h"
#endif

typedef uint8_t  u8;
typedef uint16_t u16;

#define IIC_DEVICE_ID XPAR_IIC_0_DEVICE_ID
#define INTC_DEVICE_ID XPAR_INTC_0_DEVICE_ID
#define IIC_INTR_ID XPAR_INTC_0_IIC_0_VEC_ID

#define OV5640_I2C_ADDR 0x3C

static XIic IicInstance;
static XIntc Intc;

#define VDMA_BASE XPAR_AXIVDMA_0_BASEADDR

#define XCSIRXSS_DEVICE_ID  XPAR_CSISS_0_DEVICE_ID
#define DEMOSAIC_DEVICE_ID 	XPAR_XV_DEMOSAIC_0_DEVICE_ID
#define GPIO_SENSOR 		XPAR_GPIO_1_BASEADDR

volatile int TransmitComplete = 0;
volatile int ReceiveComplete = 0;

#define HORIZONTAL_RESOLUTION	1920 //1280

#define VERTICAL_RESOLUTION		1080 //720
#define FRAME_COUNTER			3
#define STRIDE_VDMA_0			1920*3

/* Debug Constants */
#define MM2S_HALT_SUCCESS	121
#define MM2S_HALT_FAILURE	122
#define S2MM_HALT_SUCCESS	131
#define S2MM_HALT_FAILURE	132

#define SET            (0x01)
#define VDMA_S2MM    (VDMA_BASE + 0x30)
#define S2MM	1

typedef u8 AddressType;

/****************** Instances **********************/
XCsiSs CsiRxSs;

XV_demosaic InstancePtr;
XV_demosaic_Config  *demosaic_Config;
XAxiVdma AxiVdma;


/******************** Data structure Declarations *****************************/

typedef struct vdma_handle
{
	/* The device ID of the VDMA */
	unsigned int device_id;
	/* The state variable to keep track if the initialization is done*/
	unsigned int init_done;
	/** The XAxiVdma driver instance data. */
	XAxiVdma* InstancePtr;
	/* The XAxiVdma_DmaSetup structure contains all the necessary information to
	 * start a frame write or read. */
//	XAxiVdma_DmaSetup ReadCfg;
	XAxiVdma_DmaSetup WriteCfg;
	/* Horizontal size of frame */
	unsigned int hsize;
	/* Vertical size of frame */
	unsigned int vsize;
	/* Buffer address from where read and write will be done by VDMA */
	unsigned int buffer_address;
	/* Flag to tell VDMA to interrupt on frame completion*/
	unsigned int enable_frm_cnt_intr;
	/* The counter to tell VDMA on how many frames the interrupt should happen*/
	unsigned int number_of_frame_count;
}vdma_handle;

/******************** Constant Definitions **********************************/

/*
 * Device related constants. These need to defined as per the HW system.
 */
vdma_handle vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES];
static unsigned int context_init=0;

/******************* Function Prototypes ************************************/

//static int ReadSetup(vdma_handle *vdma_context);
static int WriteSetup(vdma_handle *vdma_context);
static int StartTransfer(XAxiVdma *InstancePtr);

#define VDMA_BASEADDR	XPAR_AXIVDMA_0_BASEADDR

//volatile u32 *Mm2sStatusReg = (u32*)(VDMA_BASEADDR + 0x4);
volatile u32 *S2mmStatusReg = (u32*)(VDMA_BASEADDR + 0x34);

volatile u32 *VdmaParkPtrReg = (u32 *)(VDMA_BASEADDR + 0x28);

volatile u32 *VdmaS2MMCrReg = (u32 *)(VDMA_BASEADDR + 0x30);
volatile u32 *VdmaS2MMStatusReg = (u32 *)(VDMA_BASEADDR + 0x34);
volatile u32 *VdmaS2MMVertSizeReg = (u32 *)(VDMA_BASEADDR + 0xA0);
volatile u32 *VdmaS2MMHoriSizeReg = (u32 *)(VDMA_BASEADDR + 0xA4);
volatile u32 *VdmaS2MMFrmDlrStrideReg = (u32 *)(VDMA_BASEADDR + 0xA8);

volatile u32 *VdmaS2MMFrameBuffer0Reg = (u32 *)(VDMA_BASEADDR + 0xAC);

unsigned int srcBuffer = (0x80000000U + 0x1000000);

/*****************************************************************************/
/**
*
* RunVDMA API
*
* This API is the interface between application and other API.
* When application will call this API with right argument, This API will call
* rest of the API to configure the read and write path of VDMA,based on ID.
* After that it will start both the read and write path of VDMA
*
* @param	InstancePtr is the handle to XAxiVdma data structure.
* @param	DeviceId is the device ID of current VDMA
* @param	hsize is the horizontal size of the frame. It will be in Pixels.
* 		The actual size of frame will be calculated by multiplying this
* 		with tdata width.
* @param 	vsize is the Vertical size of the frame.
* @param	buf_base_addr is the buffer address where frames will be written
*		and read by VDMA.
* @param 	number_frame_count specifies after how many frames the interrupt
*		should come.
* @param 	enable_frm_cnt_intr is for enabling frame count interrupt
*		when set to 1.
* @return
*		- XST_SUCCESS if example finishes successfully
*		- XST_FAILURE if example fails.
*
******************************************************************************/
int RunVDMA(XAxiVdma* InstancePtr, int DeviceId, int hsize,
		int vsize, int buf_base_addr, int number_frame_count,
		int enable_frm_cnt_intr)
{
  int Status,i;
 XAxiVdma_Config *Config;
 XAxiVdma_FrameCounter FrameCfgPtr;

  /* This is one time initialization of state machine context.
   * In first call it will be done for all VDMA instances in the system.
   */
  if(context_init==0) {
	for(i=0; i < XPAR_XAXIVDMA_NUM_INSTANCES; i++) {
	  vdma_context[i].InstancePtr = NULL;
	  vdma_context[i].device_id = -1;
	  vdma_context[i].hsize = 0;
	  vdma_context[i].vsize = 0;
	  vdma_context[i].init_done = 0;
	  vdma_context[i].buffer_address = 0;
	  vdma_context[i].enable_frm_cnt_intr = 0;
	  vdma_context[i].number_of_frame_count = 0;
	}
	context_init = 1;
  }

  /* The below initialization will happen for each VDMA. The API argument
   * will be stored in internal data structure
   */

  /* The information of the XAxiVdma_Config comes from hardware build.
   * The user IP should pass this information to the AXI DMA core.
   */
  #ifndef SDT
    Config = XAxiVdma_LookupConfig(DeviceId);
  #else
    Config = XAxiVdma_LookupConfig(XPAR_AXI_VDMA_0_BASEADDR);
  #endif
  if (!Config) {
	xil_printf("No video DMA found for ID %d\r\n",DeviceId );
	return XST_FAILURE;
  }

#ifndef SDT
  if(vdma_context[DeviceId].init_done ==0) {
	vdma_context[DeviceId].InstancePtr = InstancePtr;
#else
  if(vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].init_done ==0) {
	vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].InstancePtr = InstancePtr;
#endif
	/* Initialize DMA engine */
    #ifndef SDT
	    Status = XAxiVdma_CfgInitialize(vdma_context[DeviceId].InstancePtr,
						Config, Config->BaseAddress);
    #else
        Status = XAxiVdma_CfgInitialize(vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].InstancePtr,
						Config, Config->BaseAddress);
    #endif
	if (Status != XST_SUCCESS) {
	  xil_printf("Configuration Initialization failed %d\r\n",
					Status);
	  return XST_FAILURE;
	}

    #ifndef SDT
	  vdma_context[DeviceId].init_done = 1;
    #else
      vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].init_done = 1;
    #endif
  }

#ifndef SDT
  vdma_context[DeviceId].device_id = DeviceId;
  vdma_context[DeviceId].vsize = vsize;
  vdma_context[DeviceId].enable_frm_cnt_intr = enable_frm_cnt_intr;
  vdma_context[DeviceId].buffer_address = buf_base_addr;
  vdma_context[DeviceId].number_of_frame_count = number_frame_count;
  vdma_context[DeviceId].hsize = hsize * (Config->Mm2SStreamWidth>>3);
#else
  vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].device_id = XPAR_AXI_VDMA_0_BASEADDR;
  vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].vsize = vsize;
  vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].enable_frm_cnt_intr = enable_frm_cnt_intr;
  vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].buffer_address = buf_base_addr;
  vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].number_of_frame_count = number_frame_count;
  vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].hsize = hsize * (Config->Mm2SStreamWidth>>3);
#endif
  /* Setup the write channel */
#ifndef SDT
  Status = WriteSetup(&vdma_context[DeviceId]);
#else
  Status = WriteSetup(&vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES]);
#endif
  if (Status != XST_SUCCESS) {
	xil_printf("Write channel setup failed %d\r\n", Status);
	if(Status == XST_VDMA_MISMATCH_ERROR)
	  xil_printf("DMA Mismatch Error\r\n");
	return XST_FAILURE;
  }

  /* The frame counter interrupt is enabled, setting VDMA for same */
#ifndef SDT
  if(vdma_context[DeviceId].enable_frm_cnt_intr) {
#else
  if(vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].enable_frm_cnt_intr) {
#endif
//	FrameCfgPtr.ReadDelayTimerCount = 1;
//	FrameCfgPtr.ReadFrameCount = number_frame_count;
	FrameCfgPtr.WriteDelayTimerCount = 1;
	FrameCfgPtr.WriteFrameCount = number_frame_count;
#ifndef SDT
	XAxiVdma_SetFrameCounter(vdma_context[DeviceId].InstancePtr,
			&FrameCfgPtr);
#else
	XAxiVdma_SetFrameCounter(vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].InstancePtr,
			&FrameCfgPtr);
#endif
	/* Enable DMA read and write channel interrupts.
	 * The configuration for interrupt
	 * controller will be done by application	 */
#ifndef SDT
	XAxiVdma_IntrEnable(vdma_context[DeviceId].InstancePtr,
				XAXIVDMA_IXR_ERROR_MASK |
				XAXIVDMA_IXR_FRMCNT_MASK,XAXIVDMA_WRITE);
//	XAxiVdma_IntrEnable(vdma_context[DeviceId].InstancePtr,
//				XAXIVDMA_IXR_ERROR_MASK |
//				XAXIVDMA_IXR_FRMCNT_MASK,XAXIVDMA_READ);
#else
	XAxiVdma_IntrEnable(vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].InstancePtr,
				XAXIVDMA_IXR_ERROR_MASK |
				XAXIVDMA_IXR_FRMCNT_MASK,XAXIVDMA_WRITE);
	XAxiVdma_IntrEnable(vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].InstancePtr,
				XAXIVDMA_IXR_ERROR_MASK |
				XAXIVDMA_IXR_FRMCNT_MASK,XAXIVDMA_READ);
#endif
  } else	{
	  /* Enable DMA read and write channel interrupts.
	   * The configuration for interrupt
	   * controller will be done by application	 */
#ifndef SDT
	XAxiVdma_IntrEnable(vdma_context[DeviceId].InstancePtr,
				XAXIVDMA_IXR_ERROR_MASK,XAXIVDMA_WRITE);
//	XAxiVdma_IntrEnable(vdma_context[DeviceId].InstancePtr,
//				XAXIVDMA_IXR_ERROR_MASK ,XAXIVDMA_READ);
#else
	XAxiVdma_IntrEnable(vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].InstancePtr,
				XAXIVDMA_IXR_ERROR_MASK,XAXIVDMA_WRITE);
	XAxiVdma_IntrEnable(vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].InstancePtr,
				XAXIVDMA_IXR_ERROR_MASK ,XAXIVDMA_READ);
#endif
  }

  /* Start the DMA engine to transfer */
#ifndef SDT
  Status = StartTransfer(vdma_context[DeviceId].InstancePtr);
#else
  Status = StartTransfer(vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].InstancePtr);
#endif
  if (Status != XST_SUCCESS) {
	if(Status == XST_VDMA_MISMATCH_ERROR)
	  xil_printf("DMA Mismatch Error\r\n");
	return XST_FAILURE;
  }
#if DEBUG_MODE
  xil_xil_printf("Code is in Debug mode,\
		  Make sure that buffer addresses are at valid memory \r\n");
  xil_printf("In triple mode, \
		  there has to be six consecutive buffers for Debug mode \r\n");
  {

#ifndef SDT
    u32 pixels,j,Addr = vdma_context[DeviceId].buffer_address;
#else
    u32 pixels,j,Addr = vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].buffer_address;
#endif
	u8 *dst,*src;
#ifndef SDT
	u32 total_pixel = vdma_context[DeviceId].stride * \
			vdma_context[DeviceId].vsize;
#else
	u32 total_pixel = vdma_context[XPAR_XAXIVDMA_NUM_INSTANCES].stride * \
			vdma_context[DeviceId].vsize;
#endif
	src = (unsigned char *)Addr;
	dst = (unsigned char *)Addr + (total_pixel * \
			vdma_context->InstancePtr->MaxNumFrames);

	for(j=0;j<vdma_context->InstancePtr->MaxNumFrames;j++) {
	  for(pixels=0;pixels<total_pixel;pixels++) {
		if(src[pixels] != dst[pixels]) {
		  xil_xil_printf("VDMA transfer failed: SRC=0x%x, DST=0x%x\r\n",
							src[pixels],dst[pixels]);
		  exit(-1);
		}
	  }
	  src = src + total_pixel;
	  dst = dst + total_pixel;
	}
  }
  xil_printf("VDMA transfer is happening and checked for 3 frames \r\n");
#endif

  return XST_SUCCESS;

}



  /*****************************************************************************/
  /**
  *
  * This function sets up the write channel
  *
  * @param	dma_context is the context pointer to the VDMA engine..
  *
  * @return	XST_SUCCESS if the setup is successful, XST_FAILURE otherwise.
  *
  * @note		None.
  *
  ******************************************************************************/
  static int WriteSetup(vdma_handle *vdma_context)
  {
    int Index;
    u32 Addr;
    int Status;

    vdma_context->WriteCfg.VertSizeInput = vdma_context->vsize;
    vdma_context->WriteCfg.HoriSizeInput = vdma_context->hsize;

    vdma_context->WriteCfg.Stride = STRIDE_VDMA_0;
    /* This example does not test frame delay */
    vdma_context->WriteCfg.FrameDelay = 0;

    vdma_context->WriteCfg.EnableCircularBuf = 1;
    vdma_context->WriteCfg.EnableSync = 1;  /*  Gen-Lock */

    vdma_context->WriteCfg.PointNum = 0;
    vdma_context->WriteCfg.EnableFrameCounter = 0; /* Endless transfers */

    vdma_context->WriteCfg.FixedFrameStoreAddr = 0; /* We are not doing parking */
    /* Configure the VDMA is per fixed configuration, This configuration
     * is being used by majority of customers. Expert users can play around
     * with this if they have different configurations
     */

    Status = XAxiVdma_DmaConfig(vdma_context->InstancePtr,
  		          XAXIVDMA_WRITE, &vdma_context->WriteCfg);
    if (Status != XST_SUCCESS) {
  	xil_printf("Write channel config failed %d\r\n", Status);
      return Status;
    }

    /* Initialize buffer addresses
     *
     * Use physical addresses
     */
    Addr = vdma_context->buffer_address;
    /* If Debug mode is enabled write frame is shifted 3 Frames
     * store ahead to compare read and write frames
     */
  #if DEBUG_MODE
    Addr = Addr + vdma_context->InstancePtr->MaxNumFrames * \
  			(vdma_context->stride * vdma_context->vsize);
  #endif

    for(Index = 0; Index < vdma_context->InstancePtr->MaxNumFrames; Index++){
  	vdma_context->WriteCfg.FrameStoreStartAddr[Index] = Addr;
  #if DEBUG_MODE
  	xil_xil_printf("Write Buffer %d address: 0x%x \r\n",Index,Addr);
  #endif

  	Addr += (vdma_context->hsize * vdma_context->vsize);
    }

    /* Set the buffer addresses for transfer in the DMA engine */
    Status = XAxiVdma_DmaSetBufferAddr(vdma_context->InstancePtr,
  			XAXIVDMA_WRITE,
  			vdma_context->WriteCfg.FrameStoreStartAddr);
    if (Status != XST_SUCCESS) {
  	xil_printf("Write channel set buffer address failed %d\r\n", Status);
      return XST_FAILURE;
    }

    /* Clear data buffer
     */
  #if DEBUG_MODE
    memset((void *)vdma_context->buffer_address, 0,
  			vdma_context->ReadCfg.Stride * \
  			vdma_context->ReadCfg.VertSizeInput * \
  			vdma_context->InstancePtr->MaxNumFrames);
  #endif
    return XST_SUCCESS;

  }


  /*****************************************************************************/
  /**
  *
  * This function starts the DMA transfers. Since the DMA engine is operating
  * in circular buffer mode, video frames will be transferred continuously.
  *
  * @param	InstancePtr points to the DMA engine instance
  *
  * @return
  *		- XST_SUCCESS if both read and write start successfully
  *		- XST_FAILURE if one or both directions cannot be started
  *
  * @note		None.
  *
  ******************************************************************************/
  static int StartTransfer(XAxiVdma *InstancePtr)
  {

    int Status;
    /* Start the write channel of VDMA */
    Status = XAxiVdma_DmaStart(InstancePtr, XAXIVDMA_WRITE);
    if (Status != XST_SUCCESS) {
  	xil_printf("Start Write transfer failed %d\r\n", Status);
      return XST_FAILURE;
    }
  //  /* Start the Read channel of VDMA */
  //  Status = XAxiVdma_DmaStart(InstancePtr, XAXIVDMA_READ);
  //  if (Status != XST_SUCCESS) {
  //	xil_xil_printf("Start read transfer failed %d\r\n", Status);
  //	return XST_FAILURE;
  //  }

    return XST_SUCCESS;

  }



  /*****************************************************************************/
  /**
  *
  * This function wait until the DMA channel halts
  *
  * @param	VdmaChannel specifes VdmaChannel is MM2S or S2MM
  *.@param	VdmaBaseAddr VDMA base address
  *
  * @return
  *		MM2S_HALT_SUCCESS, S2MM_HALT_SUCCESS in success
  *		MM2S_HALT_FAILURE, S2MM_HALT_FAILURE on failure
  *
  * @note		None.
  *
  ******************************************************************************/
  s32 WaitForCompletion(s32 VdmaChannel, u32 *VdmaBaseAddr)
  {
  //  if (VdmaChannel == MM2S) {
  //    while (!(*Mm2sStatusReg & 0x1)) {
  //      xil_xil_printf("Mm2sStatusReg = 0x%x\r\n", *Mm2sStatusReg);
  //	  xdbg_xil_printf(XDBG_DEBUG_GENERAL,"Waiting for MM2S to halt ..."
  //			"MM2S SR = 0x%x\r\n", *Mm2sStatusReg);
  //    }
  //	if ((*Mm2sStatusReg & 0x1)) {
  //	  xdbg_xil_printf(XDBG_DEBUG_GENERAL," MM2S_HALT_SUCCESS \r\n");
  //	  return MM2S_HALT_SUCCESS;
  //	} else {
  //	  xil_xil_printf(" returning MM2S_HALT_FAILURE \r\n");
  //	  return MM2S_HALT_FAILURE;
  //	}
  //  }
  //  else
  	  if (VdmaChannel == S2MM) {
      xdbg_printf(XDBG_DEBUG_GENERAL," Poll on s2mm status register\r\n");
  	while (!(*S2mmStatusReg & 0x1)) {
        xdbg_printf(XDBG_DEBUG_GENERAL," Waiting for S2MM to halt ..."
  				"S2MM SR = 0x%x\r\n", *S2mmStatusReg);
  	}
  	if((*S2mmStatusReg & 0x1)) {
        xdbg_printf(XDBG_DEBUG_GENERAL," S2MM_HALT_SUCCESS \r\n");
        return S2MM_HALT_SUCCESS;
  	}
  	else {
  	  xil_printf(" returning S2MM_HALT_FAILURE \r\n");
        return S2MM_HALT_FAILURE;
  	}
    }
    return XST_FAILURE;
  }


  /***************************************************************************/
  /**
  *
  * This function ResetVDMA
  *
  * @param	None
  *
  * @return	None
  *
  * @note		None.
  *
  ******************************************************************************/
  void ResetVDMA()
  {

  //  XAxiVdma_Reset(&AxiVdma,XAXIVDMA_READ);
    XAxiVdma_Reset(&AxiVdma,XAXIVDMA_WRITE);

  }

  void HaltVDMA()
  {

    ResetVDMA();

  //  WaitForCompletion(VDMA_MM2S, (u32*)VDMA_BASEADDR);

    WaitForCompletion(VDMA_S2MM, (u32*)VDMA_BASEADDR);

  }

  /***************************************************************************/
  /**
   * This function programs MIPI CSI SS with the required timing paramters.
   *
   * @return      None.
   *
   * @note        None.
   *
   ***************************************************************************/

  u32 InitializeCsiRxSs(void)
  {
    u32 Status = 0;
    XCsiSs_Config *CsiRxSsCfgPtr = NULL;
  #ifndef SDT
    CsiRxSsCfgPtr = XCsiSs_LookupConfig(XCSIRXSS_DEVICE_ID);
  #else
    CsiRxSsCfgPtr = XCsiSs_LookupConfig(XCSIRXSS_BASE);
  #endif
    if (!CsiRxSsCfgPtr) {
      xil_printf("CSI2RxSs LookupCfg failed\r\n");
      return XST_FAILURE;
    }

    Status = XCsiSs_CfgInitialize(&CsiRxSs, CsiRxSsCfgPtr,
  		                               CsiRxSsCfgPtr->BaseAddr);

    if (Status != XST_SUCCESS) {
      xil_printf("CsiRxSs Cfg init failed - %x\r\n", Status);
      return Status;
    }

    return XST_SUCCESS;

  }

  /***************************************************************************/
  /**
   *  * This function enables MIPI CSI IP
   *   *
   *    * @return      None.
   *     *
   *      * @note        None.
   *       *
  ****************************************************************************/

  void EnableCSI(void)
  {
    XCsiSs_Activate(&CsiRxSs, XCSI_ENABLE);
  }

  /***************************************************************************/
  /**
   *  * This function disables MIPI CSI IP
   *   *
   *    * @return      None.
   *     *
   *      * @note        None.
   *       *
  ****************************************************************************/

  void DisableCSI(void)
  {
    XCsiSs_Reset(&CsiRxSs);
  }

  /*****************************************************************************/
  /**
  * This function resets IPs.
  *
  * @return	None.
  *
  * @note		None.
  *
  ******************************************************************************/
  void resetIp()
  {

	  xil_printf("\n\rReset IN\n\r");
    DisableCSI();
    // HaltVDMA();
    // resetVIP();
    xil_printf("\n\rReset Done\n\r");

  }

  /*
  * The configuration table for devices
  */
  #ifndef SDT
  XV_demosaic_Config XV_demosaic_ConfigTable[] =
  {
  	{
  #ifdef XPAR_XV_DEMOSAIC_NUM_INSTANCES
  		XPAR_XV_DEMOSAIC_0_DEVICE_ID,
  		XPAR_XV_DEMOSAIC_0_S_AXI_CTRL_BASEADDR,
  		XPAR_XV_DEMOSAIC_0_SAMPLES_PER_CLOCK,
  		XPAR_XV_DEMOSAIC_0_MAX_COLS,
  		XPAR_XV_DEMOSAIC_0_MAX_ROWS,
  		XPAR_XV_DEMOSAIC_0_MAX_DATA_WIDTH,
  		XPAR_XV_DEMOSAIC_0_ALGORITHM
  #endif
  	}
  };

  XV_demosaic_Config *XV_demosaic_LookupConfig(u16 DeviceId) {
  	XV_demosaic_Config *ConfigPtr = NULL;

  	int Index;

  	for (Index = 0; Index < XPAR_XV_DEMOSAIC_NUM_INSTANCES; Index++) {
  		if (XV_demosaic_ConfigTable[Index].DeviceId == DeviceId) {
  			ConfigPtr = &XV_demosaic_ConfigTable[Index];
  			break;
  		}
  	}

  	return ConfigPtr;
  }
  #endif

  /*****************************************************************************/
  /**
   * This function programs demosaic with the given width and height
   *
   * @param	width is Hsize of a packet in pixels.
   * @param	height is number of lines of a packet.
   *
   * @return	None.
   *
   * @note	None.
   *
   *****************************************************************************/
  int demosaic()
  {
  #ifndef SDT
    demosaic_Config = XV_demosaic_LookupConfig(DEMOSAIC_DEVICE_ID);
  #else
    demosaic_Config = XV_demosaic_LookupConfig(XPAR_XV_DEMOSAIC_0_BASEADDR);
  #endif
    XV_demosaic_CfgInitialize(&InstancePtr, demosaic_Config,
  		                           demosaic_Config->BaseAddress);
    XV_demosaic_Set_HwReg_width(&InstancePtr, 1920);
    XV_demosaic_Set_HwReg_height(&InstancePtr, 1080);
    XV_demosaic_Set_HwReg_bayer_phase(&InstancePtr, 0x3);
    XV_demosaic_EnableAutoRestart(&InstancePtr);
    XV_demosaic_Start(&InstancePtr);
    return XST_SUCCESS;

  }

  int vdma(){

  	ResetVDMA();

  	RunVDMA(&AxiVdma, XPAR_AXIVDMA_0_DEVICE_ID, HORIZONTAL_RESOLUTION, \
  			  VERTICAL_RESOLUTION, srcBuffer, FRAME_COUNTER, 0);

  	return XST_SUCCESS;

  }

  void stop_vdma(){

  	XAxiVdma_DmaStop(&AxiVdma, XAXIVDMA_WRITE);

  }

  void CamReset()
  {
  	Xil_Out32(GPIO_SENSOR, 0x01);
  	Xil_Out32(GPIO_SENSOR, 0x00);
  	Xil_Out32(GPIO_SENSOR, 0x01);
  }

int WriteToReg(u16 reg_addr, u8 write_data);

void IicSendHandler(XIic* InstancePtr) {
    TransmitComplete = 1;
}

void IicRecvHandler(XIic* InstancePtr) {
    ReceiveComplete = 1;
}

void IicStatusHandler(XIic* InstancePtr, int Event) {
    // Optional: Handle bus errors or arbitration lost
}

//1ms delay; processor clk = 100 MHz
void Sensor_Delay()
{
  int cnt;
  for(cnt = 0; cnt < 100; cnt++){};
}

int initIIC(){

	int Status;

	xil_printf("PASS2 \r\n");

    Status = XIic_Initialize(&IicInstance, IIC_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        xil_printf("IIC Init failed\r\n");
        return XST_FAILURE;
    }

    xil_printf("PASS3 \r\n");

    XIic_SetAddress(&IicInstance, XII_ADDR_TO_SEND_TYPE, OV5640_I2C_ADDR);
    XIic_SetRecvHandler(&IicInstance, &IicInstance, IicRecvHandler);
    XIic_SetSendHandler(&IicInstance, &IicInstance, IicSendHandler);
    XIic_SetStatusHandler(&IicInstance, &IicInstance, IicStatusHandler);

    return Status;

}

int SetupInterruptSystem() {
    int Status;

    xil_printf("PASS_3\r\n");

    Status = XIntc_Initialize(&Intc, INTC_DEVICE_ID);
    if (Status != XST_SUCCESS) return XST_FAILURE;

    xil_printf("PASS_4\r\n");

    Status = XIntc_Connect(&Intc, IIC_INTR_ID,
        (XInterruptHandler)XIic_InterruptHandler,
        &IicInstance);
    if (Status != XST_SUCCESS) return XST_FAILURE;

    xil_printf("PASS_5\r\n");

    XIntc_Start(&Intc, XIN_REAL_MODE);

    xil_printf("PASS_6\r\n");

    XIntc_Enable(&Intc, IIC_INTR_ID);

    xil_printf("PASS_7\r\n");
    microblaze_enable_interrupts();

    xil_printf("PASS_8\r\n");
    return XST_SUCCESS;
}

// I2C register read: OV5640 uses 16-bit reg addresses, 8-bit data
int ReadCameraReg(u16 reg_addr, u8* data) {
    u8 WriteBuffer[2];
    int Status;

    WriteBuffer[0] = (reg_addr >> 8) & 0xFF;
    WriteBuffer[1] = reg_addr & 0xFF;

    TransmitComplete = 0;
    ReceiveComplete = 0;

    // Write register address
    Status = XIic_Start(&IicInstance);
    if (Status != XST_SUCCESS) return XST_FAILURE;

    Status = XIic_MasterSend(&IicInstance, WriteBuffer, 2);
    if (Status != XST_SUCCESS) return XST_FAILURE;

    while (!TransmitComplete);


    // Read the data
    Status = XIic_MasterRecv(&IicInstance, data, 1);
    if (Status != XST_SUCCESS) return XST_FAILURE;

    while (!ReceiveComplete);

    XIic_Stop(&IicInstance);
    return XST_SUCCESS;
}

int WriteToReg(u16 reg_addr, u8 write_data) {
    u8 WriteBuffer[3];
    int Status;

    // Prepare the buffer: 16-bit reg address + 8-bit data
    WriteBuffer[0] = (reg_addr >> 8) & 0xFF;
    WriteBuffer[1] = reg_addr & 0xFF;
    WriteBuffer[2] = write_data;

    TransmitComplete = 0;
    ReceiveComplete = 0;

    Status = XIic_Start(&IicInstance);
    if (Status != XST_SUCCESS) return XST_FAILURE;

    // Write register address and data
    Status = XIic_MasterSend(&IicInstance, WriteBuffer, 3);
    if (Status != XST_SUCCESS) return XST_FAILURE;
    while (!TransmitComplete);

    // Small delay before read (sensor timing)
    usleep(1000);

    XIic_Stop(&IicInstance);
    return XST_SUCCESS;
}



int SensorConfig() {

	u32 Index, MaxIndex, MaxIndex1, MaxIndex2;
	int Status;
	u8 WriteBuffer[3];

	Status = XIic_SetAddress(&IicInstance, XII_ADDR_TO_SEND_TYPE, OV5640_I2C_ADDR);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	WriteToReg(0x3103, 0x11);
	WriteToReg(0x3008, 0x82);
	Sensor_Delay();

	MaxIndex = length_sensor_pre;
	for(Index = 0; Index < (MaxIndex - 0); Index++)
	{
		WriteBuffer[0] = sensor_pre[Index].Address >> 8;
		WriteBuffer[1] = sensor_pre[Index].Address;
		WriteBuffer[2] = sensor_pre[Index].Data;

		uint16_t reg_addr = ((uint16_t)WriteBuffer[0] << 8) | WriteBuffer[1];
		uint8_t write_data = WriteBuffer[2];
		Sensor_Delay();
		WriteToReg(reg_addr, write_data);

	}


	WriteToReg(0x3008, 0x42);


	MaxIndex1 = length_pcam5c_mode1;

	for(Index = 0; Index < (MaxIndex1 - 0); Index++)
	{
		WriteBuffer[0] = pcam5c_mode1[Index].Address >> 8;
		WriteBuffer[1] = pcam5c_mode1[Index].Address;
		WriteBuffer[2] = pcam5c_mode1[Index].Data;

		uint16_t reg_addr = ((uint16_t)WriteBuffer[0] << 8) | WriteBuffer[1];
		uint8_t write_data = WriteBuffer[2];

		Sensor_Delay();

		WriteToReg(reg_addr, write_data);

	}


	WriteToReg(0x3008, 0x02);
	Sensor_Delay();
	WriteToReg(0x3008, 0x42);


	MaxIndex2 = length_sensor_list;

	for(Index = 0; Index < (MaxIndex2 - 0); Index++)
	{
		WriteBuffer[0] = sensor_list[Index].Address >> 8;
		WriteBuffer[1] = sensor_list[Index].Address;
		WriteBuffer[2] = sensor_list[Index].Data;

		uint16_t reg_addr = ((uint16_t)WriteBuffer[0] << 8) | WriteBuffer[1];
		uint8_t write_data = WriteBuffer[2];
		Sensor_Delay();
		WriteToReg(reg_addr, write_data);

	}


	if(Status != XST_SUCCESS) {
	  xil_printf("Error: in Writing entry status = %x \r\n", Status);
	  return XST_FAILURE;
	}

	return XST_SUCCESS;

}
