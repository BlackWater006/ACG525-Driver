module Seg7_595_OneDigit #(
    parameter CLK_DIV = 200
)(
    input i_clk,
    input [6:0] i_sevseg,
    output reg o_dio,
    output reg o_rclk,
    output reg o_sclk
);

    reg [31:0] r_div = 32'd0;
    reg [5:0] r_cnt = 6'd0;
    reg [15:0] r_data = 16'd0;

    // ACG525 format:
    // data[15]    = dot, 1 = off
    // data[14:8]  = seg[6:0]
    // data[7:0]   = sel[7:0]
    // sel = 0000_0001 chọn LED đầu tiên
    wire [15:0] w_frame = {1'b1, i_sevseg, 8'b0000_0001};

    initial begin
        o_dio  = 1'b0;
        o_rclk = 1'b0;
        o_sclk = 1'b0;
    end

    always @(posedge i_clk) begin
        if (r_div < CLK_DIV - 1) begin
            r_div <= r_div + 1'b1;
        end else begin
            r_div <= 32'd0;

            case (r_cnt)

                6'd0: begin
                    r_data <= w_frame;
                    o_rclk <= 1'b0;
                    o_sclk <= 1'b0;
                    o_dio  <= w_frame[15];
                    r_cnt  <= 6'd1;
                end

                6'd1: begin o_sclk <= 1'b1; r_cnt <= 6'd2; end
                6'd2: begin o_sclk <= 1'b0; o_dio <= r_data[14]; r_cnt <= 6'd3; end
                6'd3: begin o_sclk <= 1'b1; r_cnt <= 6'd4; end
                6'd4: begin o_sclk <= 1'b0; o_dio <= r_data[13]; r_cnt <= 6'd5; end
                6'd5: begin o_sclk <= 1'b1; r_cnt <= 6'd6; end
                6'd6: begin o_sclk <= 1'b0; o_dio <= r_data[12]; r_cnt <= 6'd7; end
                6'd7: begin o_sclk <= 1'b1; r_cnt <= 6'd8; end
                6'd8: begin o_sclk <= 1'b0; o_dio <= r_data[11]; r_cnt <= 6'd9; end
                6'd9: begin o_sclk <= 1'b1; r_cnt <= 6'd10; end
                6'd10: begin o_sclk <= 1'b0; o_dio <= r_data[10]; r_cnt <= 6'd11; end
                6'd11: begin o_sclk <= 1'b1; r_cnt <= 6'd12; end
                6'd12: begin o_sclk <= 1'b0; o_dio <= r_data[9]; r_cnt <= 6'd13; end
                6'd13: begin o_sclk <= 1'b1; r_cnt <= 6'd14; end
                6'd14: begin o_sclk <= 1'b0; o_dio <= r_data[8]; r_cnt <= 6'd15; end
                6'd15: begin o_sclk <= 1'b1; r_cnt <= 6'd16; end
                6'd16: begin o_sclk <= 1'b0; o_dio <= r_data[7]; r_cnt <= 6'd17; end
                6'd17: begin o_sclk <= 1'b1; r_cnt <= 6'd18; end
                6'd18: begin o_sclk <= 1'b0; o_dio <= r_data[6]; r_cnt <= 6'd19; end
                6'd19: begin o_sclk <= 1'b1; r_cnt <= 6'd20; end
                6'd20: begin o_sclk <= 1'b0; o_dio <= r_data[5]; r_cnt <= 6'd21; end
                6'd21: begin o_sclk <= 1'b1; r_cnt <= 6'd22; end
                6'd22: begin o_sclk <= 1'b0; o_dio <= r_data[4]; r_cnt <= 6'd23; end
                6'd23: begin o_sclk <= 1'b1; r_cnt <= 6'd24; end
                6'd24: begin o_sclk <= 1'b0; o_dio <= r_data[3]; r_cnt <= 6'd25; end
                6'd25: begin o_sclk <= 1'b1; r_cnt <= 6'd26; end
                6'd26: begin o_sclk <= 1'b0; o_dio <= r_data[2]; r_cnt <= 6'd27; end
                6'd27: begin o_sclk <= 1'b1; r_cnt <= 6'd28; end
                6'd28: begin o_sclk <= 1'b0; o_dio <= r_data[1]; r_cnt <= 6'd29; end
                6'd29: begin o_sclk <= 1'b1; r_cnt <= 6'd30; end
                6'd30: begin o_sclk <= 1'b0; o_dio <= r_data[0]; r_cnt <= 6'd31; end
                6'd31: begin o_sclk <= 1'b1; r_cnt <= 6'd32; end

                6'd32: begin
                    o_sclk <= 1'b0;
                    o_rclk <= 1'b1;
                    r_cnt <= 6'd33;
                end

                6'd33: begin
                    o_rclk <= 1'b0;
                    r_cnt <= 6'd0;
                end

                default: begin
                    r_cnt <= 6'd0;
                end

            endcase
        end
    end

endmodule