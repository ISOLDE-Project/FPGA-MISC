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
#include "xil_io.h"

#include "xv_demosaic.h"

#include "xintc.h"

typedef uint8_t  u8;
typedef uint16_t u16;

#define IIC_DEVICE_ID XPAR_IIC_0_DEVICE_ID
#define INTC_DEVICE_ID XPAR_INTC_0_DEVICE_ID
#define IIC_INTR_ID XPAR_INTC_0_IIC_0_VEC_ID

#define OV5640_I2C_ADDR 0x3C

static XIic IicInstance;
static XIntc Intc;

#define VDMA_BASE 			XPAR_AXIVDMA_0_BASEADDR
#define VDMA_RESIZER		XPAR_AXIVDMA_1_BASEADDR

#define IMG2AXIS_BASEADDR	0x00010000

#define XCSIRXSS_DEVICE_ID  XPAR_CSISS_0_DEVICE_ID
#define DEMOSAIC_DEVICE_ID 	XPAR_XV_DEMOSAIC_0_DEVICE_ID
#define GPIO_SENSOR 		XPAR_GPIO_1_BASEADDR
#define GPIO_LEDS			XPAR_GPIO_3_BASEADDR

volatile int TransmitComplete = 0;
volatile int ReceiveComplete = 0;

/* Definitions for VDMA_0: CAM -> MIPI_PIPELINE -> VDMA */
#define HORIZONTAL_RESOLUTION	1920 //1280
#define VERTICAL_RESOLUTION		1080 //720
#define FRAME_COUNTER			3
#define STRIDE_VDMA_0			1920*3

/* Definitions for VDMA_1 (from Resizer BD): IMG2AXIS -> RESIZER -> VDMA */
#define HORIZONTAL_RESOLUTION_1		160 //640
#define VERTICAL_RESOLUTION_1		480
#define FRAME_COUNTER_1				2
#define STRIDE_VDMA_1				160*4

/* Debug Constants */
#define MM2S_HALT_SUCCESS	121
#define MM2S_HALT_FAILURE	122
#define S2MM_HALT_SUCCESS	131
#define S2MM_HALT_FAILURE	132

#define SET            		(0x01)
#define VDMA_S2MM    		(VDMA_BASE + 0x30)
#define VDMA_S2MM_RESIZER	(VDMA_RESIZER + 0x30)
#define S2MM				1


//########## INTERRUPTS DEFINES #############

#define IRPT_EN_ID XPAR_CAM_SUBSYSTEM_MICROBLAZE_0_AXI_INTC_CAM_SUBSYSTEM_MIPI_PIPELINE_INT_ENABLE_0_INT_O_INTR
#define IRPT_VIO_ID XPAR_CAM_SUBSYSTEM_MICROBLAZE_0_AXI_INTC_VIO_0_PROBE_OUT0_INTR

#define GPIO_IRPT_CTRL XPAR_GPIO_2_BASEADDR


//########## END OF INTRPT DEFINES ##########

typedef u8 AddressType;

/****************** Instances **********************/
XCsiSs CsiRxSs;

XV_demosaic InstancePtr;
XV_demosaic_Config  *demosaic_Config;
XAxiVdma AxiVdma;
XAxiVdma AxiVdmaResizer;


uint32_t read_reg(uintptr_t addr) {
    return *((volatile uint32_t *)addr);
}

void write_reg(uintptr_t addr, uint32_t value) {
    *((volatile uint32_t *)addr) = value;
}

typedef struct {
    uint32_t physical_address;
    // Add virtual address if needed
} FrameBuffer;


#define S2MM_VDMACR        0x30
#define S2MM_VDMASR        0x34
#define S2MM_VDMA_IRQ_MASK 0x3C
#define S2MM_REG_INDEX     0x44
#define S2MM_VSIZE         0xA0
#define S2MM_HSIZE         0xA4
#define S2MM_STRIDE        0xA8
#define S2MM_SA1           0xAC
#define S2MM_SA2           0xB0
#define S2MM_SA3           0xB4
#define S2MM_SA4           0xB8
#define S2MM_SA5           0xBC
#define S2MM_SA6           0xC0
#define S2MM_SA7           0xC4
#define S2MM_SA8           0xC8
#define S2MM_SA9           0xCC
#define S2MM_SA10          0xD0
#define S2MM_SA11          0xD4
#define S2MM_SA12          0xD8
#define S2MM_SA13          0xDC
#define S2MM_SA14          0xE0
#define S2MM_SA15          0xE4
#define S2MM_SA16          0xE8
//
////////////
//
#define IMG2AXIS_CTRL            0x00
#define IMG2AXIS_GIE                0x04
#define IMG2AXIS_IER                0x08
#define IMG2AXIS_ISR                0x0c
#define IMG2AXIS_DATA_PORT_DATA     0x10
#define IMG2AXIS_FRAME_CNT_DATA     0x18
#define IMG2AXIS_END_OF_STREAM_DATA 0x20

