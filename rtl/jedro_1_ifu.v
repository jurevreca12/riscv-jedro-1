////////////////////////////////////////////////////////////////////////////////                                          
// SPDX-FileCopyrightText: 2022, Jure Vreca                                   //                                          
//                                                                            //                                          
// Licenseunder the Apache License, Version 2.0(the "License");               //                                          
// you maynot use this file except in compliance with the License.            //                                           
// You may obtain a copy of the License at                                    //                                          
//                                                                            //                                          
//      http://www.apache.org/licenses/LICENSE-2.0                            //                                          
//                                                                            //                                          
// Unless required by applicable law or agreed to in writing, software        //                                          
// distributed under the License is distributed on an "AS IS" BASIS,          //                                          
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   //                                          
// See the License for the specific language governing permissions and        //                                          
// limitations under the License.                                             //                                          
// SPDX-License-Identifier: Apache-2.0                                        //                                          
// SPDX-FileContributor: Jure Vreca <jurevreca12@gmail.com>                   //                                          
////////////////////////////////////////////////////////////////////////////////      
////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jure Vreca - jurevreca12@gmail.com                         //
//                                                                            //
//                                                                            //
//                                                                            //
// Design Name:    jedro_1_ifu                                                //
// Project Name:   riscv-jedro-1                                              //
// Language:       System Verilog                                             //
//                                                                            //
// Description:    The instruction fetch unit for SPROM memory with           //
//                 a single cycle read delay. The jmp_instr_i should only be  //
//                 asserted for a single clock cycle (for every jmp instr).   //
//                                                                            //
//                                      _________                             //
//                 ________             |       |                             //
//                 |       |<-----------| pc[0] |                             //
//                 |       |            |_______|                             //
//                 |  RAM  |                                                  //
//                 |       |            ____________        _________         //
//                 |       | dout       |          |        |       |         //
//                 |       |----------->| dout_r   |------->|  M    |         //
//                 |_______|            |__________|  |     |  U    | instr_o //
//                                                    |     |  X    |-------> //
//                                    <_______________| |-->|       |         //
//                                   |                  |   |       |         //
//                          stall_r, after_stall_r_0/1  |-->|_______|         //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

`include "jedro_1_defines.v"

module jedro_1_ifu #(
    parameter BOOT_ADDR = 32'h8000_0000
) 
(
  input wire clk_i,
  input wire rstn_i,

  input wire jmp_instr_i,     // Specifes that we encountered a jump instruction and the program 
                               // counter should be changed to jmp_address_i.
  
  input wire [`DATA_WIDTH-1:0] jmp_address_i,    // The jump address

  output reg                   exception_ro,  // Signals to the controller an instruction-addr-misaligned exception
  output reg [`DATA_WIDTH-1:0] fault_addr_ro, // the address that caused the misaligned exception

  // Interface to the decoder
  output wire [`DATA_WIDTH-1:0] instr_o,     // The current instruction (to be decoded)
  output wire [`DATA_WIDTH-1:0] addr_o,      // Used by instructons that calculate on the PC.
  output reg                    valid_o,
  input  wire                   ready_i,     // Decoder ready to accept new instruction
  
  // Interface to the ROM memory
  output wire [`DATA_WIDTH-1:0]  ram_addr,
  input wire  [`DATA_WIDTH-1:0]  ram_rdata
);

localparam INSTR_SHIFTREG_DEPTH = 3;
localparam NV  = 6'b000001;
localparam DV  = 6'b000010;
localparam S0  = 6'b000100;
localparam S1  = 6'b001000;
localparam S2  = 6'b010000;
localparam EX  = 6'b100000;
localparam XXX = 6'b000000;

reg [5:0] state, next;


reg [`DATA_WIDTH-1:0] pc_shift_r0;
reg [`DATA_WIDTH-1:0] pc_shift_r1;
reg [`DATA_WIDTH-1:0] pc_shift_r2;
reg [INSTR_SHIFTREG_DEPTH-1:0] instr_valid_shift_r;

reg [`DATA_WIDTH-1:0] out_instr; // the final muxed output (it gets comb assigned to instr_o and addr_o)
reg [`DATA_WIDTH-1:0] out_addr;

reg [`DATA_WIDTH-1:0] dout_r_instr;  // buffered output from RAM
reg [`DATA_WIDTH-1:0] dout_r_addr;

reg [`DATA_WIDTH-1:0] stall_r_instr; // saves the instruciton causing the stall
reg [`DATA_WIDTH-1:0] stall_r_addr;

reg [`DATA_WIDTH-1:0] after_stall_r0_instr; // saves the first instruction after the stall
reg [`DATA_WIDTH-1:0] after_stall_r0_addr;

