module StateMachineGame #(
    parameter CLK_PER_SEC = 50000000,
    parameter GAME_LIMIT = 7,
    parameter LED_ACTIVE_LOW = 0
)(
    input i_clk,
    input [3:0] i_sw,
    output [3:0] o_led,
    output [3:0] o_display_num,
    output [1:0] o_status
);

    localparam START       = 3'd0;
    localparam PATTERN_OFF = 3'd1;
    localparam SHOW_STEP   = 3'd2;
    localparam WAIT_PLAYER = 3'd3;
    localparam LOSE        = 3'd4;
    localparam WIN         = 3'd5;

    localparam SHOW_TIME = CLK_PER_SEC / 2;
    localparam OFF_TIME  = CLK_PER_SEC / 5;

    reg [2:0] r_state = START;
    reg [31:0] r_timer = 32'd0;

    reg [3:0] r_score = 4'd0;
    reg [3:0] r_step_index = 4'd0;

    reg [1:0] r_pattern [0:15];

    reg [3:0] r_sw_prev = 4'b1111;
    reg r_dv = 1'b0;
    reg [1:0] r_sw_id = 2'd0;

    wire [21:0] w_lfsr;

    integer i;

    function [1:0] map_to_3_buttons;
        input [1:0] x;
        begin
            case (x)
                2'b00: map_to_3_buttons = 2'd0;
                2'b01: map_to_3_buttons = 2'd1;
                2'b10: map_to_3_buttons = 2'd2;
                default: map_to_3_buttons = 2'd0;
            endcase
        end
    endfunction

    always @(posedge i_clk) begin
        // i_sw[3] là reset ngoài, active-low
        if (i_sw[1] && i_sw[2]) begin
            r_state <= START;
            r_timer <= 32'd0;
            r_score <= 4'd0;
            r_step_index <= 4'd0;
        end else begin
            case (r_state)

                START: begin
                    r_score <= 4'd0;
                    r_step_index <= 4'd0;
                    r_timer <= 32'd0;

                    for (i = 0; i < GAME_LIMIT + 1; i = i + 1) begin
                        r_pattern[i] <= map_to_3_buttons({w_lfsr[i*2], w_lfsr[i*2 + 1]});
                    end

                    r_state <= PATTERN_OFF;
                end

                PATTERN_OFF: begin
                    if (r_timer >= OFF_TIME - 1) begin
                        r_timer <= 32'd0;
                        r_state <= SHOW_STEP;
                    end else begin
                        r_timer <= r_timer + 1'b1;
                    end
                end

                SHOW_STEP: begin
                    if (r_timer >= SHOW_TIME - 1) begin
                        r_timer <= 32'd0;

                        if (r_step_index == r_score) begin
                            r_step_index <= 4'd0;
                            r_state <= WAIT_PLAYER;
                        end else begin
                            r_step_index <= r_step_index + 1'b1;
                            r_state <= PATTERN_OFF;
                        end
                    end else begin
                        r_timer <= r_timer + 1'b1;
                    end
                end

                WAIT_PLAYER: begin
                    if (r_dv) begin
                        if (r_sw_id != r_pattern[r_step_index]) begin
                            r_state <= LOSE;
                        end else begin
                            if (r_step_index == r_score) begin
                                if (r_score == GAME_LIMIT) begin
                                    r_state <= WIN;
                                end else begin
                                    r_score <= r_score + 1'b1;
                                    r_step_index <= 4'd0;
                                    r_timer <= 32'd0;
                                    r_state <= PATTERN_OFF;
                                end
                            end else begin
                                r_step_index <= r_step_index + 1'b1;
                            end
                        end
                    end
                end

                LOSE: begin
                    r_state <= LOSE;
                end

                WIN: begin
                    r_state <= WIN;
                end

                default: begin
                    r_state <= START;
                end

            endcase
        end
    end

    always @(posedge i_clk) begin
        if (!i_sw[3]) begin
            r_sw_prev <= 4'b1111;
            r_dv <= 1'b0;
            r_sw_id <= 2'd0;
        end else begin
            r_sw_prev <= i_sw;
            r_dv <= 1'b0;

            if (r_state == WAIT_PLAYER) begin
                if (r_sw_prev[0] && !i_sw[0]) begin
                    r_dv <= 1'b1;
                    r_sw_id <= 2'd0;
                end else if (r_sw_prev[1] && !i_sw[1]) begin
                    r_dv <= 1'b1;
                    r_sw_id <= 2'd1;
                end else if (r_sw_prev[2] && !i_sw[2]) begin
                    r_dv <= 1'b1;
                    r_sw_id <= 2'd2;
                end
            end
        end
    end

    Lfsr22 lfsr_inst(
        .i_clk(i_clk),
        .o_data(w_lfsr)
    );

    wire [3:0] w_led_on;

    assign w_led_on[0] = (r_state == SHOW_STEP && r_pattern[r_step_index] == 2'd0) ? 1'b1 : 1'b0;
    assign w_led_on[1] = (r_state == SHOW_STEP && r_pattern[r_step_index] == 2'd1) ? 1'b1 : 1'b0;
    assign w_led_on[2] = (r_state == SHOW_STEP && r_pattern[r_step_index] == 2'd2) ? 1'b1 : 1'b0;
    assign w_led_on[3] = (r_state == LOSE || r_state == WIN) ? 1'b1 : 1'b0;

    assign o_led = LED_ACTIVE_LOW ? ~w_led_on : w_led_on;

    assign o_display_num =
        (r_state == LOSE)      ? 4'hF :
        (r_state == WIN)       ? 4'hA :
        (r_state == SHOW_STEP) ? ({2'b00, r_pattern[r_step_index]} + 4'd1) :
                                 r_score;

    // OLED status:
    // 0 = bình thường
    // 1 = LOSE
    // 2 = WIN
    assign o_status =
        (r_state == LOSE) ? 2'd1 :
        (r_state == WIN)  ? 2'd2 :
                            2'd0;

endmodule