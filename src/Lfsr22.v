module Lfsr22(
    input i_clk,
    output reg [21:0] o_data
);

    wire w_xnor;

    initial begin
        o_data = 22'h2A5A5A;
    end

    always @(posedge i_clk) begin
        o_data <= {o_data[20:0], w_xnor};
    end

    assign w_xnor = o_data[21] ^~ o_data[20];

endmodule