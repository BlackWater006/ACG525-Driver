module CountAndToggle #(
    parameter COUNT_LIMIT = 1000000
)(
    input i_clk,
    input i_en,
    output reg o_toggle
);

    reg [31:0] r_count = 32'd0;

    initial begin
        o_toggle = 1'b0;
    end

    always @(posedge i_clk) begin
        if (!i_en) begin
            r_count <= 32'd0;
            o_toggle <= 1'b0;
        end else begin
            if (r_count >= COUNT_LIMIT - 1) begin
                r_count <= 32'd0;
                o_toggle <= ~o_toggle;
            end else begin
                r_count <= r_count + 1'b1;
            end
        end
    end

endmodule