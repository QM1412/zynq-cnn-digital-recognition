`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: QM1412
// Create Date: 2025/01/25 17:51:43
// Module Name: dis_ctrol
// Description: the module will output 64x64 number image 
//////////////////////////////////////////////////////////////////////////////////
module number_choose#(
    parameter IMAGE_WIDTH   = 1024,
    parameter IMAGE_HEIGHT  = 600,
    parameter IMAGE_NUMBER_WIDTH  = 64,
    parameter IMAGE_NUMBER_HEIGHT = 64
)
(
    input             sclk        ,
    input             rst_n       ,
    input  [3:0]      read_number ,
    input             Data_Req    ,
    input  [11:0]     H_Addr      ,  
    input  [11:0]     V_Addr      ,
    output            disp_ram_en ,
    output reg [23:0] Disp_Data   
);
localparam BLACK  = 24'h000000;  //黑色
localparam BLUE   = 24'h0000FF;  //蓝色
localparam RED    = 24'hFF0000;  //红色  
localparam PURPPLE= 24'hFF00FF;  //紫色 
localparam GREEN  = 24'h00FF00;  //绿色 
localparam CYAN   = 24'h00FFFF;  //青色 
localparam YELLOW = 24'hFFFF00;  //黄色 
localparam WHITE  = 24'hFFFFFF;  //白色 
localparam RAM_ADDR_MAX = IMAGE_NUMBER_WIDTH*IMAGE_NUMBER_HEIGHT;

reg  [11:0]  disp_ram_addr;     // block memory address signals
reg  [11:0]  ram_addr[10:0];

reg   [23:0]  disp_ram_dout;    //block memory data signals
wire  [23:0]  ram_dout[10:0];

assign  disp_ram_en = (Data_Req && ( (H_Addr >= IMAGE_WIDTH - IMAGE_NUMBER_WIDTH) && (H_Addr < IMAGE_WIDTH)) && ( (V_Addr >= 0) && (V_Addr < IMAGE_NUMBER_HEIGHT)) ) ? 1 : 0;

// Combinatorial logic
always @ (*) begin
    case (read_number)
        4'd0 : ram_addr[0] = disp_ram_addr;
        4'd1 : ram_addr[1] = disp_ram_addr;            
        4'd2 : ram_addr[2] = disp_ram_addr;
        4'd3 : ram_addr[3] = disp_ram_addr;  
        4'd4 : ram_addr[4] = disp_ram_addr;
        4'd5 : ram_addr[5] = disp_ram_addr;            
        4'd6 : ram_addr[6] = disp_ram_addr;
        4'd7 : ram_addr[7] = disp_ram_addr;           
        4'd8 : ram_addr[8] = disp_ram_addr;    
        4'd9 : ram_addr[9] = disp_ram_addr; 
        default : ram_addr[10] = disp_ram_addr;  
    endcase
end    


always @ (*) begin
    case (read_number)
        4'd0 : disp_ram_dout = ram_dout[0];
        4'd1 : disp_ram_dout = ram_dout[1];            
        4'd2 : disp_ram_dout = ram_dout[2];
        4'd3 : disp_ram_dout = ram_dout[3];  
        4'd4 : disp_ram_dout = ram_dout[4];
        4'd5 : disp_ram_dout = ram_dout[5];            
        4'd6 : disp_ram_dout = ram_dout[6];
        4'd7 : disp_ram_dout = ram_dout[7];           
        4'd8 : disp_ram_dout = ram_dout[8];    
        4'd9 : disp_ram_dout = ram_dout[9]; 
        default : disp_ram_dout = ram_dout[10];  
    endcase
end

// Sequential logic
always @(posedge sclk or negedge rst_n) begin
    if(!rst_n) begin
        disp_ram_addr <= 12'b0;
    end
    // else if(disp_ram_addr == RAM_ADDR_MAX)
    //      disp_ram_addr <= 12'b0;
    else if(disp_ram_en) 
        disp_ram_addr <= disp_ram_addr + 1;
    else
        disp_ram_addr <= disp_ram_addr ;
end

always @ (posedge sclk or negedge rst_n) begin
    if (!rst_n) 
        Disp_Data <= CYAN;
    else if (disp_ram_en)
        Disp_Data <= disp_ram_dout;  
    else          
        Disp_Data <= CYAN;
end

// ROM ip initial
RAM_0 RAM_0_init (
  .clka (sclk       ),    // input wire clka
//  .ena  (ram_en  [0]),      // input wire ena
  .addra(ram_addr[0]),  // input wire [11 : 0] addra
  .douta(ram_dout[0])  // output wire [23 : 0] douta
);

ROM_1 ROM_1_init (
  .clka(sclk),    // input wire clka
  .addra(ram_addr[1]),  // input wire [11 : 0] addra
  .douta(ram_dout[1])  // output wire [23 : 0] douta
);

ROM_2 ROM_2_init(
  .clka(sclk),    // input wire clka
  .addra(ram_addr[2]),  // input wire [11 : 0] addra
  .douta(ram_dout[2])  // output wire [23 : 0] douta
);

ROM_3 ROM_3_init(
  .clka(sclk),    // input wire clka
  .addra(ram_addr[3]),  // input wire [11 : 0] addra
  .douta(ram_dout[3])  // output wire [23 : 0] douta
);

ROM_4 ROM_4_init(
  .clka(sclk),    // input wire clka
  .addra(ram_addr[4]),  // input wire [11 : 0] addra
  .douta(ram_dout[4])  // output wire [23 : 0] douta
);

ROM_5 ROM_5_init(
  .clka(sclk),    // input wire clka
  .addra(ram_addr[5]),  // input wire [11 : 0] addra
  .douta(ram_dout[5])  // output wire [23 : 0] douta
);

ROM_6 ROM_6_init(
  .clka(sclk),    // input wire clka
  .addra(ram_addr[6]),  // input wire [11 : 0] addra
  .douta(ram_dout[6])  // output wire [23 : 0] douta
);

ROM_7 ROM_7_init(
  .clka(sclk),    // input wire clka
  .addra(ram_addr[7]),  // input wire [11 : 0] addra
  .douta(ram_dout[7])  // output wire [23 : 0] douta
);

ROM_8 ROM_8_init(
  .clka(sclk),    // input wire clka
  .addra(ram_addr[8]),  // input wire [11 : 0] addra
  .douta(ram_dout[8])  // output wire [23 : 0] douta
);

ROM_9 ROM_9_init(
  .clka(sclk),    // input wire clka
  .addra(ram_addr[9]),  // input wire [11 : 0] addra
  .douta(ram_dout[9])  // output wire [23 : 0] douta
);

ROM_EMPTY ROM_EMPTY_init(
  .clka(sclk),    // input wire clka
  .addra(ram_addr[10]),  // input wire [11 : 0] addra
  .douta(ram_dout[10])  // output wire [23 : 0] douta
);

endmodule