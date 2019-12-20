`include "cpu.v"
`default_nettype none

module tb_cpu;
parameter WIDTH = 32;//width of data path
parameter ADDRSIZE = 12;//size of address field
parameter MEMSIZE = (1<<ADDRSIZE/*4096*/);//size of memory (2^ADDRSIZE)=2^12
parameter Forced_stop_number_of_cycles = 20;
//main reg
reg [WIDTH-1:0] MEM[0:MEMSIZE-1];//MEMORY
reg [WIDTH-1:0] I_MEM[0:MEMSIZE-1];//ins. mem.

reg clk;
reg rst;
reg debug;
wire [6:0] debuger;
wire [11:0] MEM_ADDR;
reg [0:31] MEM_IN;
wire [0:31] MEM_OUT;
wire MEM_CTRL;
wire [11:0] INS_ADDR;
reg [0:31] INS_MEM;
//debug
integer tb_debug;
integer ot_mem=0;

instruction_set_model cpu 
(
    .rst (rst),
    .clk (clk),
    .debug(debug),
    .debuger(debuger),
    .MEM_ADDR(MEM_ADDR),
    .MEM_IN(MEM_IN),
    .MEM_OUT(MEM_OUT),
    .MEM_CTRL(MEM_CTRL),
    .INS_ADDR(INS_ADDR),
    .INS_MEM(INS_MEM)
);

always @(MEM_ADDR) begin : always_MEM_ADDR
    MEM_IN = MEM[MEM_ADDR];
end

always @(INS_ADDR) begin : always_INS_ADDR
    INS_MEM = I_MEM[INS_ADDR];
end

always @(MEM_OUT) begin : always_MEM_OUT
    if (MEM_CTRL) begin
        MEM[MEM_ADDR] = MEM_OUT;
    end else begin
        tb_debug = 1;
    end
end

localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk=~clk;

/*
initial begin
    dumpfile("tb_cpu.vcd");
    dumpvars(0, tb_cpu);
end
*/

initial begin : monitor
    $monitor($time," | rst=%b | debug=%b | debuger=%d | MEM_ADDR=%d | MEM_IN=%d | MEM_OUT=%d | MEM_CTRL=%d | INS_ADDR=%d | INS_MEM=%b  |  tb_debug=%d",rst,debug,debuger,MEM_ADDR,MEM_IN,MEM_OUT,MEM_CTRL,INS_ADDR,INS_MEM,tb_debug);
end

always@(debuger) begin : stop
    if (debuger==5) begin
    $display("=================================================");
    for ( ot_mem= 0; ot_mem<10; ot_mem=ot_mem+1) begin
        $display("data_MEM[%d]=%d",ot_mem,MEM[ot_mem]);
    end
    $display("=================================================");
        $display("Halt...");
        $finish;
    end
end

initial begin : main_loop
    #1 rst<=1'b0;clk<=1'b0;
    debug<=1;MEM_IN<=0;INS_MEM<=0;
    #(CLK_PERIOD*3) rst<=1;
    #(CLK_PERIOD*3) rst<=0;clk<=0;

    $display("=================================================");
    for ( ot_mem= 0; ot_mem<10; ot_mem=ot_mem+1) begin
        $display("I_MEM[%d]=%b",ot_mem,I_MEM[ot_mem]);
    end
    $display("=================================================");

    #(CLK_PERIOD*Forced_stop_number_of_cycles) $finish;
end

initial begin : prog_load
    $readmemb("mem.prog",MEM);
    $readmemb("i_mem.prog",I_MEM);
end

endmodule
`default_nettype wire
/*tb_debug code
1:MEM_OUT changed, but MEM_CTRL is not set

*/