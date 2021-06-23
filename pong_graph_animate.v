`timescale 1ns/1ps

// pong game with animated graphics
// pong chu - implemented by john tramel 12/28/16

module pong_graph_animate (
   input  wire       clk, reset,
   input  wire       video_on,
   input  wire [1:0] btn,
   input  wire [3:0] sws,
   input  wire [7:0] speed,
   input  wire [9:0] pix_x, pix_y,  
   output reg  [2:0] graph_rgb
   );
   
   
wire [3:0] sws_wire; 
assign sws_wire = (sws == 0) ? 4'b0001 : sws;    
  
// constant and signal declaration
// x,y coordinates (0,0) (639,479)
parameter MAX_X = 640,
          MAX_Y = 480;
wire      refr_tick;

//////////////////////////////////////////////////
// vertical stripe as wall (fixed)
//////////////////////////////////////////////////
parameter WALL_X_L = 32,
          WALL_X_R = 35;

//////////////////////////////////////////////////
// right vertical bar (moves?)
//////////////////////////////////////////////////
parameter BAR_X_L = 600,
          BAR_X_R = 603;

// bar top, bottom boundary
wire [9:0] bar_y_t, bar_y_b;
//parameter BAR_Y_SIZE = 72;
parameter BAR_Y_SIZE = 36;

// register to track top boundary (x position fixed)
reg [9:0] bar_y_reg, bar_y_next;

// bar moving velocity when button pressed
parameter BAR_V = 4;

//////////////////////////////////////////////////
// square ball
//////////////////////////////////////////////////
//parameter BALL_SIZE = 8;
parameter BALL_SIZE = 8;

// ball left, right boundary
wire [9:0] ball_x_l, ball_x_r;

// ball top, bottom boundary
wire [9:0] ball_y_t, ball_y_b;

// reg to track left, top position
reg  [9:0] ball_x_reg, ball_y_reg;
wire [9:0] ball_x_next, ball_y_next;

// reg to track ball speed
reg  [9:0] x_delta_reg, x_delta_next;
reg  [9:0] y_delta_reg, y_delta_next;

// ball velocity can be pos or neg
parameter BALL_V_P =  2,
          BALL_V_N = -2;        

//////////////////////////////////////////////////
// round ball
//////////////////////////////////////////////////
wire [3:0] rom_addr, rom_col;
reg  [7:0] rom_data;
wire       rom_bit;

//////////////////////////////////////////////////
// object output signals
//////////////////////////////////////////////////
wire       wall_on, bar_on, sq_ball_on, rd_ball_on;
wire [2:0] wall_rgb, bar_rgb;
wire [2:0] ball_rgb;

//////////////////////////////////////////////////
// body of the design
//////////////////////////////////////////////////

//////////////////////////////////////////////////
// round ball image ROM
//////////////////////////////////////////////////
always @(*)
   case (rom_addr)
      3'h0: rom_data = 8'b00111100;  //   ****  
      3'h1: rom_data = 8'b01111110;  //  ****** 
      3'h2: rom_data = 8'b11111111;  // ********
      3'h3: rom_data = 8'b11111111;  // ********
      3'h4: rom_data = 8'b11111111;  // ********
      3'h5: rom_data = 8'b11111111;  // ********
      3'h6: rom_data = 8'b01111110;  //  ****** 
      3'h7: rom_data = 8'b00111100;  //   ****  
   endcase


//////////////////////////////////////////////////
// registers
//////////////////////////////////////////////////
always @(posedge clk, posedge reset)
   if (reset)
      begin
      bar_y_reg   <= 10'h0;
      ball_x_reg  <= 10'h0;
      ball_y_reg  <= 10'h0;
      x_delta_reg <= 10'h004;
      y_delta_reg <= 10'h004;
      end
   else
      begin
      bar_y_reg   <= bar_y_next;
      ball_x_reg  <= ball_x_next;
      ball_y_reg  <= ball_y_next;
      x_delta_reg <= x_delta_next;
      y_delta_reg <= y_delta_next;
      end

//////////////////////////////////////////////////
// refr_tick: 1-clock tick asserted at start of v-sync
// i.e. when screen is refreshed at 60 Hz
//////////////////////////////////////////////////
assign refr_tick = (pix_y == 481) && (pix_x == 0);

//////////////////////////////////////////////////
// wall - left vertical stripe
//////////////////////////////////////////////////
assign wall_on = (WALL_X_L <= pix_x) && (pix_x <= WALL_X_R);
assign wall_rgb = 3'b001;  // blue

//////////////////////////////////////////////////
// right vertical bar
//////////////////////////////////////////////////
assign bar_y_t = bar_y_reg;
assign bar_y_b = bar_y_t + BAR_Y_SIZE - 1;
assign bar_on = (BAR_X_L <= pix_x) && (pix_x <= BAR_X_R) &&
                (bar_y_t <= pix_y) && (pix_y <= bar_y_b);
assign bar_rgb = 3'b010; // green

//////////////////////////////////////////////////
// decide to move down or up
//////////////////////////////////////////////////
always @(*)
   begin
   bar_y_next = bar_y_reg;
   if (refr_tick)
      if (btn[1] & (bar_y_b < (MAX_Y - 1 - BAR_V)))
         bar_y_next = bar_y_reg + BAR_V; else
         if (btn[0] & (bar_y_t > BAR_V))
            bar_y_next = bar_y_reg - BAR_V;
   end

//////////////////////////////////////////////////
// square ball
//////////////////////////////////////////////////
assign ball_x_l = ball_x_reg;
assign ball_y_t = ball_y_reg;
assign ball_x_r = ball_x_l + BALL_SIZE - 1;
assign ball_y_b = ball_y_t + BALL_SIZE - 1;
assign sq_ball_on = (ball_x_l <= pix_x) && (pix_x <= ball_x_r) &&
                    (ball_y_t <= pix_y) && (pix_y <= ball_y_b);
assign rom_addr = pix_y[2:0] - ball_y_t[2:0];
assign rom_col  = pix_x[2:0] - ball_x_l[2:0];
assign rom_bit = rom_data[rom_col];
assign rd_ball_on = sq_ball_on & rom_bit;
assign ball_rgb = 3'b000; // red

//////////////////////////////////////////////////
// new ball position and velocity
//////////////////////////////////////////////////
assign ball_x_next = (refr_tick) ? ball_x_reg + x_delta_reg :
                                   ball_x_reg;
assign ball_y_next = (refr_tick) ? ball_y_reg + y_delta_reg :
                                   ball_y_reg;
/*
always @(*)
   begin
   x_delta_next = x_delta_reg;
   y_delta_next = y_delta_reg;

   if (ball_y_t < 1) y_delta_next           = BALL_V_P; else
   if (ball_y_b > (MAX_Y - 1)) y_delta_next = BALL_V_N; else
   if (ball_x_l <= WALL_X_R) x_delta_next   = BALL_V_P; else
   if ((BAR_X_L <= ball_x_r) && (ball_x_r <= BAR_X_R) &&
       (bar_y_t <= ball_y_b) && (ball_y_t <= bar_y_b))
      x_delta_next = BALL_V_N;
   end
*/

//Receiving the speed value from XADC 
always @(*)
   begin
   x_delta_next = x_delta_reg;
   y_delta_next = y_delta_reg;

   if (ball_y_t < 1) y_delta_next           = speed; else
   if (ball_y_b > (MAX_Y - 1)) y_delta_next = -speed; else
   if (ball_x_l <= WALL_X_R) x_delta_next   = speed; else
   if ((BAR_X_L <= ball_x_r) && (ball_x_r <= BAR_X_R) &&
       (bar_y_t <= ball_y_b) && (ball_y_t <= bar_y_b))
      x_delta_next = -speed;
   end
 

//////////////////////////////////////////////////
// rgb multiplexing circuit
//////////////////////////////////////////////////
always @(*)
   if (!video_on)
      graph_rgb = 3'b000; else
   if (wall_on)
      graph_rgb = wall_rgb; else
   if (bar_on)
      graph_rgb = bar_rgb; else
   if (rd_ball_on)
      graph_rgb = ball_rgb; 
   else
      graph_rgb = 3'b110; // yellow background

endmodule

