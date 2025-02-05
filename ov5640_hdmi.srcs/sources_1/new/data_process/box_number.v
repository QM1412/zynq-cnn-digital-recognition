module box_number #(
    parameter IMAGE_WIDTH          = 1024 ,
    parameter IMAGE_HEIGHT         = 600  ,
    parameter BOX_WINDOWS_SIZE     = 112  ,
    parameter X_BOX_WINDOWS_OFFEST = 1    ,// 这个如果是负数不知可否
    parameter Y_BOX_WINDOWS_OFFEST = 1    ,
    parameter IMAGE_NUMBER_WIDTH   = 64   ,
    parameter IMAGE_NUMBER_HEIGHT  = 64   
)
(
    input sclk,
    input rst_p,
    input en_box,

    input [23:0] disp_data,
    input        Data_Req,


    input [11:0] H_Addr,
    input [11:0] V_Addr,

    input [3:0] read_number,

    output reg [23:0] VGA_rgb

);

// box display
always @(posedge sclk or posedge rst_p) begin
  if(rst_p)
    VGA_rgb <= 24'h000000;
  else if (DataReq && (H_Addr >= (IMAGE_WIDTH/2-BOX_WINDOWS_SIZE/2 + X_BOX_WINDOWS_OFFEST)) && (H_Addr < (IMAGE_WIDTH/2+BOX_WINDOWS_SIZE/2 + X_BOX_WINDOWS_OFFEST))
          && (V_Addr >= (IMAGE_HEIGHT/2-BOX_WINDOWS_SIZE/2 + Y_BOX_WINDOWS_OFFEST)) && (V_Addr < (IMAGE_HEIGHT/2+BOX_WINDOWS_SIZE/2 +Y_BOX_WINDOWS_OFFEST )) ) begin
      if (H_Addr == (IMAGE_WIDTH/2-BOX_WINDOWS_SIZE/2 + X_BOX_WINDOWS_OFFEST) || H_Addr == (IMAGE_WIDTH/2+BOX_WINDOWS_SIZE/2)-1 + X_BOX_WINDOWS_OFFEST || 
          V_Addr == (IMAGE_HEIGHT/2-BOX_WINDOWS_SIZE/2 + Y_BOX_WINDOWS_OFFEST) || V_Addr == (IMAGE_HEIGHT/2+BOX_WINDOWS_SIZE/2) - 1 + Y_BOX_WINDOWS_OFFEST )
        VGA_rgb <= en_box?24'hFF0000:disp_data;   
      else
        VGA_rgb <= disp_data; 
    end  
  else if(disp_ram_en)
    VGA_rgb <= disp_number_data;
  else
    VGA_rgb <= disp_data; 
end


// number dispaly
wire [23:0] disp_number_data;
wire        disp_ram_en;
number_choose #(
  .IMAGE_WIDTH         (IMAGE_WIDTH        ),
  .IMAGE_HEIGHT        (IMAGE_HEIGHT       ),
  .IMAGE_NUMBER_WIDTH  (IMAGE_NUMBER_WIDTH ),
  .IMAGE_NUMBER_HEIGHT (IMAGE_NUMBER_HEIGHT)           
)number_choose_initial
(
  .sclk        (sclk        ),
  .rst_n       (!rst_p          ),
  .read_number (read_number     ),
  .Data_Req    (DataReq         ),
  .H_Addr      (H_Addr          ),  
  .V_Addr      (V_Addr          ),
  .disp_ram_en (disp_ram_en     ),
  .Disp_Data   (disp_number_data)
);


endmodule