//*********** IRPT FUNCTIONS **************

int irpt_en = 0, irpt_vio = 0, k = 0;
int Status;


//*****************************************

void img2axis_config(){

	Xil_Out32(IMG2AXIS_BASEADDR + 0x10, 0x815EEC00);
	Xil_Out32(IMG2AXIS_BASEADDR + 0x18, 0x4);
	Xil_Out32(IMG2AXIS_BASEADDR + 0x20, 0x1);
	Xil_Out32(IMG2AXIS_BASEADDR + 0x00, 0x1);
	while(Xil_In32(IMG2AXIS_BASEADDR + 0x00) != 0x4);

}

void dump_img2axis_status(uintptr_t vdma_base)
{

	uint32_t ctrl           = read_reg(vdma_base + IMG2AXIS_CTRL);
	uint32_t data_port      = read_reg(vdma_base + IMG2AXIS_DATA_PORT_DATA);
    uint32_t frame_cnt      = read_reg(vdma_base + IMG2AXIS_FRAME_CNT_DATA);
    uint32_t end_of_stream  = read_reg(vdma_base + IMG2AXIS_END_OF_STREAM_DATA);


    xil_printf("----- img2axis Status Dump -----\r\n");
    xil_printf("CTRL Reg                (0x%02X): 0x%08X\r\n", IMG2AXIS_CTRL, ctrl);
    xil_printf("DATA_PORT_DATA Reg      (0x%02X): 0x%08X\r\n", IMG2AXIS_DATA_PORT_DATA, data_port);
    xil_printf("FRAME_CNT_DATA Reg      (0x%02X): %u\r\n", IMG2AXIS_FRAME_CNT_DATA, frame_cnt);
    xil_printf("END_OF_STREAM  Reg      (0x%02X): %u\r\n", IMG2AXIS_END_OF_STREAM_DATA, end_of_stream);

}

void dump_s2mm_status(uintptr_t vdma_base)
{

    uint32_t cr     = read_reg(vdma_base + S2MM_VDMACR);
    uint32_t sr     = read_reg(vdma_base + S2MM_VDMASR);
    uint32_t vsize  = read_reg(vdma_base + S2MM_VSIZE);
    uint32_t hsize  = read_reg(vdma_base + S2MM_HSIZE);
    uint32_t stride = read_reg(vdma_base + S2MM_STRIDE);
    uint32_t sa1    = read_reg(vdma_base + S2MM_SA1);
    uint32_t sa2    = read_reg(vdma_base + S2MM_SA2);

    xil_printf("----- VDMA S2MM Status Dump -----\r\n");
    xil_printf("Control Reg     (0x%02X): 0x%08X\r\n", S2MM_VDMACR, cr);
    xil_printf("Status Reg      (0x%02X): 0x%08X\r\n", S2MM_VDMASR, sr);
    xil_printf("Vertical Size   (0x%02X): %u\r\n", S2MM_VSIZE, vsize);
    xil_printf("Horizontal Size (0x%02X): %u\r\n", S2MM_HSIZE, hsize);
    xil_printf("Stride          (0x%02X): %u\r\n", S2MM_STRIDE, stride);
    xil_printf("S2MM_SA1        (0x%02X): 0x%08X\r\n", S2MM_SA1, sa1);
    xil_printf("S2MM_SA2        (0x%02X): 0x%08X\r\n", S2MM_SA2, sa2);

    xil_printf("Status Flags:\r\n");

    struct {
        int bit;
        const char* desc;
    } status_bits[] = {
        {0,  "HALTED"},
        {1,  "VDMA Internal Error"},
        {2,  "Slave Error"},
        {3,  "Decode Error"},
        {4,  "SOF Early Error"},
        {5,  "EOL Early Error"},
        {6,  "SOF Late Error"},
        {10, "EOL Late Error"},
        {12, "Frame Count IRQ"},
        {13, "Delay Count IRQ"},
        {14, "Error IRQ"},
        {31, "DMA Internal Halted"},
    };

    for (int i = 0; i < sizeof(status_bits)/sizeof(status_bits[0]); ++i) {
        if (sr & (1 << status_bits[i].bit)) {
            xil_printf(" - Bit %d: %s\r\n", status_bits[i].bit, status_bits[i].desc);
        }
    }

    xil_printf("----------------------------------\r\n");
}

void wait_frame(uintptr_t vdma_base){

	const int FrameCountIRQ_Mask=0x00001000;
	while(1){
		 volatile uint32_t sr     = read_reg(vdma_base + S2MM_VDMASR);
		 if (sr & FrameCountIRQ_Mask) break;
	}
	//clear  IRQ flag
    write_reg(vdma_base + S2MM_VDMASR, FrameCountIRQ_Mask);

}

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

