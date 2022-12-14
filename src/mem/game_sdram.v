// jt{{.Core}}_game_sdram.v is automatically generated by JTFRAME
// Do not modify it
// Do not add it to git

`ifndef JTFRAME_COLORW
`define JTFRAME_COLORW 4
`endif

`ifndef JTFRAME_BUTTONS
`define JTFRAME_BUTTONS 2
`endif

module jt{{.Core}}_game_sdram(
    `include "jtframe_common_ports.inc"
    `include "jtframe_mem_ports.inc"
);

/* verilator lint_off WIDTH */
`ifdef JTFRAME_BA1_START
    localparam [24:0] BA1_START=`JTFRAME_BA1_START;
`endif
`ifdef JTFRAME_BA2_START
    localparam [24:0] BA2_START=`JTFRAME_BA2_START;
`endif
`ifdef JTFRAME_BA3_START
    localparam [24:0] BA3_START=`JTFRAME_BA3_START;
`endif
`ifdef JTFRAME_PROM_START
    localparam [24:0] PROM_START=`JTFRAME_PROM_START;
`endif
/* verilator lint_on WIDTH */

{{ range .Params }}
parameter {{.Name}} = {{ if .Value }}{{.Value}}{{else}}`{{.Name}}{{ end}};
{{- end}}

`ifndef JTFRAME_IOCTL_RD
wire ioctl_ram = 0;
`endif
{{range .Ports.Outputs}}wire {{.}};{{end}}
{{ range .SDRAM.Banks}}
{{- range .Buses}}
wire {{ addr_range . }} {{.Name}}_addr;
wire {{ data_range . }} {{.Name}}_data;
wire        {{.Name}}_cs, {{.Name}}_ok;
{{- if .Rw }}
wire        {{.Name}}_we;
wire {{ data_range . }} {{.Name}}_din;
wire [ 1:0] {{.Name}}_dsn;
{{end}}{{end}}
{{- end}}
wire        prom_we, header;
wire [21:0] raw_addr, post_addr;
wire [24:0] pre_addr, dwnld_addr;
wire [ 7:0] post_data;
wire [15:0] raw_data;

jt{{if .Game}}{{.Game}}{{else}}{{.Core}}{{end}}_game u_game(
    .rst        ( rst       ),
    .clk        ( clk       ),
`ifdef JTFRAME_CLK24
    .rst24      ( rst24     ),
    .clk24      ( clk24     ),
`endif
`ifdef JTFRAME_CLK48
    .rst48      ( rst48     ),
    .clk48      ( clk48     ),
`endif
    .pxl2_cen       ( pxl2_cen      ),
    .pxl_cen        ( pxl_cen       ),
    .red            ( red           ),
    .green          ( green         ),
    .blue           ( blue          ),
    .LHBL           ( LHBL          ),
    .LVBL           ( LVBL          ),
    .HS             ( HS            ),
    .VS             ( VS            ),
    // cabinet I/O
    .start_button   ( start_button  ),
    .coin_input     ( coin_input    ),
    .joystick1      ( joystick1     ),
    .joystick2      ( joystick2     ),
    `ifdef JTFRAME_4PLAYERS
    .joystick3      ( joystick3     ),
    .joystick4      ( joystick4     ),
    `endif
`ifdef JTFRAME_ANALOG
    .joyana_l1    ( joyana_l1        ),
    .joyana_l2    ( joyana_l2        ),
    `ifdef JTFRAME_ANALOG_DUAL
        .joyana_r1    ( joyana_r1        ),
        .joyana_r2    ( joyana_r2        ),
    `endif
    `ifdef JTFRAME_4PLAYERS
        .joyana_l3( joyana_l3        ),
        .joyana_l4( joyana_l4        ),
        `ifdef JTFRAME_ANALOG_DUAL
            .joyana_r3( joyana_r3        ),
            .joyana_r4( joyana_r4        ),
        `endif
    `endif
`endif
    // DIP switches
    .status         ( status        ),
    .dipsw          ( dipsw         ),
    .service        ( service       ),
    .tilt           ( tilt          ),
    .dip_pause      ( dip_pause     ),
    .dip_flip       ( dip_flip      ),
    .dip_test       ( dip_test      ),
    .dip_fxlevel    ( dip_fxlevel   ),
    // Sound output
`ifdef JTFRAME_STEREO
    .snd_left       ( snd_left      ),
    .snd_right      ( snd_right     ),
