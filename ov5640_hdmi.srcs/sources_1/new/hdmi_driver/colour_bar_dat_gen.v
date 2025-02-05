`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/31 09:44:00
// Design Name: 
// Module Name: colour_bar_dat_gen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module colour_bar_dat_gen
#(
  parameter DISP_WIDTH  = 1920,
  parameter DISP_HEIGHT = 1080
)
(
	clk_50M,
	reset_n,
	
	disp_data_req,
	visible_hcount,
	visible_vcount,
	disp_data
);
  
	input clk_50M;   //系统时钟输入
	input reset_n;  //复位信号输入，低有效
	input disp_data_req;
	input [11:0]visible_hcount;
	input [11:0]visible_vcount;
	
	output reg[23:0]disp_data;

  //定义颜色编码
	localparam 
    BLACK = 24'h000000, //黑色
    BLUE = 24'h0000FF, //蓝色
    RED = 24'hFF0000, //红色
    PURPPLE	= 24'hFF00FF, //紫色
    GREEN = 24'h00FF00, //绿色
    CYAN = 24'h00FFFF, //青色
    YELLOW	= 24'hFFFF00, //黄色
    WHITE = 24'hFFFFFF; //白色
    
  //定义每个像素块的默认显示颜色值
	localparam 
    R0_C0 = BLACK,	 //第0行0列像素块
    R0_C1 = BLUE,	   //第0行1列像素块
    R1_C0 = RED,	   //第1行0列像素块
    R1_C1 = PURPPLE, //第1行1列像素块
    R2_C0 = GREEN,	 //第2行0列像素块
    R2_C1 = CYAN,	   //第2行1列像素块
    R3_C0 = YELLOW,	 //第3行0列像素块
    R3_C1 = WHITE;	 //第3行1列像素块

	wire R0_act;
	wire R1_act;
	wire R2_act;
	wire R3_act; 
	wire C0_act;
	wire C1_act;
	wire R0_C0_act;
	wire R0_C1_act;
	wire R1_C0_act;
	wire R1_C1_act;
	wire R2_C0_act;
	wire R2_C1_act;
	wire R3_C0_act;
	wire R3_C1_act;

	assign R0_act = visible_vcount >= 0                && visible_vcount < DISP_HEIGHT/4; //正在扫描第0行条纹
	assign R1_act = visible_vcount >= DISP_HEIGHT/4    && visible_vcount < DISP_HEIGHT/2; //正在扫描第1行条纹
	assign R2_act = visible_vcount >= DISP_HEIGHT/2    && visible_vcount < DISP_HEIGHT/4*3; //正在扫描第2行条纹
	assign R3_act = visible_vcount >= DISP_HEIGHT/4*3  && visible_vcount < DISP_HEIGHT; //正在扫描第3行条纹
	assign C0_act = visible_hcount >= 0                && visible_hcount < DISP_WIDTH/2; //正在扫描第0列条纹
	assign C1_act = visible_hcount >= DISP_WIDTH/2    && visible_hcount < DISP_WIDTH; //正在扫描第1列条纹

	assign R0_C0_act = disp_data_req && R0_act && C0_act;	//第0行0列像素块处于被扫描中标志信号
	assign R0_C1_act = disp_data_req && R0_act && C1_act;	//第0行1列像素块处于被扫描中标志信号
	assign R1_C0_act = disp_data_req && R1_act && C0_act;	//第1行0列像素块处于被扫描中标志信号
	assign R1_C1_act = disp_data_req && R1_act && C1_act;	//第1行1列像素块处于被扫描中标志信号
	assign R2_C0_act = disp_data_req && R2_act && C0_act;	//第2行0列像素块处于被扫描中标志信号
	assign R2_C1_act = disp_data_req && R2_act && C1_act;	//第2行1列像素块处于被扫描中标志信号
	assign R3_C0_act = disp_data_req && R3_act && C0_act;	//第3行0列像素块处于被扫描中标志信号
	assign R3_C1_act = disp_data_req && R3_act && C1_act;	//第3行1列像素块处于被扫描中标志信号
	
	always@(*)
		case({R3_C1_act,R3_C0_act,R2_C1_act,R2_C0_act,
				  R1_C1_act,R1_C0_act,R0_C1_act,R0_C0_act})
			8'b0000_0001:disp_data = R0_C0;
			8'b0000_0010:disp_data = R0_C1;
			8'b0000_0100:disp_data = R1_C0;
			8'b0000_1000:disp_data = R1_C1;
			8'b0001_0000:disp_data = R2_C0;
			8'b0010_0000:disp_data = R2_C1;
			8'b0100_0000:disp_data = R3_C0;
			8'b1000_0000:disp_data = R3_C1;
			default:disp_data = R0_C0;
		endcase
		
endmodule