static int WriteSetup(vdma_handle *vdma_context);
static int StartTransfer(XAxiVdma *InstancePtr);

unsigned int srcBuffer = (0x80000000U + 0x1000000);
unsigned int dstBufferResizer = (0x80000000U + 0x9000000);

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

  Config = XAxiVdma_LookupConfig(DeviceId);

  if (!Config) {
	xil_printf("No video DMA found for ID %d\r\r\n",DeviceId );
	return XST_FAILURE;
  }

  if(vdma_context[DeviceId].init_done ==0) {
	vdma_context[DeviceId].InstancePtr = InstancePtr;

	/* Initialize DMA engine */
	Status = XAxiVdma_CfgInitialize(vdma_context[DeviceId].InstancePtr,
						Config, Config->BaseAddress);

	if (Status != XST_SUCCESS) {
	  xil_printf("Configuration Initialization failed %d\r\r\n",
					Status);
	  return XST_FAILURE;
	}

	  vdma_context[DeviceId].init_done = 1;

  }

  vdma_context[DeviceId].device_id = DeviceId;
  vdma_context[DeviceId].vsize = vsize;
  vdma_context[DeviceId].enable_frm_cnt_intr = enable_frm_cnt_intr;
  vdma_context[DeviceId].buffer_address = buf_base_addr;
  vdma_context[DeviceId].number_of_frame_count = number_frame_count;

  if(hsize==1920)
	  vdma_context[DeviceId].hsize = hsize * 3;
  else
	  vdma_context[DeviceId].hsize = hsize * 4;

  /* Setup the write channel */

  Status = WriteSetup(&vdma_context[DeviceId]);

  if (Status != XST_SUCCESS) {
	xil_printf("Write channel setup failed %d\r\n", Status);
	if(Status == XST_VDMA_MISMATCH_ERROR)
	  xil_printf("DMA Mismatch Error\r\n");
	return XST_FAILURE;
  }

  /* The frame counter interrupt is enabled, setting VDMA for same */

  if(vdma_context[DeviceId].enable_frm_cnt_intr) {

	FrameCfgPtr.WriteDelayTimerCount = 1;
	FrameCfgPtr.WriteFrameCount = number_frame_count;

	XAxiVdma_SetFrameCounter(vdma_context[DeviceId].InstancePtr,
			&FrameCfgPtr);
	/* Enable DMA read and write channel interrupts.
	 * The configuration for interrupt
	 * controller will be done by application	 */
	XAxiVdma_IntrEnable(vdma_context[DeviceId].InstancePtr,
				XAXIVDMA_IXR_ERROR_MASK |
				XAXIVDMA_IXR_FRMCNT_MASK,XAXIVDMA_WRITE);

  } else	{
	  /* Enable DMA read and write channel interrupts.
	   * The configuration for interrupt
	   * controller will be done by application	 */
	XAxiVdma_IntrEnable(vdma_context[DeviceId].InstancePtr,
				XAXIVDMA_IXR_ERROR_MASK,XAXIVDMA_WRITE);

  }

  /* Start the DMA engine to transfer */
  Status = StartTransfer(vdma_context[DeviceId].InstancePtr);

  if (Status != XST_SUCCESS) {
	if(Status == XST_VDMA_MISMATCH_ERROR)
	  xil_printf("DMA Mismatch Error\r\n");
	return XST_FAILURE;
  }

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

    if(vdma_context->vsize == 1080)
    	vdma_context->WriteCfg.Stride = STRIDE_VDMA_0;
    else
    	vdma_context->WriteCfg.Stride = STRIDE_VDMA_1;

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

    for(Index = 0; Index < vdma_context->InstancePtr->MaxNumFrames; Index++){
  	vdma_context->WriteCfg.FrameStoreStartAddr[Index] = Addr;

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

    return XST_SUCCESS;

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

    XAxiVdma_Reset(&AxiVdma,XAXIVDMA_WRITE);

  }

  void ResetVDMA_Resizer()
  {

    XAxiVdma_Reset(&AxiVdmaResizer,XAXIVDMA_WRITE);

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

    CsiRxSsCfgPtr = XCsiSs_LookupConfig(XCSIRXSS_DEVICE_ID);

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
    demosaic_Config = XV_demosaic_LookupConfig(DEMOSAIC_DEVICE_ID);

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

  int vdma_1(){

	ResetVDMA_Resizer();

  	RunVDMA(&AxiVdmaResizer, XPAR_AXIVDMA_1_DEVICE_ID, HORIZONTAL_RESOLUTION_1, \
  			  VERTICAL_RESOLUTION_1, dstBufferResizer, FRAME_COUNTER_1, 0);

  	return XST_SUCCESS;

  }

  void stop_vdma(){

  	XAxiVdma_DmaStop(&AxiVdma, XAXIVDMA_WRITE);

  }

  void stop_vdma_1(){

	XAxiVdma_DmaStop(&AxiVdmaResizer, XAXIVDMA_WRITE);

  }

  FrameBuffer frame_rcv1;
  FrameBuffer frame_rcv2;

  void stop_vdma_resizer(){

  	XAxiVdma_DmaStop(&AxiVdmaResizer, XAXIVDMA_WRITE);

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

    Status = XIic_Initialize(&IicInstance, IIC_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        xil_printf("IIC Init failed\r\n");
        return XST_FAILURE;
    }

    XIic_SetAddress(&IicInstance, XII_ADDR_TO_SEND_TYPE, OV5640_I2C_ADDR);
    XIic_SetRecvHandler(&IicInstance, &IicInstance, IicRecvHandler);
    XIic_SetSendHandler(&IicInstance, &IicInstance, IicSendHandler);
    XIic_SetStatusHandler(&IicInstance, &IicInstance, IicStatusHandler);

    return Status;

}

int SetupInterruptSystem() {
    int Status;

    Status = XIntc_Initialize(&Intc, INTC_DEVICE_ID);
    if (Status != XST_SUCCESS) return XST_FAILURE;

    Status = XIntc_Connect(&Intc, IIC_INTR_ID,
        (XInterruptHandler)XIic_InterruptHandler,
        &IicInstance);
    if (Status != XST_SUCCESS) return XST_FAILURE;

//    Status = XIntc_Connect(&Intc, IRPT_EN_ID,
//            (XInterruptHandler)ISR_3, NULL);
//	if (Status != XST_SUCCESS) return XST_FAILURE;

//	Status = XIntc_Connect(&Intc, IRPT_VIO_ID,
//		(XInterruptHandler)ISR_4, NULL);
//	if (Status != XST_SUCCESS) return XST_FAILURE;

    XIntc_Start(&Intc, XIN_REAL_MODE);

    XIntc_Enable(&Intc, IIC_INTR_ID);
//    XIntc_Enable(&Intc, IRPT_EN_ID);
//    XIntc_Enable(&Intc, IRPT_VIO_ID);

    microblaze_enable_interrupts();

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


void ISR_3(void *CallbackRef) {

	irpt_en = 1;
	k++;
	if(k%20 == 0){
		xil_printf("FHD frame written into DDR. \n\r");
		Xil_Out32(GPIO_LEDS, 0x1);
		stop_vdma();

    // reconfig the vdma_1
	Status = vdma_1();
	if (Status != XST_SUCCESS) {
	   xil_printf("\n\rVdma1 Failed \n\r");
	   return XST_FAILURE;
	}

	// restart the img2axis ip to read, resize and write VGA grayscale frame into memory
	img2axis_config();
	Xil_Out32(GPIO_LEDS, 0x3);
	Xil_Out32(GPIO_IRPT_CTRL, 0x0); //disable the interrupt frame_sent

	xil_printf("Interrupts disabled. \n\r");
	}

}

int nr = 0;

void ISR_4(void *CallbackRef) {

	irpt_vio = 1;
	xil_printf("Accelerator ready to read data from 0x81000000. \n\r");

	nr++;
	if(nr%3==0){
		xil_printf("Interrupts enabled. \n\r");
		//after three vio interrupts result that accelerator done to read the image from the location
		Xil_Out32(GPIO_IRPT_CTRL, 0x1);// enable interrupt frame_sent
		Xil_Out32(GPIO_LEDS, 0x0);
		Sensor_Delay();
		Status = vdma();
			if (Status != XST_SUCCESS) {
		   xil_printf("\n\rVdma Failed \n\r");
		   return XST_FAILURE;
		 };
		xil_printf("VDMA_0 configured. \n\r");

	};

}
int SetupInterruptSystemNewIrpt() {

    int Status;

    Status = XIntc_Connect(&Intc, IRPT_EN_ID,
        (XInterruptHandler)ISR_3, NULL);
    if (Status != XST_SUCCESS) return XST_FAILURE;

    Status = XIntc_Connect(&Intc, IRPT_VIO_ID,
        (XInterruptHandler)ISR_4, NULL);
    if (Status != XST_SUCCESS) return XST_FAILURE;

    XIntc_Start(&Intc, XIN_REAL_MODE);

    XIntc_Enable(&Intc, IRPT_EN_ID);
    XIntc_Enable(&Intc, IRPT_VIO_ID);

    microblaze_enable_interrupts();

    return XST_SUCCESS;
}
