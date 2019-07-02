#ifndef SRC_ADC_DMA_H_
#define SRC_ADC_DMA_H_

#include "ad9280_sample.h"

#include "xaxidma.h"
#include "dma_bd/dma_bd.h"

#include "xil_types.h"
#include "xscugic.h"

/*
 *DMA redefines
 */
#define MAX_DMA_LEN		   0x800000      /* DMA max length in byte */
#define DMA_DEV_ID		   XPAR_AXIDMA_0_DEVICE_ID
#define S2MM_INTR_ID       XPAR_FABRIC_AXI_DMA_0_S2MM_INTROUT_INTR

/*
 *ADC defines
 */
#define AD9280_BASE        XPAR_AD9280_SAMPLE_0_S00_AXI_BASEADDR
#define AD9280_START       AD9280_SAMPLE_S00_AXI_SLV_REG0_OFFSET
#define AD9280_LENGTH      AD9280_SAMPLE_S00_AXI_SLV_REG1_OFFSET

#define ADC_BYTE           2              /* ADC data byte number */
#define ADC_BITS           8


/*
 *DMA BD defines
 */
#define BD_COUNT         4


#define ADC_SAMPLE_NUM  128


extern volatile int s2mm_flag;

int XAxiDma_Initial(u16 DeviceId, u16 IntrID, XAxiDma *XAxiDma, XScuGic *InstancePtr);
void Dma_Interrupt_Handler(void *CallBackRef);
void XAxiDma_Adc(u32 *BdChainBuffer, u32 adc_addr, u32 adc_len, u16 BdCount, XAxiDma *AxiDma) ;
void ad9280_sample(u32 adc_addr, u32 adc_len) ;


#endif /* SRC_ADC_DMA_H_ */
