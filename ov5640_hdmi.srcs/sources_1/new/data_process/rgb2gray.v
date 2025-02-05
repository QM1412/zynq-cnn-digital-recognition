/////////////////////////////////////////////////////////////////////////////////
// Company       : 武汉芯路恒科技有限公司
//                 http://xiaomeige.taobao.com
// Web           : http://www.corecourse.cn
// 
// Create Date   : 2019/05/01 00:00:00
// Module Name   : rgb2gray
// Description   : 图像处理之彩色图像灰度化，提供三种方式
// 
// Dependencies  : 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module rgb2gray
#(
  parameter PROC_METHOD = "FORMULA" //"AVERAGE"     :求平均法
                                    //or "FORMULA"  :直接公式法
)
(
  input           clk,         //时钟
  input           reset_p,     //复位
  input           rgb_valid,   //rgb输入有效标识
  input           rgb_hs,      //rgb输入行信号
  input           rgb_vs,      //rgb输入场信号
  input     [7:0] red_8b_i,    //R输入
  input     [7:0] green_8b_i,  //G输入
  input     [7:0] blue_8b_i,   //B输入

  output    [7:0] gray_8b_o,   //GRAY输出
  output reg      gray_valid,  //gray输出有效标识
  output reg      gray_hs,     //gray输出行信号
  output reg      gray_vs      //gray输出场信号
);

generate
  if (PROC_METHOD == "AVERAGE") begin: PROC_AVERAGE
//---------------------------------------------
//求平均法GRAY = (R+B+G)/3=（(R+B+G)*85）>>8
    wire [9:0]sum;
    reg [15:0]gray_r;
    
    assign sum = red_8b_i + green_8b_i + blue_8b_i;
    
    always@(posedge clk or posedge reset_p)
    begin
      if(reset_p)
        gray_r <= 16'd0;
      else if(rgb_valid)
        gray_r <= (sum << 6)+(sum << 4)+(sum << 2)+ sum;
      else
        gray_r <= 16'd0;
    end
  
    assign gray_8b_o = gray_r[15:8];

    always@(posedge clk)
    begin
      gray_valid <= rgb_valid;
      gray_hs    <= rgb_hs;
      gray_vs    <= rgb_vs;
    end
//---------------------------------------------
  end
  else if (PROC_METHOD == "FORMULA") begin: PROC_FORMULA
//---------------------------------------------
//典型灰度转换公式Gray = R*0.299+G*0.587+B*0.114=(R*77 + G*150 + B*29) >>8
    wire [15:0]red_x77;
    wire [15:0]green_x150;
    wire [15:0]blue_x29;
    reg  [15:0]sum;

    //乘法转换成移位相加方式
    assign red_x77    = (red_8b_i  << 6) + (red_8b_i  << 3) + (red_8b_i  << 2) + red_8b_i;
    assign green_x150 = (green_8b_i<< 7) + (green_8b_i<< 4) + (green_8b_i<< 2) + (green_8b_i<<1);
    assign blue_x29   = (blue_8b_i << 4) + (blue_8b_i << 3) + (blue_8b_i << 2) + blue_8b_i;

    always@(posedge clk or posedge reset_p)
    begin
      if(reset_p)
        sum <= 16'd0;
      else if(rgb_valid)
        sum <= red_x77 + green_x150 + blue_x29;
      else
        sum <= 16'd0;
    end
    
    assign gray_8b_o = sum[15:8];

    always@(posedge clk)
    begin
      gray_valid <= rgb_valid;
      gray_hs    <= rgb_hs;
      gray_vs    <= rgb_vs;
    end
//---------------------------------------------
//---------------------------------------------
  end
  else begin: PROC_NONE
//---------------------------------------------
    assign gray_8b_o = 8'h00;

    always@(posedge clk)
    begin
      gray_valid <= rgb_valid;
      gray_hs    <= rgb_hs;
      gray_vs    <= rgb_vs;
    end
//---------------------------------------------
  end
endgenerate
endmodule 