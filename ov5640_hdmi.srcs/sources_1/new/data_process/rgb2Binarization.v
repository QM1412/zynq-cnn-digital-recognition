module rgb2Binarization
#(
    parameter PROC_METHOD  = "FORMULA" , //"AVERAGE" or "FORMULA"
    parameter IMAGE_WIDTH  = 1024,
    parameter IMAGE_HEIGHT = 600 ,
    parameter WINDOWS_SIZE = 784,
    parameter THRESHOLD    = 119
)
(
    input           sclk,
    input           reset_p,
    input           rgb_hs,      //rgb输入行信号
    input           rgb_vs,      //rgb输入场信号
    input [15:0]    rgb_data ,
    input           rgb_valid,   //rgb输入有效标识
    input [11:0]    rgb_Xaddr,
    input [11:0]    rgb_Yaddr,

    output reg [15:0] deal_image_data       ,
    output reg        deal_image_data_valid ,
    output reg [11:0] deal_image_Xaddr      ,
    output reg [11:0] deal_image_Yaddr      ,
    output reg        deal_image_hs         ,
    output reg        deal_image_vs         
);

wire [7:0]  gray_image_data      ;     
wire        gray_image_data_valid;
wire        gray_image_data_hs   ;
wire        gray_image_data_vs   ;

reg  [11:0] rgb_Xaddr_delay      ;
reg  [11:0] rgb_Yaddr_delay      ;
reg  [15:0] rgb_data_delay       ;
reg         rgb_data_valid_delay ;

wire [7:0] bin_gray_image_data;

// rgb to gray
rgb2gray #(
  .PROC_METHOD("FORMULA") //"AVERAGE" or "FORMULA"
)rgb2gray_initial  
(
  // signals input 
  .clk         (sclk       ),  
  .reset_p     (reset_p    ),  
  .rgb_hs      (rgb_hs     ),   
  .rgb_vs      (rgb_vs     ),   
  .rgb_valid   (rgb_valid   ),        
  .red_8b_i    ({rgb_data[15:11] ,3'b0}),   //R
  .green_8b_i  ({rgb_data[10:5]  ,2'b0}),   //G
  .blue_8b_i   ({rgb_data[4:0]   ,3'b0}),   //B
  // signals output
  .gray_8b_o   (gray_image_data       ),  //GRAY output
  .gray_valid  (gray_image_data_valid ),  //gray data valide
  .gray_hs     (gray_image_data_hs    ),  //gray hs
  .gray_vs     (gray_image_data_vs    )   //gray vs
);

// the rgb2gray module will delay one clock for gray_image_data,so in order to synchronized data stream,
// I dealy one clock for the follow signals
always @(posedge sclk or posedge reset_p) begin
  if(reset_p)begin
    rgb_Xaddr_delay      <= 'b0;
    rgb_Yaddr_delay      <= 'b0;
    rgb_data_delay       <= 'b0;
    rgb_data_valid_delay <= 'b0;
  end
  else begin
    rgb_Xaddr_delay      <= rgb_Xaddr;
    rgb_Yaddr_delay      <= rgb_Yaddr;
    rgb_data_delay       <= rgb_data ;
    rgb_data_valid_delay <= rgb_valid;
  end

end

// 二值化
assign  bin_gray_image_data = gray_image_data < THRESHOLD ? 8'hff : 8'h00;

// Binarization range
always @ (posedge sclk or posedge reset_p) begin 
  if(reset_p)
    deal_image_data <= 'd0;
  else begin
    if ( (rgb_Xaddr_delay >=  (IMAGE_WIDTH/2-WINDOWS_SIZE/2)) && (rgb_Xaddr_delay < (IMAGE_WIDTH/2+WINDOWS_SIZE/2)) 
                    && (rgb_Yaddr_delay >= (IMAGE_HEIGHT/2-WINDOWS_SIZE/2)) && (rgb_Yaddr_delay <(IMAGE_HEIGHT/2+WINDOWS_SIZE/2)) ) begin
            deal_image_data  <= {bin_gray_image_data[7:3], bin_gray_image_data[7:2], bin_gray_image_data[7:3]}; 
        end    
    else          
            deal_image_data  <= rgb_data_delay; 
  end
end

// the valid sigal also need to synchronized gray_image_data_valid(same as rgb_data_valid_delay)
always @(posedge sclk or posedge reset_p) begin
  if(reset_p)
    deal_image_data_valid <= 1'b0;
  else
    deal_image_data_valid <= gray_image_data_valid;   // or rgb_data_valid_delay
end

always @(posedge sclk or posedge reset_p) begin
  if(reset_p)begin
    deal_image_hs    <= 1'd0;
    deal_image_vs    <= 1'd0;
    deal_image_Xaddr <= 12'd0;
    deal_image_Yaddr <= 12'd0;
  end
  else begin
    deal_image_hs    <= gray_image_data_hs;
    deal_image_vs    <= gray_image_data_vs;
    deal_image_Xaddr <= rgb_Xaddr_delay;
    deal_image_Yaddr <= rgb_Yaddr_delay;
  end 
end

endmodule