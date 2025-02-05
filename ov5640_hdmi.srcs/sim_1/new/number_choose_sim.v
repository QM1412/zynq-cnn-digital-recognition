`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/25 22:10:56
// Design Name: 
// Module Name: number_choose_sim
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


module number_choose_sim();
reg sclk;
reg rst_n;
reg [11:0]     H_Addr      ;  
reg [11:0]     V_Addr     ;

wire disp_ram_en;
wire [23:0]  disp_number_data;

initial begin
    sclk = 1'b1;
    rst_n = 1'b0;
    #100
    rst_n = 1'b1;
end

always #10 sclk = ~sclk;

always @(posedge sclk or negedge rst_n)begin
    if (!rst_n) begin
        H_Addr <= 'd0;
    end
    else if(H_Addr == 'd1024)
        H_Addr <= 'd0 ;
    else
        H_Addr <= H_Addr+'d1;
end

always @(posedge sclk or negedge rst_n)begin
    if (!rst_n) begin
        V_Addr <= 'd0;
    end
    else if(V_Addr == 'd600)
        V_Addr <= 'd0;
    else if(H_Addr == 'd1024)
        V_Addr <= V_Addr + 'd1 ;
    else
        V_Addr <= V_Addr;
end

number_choose number_choose_initial
(
  .sclk        (sclk        ),
  .rst_n       (rst_n          ),
  .read_number (4'd0            ),
  .Data_Req    (1'b1         ),
  .H_Addr      (H_Addr          ),  
  .V_Addr      (V_Addr          ),
  .disp_ram_en (disp_ram_en     ),
  .Disp_Data   (disp_number_data)
);


endmodule
