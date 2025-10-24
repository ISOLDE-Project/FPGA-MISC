#ifndef __IIC_FUNCTIONS_H_
#define __IIC_FUNCTIONS_H_

void IicSendHandler(XIic* InstancePtr);
void IicRecvHandler(XIic* InstancePtr);
void IicStatusHandler(XIic* InstancePtr, int Event);

void Sensor_Delay();
int SetupInterruptSystem();
int ReadCameraReg(u16 reg_addr, u8* data);
int WriteToReg(u16 reg_addr, u8 write_data);

int initIIC();
int SensorConfig();

void resetIp();
void EnableCSI(void);
u32 InitializeCsiRxSs(void);
void HaltVDMA();
void ResetVDMA();

void DisableCSI(void);
int demosaic();
int vdma();
void stop_vdma();
int vdma_resizer();
void CamReset();

void img2axis_config();
void poll_sr();

extern int irpt_en,k;
extern int irpt_vio;

#endif
