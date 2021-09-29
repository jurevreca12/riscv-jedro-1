////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jure Vreča - jurevreca12@gmail.com                         //
//                                                                            //
//                                                                            //
//                                                                            //
// Design Name:    jedro_1_alu                                                //
// Project Name:   riscv-jedro-1                                              //
// Language:       Verilog                                                    //
//                                                                            //
// Description:    The arithmetic logic unit is defined here.                 //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

import jedro_1_defines.v::*;

module jedro_1_alu
(
  input clk_i,
  input rstn_i,

  input  [ALU_OP_WIDTH-1:0]   alu_op_sel_i,

  input  [DATA_WIDTH-1:0]     opa_i,
  input  [DATA_WIDTH-1:0]     opb_i,
  output [DATA_WIDTH-1:0]     res_o,
  output                      overflow_o,

  input [REG_ADDR_WIDTH-1:0]  reg_alu_dest_addr_i,
  output [REG_ADDR_WIDTH-1:0] reg_alu_dest_addr_o,
  
  input  alu_reg_wb_i,
  output alu_reg_wb_o
);


logic [DATA_WIDTH-1:0] adder_res;
logic [DATA_WIDTH-1:0] and_res;
logic [DATA_WIDTH-1:0] or_res;
logic [DATA_WIDTH-1:0] xor_res;
logic [DATA_WIDTH-1:0] less_than_sign_res;
logic [DATA_WIDTH-1:0] less_than_unsign_res;
logic [DATA_WIDTH-1:0] shifter_right_res;
logic [DATA_WIDTH-1:0] shifter_left_res;
logic adder_overflow;

// Ripple-carry adder
ripple_carry_adder_Nb #(.N(`DATA_WIDTH)) ripple_carry_adder_32b_inst (
  .carry_i (1'b0),
  .opa_i   (opa_i),
  .opb_i   (opb_i),
  .inv_b_i (alu_op_sel_i[3]),
  .res_o  (adder_res),
  .carry_o (adder_overflow)
);

// AND
assign and_res = opa_i & opb_i;

// OR
assign or_res = opa_i | opb_i;

// XOR
assign xor_res = opa_i ^ opb_i;

// Compare modules
less_than_sign_Nb #(.N(`DATA_WIDTH)) less_than_sign_32b_inst
(
  .a (opa_i),
  .b (opb_i),
  .r (less_than_sign_res)
);

less_than_unsign_Nb #(.N(`DATA_WIDTH)) less_than_unsign_32b_inst
(
  .a (opa_i),
  .b (opb_i),
  .r (less_than_unsign_res)
);


// SHIFTERS
barrel_shifter_left_32b shifter_left_32b_inst
(
  .in    (opa_i),
  .cntrl   (opb_i[5-1:0]),
  .out   (shifter_left_res)
);

barrel_shifter_right_32b shifter_right_32b_inst
(
  .in    (opa_i),
  .cntrl (opb_i[5-1:0]),
  .arith   (alu_op_sel_i[3]),   // Last bit of alu_op_sel_i selects between SRL and SRA instrucitons (its a hack I know)
  .out   (shifter_right_res)
);

always_ff@(posedge clk_i) begin
  if (rstn_i == 1'b0) begin
    overflow_o <= 0;
    alu_reg_wb_o <= 0;
    reg_alu_dest_addr_o <= 0; 
  end
  else begin
    overflow_o <= adder_overflow;
    alu_reg_wb_o <= alu_reg_wb_i; 
    reg_alu_dest_addr_o <= reg_alu_dest_addr_i; 
  end
end

// Result muxing
always_ff@(posedge clk_i)
begin
  if (rstn_i == 1'b0) begin
    res_o <= 0;
  end
  else begin
    case (alu_op_sel_i)
      `ALU_OP_ADD: begin
        res_o <= adder_res; 
      end

      `ALU_OP_SUB: begin
        res_o <= adder_res;
      end

      `ALU_OP_SLL: begin
        res_o <= shifter_left_res; 
      end

      `ALU_OP_SLT: begin
        res_o <= less_than_sign_res;
      end

      `ALU_OP_SLTU: begin
        res_o <= less_than_unsign_res;
      end

      `ALU_OP_XOR: begin
        res_o <= xor_res;
      end

      `ALU_OP_SRL: begin
        res_o <= shifter_right_res;
      end

      `ALU_OP_SRA: begin
        res_o <= shifter_right_res;
      end

      `ALU_OP_OR: begin
        res_o <= or_res;
      end

      `ALU_OP_AND: begin
        res_o <= and_res; 
      end

      default: begin 
        res_o <= 32'b0;
      end
    endcase
  end
end

endmodule
