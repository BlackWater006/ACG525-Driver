module BinaryToSevSeg(
    input i_clk,
    input [3:0] i_bin_num,
    output reg [6:0] o_sevseg
);

    initial begin
        o_sevseg = 7'b1111111;
    end

    always @(posedge i_clk) begin
        case (i_bin_num)
            4'd0: o_sevseg <= ~(7'b0111111);
            4'd1: o_sevseg <= ~(7'b0000110);
            4'd2: o_sevseg <= ~(7'b1011011);
            4'd3: o_sevseg <= ~(7'b1001111);
            4'd4: o_sevseg <= ~(7'b1100110);
            4'd5: o_sevseg <= ~(7'b1101101);
            4'd6: o_sevseg <= ~(7'b1111101);
            4'd7: o_sevseg <= ~(7'b0000111);
            4'd8: o_sevseg <= ~(7'b1111111);
            4'd9: o_sevseg <= ~(7'b1101111);
            4'hA: o_sevseg <= ~(7'b1110111);
            4'hF: o_sevseg <= ~(7'b1110001);
            default: o_sevseg <= ~(7'b0000000);
        endcase
    end

endmodule