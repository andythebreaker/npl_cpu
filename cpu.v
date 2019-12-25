module instruction_set_model(
    //MEMORY
    input clk,
    input rst,
    input debug,
    output [6:0] debuger,/*2^7=128*/
    output [11:0] MEM_ADDR,/*ADDRSIZE-1:0*/
    input [0:31] MEM_IN,/*0:WIDTH-1*/
    output [0:31] MEM_OUT,/*0:WIDTH-1*/
    output MEM_CTRL,//0:read | 1:write
    output [11:0] INS_ADDR,
    input [0:31] INS_MEM//always in read mode

    //-------------------
    //output [32:0] reg_debug_out
    //-------------------
);
//parameter CYCLE = 10;//cycle time
parameter WIDTH = 32;//width of data path
parameter ADDRSIZE = 12;//size of address field
//parameter MEMSIZE = (1<<ADDRSIZE/*4096*/);//size of memory (2^ADDRSIZE)=2^12
parameter MAXREGS = 16;//max # of reg.
parameter SBITS = 5;//status reg. bits
//cpu reg.
reg [WIDTH-1:0/*32*/] RFILE[0:MAXREGS-1/*16*/],//Register File
                      ir,//Instruction Register
                      src1, src2 ;//Alu operation registers
reg [WIDTH:0/*33*/] result ;//ALU result register
reg [SBITS-1:0/*5*/] psr;//Processor Status Register
reg [ADDRSIZE-1:0/*12*/] pc ;//Program counter
//reg. for output
reg [ADDRSIZE-1:0] MEM_D ;
//reg [ADDRSIZE-1:0] INS_D ;//<X>
reg [0:WIDTH-1] MEM_O ;
reg MEM_C;
assign MEM_ADDR = MEM_D;
assign INS_ADDR = /*<X>*//*INS_D*/pc;
assign MEM_OUT = MEM_O;
assign MEM_CTRL = MEM_C;
/*debug*/
reg [6:0] debug_r;
assign debuger = debug_r; 
//temp. reg.
reg temp_checkcond;
//define
`define TRUE 1
`define FALSE 0 
/*============================================================
Instruction Format
31      28 27    24 23         12 11            0
+-----------------------------------------------+
| 4bits   |  4bits |   12bits    |    12bits    |
+-----------------------------------------------+
IR[31:28]:OPcode (max # of instructions = 2^4 = 16)
IR[27:24]: condition code  !or!
{
IR[27]:	 source type 0=reg (mem), 1=imm
IR[26]:	 destination type 0=reg (mem), 1=imm (Not valid)
}
IR[23:12]:  source address or	shift/rotate count
IR[11:0] : destination address
============================================================*/
`define OPCODE ir[31:28]
`define SRC ir[23:12]// source addr.
`define DST ir[11:0]// destination addr.
`define SRCTYPE ir[27] // source type, 0=reg, 1=imm
`define DSTTYPE ir[26] // destination type, 0=reg, 1=imm
`define CCODE ir[27:24]
`define SRCNT ir[23:12] // Shift/Rotate count -= left, +=right
// Operand Types
`define REGTYPE 0
`define IMMTYPE 1
// Define opcodes for each instruction
`define NOP 4'b0000 //0
`define BRA 4'b0001 //1
`define LD  4'b0010 //2
`define STR 4'b0011 //3
`define ADD 4'b0100 //4
`define MUL 4'b0101 //5
`define CMP 4'b0110 //6
`define SHF 4'b0111 //7
`define ROT 4'b1000 //8
`define HLT 4'b1001 //9
`define DIV 4'b1010 //10 Division
`define RMD 4'b1011 //11 Remainder
// Define Condition Code fields
`define CARRY psr[0]
`define EVEN psr[1] // if x is even, x%2 (in C language) = 0
`define PARITY psr[2] // the fact of being even or odd. <!>
`define ZERO psr[3]
`define NEG psr[4] //Negative 
// Define Condition Codes <!>
`define CCC 1 // Result has carry
`define CCE 2 // Result is even
`define CCP 3 // Result is odd parity
`define CCZ 4 // Result is Zero
`define CCN 5 // Result is Negative
`define CCA 0 // Always
//L/R
`define RIGHT  0 // Rotate/Shift Right
`define LEFT   1 // Rotate/Shift Left
//integer
integer i;

//--------------------------------------------
//assign reg_debug_out = ir;
//--------------------------------------------

