#include <stdio.h>
#include <stdlib.h>

#include "xil_types.h"
#include "sleep.h"
#include "xparameters.h"
#include "xil_exception.h"

#include "xparameters_ps.h"
#include "xil_io.h"
#include "xil_printf.h"

#include "pl_bram_rd.h"
#include "param_init.h"
#include "xuartps.h"

#define  DDR_BASEARDDR      		(XPAR_DDR_MEM_BASEADDR + 0x01800000)

#define  PL_BRAM_BASE        		XPAR_PL_BRAM_RD_0_S00_AXI_BASEADDR   //PL_RAM_RD basic address
#define  PL_BRAM_SLV_3				PL_BRAM_RD_S00_AXI_SLV_REG3_OFFSET	 // Slave regist

//////////////////////////////////////////////////////////////////////////////////////////////
#define  IMAGE_WIDTH            	1024
#define  IMAGE_HEIGHT           	600
#define	 WINDOWS_SIZE				28*4
//////////////////////////////////////////////////////////////////////////////////////////////
void soft_downsample(uint16_t cmos_data[],uint8_t image_28X28[]);
int UART_init(u32 baudrate);
//////////////////////////////////////////////////////////////////////////////////////////////
XUartPs  Uart_Ps_0;
// debug parameter
#define DEBUG 1
#define DEBUG_NUMBER 28
#define DEBUG_SIZE 100
void debug_print(uint8_t img[],uint8_t delay);


//main function
int main()
{
	UART_init(115200);
	/* Convolutional layer parameter address */
    float *cnn_param_w = (float *)0x2000000;
	float *cnn_param_b = (float *)0x2000C00;
    conv_param_init();
    float *conv_rlst = (float *)0x2000D00;
    float conv_temp;

    /* Pooling layer parameter address */
    float pool_temp = 0;
    float *pool_rslt = (float *)0x2020000;

    /* hidden layer parameter addresses */
    float *affine1_w = (float *)0x2025000;
    float *affine1_b = (float *)0x21CB000;
    affine1_param_init();
    float *affine1_rslt = (float *)0x21CC000;
    float affine1_temp;

    /* output layer parameter addresses */
    float *affine2_w = (float *)0x21CC200;
    float *affine2_b = (float *)0x21CD200;
    float affine2_temp;
    affine2_param_init();
    float affine2_rslt[10];

    /* compare the output layer size */
    float temp = -100;
    int predict_num;

	uint16_t *cmos_data = (uint16_t *)DDR_BASEARDDR;
    uint8_t  img_data[784];

    while(1)
    {
    	soft_downsample(cmos_data,img_data);// Software downsampling
		///////////////////////////////////////////////
		// Convolutional layer calculations
		///////////////////////////////////////////////
		for(int n=0; n<30; n++)
		{
			for(int row=0; row<=23; row++)
			{
				for(int col=0; col<=23; col++)
				{
					conv_temp = 0;
					for(int x=0; x<5; x++)
					{
						for(int y=0; y<5; y++)
						{
							conv_temp += img_data[row*28+col+x*28+y] * cnn_param_w[x*5+y+n*25];
						}
					}
					conv_temp += cnn_param_b[n];

					// Activate the function
					if(conv_temp > 0)
						conv_rlst[row*24+col+n*576] = conv_temp; // 576=24x24
					else
						conv_rlst[row*24+col+n*576] = 0;
				}
			}
		}
		///////////////////////////////////////////////
		// Pooling layer calculations
		///////////////////////////////////////////////
		for(int n=0; n<30; n++)
		{
			for(int row=0; row<24; row=row+2)
			{
				for(int col=0; col<24; col=col+2)
				{
					pool_temp = 0;
					for(int x=0; x<2; x++)
					{
						for(int y=0; y<2; y++)
						{
							if(pool_temp <= conv_rlst[row*24+col+x*24+y+n*576])
								pool_temp = conv_rlst[row*24+col+x*24+y+n*576];
						}
					}
					pool_rslt[(row/2)*12+col/2+n*144] = pool_temp;
				}
			}
		}
		///////////////////////////////////////////////
		// Hidden layer calculations
		///////////////////////////////////////////////
		for(int n=0; n<100; n++)
		{
			affine1_temp = 0;
			for(int i=0; i<4320; i++)
			{
				affine1_temp = affine1_temp + pool_rslt[i] * affine1_w[i+4320*n]; // 4320=30x12x12
			}
			affine1_temp = affine1_temp + affine1_b[n];
			// Activate the function
			if(affine1_temp > 0)
				affine1_rslt[n] = affine1_temp;
			else
				affine1_rslt[n]	= 0;
		}
		///////////////////////////////////////////////
		// Output layer calculations
		///////////////////////////////////////////////
		temp = -100;
		for(int n=0; n<10; n++)
		{
			affine2_temp = 0;
			for(int i=0; i<100;i++)
			{
				affine2_temp = affine2_temp + affine2_w[i+100*n] * affine1_rslt[i];
			}
			affine2_rslt[n] = affine2_temp;

			if(temp <= affine2_rslt[n])
			{
				temp = affine2_rslt[n];
				predict_num = n;
			}
		}

		PL_BRAM_RD_mWriteReg(PL_BRAM_BASE,PL_BRAM_SLV_3,predict_num);
    }
    return 0;
}



void soft_downsample(uint16_t cmos_data[],uint8_t image_28X28[])
{
	uint8_t temp_img_data[WINDOWS_SIZE*WINDOWS_SIZE];
	int index=0;
    for(int h_cnt=0; h_cnt<IMAGE_HEIGHT; h_cnt++)
    {
        for(int w_cnt=0; w_cnt<IMAGE_WIDTH; w_cnt++)
        {
            if(( w_cnt>=(IMAGE_WIDTH/2-WINDOWS_SIZE/2) && w_cnt<(IMAGE_WIDTH/2+WINDOWS_SIZE/2)) && (h_cnt>= (IMAGE_HEIGHT/2-WINDOWS_SIZE/2) && h_cnt<(IMAGE_HEIGHT/2+WINDOWS_SIZE/2)))
            {
            	temp_img_data[index] = cmos_data[h_cnt*IMAGE_WIDTH + w_cnt];
            	index = index + 1;
            }
        }
    }

	index = 0;
	for(int h_cnt=0; h_cnt<WINDOWS_SIZE; h_cnt++)
	{
		for(int w_cnt=0; w_cnt<WINDOWS_SIZE; w_cnt++)
		{
			if(w_cnt%4 == 0 && h_cnt%4 == 0)
			{
				image_28X28[index] = temp_img_data[h_cnt*WINDOWS_SIZE+w_cnt];
				index++;
			}
		}
	}
}

int UART_init(u32 baudrate){
	XUartPs_Config *Config;
	int Status;
	Config = XUartPs_LookupConfig(XPAR_XUARTPS_0_DEVICE_ID);
	Status = XUartPs_CfgInitialize(&Uart_Ps_0, Config, Config->BaseAddress);
	XUartPs_SetBaudRate(&Uart_Ps_0, baudrate);
	return Status;
}

void debug_print(uint8_t img[],uint8_t delay)
{
	for(int j=0;j<DEBUG_NUMBER;j++)
	{
		for(int k=0;k<DEBUG_NUMBER;k++)
		{
			if(k == DEBUG_NUMBER-1)
				xil_printf("%d",img[j*DEBUG_NUMBER+k]);
			else
				xil_printf("%d,",img[j*DEBUG_NUMBER+k]);
		}
		print("\r\n");
		usleep(100);
	}
	sleep(delay);
}



