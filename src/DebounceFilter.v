module DebounceFilter #(
    parameter DEBOUNCE_LIMIT = 5000000
)(
    input i_clk,
    input i_bouncy,
    output o_debounced
);

    reg [31:0] r_count = 32'd0;
    reg r_state = 1'b1;

    always @(posedge i_clk) begin
        if (i_bouncy == r_state) begin
            r_count <= 32'd0;
        end else begin
            if (r_count >= DEBOUNCE_LIMIT - 1) begin
                r_state <= i_bouncy;
                r_count <= 32'd0;
            end else begin
                r_count <= r_count + 1'b1;
            end
        end
    end

    assign o_debounced = r_state;

endmodule