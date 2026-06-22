module OLED_Status_SSD1306 #(
    parameter I2C_DIV = 250
)(
    input i_clk,
    input [1:0] i_status,
    output reg o_scl,
    inout io_sda
);

    localparam OLED_ADDR = 7'h3C;

    reg sda_drive_low;
    assign io_sda = sda_drive_low ? 1'b0 : 1'bz;

    reg [15:0] r_div = 16'd0;
    wire tick = (r_div == I2C_DIV - 1);

    always @(posedge i_clk) begin
        if (r_div == I2C_DIV - 1)
            r_div <= 16'd0;
        else
            r_div <= r_div + 1'b1;
    end

    reg [7:0] init_rom [0:30];
    reg [7:0] clear_addr_rom [0:5];
    reg [7:0] text_addr_rom [0:5];

    initial begin
        init_rom[0]  = 8'hAE;
        init_rom[1]  = 8'hD5;
        init_rom[2]  = 8'h80;
        init_rom[3]  = 8'hA8;
        init_rom[4]  = 8'h3F;
        init_rom[5]  = 8'hD3;
        init_rom[6]  = 8'h00;
        init_rom[7]  = 8'h40;
        init_rom[8]  = 8'h8D;
        init_rom[9]  = 8'h14;
        init_rom[10] = 8'h20;
        init_rom[11] = 8'h00;
        init_rom[12] = 8'hA1;
        init_rom[13] = 8'hC8;
        init_rom[14] = 8'hDA;
        init_rom[15] = 8'h12;
        init_rom[16] = 8'h81;
        init_rom[17] = 8'hCF;
        init_rom[18] = 8'hD9;
        init_rom[19] = 8'hF1;
        init_rom[20] = 8'hDB;
        init_rom[21] = 8'h40;
        init_rom[22] = 8'hA4;
        init_rom[23] = 8'hA6;
        init_rom[24] = 8'hAF;
        init_rom[25] = 8'h21;
        init_rom[26] = 8'h00;
        init_rom[27] = 8'h7F;
        init_rom[28] = 8'h22;
        init_rom[29] = 8'h00;
        init_rom[30] = 8'h07;

        // Set full screen address
        clear_addr_rom[0] = 8'h21;
        clear_addr_rom[1] = 8'h00;
        clear_addr_rom[2] = 8'h7F;
        clear_addr_rom[3] = 8'h22;
        clear_addr_rom[4] = 8'h00;
        clear_addr_rom[5] = 8'h07;

        // Set text position: column 40, page 3
        text_addr_rom[0] = 8'h21;
        text_addr_rom[1] = 8'h28;
        text_addr_rom[2] = 8'h7F;
        text_addr_rom[3] = 8'h22;
        text_addr_rom[4] = 8'h03;
        text_addr_rom[5] = 8'h03;

        o_scl = 1'b1;
        sda_drive_low = 1'b0;
    end

    localparam M_POWER_WAIT      = 8'd0;
    localparam M_INIT_SEND       = 8'd1;
    localparam M_INIT_NEXT       = 8'd2;
    localparam M_CLEAR_ADDR_SEND = 8'd3;
    localparam M_CLEAR_ADDR_NEXT = 8'd4;
    localparam M_CLEAR_SEND      = 8'd5;
    localparam M_CLEAR_NEXT      = 8'd6;
    localparam M_TEXT_ADDR_SEND  = 8'd7;
    localparam M_TEXT_ADDR_NEXT  = 8'd8;
    localparam M_TEXT_SEND       = 8'd9;
    localparam M_TEXT_NEXT       = 8'd10;
    localparam M_IDLE            = 8'd11;

    reg [7:0] main_state = M_POWER_WAIT;
    reg [15:0] power_count = 16'd0;

    reg [7:0] init_index = 8'd0;
    reg [2:0] addr_index = 3'd0;
    reg [9:0] clear_count = 10'd0;
    reg [9:0] text_count = 10'd0;

    reg [1:0] drawn_status = 2'b11;

    reg tx_active = 1'b0;
    reg [3:0] tx_state = 4'd0;
    reg [7:0] tx_control = 8'h00;
    reg [7:0] tx_data = 8'h00;
    reg [7:0] tx_cur_byte = 8'h00;
    reg [1:0] tx_byte_index = 2'd0;
    reg [3:0] tx_bit_index = 4'd7;
    reg [7:0] tx_return_state = M_IDLE;

    function [7:0] font_data;
        input [7:0] ch;
        input [2:0] col;
        begin
            case (ch)

                // W
                8'h57: begin
                    case (col)
                        3'd0: font_data = 8'h7F;
                        3'd1: font_data = 8'h20;
                        3'd2: font_data = 8'h18;
                        3'd3: font_data = 8'h20;
                        3'd4: font_data = 8'h7F;
                        default: font_data = 8'h00;
                    endcase
                end

                // I
                8'h49: begin
                    case (col)
                        3'd0: font_data = 8'h00;
                        3'd1: font_data = 8'h41;
                        3'd2: font_data = 8'h7F;
                        3'd3: font_data = 8'h41;
                        3'd4: font_data = 8'h00;
                        default: font_data = 8'h00;
                    endcase
                end

                // N
                8'h4E: begin
                    case (col)
                        3'd0: font_data = 8'h7F;
                        3'd1: font_data = 8'h02;
                        3'd2: font_data = 8'h0C;
                        3'd3: font_data = 8'h10;
                        3'd4: font_data = 8'h7F;
                        default: font_data = 8'h00;
                    endcase
                end

                // L
                8'h4C: begin
                    case (col)
                        3'd0: font_data = 8'h7F;
                        3'd1: font_data = 8'h40;
                        3'd2: font_data = 8'h40;
                        3'd3: font_data = 8'h40;
                        3'd4: font_data = 8'h40;
                        default: font_data = 8'h00;
                    endcase
                end

                // O
                8'h4F: begin
                    case (col)
                        3'd0: font_data = 8'h3E;
                        3'd1: font_data = 8'h41;
                        3'd2: font_data = 8'h41;
                        3'd3: font_data = 8'h41;
                        3'd4: font_data = 8'h3E;
                        default: font_data = 8'h00;
                    endcase
                end

                // S
                8'h53: begin
                    case (col)
                        3'd0: font_data = 8'h46;
                        3'd1: font_data = 8'h49;
                        3'd2: font_data = 8'h49;
                        3'd3: font_data = 8'h49;
                        3'd4: font_data = 8'h31;
                        default: font_data = 8'h00;
                    endcase
                end

                // E
                8'h45: begin
                    case (col)
                        3'd0: font_data = 8'h7F;
                        3'd1: font_data = 8'h49;
                        3'd2: font_data = 8'h49;
                        3'd3: font_data = 8'h49;
                        3'd4: font_data = 8'h41;
                        default: font_data = 8'h00;
                    endcase
                end

                default: font_data = 8'h00;

            endcase
        end
    endfunction

    function [7:0] word_char;
        input [1:0] status;
        input [2:0] index;
        begin
            if (status == 2'd2) begin
                // WIN
                case (index)
                    3'd0: word_char = 8'h57; // W
                    3'd1: word_char = 8'h49; // I
                    3'd2: word_char = 8'h4E; // N
                    default: word_char = 8'h20;
                endcase
            end else if (status == 2'd1) begin
                // LOSE
                case (index)
                    3'd0: word_char = 8'h4C; // L
                    3'd1: word_char = 8'h4F; // O
                    3'd2: word_char = 8'h53; // S
                    3'd3: word_char = 8'h45; // E
                    default: word_char = 8'h20;
                endcase
            end else begin
                word_char = 8'h20;
            end
        end
    endfunction

    always @(posedge i_clk) begin
        if (tick) begin

            if (tx_active) begin
                case (tx_state)

                    4'd0: begin
                        o_scl <= 1'b1;
                        sda_drive_low <= 1'b0;
                        tx_state <= 4'd1;
                    end

                    4'd1: begin
                        // START
                        o_scl <= 1'b1;
                        sda_drive_low <= 1'b1;
                        tx_byte_index <= 2'd0;
                        tx_bit_index <= 4'd7;
                        tx_cur_byte <= {OLED_ADDR, 1'b0};
                        tx_state <= 4'd2;
                    end

                    4'd2: begin
                        o_scl <= 1'b0;
                        sda_drive_low <= ~tx_cur_byte[tx_bit_index];
                        tx_state <= 4'd3;
                    end

                    4'd3: begin
                        o_scl <= 1'b1;

                        if (tx_bit_index == 4'd0) begin
                            tx_state <= 4'd4;
                        end else begin
                            tx_bit_index <= tx_bit_index - 1'b1;
                            tx_state <= 4'd2;
                        end
                    end

                    4'd4: begin
                        // ACK bit, ignore
                        o_scl <= 1'b0;
                        sda_drive_low <= 1'b0;
                        tx_state <= 4'd5;
                    end

                    4'd5: begin
                        o_scl <= 1'b1;
                        tx_state <= 4'd6;
                    end

                    4'd6: begin
                        o_scl <= 1'b0;

                        if (tx_byte_index == 2'd2) begin
                            tx_state <= 4'd7;
                        end else begin
                            tx_byte_index <= tx_byte_index + 1'b1;
                            tx_bit_index <= 4'd7;

                            if (tx_byte_index == 2'd0)
                                tx_cur_byte <= tx_control;
                            else
                                tx_cur_byte <= tx_data;

                            tx_state <= 4'd2;
                        end
                    end

                    4'd7: begin
                        // STOP
                        o_scl <= 1'b0;
                        sda_drive_low <= 1'b1;
                        tx_state <= 4'd8;
                    end

                    4'd8: begin
                        o_scl <= 1'b1;
                        tx_state <= 4'd9;
                    end

                    4'd9: begin
                        sda_drive_low <= 1'b0;
                        tx_state <= 4'd10;
                    end

                    4'd10: begin
                        tx_active <= 1'b0;
                        main_state <= tx_return_state;
                    end

                    default: begin
                        tx_active <= 1'b0;
                        main_state <= tx_return_state;
                    end

                endcase
            end else begin
                case (main_state)

                    M_POWER_WAIT: begin
                        if (power_count < 16'd10000) begin
                            power_count <= power_count + 1'b1;
                        end else begin
                            init_index <= 8'd0;
                            main_state <= M_INIT_SEND;
                        end
                    end

                    M_INIT_SEND: begin
                        tx_control <= 8'h00;
                        tx_data <= init_rom[init_index];
                        tx_return_state <= M_INIT_NEXT;
                        tx_state <= 4'd0;
                        tx_active <= 1'b1;
                    end

                    M_INIT_NEXT: begin
                        if (init_index < 8'd30) begin
                            init_index <= init_index + 1'b1;
                            main_state <= M_INIT_SEND;
                        end else begin
                            addr_index <= 3'd0;
                            main_state <= M_CLEAR_ADDR_SEND;
                        end
                    end

                    M_CLEAR_ADDR_SEND: begin
                        tx_control <= 8'h00;
                        tx_data <= clear_addr_rom[addr_index];
                        tx_return_state <= M_CLEAR_ADDR_NEXT;
                        tx_state <= 4'd0;
                        tx_active <= 1'b1;
                    end

                    M_CLEAR_ADDR_NEXT: begin
                        if (addr_index < 3'd5) begin
                            addr_index <= addr_index + 1'b1;
                            main_state <= M_CLEAR_ADDR_SEND;
                        end else begin
                            clear_count <= 10'd0;
                            main_state <= M_CLEAR_SEND;
                        end
                    end

                    M_CLEAR_SEND: begin
                        tx_control <= 8'h40;
                        tx_data <= 8'h00;
                        tx_return_state <= M_CLEAR_NEXT;
                        tx_state <= 4'd0;
                        tx_active <= 1'b1;
                    end

                    M_CLEAR_NEXT: begin
                        if (clear_count < 10'd1023) begin
                            clear_count <= clear_count + 1'b1;
                            main_state <= M_CLEAR_SEND;
                        end else begin
                            addr_index <= 3'd0;
                            main_state <= M_TEXT_ADDR_SEND;
                        end
                    end

                    M_TEXT_ADDR_SEND: begin
                        tx_control <= 8'h00;
                        tx_data <= text_addr_rom[addr_index];
                        tx_return_state <= M_TEXT_ADDR_NEXT;
                        tx_state <= 4'd0;
                        tx_active <= 1'b1;
                    end

                    M_TEXT_ADDR_NEXT: begin
                        if (addr_index < 3'd5) begin
                            addr_index <= addr_index + 1'b1;
                            main_state <= M_TEXT_ADDR_SEND;
                        end else begin
                            text_count <= 10'd0;
                            main_state <= M_TEXT_SEND;
                        end
                    end

                    M_TEXT_SEND: begin
                        if (text_count < 10'd36) begin
                            tx_control <= 8'h40;

                            if ((text_count % 6) == 5)
                                tx_data <= 8'h00;
                            else
                                tx_data <= font_data(
                                    word_char(i_status, text_count / 6),
                                    text_count % 6
                                );

                            tx_return_state <= M_TEXT_NEXT;
                            tx_state <= 4'd0;
                            tx_active <= 1'b1;
                        end else begin
                            drawn_status <= i_status;
                            main_state <= M_IDLE;
                        end
                    end

                    M_TEXT_NEXT: begin
                        text_count <= text_count + 1'b1;
                        main_state <= M_TEXT_SEND;
                    end

                    M_IDLE: begin
                        o_scl <= 1'b1;
                        sda_drive_low <= 1'b0;

                        if (i_status != drawn_status) begin
                            addr_index <= 3'd0;
                            main_state <= M_CLEAR_ADDR_SEND;
                        end
                    end

                    default: begin
                        main_state <= M_POWER_WAIT;
                    end

                endcase
            end
        end
    end

endmodule