/*
 * main.c: simple test application
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
#include <unistd.h>

#include "platform.h"
#include "xil_printf.h"

#include "zynq_interrupt.h"

#include "adc_dma.h"
#include "xaxidma.h"
#include "dma_bd/dma_bd.h"

#include "xil_types.h"
#include "xscugic.h"

#define INT_DEVICE_ID      XPAR_SCUGIC_SINGLE_DEVICE_ID

static XScuGic XScuGicInstance;
static XAxiDma AxiDma;

static unsigned char DmaRxBuffer[MAX_DMA_LEN]  	__attribute__ ((aligned(64)));
static u32 BdChainBuffer[BD_ALIGNMENT*16] 		__attribute__ ((aligned(64)));

int main()
{
    init_platform();

    print("Hello World\n\r");

    InterruptInit(INT_DEVICE_ID, &XScuGicInstance);

    /* Initialize DMA */
    XAxiDma_Initial(DMA_DEV_ID, S2MM_INTR_ID, &AxiDma, &XScuGicInstance) ;

    /* Interrupt register */
    InterruptConnect(&XScuGicInstance, S2MM_INTR_ID, Dma_Interrupt_Handler, &AxiDma, 0, 3);

    /* Create BD chain */
    CreateBdChain(BdChainBuffer, BD_COUNT, ADC_SAMPLE_NUM, (unsigned char *)DmaRxBuffer, RXPATH) ;

	/* Start ADC channel 0 */
	XAxiDma_Adc(BdChainBuffer, AD9280_BASE, ADC_SAMPLE_NUM, BD_COUNT, &AxiDma) ;
    while (1) {
    	/* Wait for times */
		sleep(1);

		/* Check if DMA completed */
		if (s2mm_flag) {
			s2mm_flag = FALSE;

			Xil_DCacheInvalidateRange((u32) DmaRxBuffer, ADC_SAMPLE_NUM);

			const uint8_t *data = (uint8_t *)DmaRxBuffer;
		    printf("Got adc: len:%d, data:\n", ADC_SAMPLE_NUM);
		    for (int i=0; i<ADC_SAMPLE_NUM; i++) {
		        printf("%2x ", data[i]);
		        if ((i+1)%10 == 0) printf("\n");
		    }
		    printf("\n");

			/* Start ADC channel 0 */
			XAxiDma_Adc(BdChainBuffer, AD9280_BASE, ADC_SAMPLE_NUM, BD_COUNT, &AxiDma) ;
		}
    }
    cleanup_platform();
    return 0;
}