//function
function [6:0] setcondcode;//Compute the condition codes and set PSR
    input [WIDTH:0] res;//33 bit result register
    begin
        `CARRY = res[WIDTH];
        `EVEN = ~res[0];
        `PARITY = ^res;
        `ZERO = ~(|res);
        `NEG = res [WIDTH-1];
        setcondcode = 8;//debug<!>
    end
endfunction//setcondcode

function [WIDTH-1:0] getsrc;
    input [WIDTH-1:0] in;
    begin
        if(`SRCTYPE == `REGTYPE) getsrc = RFILE[`SRC];//reg
        else getsrc = `SRC;//imm. type
    end
endfunction//getsrc

function [WIDTH-1:0] getdst;
    input  [WIDTH-1:0] in;
    begin
        if(`DSTTYPE == `REGTYPE) begin
            getdst = RFILE[`DST];//reg
        end else begin
            //ERROR imm. type
            debug_r = 10;
        end
    end
    
endfunction//getdst

//negedge -> do fetch
always @(negedge clk)
begin
	ir = INS_MEM;
end

always @(posedge clk or posedge rst)
begin//always @(posedge clk or posedge rst)
    if (rst) begin
        debug_r = 2;
        //initialization
        for (i = 0; i<MAXREGS; i=i+1/*0~16*/) begin
            RFILE[i] = 0;
        end
        ir = 0;
        src1 = 0;
        src2 = 0;
        result = 0;
        psr = 0;
        pc = 0;
        MEM_D = 0;
        //INS_D = 0;//<X>
        MEM_O = 0;
        temp_checkcond = 0;
        MEM_C = 0;
 
    end else begin
        //make mem. unreadable
        MEM_C = 0;
        //fetch
        //ir = INS_MEM;
        //INS_D = pc+1;//<X>
        pc = pc+1;
        //execute
        case (`OPCODE/*ir...*/)
            /*0*/`NOP: begin
                debug_r = 3;
            end
            /*1*/`BRA: begin
                //function checkcond; //Returns 1 if condition code is set .
                //input [4:0] ccode;
                case (`CCODE)
                /*================Grammar description================
                CCODE is "part of OPCODE" (4 bits)
                it has 5 different state (Just like the abbreviation written below)
                eg.: CCC | CCE | CCP ...etc
                for every case/state of CCODE been asked for,
                we want to go and find the corresponding state memory,
                and see if this state is set (is true),
                this led to the appearance of the "equal to one" judgment.
                ======END=======Grammar description========END=====*/
                    `CCC: temp_checkcond = `CARRY;
                    `CCE: temp_checkcond = `EVEN;
                    `CCP: temp_checkcond = `PARITY;
                    `CCZ: temp_checkcond = `ZERO;
                    `CCN: temp_checkcond = `NEG;
                    `CCA: temp_checkcond = 1;//always
                    default: debug_r = 6 ;
                endcase
                if (temp_checkcond) begin
                    if (debug) begin
                        debug_r=9;
                    end else begin
                        debug_r=0;
                    end
                    pc = `DST;
                end else begin
                    debug_r = 7 ;
                end
            end
            /*2*/`LD: begin
                psr = 0;//clearcondcode
                MEM_D = `SRC;
                RFILE[`DST] = (`SRCTYPE)?`SRC/*SRCTYPE=1 :imm*/:MEM_IN;
                debug_r = setcondcode({1'b0,RFILE[`DST]}/*33bits*/);
            end
            /*3*/`STR: begin
                psr = 0;//clearcondcode
                MEM_C = 1;//let MEM do "write"
                MEM_D = `DST;
                MEM_O = (`SRCTYPE)?`SRC/*SRCTYPE=1 :imm*/:RFILE[`SRC];
                debug_r = (`SRCTYPE)?setcondcode({21'b0, `SRC/*12bit, imm*/}):setcondcode({1'b0, RFILE[`SRC]});
            end
            /*4*/`ADD: begin
                //debug_r =104;
                psr = 0;//clearcondcode
                src1 = getsrc(ir);
                src2 = getdst(ir);
                result = src1+src2;
                debug_r = setcondcode(result);
            end
            /*5*/`MUL: begin
                debug_r =105;
            end
            /*6*/`CMP: begin
                debug_r =106;
            end
            /*7*/`SHF: begin
                debug_r =107;
            end
            /*8*/`ROT: begin
                debug_r =108;
            end
            /*9*/`HLT: begin
                debug_r = 5;
            end
            /*10*/`DIV: begin
                debug_r =110;
            end
            /*11*/`RMD: begin
                debug_r =111;
            end
            default: begin
                debug_r = 4;
            end
        endcase
    end
end//always @(posedge clk or posedge rst)

endmodule // instruction_set_model
/*
debug_r code 
0:undefine
2:[run rst.]
3:[exe. NOP]
4:[can't find ins.]go into default @ case(OPCODE)
5:[ext. HLT]need do:$display("Halt");$stop;
6:go in default @ [case (`CCODE)]
7:[sataus reg. Status is different from demand] @ BRA
8:[do SETCONDCODE]
9:branch, true, do change pc
10:$display("Error:Immediate data can’t be destination.");
//104:opcode case = 4
105:opcode case = 5
106:opcode case = 6
107:opcode case = 7
108:opcode case = 8
110:opcode case = 10
111:opcode case = 11
*/
