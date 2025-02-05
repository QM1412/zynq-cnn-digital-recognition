`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/21 20:09:36
// Design Name: 
// Module Name: ov5640_hdmi_top
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
module ov5640_hdmi_top(
    // system clock and reset(negedge)
    //input         clk50M            ,
    input         reset_n           ,  
    
    input         camera_pclk       ,
    input         Vsync             ,
    input         Href              ,
    input [7:0]   Data              ,
    // uart port
    input          rx_pin            ,
    output         tx_pin            ,
    // camera interface
    inout         i2c_sdat          ,
    output        i2c_sclk          ,
    output        camera_pwdn       ,
    output        Init_Done_led     ,
    output        camera_rst_n      ,

    // hdmi interface
    output        tmds_clk_p        ,
    output        tmds_clk_n        ,
    output [2:0]  tmds_data_p       ,
    output [2:0]  tmds_data_n       ,

    // DDR3 interface
    // DDR3
    inout [14:0]  ddr_addr          ,
    inout [2:0]   ddr_ba            ,
    inout         ddr_cas_n         ,
    inout         ddr_ck_n          ,
    inout         ddr_ck_p          ,
    inout         ddr_cke           ,
    inout         ddr_cs_n          ,
    inout [3:0]   ddr_dm            ,
    inout [31:0]  ddr_dq            ,
    inout [3:0]   ddr_dqs_n         ,
    inout [3:0]   ddr_dqs_p         ,
    inout         ddr_odt           ,
    inout         ddr_ras_n         ,
    inout         ddr_reset_n       ,
    inout         ddr_we_n          ,
    //fixed interface
    inout         FIXED_IO_ddr_vrn  ,
    inout         FIXED_IO_ddr_vrp  ,
    inout [53:0]  FIXED_IO_mio      ,
    inout         FIXED_IO_ps_clk   ,
    inout         FIXED_IO_ps_porb  ,
    inout         FIXED_IO_ps_srstb 
    );
/**********************   parameter   *************************/
// camera parameter
parameter IMAGE_WIDTH     =1024; // 1024x600
parameter IMAGE_HEIGHT    =600;
parameter IMAGE_TYPE      =0;   //0:RGB 1:JPEG
parameter IMAGE_FLIP_EN   =1;
parameter IMAGE_MIRROR_EN =1;

// fifo adapter parameter
parameter DDR_BASE_ADDR  = 32'h1800000; // this is basic address,must save some space to give ps
parameter FIFO_DW        = 16;
parameter AXI_ID_WIDTH   = 4;
parameter AXI_ADDR_WIDTH = 32;
parameter AXI_DATA_WIDTH = 64;
parameter AXI_ID         = 4'b0000;

// number choose and box parameter
parameter IMAGE_NUMBER_WIDTH  =64;
parameter IMAGE_NUMBER_HEIGHT =64;
parameter BIN_WINDOWS_SIZE    =28*4+2;   // 目前设计的间隔为4主要是image2ps模块卡住
parameter BOX_WINDOWS_SIZE    =28*4; 

// rgb2binarization parameter
parameter THRESHOLD = 8'd119;

/**************************************************************/

/**********************   Camera  driver  *********************/
// camera initial
wire init_done;
wire PCLK;
assign Init_Done_led = init_done;
// assign PCLK = camera_pclk;
BUFG BUFG_inst (
   .O(PCLK ), // 1-bit output: Clock output
   .I(camera_pclk )  // 1-bit input: Clock input
);

camera_init  #(
  .IMAGE_TYPE      (IMAGE_TYPE)     ,        //0:RGB 1:JPEG
  .IMAGE_WIDTH     (IMAGE_WIDTH)    ,
  .IMAGE_HEIGHT    (IMAGE_HEIGHT)   ,
  .IMAGE_FLIP_EN   (IMAGE_FLIP_EN)  ,
  .IMAGE_MIRROR_EN (IMAGE_MIRROR_EN)
)camera_init_0
(
  .Clk         (ps2pl_clk50m)         ,
  .Rst_n       (!reset)        ,
  .Init_Done   (init_done)      ,
  .camera_rst_n(camera_rst_n)   ,
  .camera_pwdn (camera_pwdn)    ,
  .i2c_sclk    (i2c_sclk)       ,
  .i2c_sdat    (i2c_sdat)
);

// camera data capture
wire        ImageState;
wire        camera_data_valid;
wire [15:0] camera_data;
wire        camera_Hs;
wire        camera_Vs;
wire [11:0] camera_Xaddr;
wire [11:0] camera_Yaddr;

DVP_Capture DVP_Capture_initial(
  .Rst_p      (!init_done)  ,   // this only one pulse
  .PCLK       (PCLK)  ,
  .Vsync      (Vsync)  ,
  .Href       (Href)  ,
  .Data       (Data)  ,
  .ImageState (ImageState)  ,  // this mean that DVP_Capture is working
  .DataValid  (camera_data_valid)  ,
  .DataPixel  (camera_data)  ,
  .DataHs     (camera_Hs)  ,
  .DataVs     (camera_Vs)  ,
  .Xaddr      (camera_Xaddr)  ,
  .Yaddr      (camera_Yaddr)  
);
/**************************************************************/

/*****************rgb to gray to binarization******************/
wire [15:0] data2wrfifo;
wire        data2wrfifo_valid;

wire [15:0] deal_image_data      ;
wire        deal_image_data_valid;
wire        deal_image_hs        ;
wire        deal_image_vs        ;
wire [11:0] deal_image_Xaddr     ;
wire [11:0] deal_image_Yaddr     ;

// gray to Binarization
rgb2Binarization#(
  .PROC_METHOD ("FORMULA"   ), //"AVERAGE" or "FORMULA"
  .IMAGE_WIDTH (IMAGE_WIDTH ),
  .IMAGE_HEIGHT(IMAGE_HEIGHT),
  .WINDOWS_SIZE(BIN_WINDOWS_SIZE),
  .THRESHOLD   (THRESHOLD   )
)rgb2Binarization_initial
(
  .sclk     (PCLK             ),
  .reset_p  (reset            ),
  .rgb_hs   (camera_Hs        ),      
  .rgb_vs   (camera_Vs        ),      
  .rgb_data (camera_data      ),
  .rgb_valid(camera_data_valid),   //rgb输入有效标识
  .rgb_Xaddr(camera_Xaddr     ),
  .rgb_Yaddr(camera_Yaddr     ),

  .deal_image_data      (deal_image_data      ),
  .deal_image_data_valid(deal_image_data_valid),
  .deal_image_hs        (deal_image_hs        ),
  .deal_image_vs        (deal_image_vs        ),
  .deal_image_Xaddr     (deal_image_Xaddr     ),
  .deal_image_Yaddr     (deal_image_Yaddr     )
);

assign data2wrfifo       = deal_image_data;
assign data2wrfifo_valid = deal_image_data_valid;
/**************************************************************/

/*********************   clock  driver  ***********************/
wire         reset      ;
wire         pl_reset_n ;
wire         reset_pre  ;
wire         pll_locked ;
wire         loc_clk100m;
wire         loc_clk200m;
reg  [19:0]  reset_sync ;
reg  [4:0]   reset_cnt;

assign pl_reset_n = ps2pl_resetn & reset_n;
assign reset_pre  = ~pll_locked;
assign reset      = reset_sync[19];

//The PS releases the reset first, and the logic reset release of the PL is delayed by 20 clock cycles
always@(posedge loc_clk200m or posedge reset_pre)
begin
  if(reset_pre)
    reset_sync <= {20{1'b1}};
  else
    reset_sync <= reset_sync << 1;
end


clk_wiz_0 pll_initial
(
  .loc_clk200m(loc_clk200m),  // output loc_clk200m
  .loc_clk100m(loc_clk100m),  // output loc_clk100m
  .resetn(pl_reset_n),        // input resetn
  .locked(pll_locked),        // output locked
  .clk_in1(ps2pl_clk50m)            // input 50M
);      

clk_wiz_1 hdmi_pll
(
.pixelclk(pixelclk),     // output pixelclk
.pixelclk5x(pixelclk5x), // output pixelclk5x
.resetn(!reset),        // input resetn
.locked(),       // output locked
.clk_in1(loc_clk100m)
);
/**************************************************************/

/***************   display black box and number  **************/
// box
wire [23:0]  vga_data_tmp;
reg  [23:0]  VGA_rgb  ;

always @(posedge pixelclk or posedge reset) begin
  if(reset)
    VGA_rgb <= 24'h000000;
  else if (DataReq && (H_Addr >= (IMAGE_WIDTH/2-BOX_WINDOWS_SIZE/2 + 1)) && (H_Addr < (IMAGE_WIDTH/2+BOX_WINDOWS_SIZE/2 + 1))
          && (V_Addr >= (IMAGE_HEIGHT/2-BOX_WINDOWS_SIZE/2 - 1)) && (V_Addr < (IMAGE_HEIGHT/2+BOX_WINDOWS_SIZE/2 - 1 )) ) begin
      if (H_Addr == (IMAGE_WIDTH/2-BOX_WINDOWS_SIZE/2 + 1) || H_Addr == (IMAGE_WIDTH/2+BOX_WINDOWS_SIZE/2)-1 + 1 || 
          V_Addr == (IMAGE_HEIGHT/2-BOX_WINDOWS_SIZE/2 - 1) || V_Addr == (IMAGE_HEIGHT/2+BOX_WINDOWS_SIZE/2) - 1 -1)
        VGA_rgb <= 24'hFFC0CB;   
      else
        VGA_rgb <= vga_data_tmp; 
    end  
  else if(disp_ram_en)
    VGA_rgb <= disp_number_data;
  else
    VGA_rgb <= vga_data_tmp; 
end

// number dispaly
wire [3:0]  read_number;
wire [23:0] disp_number_data;
wire        disp_ram_en;
reg  [31:0] slv_reg3_out_delay;

always @(posedge pixelclk) begin  // axi_clock to pixelclk
  slv_reg3_out_delay<= slv_reg3_out;
end

assign read_number = slv_reg3_out_delay; 

number_choose #(
  .IMAGE_WIDTH         (IMAGE_WIDTH        ),
  .IMAGE_HEIGHT        (IMAGE_HEIGHT       ),
  .IMAGE_NUMBER_WIDTH  (IMAGE_NUMBER_WIDTH ),
  .IMAGE_NUMBER_HEIGHT (IMAGE_NUMBER_HEIGHT)           
)number_choose_initial
(
  .sclk        (pixelclk        ),
  .rst_n       (!reset          ),
  .read_number (read_number     ),
  .Data_Req    (DataReq         ),
  .H_Addr      (H_Addr          ),  
  .V_Addr      (V_Addr          ),
  .disp_ram_en (disp_ram_en     ),
  .Disp_Data   (disp_number_data)
);
/**************************************************************/

/**********************   hdmi  driver  ***********************/
/*if you want to modify resolution,you must modify vga_pll and hdmi_pll*/
wire hdmi_pll_locked;
wire ClkDisp;
wire pixelclk;
wire pixelclk5x;
wire frame_begin;

wire [23:0] Disp_Data;  // this is display data
wire        DataReq;
wire [7 :0] Disp_Red;   // the mod is RGB888
wire [7 :0] Disp_Green;
wire [7 :0] Disp_Blue;
wire        Disp_HS;
wire        Disp_VS;
wire        Disp_DE;
wire        Disp_PCLK;

reg         Disp_HS_delay;
reg         Disp_VS_delay;

wire [11:0] H_Addr;
wire [11:0] V_Addr;

// The reset signal is tapped using the pixel clock
reg reset_tmp1,reset_tmp2;
always @(posedge pixelclk)begin
    reset_tmp1 <= reset;
    reset_tmp2 <= reset_tmp1;
end

disp_driver #(
  .AHEAD_CLK_CNT(1) //ahead N clock generate DataReq
)disp_driver_initial(
  .ClkDisp   (pixelclk) ,
  .Rst_n     (!reset) ,
  .Data      (Disp_Data) ,
  .DataReq   (DataReq) ,
  .H_Addr    (H_Addr) ,
  .V_Addr    (V_Addr) ,
  .Disp_Sof  (frame_begin) ,
  .Disp_HS   (Disp_HS) ,
  .Disp_VS   (Disp_VS) ,
  .Disp_Red  (vga_data_tmp[23:16]) ,
  .Disp_Green(vga_data_tmp[15:8]) ,
  .Disp_Blue (vga_data_tmp[7:0]) ,
  .Disp_DE   (Disp_DE) ,
  .Disp_PCLK () 
);
// The request signal comes one cycle in advance, because the ROM is configured to have data after two cycles of input address, 
// then the data must be requested one cycle in advance, and then the output effective signal is delayed by one cycle
// 请求信号提前一个周期过来，因为ROM的配置的是输入地址后两个周期才会有数据，那么就要提前一个周期请求数据，然后输出有效信号延后一个周期
// In this way, the Disp_DE signal will be delayed by one beat (disp_driver is delayed in the other), 
// then the HS and VS signals will be delayed by one beat together, otherwise they will be misaligned
// 这样Disp_DE信号就要延迟一拍(disp_driver里面延迟了)，那么HS和VS信号就要一同延迟一拍，不然会错位
always @(posedge pixelclk) begin
  Disp_HS_delay <= Disp_HS;
  Disp_VS_delay <= Disp_VS;  
end

dvi_encoder dvi_encoder_initial(
  // clock and reset sigal
  .pixelclk     (pixelclk),
  .pixelclk5x   (pixelclk5x),
  // .rst_p        (!hdmi_pll_locked),
   .rst_p       (reset_tmp2),
  // data signals and synchronization signals
  .blue_din     (VGA_rgb[7:0]),
  .green_din    (VGA_rgb[15:8]),
  .red_din      (VGA_rgb[23:16]),
  .hsync        (Disp_HS_delay),
  .vsync        (Disp_VS_delay),
  .de           (Disp_DE),
  // tmds signals
  .tmds_clk_p   (tmds_clk_p),
  .tmds_clk_n   (tmds_clk_n),
  .tmds_data_p  (tmds_data_p),
  .tmds_data_n  (tmds_data_n)
);
/**************************************************************/

/********************   fifo adapter  driver  *****************/
// write signal define
wire               wrfifo_clr  ;
wire               wrfifo_clk  ;
wire               wrfifo_wren ;
wire [FIFO_DW-1:0] wrfifo_din  ;
// read signal define
wire               rdfifo_clr    ;
wire               rdfifo_clk    ;
wire               rdfifo_rden   ;
wire [FIFO_DW-1:0] rdfifo_dout   ;
// slave interface write address ports
wire [AXI_ID_WIDTH-1:0]     s_axi_awid    ;
wire [AXI_ADDR_WIDTH-1:0]   s_axi_awaddr  ;
wire [7:0]                  s_axi_awlen   ;
wire [2:0]                  s_axi_awsize  ;
wire [1:0]                  s_axi_awburst ;
wire [0:0]                  s_axi_awlock  ;
wire [3:0]                  s_axi_awcache ;
wire [2:0]                  s_axi_awprot  ;
wire [3:0]                  s_axi_awqos   ;
wire [3:0]                  s_axi_awregion;
wire                        s_axi_awvalid ;
wire                        s_axi_awready ;
// slave interface write data ports
wire [AXI_DATA_WIDTH-1:0]   s_axi_wdata   ;
wire [AXI_DATA_WIDTH/8-1:0] s_axi_wstrb   ;
wire                        s_axi_wlast   ;
wire                        s_axi_wvalid  ;
wire                        s_axi_wready  ;
// slave interface write response ports
wire [1:0]                  s_axi_bresp   ;
wire                        s_axi_bvalid  ;
wire                        s_axi_bready  ;
// slave interface read address ports
wire [AXI_ID_WIDTH-1:0]     s_axi_arid    ;
wire [AXI_ADDR_WIDTH-1:0]   s_axi_araddr  ;
wire [7:0]                  s_axi_arlen   ;
wire [2:0]                  s_axi_arsize  ;
wire [1:0]                  s_axi_arburst ;
wire [0:0]                  s_axi_arlock  ;
wire [3:0]                  s_axi_arcache ;
wire [2:0]                  s_axi_arprot  ;
wire [3:0]                  s_axi_arqos   ;
wire [3:0]                  s_axi_arregion;
wire                        s_axi_arvalid ;
wire                        s_axi_arready ;
// slave interface read data ports
wire [AXI_DATA_WIDTH-1:0]   s_axi_rdata   ;
wire [1:0]                  s_axi_rresp   ;
wire                        s_axi_rlast   ;
wire                        s_axi_rvalid  ;
wire                        s_axi_rready  ;
// other ports
wire                        s_axi_aclk    ;

// write fifo assign
assign wrfifo_clr  = reset;
assign wrfifo_clk  = PCLK;
// assign wrfifo_din  = camera_data;     // here conect Original camera's data
// assign wrfifo_wren = camera_data_valid;
assign wrfifo_din  = data2wrfifo;       // here conect  gray data
assign wrfifo_wren = data2wrfifo_valid;

// read fifo assign
assign rdfifo_clr  = reset || frame_begin;
assign rdfifo_rden = DataReq;
assign Disp_Data = {rdfifo_dout[15:11],3'd0,rdfifo_dout[10:5],2'd0,rdfifo_dout[4:0],3'd0}; // Conversion mode RGB565->RGB888
assign s_axi_aclk = loc_clk200m;

// you must match fifo's width and depth
fifo_axi4_adapter #(
  .FIFO_DW                 (FIFO_DW     ),
  .WR_AXI_BYTE_ADDR_BEGIN  (DDR_BASE_ADDR      ),
  .WR_AXI_BYTE_ADDR_END    (DDR_BASE_ADDR + IMAGE_WIDTH*IMAGE_HEIGHT*2 - 1   ),
  .RD_AXI_BYTE_ADDR_BEGIN  (DDR_BASE_ADDR      ),
  .RD_AXI_BYTE_ADDR_END    (DDR_BASE_ADDR + IMAGE_WIDTH*IMAGE_HEIGHT*2 - 1    ),
  .AXI_DATA_WIDTH          (AXI_DATA_WIDTH     ),
  .AXI_ADDR_WIDTH          (AXI_ADDR_WIDTH     ),
  .AXI_ID_WIDTH            (AXI_ID_WIDTH      ),
  .AXI_ID                  (AXI_ID),
  .AXI_BURST_LEN           (8'd15  ), //burst length = AXI_BURST_LEN+1
  .FIFO_ADDR_DEPTH         (64     )
)fifo_axi4_adapter_initial
(
  // system clock 200M and reset
  .clk           (loc_clk200m  ),
  .reset         (reset        ),
  // wr_fifo wr Interface
  .wrfifo_clr    (wrfifo_clr   ),
  .wrfifo_clk    (wrfifo_clk   ),
  .wrfifo_wren   (wrfifo_wren  ),
  .wrfifo_din    (wrfifo_din   ),
  .wrfifo_full   (),
  .wrfifo_wr_cnt (),
  // rd_fifo rd Interface
  .rdfifo_clr    (rdfifo_clr  ),
  .rdfifo_clk    (pixelclk    ),
  .rdfifo_rden   (rdfifo_rden ),
  .rdfifo_dout   (rdfifo_dout ),
  .rdfifo_empty  (),
  .rdfifo_rd_cnt (),
  // Master Interface Write Address Ports
  .m_axi_awid    (s_axi_awid   ),
  .m_axi_awaddr  (s_axi_awaddr ),
  .m_axi_awlen   (s_axi_awlen  ),
  .m_axi_awsize  (s_axi_awsize ),
  .m_axi_awburst (s_axi_awburst),
  .m_axi_awlock  (s_axi_awlock ),
  .m_axi_awcache (s_axi_awcache),
  .m_axi_awprot  (s_axi_awprot ),
  .m_axi_awqos   (s_axi_awqos  ),
  .m_axi_awregion(s_axi_awregio),
  .m_axi_awvalid (s_axi_awvalid),
  .m_axi_awready (s_axi_awready),
  // Master Interface Write Data Ports
  .m_axi_wdata   (s_axi_wdata ),
  .m_axi_wstrb   (s_axi_wstrb ),
  .m_axi_wlast   (s_axi_wlast ),
  .m_axi_wvalid  (s_axi_wvalid),
  .m_axi_wready  (s_axi_wready),
  // Master Interface Write Response Ports
  .m_axi_bid     (AXI_ID),
  .m_axi_bresp   (s_axi_bresp ),
  .m_axi_bvalid  (s_axi_bvalid),
  .m_axi_bready  (s_axi_bready),
  // Master Interface Read Address Ports
  .m_axi_arid    (s_axi_arid    ),
  .m_axi_araddr  (s_axi_araddr  ),
  .m_axi_arlen   (s_axi_arlen   ),
  .m_axi_arsize  (s_axi_arsize  ),
  .m_axi_arburst (s_axi_arburst ),
  .m_axi_arlock  (s_axi_arlock  ),
  .m_axi_arcache (s_axi_arcache ),
  .m_axi_arprot  (s_axi_arprot  ),
  .m_axi_arqos   (s_axi_arqos   ),
  .m_axi_arregion(s_axi_arregion),
  .m_axi_arvalid (s_axi_arvalid ),
  .m_axi_arready (s_axi_arready ),
  // Master Interface Read Data Ports
  .m_axi_rid     (AXI_ID),
  .m_axi_rdata   (s_axi_rdata ),
  .m_axi_rresp   (s_axi_rresp ),
  .m_axi_rlast   (s_axi_rlast ),
  .m_axi_rvalid  (s_axi_rvalid),
  .m_axi_rready  (s_axi_rready)
);
/**************************************************************/

/********************   fifo adapter  driver  *****************/
wire ps2pl_clk50m;
wire ps2pl_resetn;
wire pl2ps_axi_resetn;
wire [31:0]slv_reg3_out;
wire [31:0]the_rd_data;

assign pl2ps_axi_resetn = pll_locked;

system_wrapper system_wrapper_initial
(
  // ps2pl-clock and ps2pl-reset
  .ps2pl_clk50m     (ps2pl_clk50m),
  .ps2pl_resetn     (ps2pl_resetn),
  .pl2ps_axi_resetn (pl2ps_axi_resetn),
  // bram data
  .slv_reg3_out     (slv_reg3_out),
  .the_rd_data      (the_rd_data),
  // uart ports
  .UART_rxd         (rx_pin),
  .UART_txd         (tx_pin),
  //DDR interface
  .DDR_addr         (ddr_addr   ),
  .DDR_ba           (ddr_ba     ),
  .DDR_cas_n        (ddr_cas_n  ),
  .DDR_ck_n         (ddr_ck_n   ),
  .DDR_ck_p         (ddr_ck_p   ),
  .DDR_cke          (ddr_cke    ),
  .DDR_cs_n         (ddr_cs_n   ),
  .DDR_dm           (ddr_dm     ),
  .DDR_dq           (ddr_dq     ),
  .DDR_dqs_n        (ddr_dqs_n  ),
  .DDR_dqs_p        (ddr_dqs_p  ),
  .DDR_odt          (ddr_odt    ),
  .DDR_ras_n        (ddr_ras_n  ),
  .DDR_reset_n      (ddr_reset_n),
  .DDR_we_n         (ddr_we_n   ),
  //fixed_io interface
  .FIXED_IO_ddr_vrn (FIXED_IO_ddr_vrn ),
  .FIXED_IO_ddr_vrp (FIXED_IO_ddr_vrp ),
  .FIXED_IO_mio     (FIXED_IO_mio     ),
  .FIXED_IO_ps_clk  (FIXED_IO_ps_clk  ),
  .FIXED_IO_ps_porb (FIXED_IO_ps_porb ),  
  .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
  //slave interface read address ports
  .pl2ps_axi_aclk   (s_axi_aclk       ),
  .pl2ps_axi_arid   (),
  .pl2ps_axi_araddr (s_axi_araddr     ),
  .pl2ps_axi_arburst(s_axi_arburst    ),
  .pl2ps_axi_arcache(s_axi_arcache    ),
  .pl2ps_axi_arlen  (s_axi_arlen      ),
  .pl2ps_axi_arlock (s_axi_arlock     ),
  .pl2ps_axi_arprot (s_axi_arprot     ),
  .pl2ps_axi_arqos  (s_axi_arqos      ),
  .pl2ps_axi_arready(s_axi_arready    ),
  .pl2ps_axi_arsize (s_axi_arsize     ),
  .pl2ps_axi_arvalid(s_axi_arvalid    ),
  //slave interface write address ports
  .pl2ps_axi_awaddr (s_axi_awaddr     ),
  .pl2ps_axi_awburst(s_axi_awburst    ),
  .pl2ps_axi_awcache(s_axi_awcache    ),
  .pl2ps_axi_awid   (),
  .pl2ps_axi_awlen  (s_axi_awlen      ),
  .pl2ps_axi_awlock (s_axi_awlock     ),
  .pl2ps_axi_awprot (s_axi_awprot     ),
  .pl2ps_axi_awqos  (s_axi_awqos      ),
  .pl2ps_axi_awready(s_axi_awready    ),
  .pl2ps_axi_awsize (s_axi_awsize     ),
  .pl2ps_axi_awvalid(s_axi_awvalid    ),
  //slave interface write response ports
  .pl2ps_axi_bid    (),
  .pl2ps_axi_bready (s_axi_bready     ),
  .pl2ps_axi_bresp  (s_axi_bresp      ),
  .pl2ps_axi_bvalid (s_axi_bvalid     ),
  //slave interface read data ports
  .pl2ps_axi_rdata  (s_axi_rdata),
  .pl2ps_axi_rid    (),
  .pl2ps_axi_rlast  (s_axi_rlast),
  .pl2ps_axi_rready (s_axi_rready),
  .pl2ps_axi_rresp  (s_axi_rresp),
  .pl2ps_axi_rvalid (s_axi_rvalid),
  //slave interface write data ports
  .pl2ps_axi_wdata  (s_axi_wdata),
  .pl2ps_axi_wid    (),
  .pl2ps_axi_wlast  (s_axi_wlast),
  .pl2ps_axi_wready (s_axi_wready),
  .pl2ps_axi_wstrb  (s_axi_wstrb),
  .pl2ps_axi_wvalid (s_axi_wvalid)
);
/**************************************************************/

endmodule