reg [`DATA_WIDTH-1:0] after_stall_r1_instr; // saves the second instruction after the stall
reg [`DATA_WIDTH-1:0] after_stall_r1_addr;

wire stall_begin_pulse;   // generates a pulse event on the clock cycle at which the stall happened
reg  stall_begin_pulse_r; // a pulse event one clock cycle later then the stall_begin_pulse
reg  prev_ready;          // used to generate the stall_begin_pulse (ready low indicates stall)

wire stall_in_stall;       // an OR combination of stall_in_stall_r and stall_in_stall_pulse
reg  stall_in_stall_r;     // gets set when stall_in_stall_pulse is 1, and gets deasserted when state=DV
wire stall_in_stall_pulse; // when a stall occurs when state!=DV then this gets triggered combinatorialy
reg  [`DATA_WIDTH-1:0] after_stall_addr;  // address to continue from if a stall_in_stall event occurs

reg jmp_instr; // this signal filters incorrect jumps
reg is_exception;

/***************************************
* MISALIGNED JUMPS EXCEPTION GENERATION
***************************************/
always@(*) begin
    if (jmp_instr_i == 1'b1) begin
        if (jmp_address_i[1:0] == 2'b00) begin
            jmp_instr = 1'b1;
            is_exception = 1'b0;
        end
        else begin
            jmp_instr = 1'b0;
            is_exception = 1'b1;
        end
    end
    else begin
        jmp_instr = 1'b0;
        is_exception = 1'b0;
    end 
end

always @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        exception_ro <= 0;
        fault_addr_ro <= 0;       
    end 
    else begin
        exception_ro <= is_exception;
        fault_addr_ro <= jmp_address_i;
    end
end

/***************************************
* PROGRAM COUNTER LOGIC and VALID LOGIC
***************************************/
assign ram_addr = pc_shift_r0; // The output address just follows pc_shift_r0

always @(posedge clk_i) begin
  if (rstn_i == 1'b0) begin
     pc_shift_r0 <= BOOT_ADDR;
     pc_shift_r1 <= BOOT_ADDR;
     pc_shift_r2 <= BOOT_ADDR;
     instr_valid_shift_r <= 3'b001;
  end
  else begin
    if (jmp_instr == 1'b1) begin
        pc_shift_r0 <= jmp_address_i;
        pc_shift_r1 <= jmp_address_i;
        pc_shift_r2 <= jmp_address_i;
        instr_valid_shift_r <= 3'b001;
    end
    else if (stall_in_stall_pulse == 1'b1) begin
        pc_shift_r0 <= after_stall_addr;
        pc_shift_r1 <= after_stall_addr;
        pc_shift_r2 <= after_stall_addr;
        instr_valid_shift_r <= 3'b001;
    end
    else if ((stall_in_stall_r == 1'b1) ||
             (stall_in_stall_r == 1'b0 && ready_i == 1'b0)) begin
        pc_shift_r0 <= pc_shift_r0;
        pc_shift_r1 <= pc_shift_r1;
        pc_shift_r2 <= pc_shift_r2;
        instr_valid_shift_r <= instr_valid_shift_r;
    end
    else begin
        pc_shift_r0 <= pc_shift_r0 + 4;
        pc_shift_r1 <= pc_shift_r0;
        pc_shift_r2 <= pc_shift_r1;
        instr_valid_shift_r <= instr_valid_shift_r << 1;
        instr_valid_shift_r[0] <= 1'b1;
    end
  end
end


/***************************************
* READING LOGIC
***************************************/
always @(posedge clk_i) begin
  if (rstn_i == 1'b0) begin
    {dout_r_instr, dout_r_addr} <= {`NOP_INSTR, 32'b0}; // we reset to the NOP operation
  end
  else begin
    {dout_r_instr, dout_r_addr} <= {ram_rdata, pc_shift_r1};
  end
end

always @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        {stall_r_instr, stall_r_addr} <= {32'b0, 32'b0};
    end
    else begin
        if (ready_i == 1'b1) begin
            {stall_r_instr, stall_r_addr} <= {dout_r_instr, dout_r_addr}; 
        end
        else begin
            {stall_r_instr, stall_r_addr} <= {stall_r_instr, stall_r_addr};
        end
    end
end

always @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        {after_stall_r0_instr, after_stall_r0_addr} <= 0;
    end
    else begin
        if (stall_begin_pulse == 1'b1 && state == DV) begin
            {after_stall_r0_instr, after_stall_r0_addr} <= {dout_r_instr, dout_r_addr};
        end
        else begin
            {after_stall_r0_instr, after_stall_r0_addr} <= {after_stall_r0_instr, after_stall_r0_addr};
        end
    end
end

always @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        {after_stall_r1_instr, after_stall_r1_addr} <= {32'b0, 32'b0};
    end
    else begin
        if (stall_begin_pulse_r == 1'b1 && state == S0) begin
            {after_stall_r1_instr, after_stall_r1_addr} <= {dout_r_instr, dout_r_addr};
        end
        else begin
            {after_stall_r1_instr, after_stall_r1_addr} <= {after_stall_r1_instr, after_stall_r1_addr};
        end
    end
end

always @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        after_stall_addr <= 0;
    end
    else begin
        if (state == DV && ready_i == 1'b0) begin
            after_stall_addr <= pc_shift_r0;
        end
        else begin
            after_stall_addr <= after_stall_addr;
        end
    end
end

/***************************************
* CONTROL LOGIC 
***************************************/
always @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        prev_ready <= 1'b0;
    end
    else begin
        prev_ready <= ready_i;
    end
end

assign stall_begin_pulse = prev_ready  & (~ready_i) & valid_o;
always @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        stall_begin_pulse_r <= 1'b0;
    end
    else begin
        stall_begin_pulse_r <= stall_begin_pulse;
    end
end

assign stall_in_stall = stall_in_stall_r || stall_in_stall_pulse;
assign stall_in_stall_pulse = prev_ready & (~ready_i) & (state == S1 || state == S2) & (~stall_in_stall_r);
always @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        stall_in_stall_r <= 0;
    end
    else begin
        if (stall_in_stall_pulse == 1'b1) stall_in_stall_r <= 1'b1;
        else if (next == NV)              stall_in_stall_r <= 1'b0;
        else                              stall_in_stall_r <= stall_in_stall_r;
    end
end

/***************************************
* FINITE STATE MACHINE/OUTPUT MUXING
***************************************/
assign instr_o = out_instr;
assign addr_o  = out_addr;

always @(posedge clk_i) begin
    if (rstn_i == 1'b0) state <= NV;
    else                state <= next;
end

always@(*) begin
    next = XXX;
    case (state)
        NV : if (instr_valid_shift_r[1] == 1'b1) next = DV;
             else                                next = NV;

        DV : if      (is_exception)              next = EX;
             else if (jmp_instr == 1'b1)         next = NV;
             else if (ready_i == 1'b1)           next = DV;
             else                                next = S0;
                
        S0 : if      (is_exception)              next = EX;
             else if (jmp_instr == 1'b1)         next = NV;
             else if (ready_i == 1'b0)           next = S0;
             else                                next = S1;

        S1 : if      (is_exception)              next = EX;
             else if (jmp_instr == 1'b1)         next = NV;
             else if (ready_i == 1'b0)           next = S1;
             else                                next = S2;

        S2 : if      (is_exception)              next = EX;
             else if (jmp_instr == 1'b1)         next = NV;
             else if (ready_i == 1'b0)           next = S2;
             else if (ready_i == 1'b1 && 
                      stall_in_stall == 1'b1)    next = NV;
             else                                next = DV;
        
        EX : if    (jmp_instr)                   next = NV;
             else                                next = EX;
        
        default :                                next = XXX;
    endcase 
end

always@(*) begin
    {out_instr, out_addr}  = {`NOP_INSTR, 32'b0};
    case (state)
        NV:                                  {out_instr, out_addr} = {`NOP_INSTR, 32'b0};

        DV: if (ready_i == 1'b1)             {out_instr, out_addr} = {dout_r_instr, dout_r_addr};
            else                             {out_instr, out_addr} = {stall_r_instr, stall_r_addr};

        S0: if (ready_i == 1'b0)             {out_instr, out_addr} = {stall_r_instr, stall_r_addr};
            else                             {out_instr, out_addr} = {after_stall_r0_instr, after_stall_r0_addr};

        S1: if (ready_i == 1'b0)             {out_instr, out_addr} = {after_stall_r0_instr, after_stall_r0_addr};
            else                             {out_instr, out_addr} = {after_stall_r1_instr, after_stall_r1_addr};

        S2: if (ready_i == 1'b0)             {out_instr, out_addr} = {after_stall_r1_instr, after_stall_r1_addr};
            else if (ready_i == 1'b1 &&
                     stall_in_stall == 1'b1) {out_instr, out_addr} = {`NOP_INSTR, 32'b0};
            else                             {out_instr, out_addr} = {dout_r_instr, dout_r_addr};

        EX:                                  {out_instr, out_addr} = {dout_r_instr, dout_r_addr};

        default:                             {out_instr, out_addr} = {32'b0, 32'b0};
    endcase
end

always@(*) begin
    if ((state == NV) || 
        (jmp_instr == 1'b1) ||
        (state == S2 && ready_i == 1'b1 && 
         stall_in_stall == 1'b1) ||
        (state == EX))                                             valid_o = 1'b0;
    else                                                           valid_o = 1'b1;
end

endmodule