`else
    .snd            ( snd           ),
`endif
    .sample         ( sample        ),
    .game_led       ( game_led      ),
    .enable_psg     ( enable_psg    ),
    .enable_fm      ( enable_fm     ),
    // Memory interface
    {{- range .Ports.Outputs}}
    .{{.}}   ( {{.}} ),
    {{end}}
    {{- range .SDRAM.Banks}}
    {{- range .Buses}}
    .{{.Name}}_addr ( {{.Name}}_addr ),{{ if not .Cs}}
    .{{.Name}}_cs   ( {{.Name}}_cs   ),{{end}}
    .{{.Name}}_ok   ( {{.Name}}_ok   ),
    .{{.Name}}_data ( {{.Name}}_data ),
    {{- if .Rw }}
    .{{.Name}}_we   ( {{.Name}}_we   ),
    .{{.Name}}_dsn  ( {{.Name}}_dsn  ),
    .{{.Name}}_din  ( {{.Name}}_din  ),
    {{- end}}
    {{end}}
    {{- end}}
    // PROM writting
    .ioctl_addr   ( ioctl_addr     ),
    .prog_addr    ( (header | ioctl_ram) ? ioctl_addr[21:0] : raw_addr      ),
    .prog_data    ( header ? ioctl_dout : raw_data[7:0] ),
    .prog_we      ( (header | ioctl_ram) ? ioctl_wr   : prog_we  ),
    .prog_ba      ( prog_ba        ), // prog_ba supplied in case it helps re-mapping addresses
`ifdef JTFRAME_PROM_START
    .prom_we      ( prom_we        ),
`endif
    {{- with .Download.Pre_addr }}
    // SDRAM address mapper during downloading
    .pre_addr     ( pre_addr       ),
    {{- end }}
    {{- with .Download.Post_addr }}
    // SDRAM address mapper during downloading
    .post_addr    ( post_addr      ),
    {{- end }}
    {{- with .Download.Post_data }}
    .post_data    ( post_data      ),
    {{- end }}
`ifdef JTFRAME_HEADER
    .header       ( header         ),
`endif
`ifdef JTFRAME_IOCTL_RD
    .ioctl_ram    ( ioctl_ram      ),
    .ioctl_din    ( ioctl_din      ),
`endif
    // Debug  
`ifdef JTFRAME_DEBUG
    .debug_bus    ( debug_bus      ),
    .debug_view   ( debug_view     ),
`endif
`ifdef JTFRAME_STATUS
    .st_addr      ( st_addr        ),
    .st_dout      ( st_dout        ),
`endif
`ifdef JTFRAME_LF_BUFFER
    .game_vrender( game_vrender  ),
    .game_hdump  ( game_hdump    ),
    .ln_addr     ( ln_addr       ),
    .ln_data     ( ln_data       ),
    .ln_done     ( ln_done       ),
    .ln_hs       ( ln_hs         ),
    .ln_pxl      ( ln_pxl        ),
    .ln_v        ( ln_v          ),
    .ln_we       ( ln_we         ),
`endif
    .gfx_en      ( gfx_en        )
);

assign dwnld_busy = downloading | prom_we; // prom_we is really just for sims
assign dwnld_addr = {{if .Download.Pre_addr }}pre_addr{{else}}ioctl_addr{{end}};
assign prog_addr = {{if .Download.Post_addr }}post_addr{{else}}raw_addr{{end}};
assign prog_data = {{if .Download.Post_data }}{2{post_data}}{{else}}raw_data{{end}};

jtframe_dwnld #(
`ifdef JTFRAME_HEADER
    .HEADER    ( `JTFRAME_HEADER   ),
`endif
`ifdef JTFRAME_BA1_START
    .BA1_START ( BA1_START ),
`endif
`ifdef JTFRAME_BA2_START
    .BA2_START ( BA2_START ),
`endif
`ifdef JTFRAME_BA3_START
    .BA3_START ( BA3_START ),
`endif
`ifdef JTFRAME_PROM_START
    .PROM_START( PROM_START ),
