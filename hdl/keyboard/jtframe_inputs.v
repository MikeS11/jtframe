/*  This file is part of JT_FRAME.
    JTFRAME program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTFRAME program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTFRAME.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 10-5-2021 */

module jtframe_inputs(
    input             rst,
    input             clk,
    input             vs,
    input             LHBL,

    input             dip_flip,
    input             autofire0,

    output reg        soft_rst,
    output reg        game_pause,

    input      [15:0] board_joy1, board_joy2, board_joy3, board_joy4,
    input       [3:0] board_coin, board_start,

    input       [9:0] key_joy1, key_joy2, key_joy3,
    input       [3:0] key_start, key_coin,
    input             key_service,
    input             key_test,
    input             key_tilt,

    input             key_pause,
    input             osd_pause,
    input             key_reset,
    input             rot_control,

    output reg [9:0]  game_joy1, game_joy2, game_joy3, game_joy4,
    output reg [3:0]  game_coin, game_start,
    output reg        game_service,
    output            game_test,
    output reg        game_tilt,
    input             lock, // disable joystick inputs

    // Mouse & Paddle
    input signed [8:0] bd_mouse_dx, bd_mouse_dy,
    input        [7:0] bd_mouse_f,
    input              bd_mouse_st,
    input              bd_mouse_idx,

    input       [ 7:0] board_paddle_1, board_paddle_2,
    input       [ 1:0] sensty,
    input       [ 8:0] spinner_1,      spinner_2,

    output      [15:0] mouse_1p, mouse_2p,
    output      [ 7:0] game_paddle_1, game_paddle_2,
    output      [ 1:0] dial_x, dial_y,

    input       [ 7:0] debug_bus,
    // For simulation only
    input              downloading
);

parameter BUTTONS    = 2,
          ACTIVE_LOW = 1;

reg  [15:0] joy1_sync, joy2_sync, joy3_sync, joy4_sync;
wire [ 3:0] joy4way1p, joy4way2p, joy4way3p, joy4way4p;
wire [ 2:0] mouse_but_1p, mouse_but_2p;

`ifdef JTFRAME_SUPPORT_4WAY
    wire en4way = core_mod[1];
`else
    wire en4way = 0;
`endif

// This one passes unfiltered
assign game_paddle_2 = board_paddle_2;

always @(posedge clk) begin
    joy1_sync <= { board_joy1[15:4], joy4way1p[3:0] };
    joy2_sync <= { board_joy2[15:4], joy4way2p[3:0] };
end

`ifdef JTFRAME_4PLAYERS
    always @(posedge clk) begin
        joy3_sync <= { board_joy3[15:4], joy4way3p[3:0] };
        joy4_sync <= { board_joy4[15:4], joy4way4p[3:0] };
    end
`else
    initial begin
        joy3_sync = 0;
        joy4_sync = 0;
    end
`endif

jtframe_4wayjoy u_4way_1p(
    .rst        ( rst               ),
    .clk        ( clk               ),
    .enable     ( en4way            ),
    .joy8way    ( board_joy1[3:0]   ),
    .joy4way    ( joy4way1p         )
);

jtframe_4wayjoy u_4way_2p(
    .rst        ( rst               ),
    .clk        ( clk               ),
    .enable     ( en4way            ),
    .joy8way    ( board_joy2[3:0]   ),
    .joy4way    ( joy4way2p         )
);

jtframe_4wayjoy u_4way_3p(
    .rst        ( rst               ),
    .clk        ( clk               ),
    .enable     ( en4way            ),
    .joy8way    ( board_joy3[3:0]   ),
    .joy4way    ( joy4way3p         )
);

jtframe_4wayjoy u_4way_4p(
    .rst        ( rst               ),
    .clk        ( clk               ),
    .enable     ( en4way            ),
    .joy8way    ( board_joy4[3:0]   ),
    .joy4way    ( joy4way4p         )
);

localparam START_BIT  = 6+(BUTTONS-2);
localparam COIN_BIT   = 7+(BUTTONS-2);
localparam PAUSE_BIT  = 8+(BUTTONS-2);

