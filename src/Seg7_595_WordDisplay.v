module Seg7_595_WordDisplay #(
    parameter CLK_DIV = 50
)(
    input i_clk,
    input [3:0] i_num,
    input [1:0] i_status,

    output reg o_dio,
    output reg o_rclk,
    output reg o_sclk
);

    // i_status:
    // 0 = đang chơi, hiện số
    // 1 = thua, hiện LOSER
    // 2 = thắng, hiện WINER

    reg [31:0] r_div = 32'd0;
    reg [2:0] r_state = 3'd0;
    reg [4:0] r_bit_count = 5'd0;
    reg [15:0] r_shift = 16'd0;

    reg [2:0] r_digit = 3'd0;
    reg [6:0] r_seg;
    reg [7:0] r_sel;

    wire [15:0] w_frame;

    // ACG525 frame:
    // bit 15   = DP, 1 = tắt chấm
    // bit 14:8 = segment gfedcba, active-low
    // bit 7:0  = chọn digit
    assign w_frame = {1'b1, r_seg, r_sel};

    initial begin
        o_dio  = 1'b0;
        o_rclk = 1'b0;
        o_sclk = 1'b0;
    end

    function [6:0] seg_num;
        input [3:0] num;
        begin
            case (num)
                4'h0: seg_num = 7'b1000000;
                4'h1: seg_num = 7'b1111001;
                4'h2: seg_num = 7'b0100100;
                4'h3: seg_num = 7'b0110000;
                4'h4: seg_num = 7'b0011001;
                4'h5: seg_num = 7'b0010010;
                4'h6: seg_num = 7'b0000010;
                4'h7: seg_num = 7'b1111000;
                4'h8: seg_num = 7'b0000000;
                4'h9: seg_num = 7'b0010000;
                default: seg_num = 7'b1111111;
            endcase
        end
    endfunction

    function [6:0] seg_char;
        input [7:0] ch;
        begin
            case (ch)
                "L": seg_char = 7'b1000111;
                "O": seg_char = 7'b1000000;
                "S": seg_char = 7'b0010010;
                "E": seg_char = 7'b0000110;
                "R": seg_char = 7'b0101111;

                // LED 7 đoạn không hiện W chuẩn, W sẽ gần giống U
                "W": seg_char = 7'b1000001;
                "I": seg_char = 7'b1111001;
                "N": seg_char = 7'b0101011;

                default: seg_char = 7'b1111111;
            endcase
        end
    endfunction

    // Map chữ theo digit vật lý để hiện từ trái qua phải.
    // Nếu board của bạn hiện 8 digit theo thứ tự:
    // left -> right = digit 7,6,5,4,3,2,1,0
    function [7:0] get_char_left_to_right;
        input [1:0] status;
        input [2:0] digit;
        begin
            if (status == 2'd1) begin
                // LOSER từ trái qua phải
                case (digit)
                    3'd6: get_char_left_to_right = "L";
                    3'd5: get_char_left_to_right = "O";
                    3'd4: get_char_left_to_right = "S";
                    3'd3: get_char_left_to_right = "E";
                    3'd2: get_char_left_to_right = "R";
                    default: get_char_left_to_right = " ";
                endcase
            end else if (status == 2'd2) begin
                // WINER từ trái qua phải
                case (digit)
                    3'd6: get_char_left_to_right = "W";
                    3'd5: get_char_left_to_right = "I";
                    3'd4: get_char_left_to_right = "N";
                    3'd3: get_char_left_to_right = "E";
                    3'd2: get_char_left_to_right = "R";
                    default: get_char_left_to_right = " ";
                endcase
            end else begin
                get_char_left_to_right = " ";
            end
        end
    endfunction

    always @(*) begin
        case (r_digit)
            3'd0: r_sel = 8'b00000001;
            3'd1: r_sel = 8'b00000010;
            3'd2: r_sel = 8'b00000100;
            3'd3: r_sel = 8'b00001000;
            3'd4: r_sel = 8'b00010000;
            3'd5: r_sel = 8'b00100000;
            3'd6: r_sel = 8'b01000000;
            3'd7: r_sel = 8'b10000000;
            default: r_sel = 8'b00000001;
        endcase

        if (i_status == 2'd0) begin
            // Đang chơi: hiện số ở digit phải nhất
            if (r_digit == 3'd0)
                r_seg = seg_num(i_num);
            else
                r_seg = 7'b1111111;
        end else begin
            // Thắng/thua: hiện WINER / LOSER
            r_seg = seg_char(get_char_left_to_right(i_status, r_digit));
        end
    end

    always @(posedge i_clk) begin
        if (r_div < CLK_DIV - 1) begin
            r_div <= r_div + 1'b1;
        end else begin
            r_div <= 32'd0;

            case (r_state)

                3'd0: begin
                    r_shift <= w_frame;
                    r_bit_count <= 5'd0;
                    o_rclk <= 1'b0;
                    o_sclk <= 1'b0;
                    r_state <= 3'd1;
                end

                3'd1: begin
                    o_sclk <= 1'b0;
                    o_rclk <= 1'b0;
                    o_dio <= r_shift[15];
                    r_state <= 3'd2;
                end

                3'd2: begin
                    o_sclk <= 1'b1;
                    r_shift <= {r_shift[14:0], 1'b0};

                    if (r_bit_count == 5'd15) begin
                        r_bit_count <= 5'd0;
                        r_state <= 3'd3;
                    end else begin
                        r_bit_count <= r_bit_count + 1'b1;
                        r_state <= 3'd1;
                    end
                end

                3'd3: begin
                    o_sclk <= 1'b0;
                    o_rclk <= 1'b1;
                    r_state <= 3'd4;
                end

                3'd4: begin
                    o_rclk <= 1'b0;

                    if (r_digit == 3'd7)
                        r_digit <= 3'd0;
                    else
                        r_digit <= r_digit + 1'b1;

                    r_state <= 3'd0;
                end

                default: begin
                    r_state <= 3'd0;
                end

            endcase
        end
    end

endmodule