`endif
    .SWAB      ( {{if .Download.Noswab }}0{{else}}1{{end}}         )
) u_dwnld(
    .clk          ( clk            ),
    .downloading  ( downloading & ~ioctl_ram    ),
    .ioctl_addr   ( dwnld_addr     ),
    .ioctl_dout   ( ioctl_dout     ),
    .ioctl_wr     ( ioctl_wr       ),
    .prog_addr    ( raw_addr       ),
    .prog_data    ( raw_data       ),
    .prog_mask    ( prog_mask      ), // active low
    .prog_we      ( prog_we        ),
    .prog_rd      ( prog_rd        ),
    .prog_ba      ( prog_ba        ),
    .prom_we      ( prom_we        ),
    .header       ( header         ),
    .sdram_ack    ( prog_ack       )
);

{{ range $bank, $each:=.SDRAM.Banks }}
{{- if gt (len .Buses) 0 }}
/* verilator tracing_off */
jtframe_{{.MemType}}_{{len .Buses}}slot{{with lt 1 (len .Buses)}}s{{end}} #(
{{- $first := true}}
{{- range $index, $each:=.Buses}}
    {{- if $first}}{{$first = false}}{{else}}, {{end}}
    // {{.Name}}
    {{- if not .Rw }}
    {{- with .Offset }}
    .SLOT{{$index}}_OFFSET({{.}}[21:0]),{{end}}{{end}}
    .SLOT{{$index}}_AW({{ slot_addr_width . }}),
    .SLOT{{$index}}_DW({{ printf "%2d" .Data_width}})
{{- end}}
`ifdef JTFRAME_BA2_LEN
{{- range $index, $each:=.Buses}}
    {{- if not .Rw}}
    ,.SLOT{{$index}}_DOUBLE(1){{ end }}
{{- end}}
`endif
{{- $is_rom := eq .MemType "rom" }}
) u_bank{{$bank}}(
    .rst         ( rst        ),
    .clk         ( clk        ),
    {{ range $index2, $each:=.Buses }}
    {{- if eq .Data_width 32 }}
    .slot{{$index2}}_addr  ( { {{.Name}}_addr, 1'b0 } ),
    {{- else }}
    .slot{{$index2}}_addr  ( {{.Name}}_addr  ),
    {{- end }}
    {{- if .Rw }}
    .slot{{$index2}}_wen   ( {{.Name}}_we    ),
    .slot{{$index2}}_din   ( {{if .Din}}{{.Din}}{{else}}{{.Name}}_din{{end}}   ),
    .slot{{$index2}}_wrmask( {{if .Dsn}}{{.Dsn}}{{else}}{{.Name}}_dsn{{end}}   ),
    {{with .Offset }}.slot{{$index2}}_offset( {{.}}[21:0] ), {{end}}
    {{- else }}
    {{- if not $is_rom }}
    .slot{{$index2}}_clr   ( 1'b0       ), // only 1'b0 supported in mem.yaml
    {{- end }}{{- end}}
    .slot{{$index2}}_dout  ( {{.Name}}_data  ),
    .slot{{$index2}}_cs    ( {{ if .Cs }}{{.Cs}}{{else}}{{.Name}}_cs{{end}}    ),
    .slot{{$index2}}_ok    ( {{.Name}}_ok    ),
    {{end}}
    // SDRAM controller interface
    .sdram_ack   ( ba_ack[{{$bank}}]  ),
    .sdram_rd    ( ba_rd[{{$bank}}]   ),
    .sdram_addr  ( ba{{$bank}}_addr   ),
{{- if not $is_rom }}
    .sdram_wr    ( ba_wr[{{$bank}}]   ),
    .sdram_wrmask( ba{{$bank}}_dsn    ),
    .data_write  ( ba{{$bank}}_din    ),{{end}}
    .data_dst    ( ba_dst[{{$bank}}]  ),
    .data_rdy    ( ba_rdy[{{$bank}}]  ),
    .data_read   ( data_read  )
);

{{- if $is_rom }}
assign ba_wr[{{$bank}}] = 0;
assign ba{{$bank}}_din  = 0;
assign ba{{$bank}}_dsn  = 3;
{{- end}}{{- end }}{{end}}

{{ range $index, $each:=.Unused }}
{{- with . -}}
assign ba{{$index}}_addr = 0;
assign ba_rd[{{$index}}] = 0;
assign ba_wr[{{$index}}] = 0;
assign ba{{$index}}_dsn  = 3;
assign ba{{$index}}_din  = 0;
{{ end -}}
{{ end -}}

{{ range $cnt, $bus:=.BRAM -}}
// Dual port BRAM for {{$bus.Name}} and {{$bus.Dual_port.Name}}
{{- if $bus.Dual_port.Name }}
jtframe_dual_ram{{ if eq $bus.Data_width 16 }}16{{end}} #(
    .aw({{$bus.Addr_width}}){{ if $bus.Sim_file }},
    {{ if eq $bus.Data_width 16 }}.simfile_lo("{{$bus.Name}}_lo.bin"),
    .simfile_hi("{{$bus.Name}}_hi.bin"){{else}}.simfile("{{$bus.Name}}.bin"){{end}}{{end}}
) u_bram_{{$bus.Name}}(
    // Port 0 - {{$bus.Name}}
    .clk0   ( clk ),
    .addr0  ( {{$bus.Name}}_addr ),
    {{ if $bus.Rw }}
    .data0  ( {{$bus.Name}}_din  ),
    .we0    ( {2{ {{$bus.Cs}} }} & ~{{$bus.Name}}.dsn ), {{ else }}
    .data0  ( {{$bus.Data_width}}'h0 ),
    .we0    ( 2'd0 ),{{end}}
    .q0     ( {{$bus.Name}}_dout ),
    // Port 1 - {{$bus.Dual_port.Name}}
    .clk1   ( clk ),
    .data1  ( {{$bus.Dual_port.Name}}_dout ),
    .addr1  ( {{$bus.Dual_port.Name}}_addr{{ addr_range $bus }}),
    {{ if $bus.Dual_port.Rw }}
    .we1    ( {2{ {{$bus.Dual_port.Cs}} }} & ~{{$bus.Dual_port.Name}}_dsn ), {{ else }}
    .we1    ( 2'd0 ),{{end}}
    .q1     ( {{$bus.Name}}2{{$bus.Dual_port.Name}}_data )
);
{{ end -}}
{{ end }}

endmodule
