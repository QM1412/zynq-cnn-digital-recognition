`timescale 1ns/1ps

module top_sim ();

// generate data
reg PCLK; // 50M
reg axi_sclk;
reg Rst_p;// 高电平复位
reg       Vsync;
reg       Href;
reg [12:0] Data;

// define parameter
parameter WIDTH = 20;
parameter HIGHT = 20;
parameter WIDTH_GEN = WIDTH*2; // 数据采集中，每两个8bit数据合成一个16bit的数据输出，所以生成的时候要2倍


// out signal
wire  ImageState;
wire  DataValid;
wire [15:0] DataPixel;
wire DataHs;
wire DataVs;
wire [11:0] Xaddr;
wire [11:0] Yaddr;

// initial data and signal
always #5 PCLK = ~PCLK;  // 100M
always #2  axi_sclk = ~axi_sclk; //200M 
integer i,j;
initial begin
    PCLK = 1;
    axi_sclk = 1;
    Rst_p = 1;
    Vsync = 0;
    Href = 0;
    Data = 8'd0 ;
    #805;
    Rst_p = 0;
    #400;

    repeat(30) begin
        Vsync = 1;
        #320;
        Vsync = 0;
        #800;
        for(i=0;i<HIGHT;i=i+1) begin
            for(j=0;j<WIDTH_GEN;j=j+1) begin
                Href = 1;
                Data = {$random};
                #80;
            end
            Href = 0;
            #800;
        end
    end
    $stop;
end


DVP_Capture DVP_Capture_initial(
  .Rst_p        (Rst_p)    ,
  .PCLK         (PCLK)    ,
  .Vsync        (Vsync)    ,
  .Href         (Href)    ,
  .Data         (Data)    ,

  .ImageState   (ImageState)    ,
  .DataValid    (camera_data_valid)    ,
  .DataPixel    (camera_data)    ,
  .DataHs       (DataHs)    ,
  .DataVs       (DataVs)    ,
  .Xaddr        (Xaddr)    ,
  .Yaddr        (Yaddr)
);

wire [15:0] camera_data;
wire camera_data_valid;

wire [15:0] deal_image_data       ;
wire        deal_image_data_valid ;
wire [11:0] deal_image_Xaddr      ;
wire [11:0] deal_image_Yaddr      ;
wire        deal_image_hs         ;
wire        deal_image_vs         ;

rgb2Binarization#(
  .PROC_METHOD ("FORMULA"   ), //"AVERAGE" or "FORMULA"
  .IMAGE_WIDTH (WIDTH ),
  .IMAGE_HEIGHT(HIGHT),
  .WINDOWS_SIZE(10),
  .THRESHOLD   (128   )
)rgb2Binarization_initial
(
  .sclk     (PCLK             ),
  .reset_p  (Rst_p            ),
  .rgb_hs   (DataHs        ),      
  .rgb_vs   (DataVs        ),      
  .rgb_data (camera_data      ),
  .rgb_valid(camera_data_valid),   //rgb输入有效标识
  .rgb_Xaddr(Xaddr     ),
  .rgb_Yaddr(Yaddr     ),

  .deal_image_data      (deal_image_data      ),
  .deal_image_data_valid(deal_image_data_valid),
  .deal_image_hs        (deal_image_hs        ),
  .deal_image_vs        (deal_image_vs        ),
  .deal_image_Xaddr     (deal_image_Xaddr     ),
  .deal_image_Yaddr     (deal_image_Yaddr     )
);
//);

image2ps #(
    .TRANS_NUM        (10*10),
    .IMAGE_WIDTH      (WIDTH),
    .IMAGE_HEIGHT     (HIGHT),
    .WINDOWS_SIZE     (10)
)image2ps_initial
(
    .reset_p(Rst_p),

    .rd_clk(axi_sclk),
    .wr_clk(PCLK),

    .image_data(deal_image_data),
    .image_data_valid(deal_image_data_valid),
    .image_Xaddr(deal_image_Xaddr),
    .image_Yaddr(deal_image_Yaddr)
);



    
endmodule