reg        last_pause, last_osd_pause, last_joypause, last_reset;
wire       joy_pause;
wire [3:0] joy_start, joy_coin;
wire       vbl_in, vbl_out;
reg        autofire, vsl, service_l, pause_frame;
reg  [2:0] firecnt;

`ifdef POCKET   // The Pocket only uses the small buttons at the front for these functions
    assign joy_pause = board_coin[0] & board_joy1[4];
    assign joy_start = 0;
    assign joy_coin  = 0;
`else
    assign joy_pause = joy1_sync[PAUSE_BIT] | joy2_sync[PAUSE_BIT] | joy3_sync[PAUSE_BIT] | joy4_sync[PAUSE_BIT];
    assign joy_start = { joy4_sync[START_BIT], joy3_sync[START_BIT], joy2_sync[START_BIT], joy1_sync[START_BIT]};
    assign joy_coin  = { joy4_sync[COIN_BIT] , joy3_sync[COIN_BIT] , joy2_sync[COIN_BIT] , joy1_sync[COIN_BIT]};
`endif
assign vbl_in    = vs && !vsl;
assign vbl_out   =!vs &&  vsl;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        firecnt  <= 0;
        autofire <= 1;
    end else begin
        vsl <= vs;
        if( vbl_in ) firecnt <= firecnt+1'd1;
        autofire <= !autofire0 || firecnt>5;
    end
end

function [9:0] apply_rotation;
    input [9:0] joy_in;
    input       rot;
    input       flip;
    input       autofire;
    begin
    apply_rotation = {10{ACTIVE_LOW[0]}} ^
        (!rot ? joy_in & { 5'h1f, autofire, 4'hf } :
        flip ?
         { joy_in[9:5],joy_in[4]&autofire, joy_in[1], joy_in[0], joy_in[2], joy_in[3] } :
         { joy_in[9:5],joy_in[4]&autofire, joy_in[0], joy_in[1], joy_in[3], joy_in[2] });
    end
endfunction

function [9:0] reorder;
    input [9:0] joy_in;
    begin
        reorder = joy_in; // default order up, down, left, right
`ifdef JTFRAME_JOY_LRUD reorder[3:0]={joy_in[1:0],joy_in[3:2]}; `endif
`ifdef JTFRAME_JOY_RLDU reorder[3:0]={joy_in[0], joy_in[1], joy_in[2], joy_in[3]}; `endif
`ifdef JTFRAME_JOY_DURL reorder[3:0]={joy_in[2], joy_in[3], joy_in[0], joy_in[1]}; `endif
`ifdef JTFRAME_JOY_UDRL reorder[3:0]={joy_in[3:2], joy_in[0], joy_in[1]}; `endif
    end
endfunction

`ifdef SIM_INPUTS
    reg [15:0] sim_inputs[0:16383];
    integer frame_cnt;
    initial begin : read_sim_inputs
        integer c;
        for( c=0; c<16384; c=c+1 ) sim_inputs[c] = 8'h0;
        $display("INFO: input simulation enabled");
        $readmemh( "sim_inputs.hex", sim_inputs );
    end
    always @(negedge vs, posedge rst) begin
        if( rst )
            frame_cnt <= 0;
        else frame_cnt <= frame_cnt+1;
    end
    assign game_test = sim_inputs[frame_cnt][11];
`else
    assign game_test = key_test;
`endif

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        game_pause   <= 0;
        game_service <= 1'b0 ^ ACTIVE_LOW[0];
        soft_rst     <= 0;
        service_l    <= 0;
    end else begin
        service_l      <= game_service;
        last_pause     <= key_pause;
        last_osd_pause <= osd_pause;
        last_reset     <= key_reset;
        last_joypause  <= joy_pause; // joy is active low!

        // joystick, coin, start and service inputs are inverted
        // as indicated in the instance parameter

