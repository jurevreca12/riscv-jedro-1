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
// Design Name:    jedro_1_alu                                                //
// Project Name:   riscv-jedro-1                                              //
// Language:       System Verilog                                             //
//                                                                            //
// Description:    The arithmetic logic unit is defined here.                 //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

`include "jedro_1_defines.v"

module jedro_1_alu
(
  input  wire clk_i,
  input  wire rstn_i,

  input  wire [`ALU_OP_WIDTH-1:0]   sel_i, // select arithmetic operation

  input  wire [`DATA_WIDTH-1:0]     op_a_i,
  input  wire [`DATA_WIDTH-1:0]     op_b_i,
  output reg  [`DATA_WIDTH-1:0]     res_ro,
  output reg                       ops_eq_ro, // is 1 if op_a_i == op_b_i
  output reg                       overflow_ro,

  input  wire [`REG_ADDR_WIDTH-1:0] dest_addr_i,
  output reg  [`REG_ADDR_WIDTH-1:0] dest_addr_ro,
  
  input  wire                      wb_i,
  output reg                       wb_ro
);

/*******************************
* SIGNAL DECLARATION
*******************************/
wire [`DATA_WIDTH-1:0] adder_res;
wire [`DATA_WIDTH-1:0] and_res;
wire [`DATA_WIDTH-1:0] or_res;
wire [`DATA_WIDTH-1:0] xor_res;
wire [`DATA_WIDTH-1:0] less_than_sign_res;
wire [`DATA_WIDTH-1:0] less_than_unsign_res;
wire [`DATA_WIDTH-1:0] shifter_right_res;
wire [`DATA_WIDTH-1:0] shifter_left_res;
wire                   ops_eq_res;
wire                   adder_overflow;
reg  [`DATA_WIDTH-1:0] res_w;


/*******************************
* RESULT BUFFERING
*******************************/
always@(posedge clk_i) begin
  if (rstn_i == 1'b0) begin
    overflow_ro <= 0;
    res_ro <= 0;
    ops_eq_ro <= 0;
  end
  else begin
    overflow_ro <= adder_overflow;
	res_ro <= res_w;
    ops_eq_ro <= ops_eq_res;
  end
end


/*******************************
* GO-THROUGH SIGNAL BUFFERING
*******************************/
always@(posedge clk_i) begin
  if (rstn_i == 1'b0) begin
    wb_ro <= 0;
    dest_addr_ro <= 0; 
  end
  else begin
    wb_ro <= wb_i; 
    dest_addr_ro <= dest_addr_i; 
  end
end


/*******************************
* ARITHMETIC CIRCUITS
*******************************/
// ripple-carry adder
ripple_carry_adder_Nb #(.N(`DATA_WIDTH)) ripple_carry_adder_32b_inst (
  .carry_i (1'b0),
  .opa_i   (op_a_i),
  .opb_i   (op_b_i),
  .inv_b_i (sel_i[3]),
  .res_o  (adder_res),
  .carry_o (adder_overflow)
);

assign and_res = op_a_i & op_b_i; // and
assign or_res = op_a_i | op_b_i;  // or
assign xor_res = op_a_i ^ op_b_i; // xor

// compare modules
less_than_sign_Nb #(.N(`DATA_WIDTH)) less_than_sign_32b_inst
(
  .a (op_a_i),
  .b (op_b_i),
  .r (less_than_sign_res)
);
less_than_unsign_Nb #(.N(`DATA_WIDTH)) less_than_unsign_32b_inst
(
  .a (op_a_i),
  .b (op_b_i),
  .r (less_than_unsign_res)
);
equality_Nb #(.N(`DATA_WIDTH)) equality_32b_inst
(
  .a (op_a_i),
  .b (op_b_i),
  .r (ops_eq_res)
);

// shifters
barrel_shifter_left_32b shifter_left_32b_inst
(
  .in    (op_a_i),
  .cntrl (op_b_i[5-1:0]),
  .out   (shifter_left_res)
);
barrel_shifter_right_32b shifter_right_32b_inst
(
  .in    (op_a_i),
  .cntrl (op_b_i[5-1:0]),
  .arith (sel_i[3]),   // Last bit of alu_op_sel_i selects between SRL and SRA instrucitons.
  .out   (shifter_right_res)
);


/*******************************
* RESULT MUXING
*******************************/
always@(*)
begin
  case (sel_i)
    `ALU_OP_ADD: begin
      res_w = adder_res; 
    end

    `ALU_OP_SUB: begin
      res_w = adder_res;
    end

    `ALU_OP_SLL: begin
      res_w = shifter_left_res; 
    end

    `ALU_OP_SLT: begin
      res_w = less_than_sign_res;
    end

    `ALU_OP_SLTU: begin
      res_w = less_than_unsign_res;
    end

    `ALU_OP_XOR: begin
      res_w = xor_res;
    end

    `ALU_OP_SRL: begin
      res_w = shifter_right_res;
    end

    `ALU_OP_SRA: begin
      res_w = shifter_right_res;
    end

    `ALU_OP_OR: begin
      res_w = or_res;
    end

    `ALU_OP_AND: begin
      res_w = and_res; 
    end

    default: begin 
      res_w = 32'b0;
    end
  endcase
end

endmodule

