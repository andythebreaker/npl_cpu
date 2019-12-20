module clk_test(
    input clk,
    input rst,
    input [15:0] data_in,
    output [15:0] data_out
);
reg data_out;

always@(posedge clk)begin
    if(rst)begin
        data_out = 0;
    end else begin
    if (data_in > 10) begin
        data_out = 5;
    end
    end
end


endmodule // clk_test