`ifdef SIM_INPUTS
        game_coin  <= {4{ACTIVE_LOW[0]}} ^ { 2'b0, sim_inputs[frame_cnt][1:0] };
        game_start <= {4{ACTIVE_LOW[0]}} ^ { 2'b0, sim_inputs[frame_cnt][3:2] };
        game_joy1  <= reorder({10{ACTIVE_LOW[0]}} ^ { 3'd0, sim_inputs[frame_cnt][10:4] });
`else
        game_coin  <= {4{ACTIVE_LOW[0]}} ^ ( joy_coin | key_coin  | board_coin  );
        game_start <= {4{ACTIVE_LOW[0]}} ^ ( joy_start| key_start | board_start );
        game_joy1  <= reorder(apply_rotation( joy1_sync | key_joy1 | { mouse_but_1p, 4'd0}, rot_control, ~dip_flip, autofire ));
`endif
        game_joy2 <= reorder(apply_rotation(joy2_sync | key_joy2 | { mouse_but_2p, 4'd0}, rot_control, ~dip_flip, autofire ));
        game_joy3 <= reorder(apply_rotation(joy3_sync | key_joy3, rot_control, ~dip_flip, autofire ));
        game_joy4 <= reorder(apply_rotation(joy4_sync           , rot_control, ~dip_flip, autofire ));

        soft_rst <= key_reset && !last_reset;

        // state variables:
`ifndef DIP_PAUSE // Forces pause during simulation
        if( downloading )
            game_pause<=0;
        else begin// toggle
            if( (key_pause && !last_pause) || (joy_pause && !last_joypause) )
                game_pause   <= ~game_pause;
            if (last_osd_pause ^ osd_pause) game_pause <= osd_pause;
            if( game_pause ) begin
                if( game_service && !service_l ) begin
                    pause_frame <= 1;
                    game_pause <= 0;
                end
            end
            if( vbl_out && pause_frame ) begin
                game_pause <= ~game_pause;
                if(!game_pause) pause_frame <= 0;
            end
        end
`else
        game_pause <= 1'b1;
`endif
        game_service <= key_service ^ ACTIVE_LOW[0];
        game_tilt    <= key_tilt    ^ ACTIVE_LOW[0];

        // Disable inputs for locked cores
        if( lock ) begin
            game_joy1    <= {10{ACTIVE_LOW[0]}};
            game_joy2    <= {10{ACTIVE_LOW[0]}};
            game_joy3    <= {10{ACTIVE_LOW[0]}};
            game_joy4    <= {10{ACTIVE_LOW[0]}};
            game_start   <= {4{ACTIVE_LOW[0]}};
            game_coin    <= {4{ACTIVE_LOW[0]}};
            game_pause   <= 0;
            game_service <= ACTIVE_LOW[0];
        end
    end
end

// Dial emulation
jtframe_dial u_dial(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .LHBL       ( LHBL          ),
    .joystick1  ( game_joy1     ),
    .joystick2  ( game_joy2     ),
    .spinner_1  ( spinner_1     ),
    .spinner_2  ( spinner_2     ),
    .sensty     ( sensty        ),
    .dial_x     ( dial_x        ),
    .dial_y     ( dial_y        )
);

// Paddle emulation using the mouse
jtframe_paddle u_paddle(
    .rst        ( rst            ),
    .clk        ( clk            ),
    .hw_paddle  ( board_paddle_1 ),
    .mouse_dx   ( bd_mouse_dx    ),
    .mouse_st   ( bd_mouse_st    ),
    .paddle     ( game_paddle_1  )
);

jtframe_mouse u_mouse(
    .rst        ( rst          ),
    .clk        ( clk          ),
    .lock       ( lock         ),

    // Mouse emulation
    .joy1       ( game_joy1[3:0] ^ {4{ACTIVE_LOW[0]}} ),
    .joy2       ( game_joy2[3:0] ^ {4{ACTIVE_LOW[0]}} ),

    // Actual mouse input
    .mouse_dx   ( bd_mouse_dx  ),
    .mouse_dy   ( bd_mouse_dy  ),
    .mouse_f    ( bd_mouse_f   ),
    .mouse_st   ( bd_mouse_st  ),
    .mouse_idx  ( bd_mouse_idx ),
    .mouse_1p   ( mouse_1p     ),
    .mouse_2p   ( mouse_2p     ),
    .but_1p     ( mouse_but_1p ),
    .but_2p     ( mouse_but_2p )
);

endmodule