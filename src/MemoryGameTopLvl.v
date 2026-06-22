module MemoryGameTopLvl(
    input i_clk,
    input [3:0] i_sw,

    output [3:0] o_led,

    output o_seg7_dio,
    output o_seg7_rclk,
    output o_seg7_sclk,

    output o_oled_scl,
    inout  io_oled_sda
);

    localparam GAME_LIMIT = 7;
    localparam CLK_PER_SEC = 50000000;
    localparam DEBOUNCE_LIMIT = 1000000;

    wire [3:0] w_sw;
    wire [3:0] w_display_num;
    wire [1:0] w_status;

    DebounceFilter #(.DEBOUNCE_LIMIT(DEBOUNCE_LIMIT)) debounce_sw0(
        .i_clk(i_clk),
        .i_bouncy(i_sw[0]),
        .o_debounced(w_sw[0])
    );

    DebounceFilter #(.DEBOUNCE_LIMIT(DEBOUNCE_LIMIT)) debounce_sw1(
        .i_clk(i_clk),
        .i_bouncy(i_sw[1]),
        .o_debounced(w_sw[1])
    );

    DebounceFilter #(.DEBOUNCE_LIMIT(DEBOUNCE_LIMIT)) debounce_sw2(
        .i_clk(i_clk),
        .i_bouncy(i_sw[2]),
        .o_debounced(w_sw[2])
    );

    DebounceFilter #(.DEBOUNCE_LIMIT(DEBOUNCE_LIMIT)) debounce_sw3(
        .i_clk(i_clk),
        .i_bouncy(i_sw[3]),
        .o_debounced(w_sw[3])
    );

    StateMachineGame #(
        .CLK_PER_SEC(CLK_PER_SEC),
        .GAME_LIMIT(GAME_LIMIT),
        .LED_ACTIVE_LOW(0)
    ) game_inst(
        .i_clk(i_clk),
        .i_sw(w_sw),
        .o_led(o_led),
        .o_display_num(w_display_num),
        .o_status(w_status)
    );

    Seg7_595_WordDisplay seg7_inst(
        .i_clk(i_clk),
        .i_num(w_display_num),
        .i_status(w_status),
        .o_dio(o_seg7_dio),
        .o_rclk(o_seg7_rclk),
        .o_sclk(o_seg7_sclk)
    );

    OLED_Status_SSD1306 oled_inst(
        .i_clk(i_clk),
        .i_status(w_status),
        .o_scl(o_oled_scl),
        .io_sda(io_oled_sda)
    );

endmodule