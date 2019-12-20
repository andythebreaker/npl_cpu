module clk_test(
    input clk,
    input rst,
    input [15:0] data_in,
    output [15:0] data_out
);
reg [15:0] R_data_out;
assign data_out=R_data_out;
always@(posedge clk)begin
    if(rst)begin
       R_data_out = 0;
    end else begin
    if (data_in > 10) begin
        R_data_out = 5;
    end else begin
R_data_out=3;
end
    end
end


endmodule // clk_test
