`timescale 1ns/1ps

// pong chu top animate module implemented by John Tramel
// 12/28/16

module pong_top_an (
   input S_AXI_ACLK,
   input slv_reg_wren,
   input [2:0] axi_awaddr,
   input [31:0] S_AXI_WDATA,
   input S_AXI_ARESETN,

   input  wire [ 1:0] btn,
   input  wire [3:0]  sws,
   output wire        hsync, vsync,
   output wire [3:0] VGA_R,
   output wire [3:0] VGA_G,
   output wire [3:0] VGA_B, 
   
   input  wire [7:0]  ja, 
   output wire [3:0]  led
   );
wire [7:0]  speed;

wire [11:0] rgb;
/////////////////////////////////////////////
// signal declaration
/////////////////////////////////////////////
wire [9:0] pixel_x, pixel_y;
wire       video_on, cnt3;
reg  [2:0] rgb_reg;
wire [2:0] rgb_next;

/////////////////////////////////////////////
// body
/////////////////////////////////////////////
vga_sync vsuut (
   .clk(S_AXI_ACLK),
   .reset(S_AXI_ARESETN),
   .hsync(hsync),
   .vsync(vsync),
   .video_on(video_on),
   .cnt3(cnt3),
   .pixel_x(pixel_x),
   .pixel_y(pixel_y));
pong_graph_animate pgauut (
   .clk(S_AXI_ACLK),
   .reset(S_AXI_ARESETN),
   .btn(btn),
   .sws(sws),
   .speed(speed),
   .video_on(video_on),
   .pix_x(pixel_x),
   .pix_y(pixel_y),
   .graph_rgb(rgb_next));   

xadc_user_logic xadcuut (
    .clk(S_AXI_ACLK),
    .ja(ja),
    .led(led), 
    .data_out(speed)
);

/////////////////////////////////////////////
// rgb buffer
/////////////////////////////////////////////
always @(posedge S_AXI_ACLK, posedge S_AXI_ARESETN)
   if (S_AXI_ARESETN)
      rgb_reg <= 3'b000; else
   if (cnt3)
      rgb_reg <= rgb_next;
		
assign rgb[11:8] = {4{rgb_reg[2]}};  //Nexys4
assign rgb[ 7:4] = {4{rgb_reg[1]}};
assign rgb[ 3:0] = {4{rgb_reg[0]}};
  

assign VGA_R = (rgb_reg == 3'b110)? 4'b1111: {4{rgb_reg[2]}};
assign VGA_G = (rgb_reg == 3'b110)? sws    : {4{rgb_reg[1]}};
assign VGA_B = (rgb_reg == 3'b110)? 4'b0100: {4{rgb_reg[0]}};
		

endmodule


