`include "clk_test.v"
`default_nettype none

module tb_clk_test;
reg clk;
reg rst;
reg [15:0] data_in;
wire [15:0] data_out;
reg [3:0] t;
reg [31:0] src2;
reg [31:0] src1;


clk_test clk_t
(
    .rst (rst),
    .clk (clk),
    .data_in (data_in),
    .data_out (data_out)
);

localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk=~clk;

/*
initial begin
    dumpfile("tb_clk_test.vcd");
    dumpvars(0, tb_clk_test);
end
*/

initial begin
    #1 rst<=1'bx;clk<=1'bx;
    data_in=0;
    #(CLK_PERIOD*3) rst<=1;
    #(CLK_PERIOD*3) rst<=0;clk<=0;
    #(CLK_PERIOD*3) data_in=1;
    #(CLK_PERIOD*3) data_in=12;
    #(CLK_PERIOD*3) data_in=5;
    #(CLK_PERIOD*3) t=4'b0010;
    #(CLK_PERIOD*3) t=t>>1;
    #(CLK_PERIOD*3) t=4'b0010;
    #(CLK_PERIOD*3) t=t>>2;
    #(CLK_PERIOD*3) t=4'b1111;
    #(CLK_PERIOD*3) t=t>>2;
    #(CLK_PERIOD*3) t=4'b1111;
    #(CLK_PERIOD*3) t=t<<2;
    #(CLK_PERIOD*3) t=4'b0010;
    #(CLK_PERIOD*3) t=t<<1;
    src2=32'b00000000000000000000000000000011;
    src1=1;
    #(CLK_PERIOD*3) src2 = /*( src2 >> src1 ) || */( src2 << ( 32 -src1 ) );
    #(CLK_PERIOD*3) t=4'b0010|4'b0001;//Bitwise or not equal to||
    #(CLK_PERIOD*3) $finish;
end

initial begin : monitor
    $monitor($time,"  |  in=%d  |  out=%d  |  t=%b  |  src2=%b",data_in,data_out,t,src2);
end

endmodule
`default_nettype wire