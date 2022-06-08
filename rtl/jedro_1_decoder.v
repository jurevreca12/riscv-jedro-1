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
// Design Name:    jedro_1_decoder                                            //
// Project Name:   riscv-jedro-1                                              //
// Language:       System Verilog                                             //
//                                                                            //
// Description:    Decoder for the RV32I instructions.                        //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

`include "jedro_1_defines.v"

module jedro_1_decoder
(
  input wire clk_i,
  input wire rstn_i,

  // IFU INTERFACE
  input  wire [`DATA_WIDTH-1:0] instr_i,        // Instructions coming in from memory/cache
  input  wire [`DATA_WIDTH-1:0] instr_addr_i,
  output reg  [`DATA_WIDTH-1:0] instr_addr_ro,
  input  wire                  instr_valid_i,
  output reg                   use_pc_ro,
  output reg                   ready_ro,       // Ready for instructions.
  output reg                   jmp_instr_ro,
  output reg  [`DATA_WIDTH-1:0] jmp_addr_ro,
  output reg                   use_alu_jmp_addr_ro,

  // CONTROL UNIT INTERFACE
  output reg illegal_instr_ro, // Illegal instruction encountered.
  output reg ecall_ro,         // ecall instruction encountered
  output reg ebreak_ro,        // ebreak instruction encountered

  // ALU INTERFACE
  output reg                        is_alu_write_ro,    // Controls mux4-if RF WPC bellongs to ALU.
  output reg  [`ALU_OP_WIDTH-1:0]    alu_sel_ro,         // Select operation that ALU should perform.
  output reg  [`REG_ADDR_WIDTH-1:0]  alu_dest_addr_ro,  
  output reg                        alu_wb_ro,          // Writeback to the register?
  input  wire [`DATA_WIDTH-1:0]      alu_res_i,          // Writeback used for branch instr.
  input  wire                       alu_ops_eq_i,
  
  // REGISTER FILE INTERFACE  
  output reg  [`REG_ADDR_WIDTH-1:0]  rf_addr_a_ro,
  output reg  [`REG_ADDR_WIDTH-1:0]  rf_addr_b_ro,
  
  output reg                        is_imm_ro,   // Does the operation contain a immediate value?
  output reg  [`DATA_WIDTH-1:0]      imm_ext_ro,  // Sign extended immediate.

  // LSU INTERFACE
  output reg                        lsu_ctrl_valid_ro, 
  output reg  [`LSU_CTRL_WIDTH-1:0]  lsu_ctrl_ro,
  output reg  [`REG_ADDR_WIDTH-1:0]  lsu_regdest_ro,
  input  wire                       lsu_read_complete_i,

  // CSR INTERFACE
  output reg  [`CSR_ADDR_WIDTH-1:0]  csr_addr_ro,
  output reg                        csr_we_ro,
  input  wire [`DATA_WIDTH-1:0]      csr_data_i,
  output reg  [`CSR_UIMM_WIDTH-1:0]  csr_uimm_data_ro,
  output reg                        csr_uimm_we_ro,
  output reg  [`CSR_WMODE_WIDTH-1:0] csr_wmode_ro,
  output reg                        csr_mret_ro
);

/*************************************
* INTERNAL SIGNAL DEFINITION
*************************************/
reg                        use_alu_jmp_addr_w;
reg                        use_pc_w;
reg                        is_alu_write_w;
reg [`ALU_OP_WIDTH-1:0]    alu_sel_w;
reg                        alu_op_a_w;
reg                        alu_op_b_w;
reg [`REG_ADDR_WIDTH-1:0]  alu_dest_addr_w;
reg                        alu_wb_w;

reg                        illegal_instr_w;
reg                        ecall_w;
reg                        ebreak_w;

reg [`REG_ADDR_WIDTH-1:0]  rf_addr_a_w;
reg [`REG_ADDR_WIDTH-1:0]  rf_addr_b_w;

reg [`DATA_WIDTH-1:0]      imm_ext_w;

reg                        lsu_ctrl_valid_w;
reg [3:0]                  lsu_ctrl_w;
reg [`REG_ADDR_WIDTH-1:0]  lsu_regdest_w;

reg                        ready_w;
reg                        jmp_instr_w;
reg [`DATA_WIDTH-1:0]      jmp_addr_w;

reg [`CSR_ADDR_WIDTH-1:0]  csr_addr_w;
reg                        csr_we_w;
reg [`DATA_WIDTH-1:0]      csr_temp_r;
reg [`CSR_UIMM_WIDTH-1:0]  csr_uimm_data_w; 
reg                        csr_uimm_we_w;
reg [`CSR_WMODE_WIDTH-1:0] csr_wmode_w;
reg                        csr_mret_w;

reg [`DATA_WIDTH-1:0]      jmp_addr_save_r;

// Other signal definitions
wire [`DATA_WIDTH-1:0] I_imm_sign_extended_w;
wire [`DATA_WIDTH-1:0] I_shift_imm_sign_extended_w;
wire [`DATA_WIDTH-1:0] J_imm_sign_extended_w;
wire [`DATA_WIDTH-1:0] B_imm_sign_extended_w;
wire [`DATA_WIDTH-1:0] S_imm_sign_extended_w;

// For generating stalling logic
reg [`REG_ADDR_WIDTH-1:0] prev_dest_addr;


// FSM signals
localparam eOK                 = 41'b00000000000000000000000000000000000000001; 
localparam eSTALL              = 41'b00000000000000000000000000000000000000010;
localparam eJAL_JMP_ADDR_CALC  = 41'b00000000000000000000000000000000000000100;
localparam eJAL_WAIT_1         = 41'b00000000000000000000000000000000000001000;
localparam eJAL_WRITE_RF_JMP   = 41'b00000000000000000000000000000000000010000;
localparam eJAL_WAIT_2         = 41'b00000000000000000000000000000000000100000;
localparam eJALR_JMP_ADDR_CALC = 41'b00000000000000000000000000000000001000000;
localparam eJALR_WAIT_1        = 41'b00000000000000000000000000000000010000000;
localparam eJALR_PC_CALC       = 41'b00000000000000000000000000000000100000000;
localparam eJALR_JMP           = 41'b00000000000000000000000000000001000000000;
localparam eJALR_WAIT_2        = 41'b00000000000000000000000000000010000000000;
localparam eBRANCH_CALC_COND   = 41'b00000000000000000000000000000100000000000;
localparam eBRANCH_CALC_ADDR   = 41'b00000000000000000000000000001000000000000;
localparam eBRANCH_STALL       = 41'b00000000000000000000000000010000000000000;
localparam eBRANCH_JUMP        = 41'b00000000000000000000000000100000000000000;
localparam eBRANCH_STALL_2     = 41'b00000000000000000000000001000000000000000;
localparam eLSU_CALC_ADDR      = 41'b00000000000000000000000010000000000000000;
localparam eLSU_STORE          = 41'b00000000000000000000000100000000000000000;
localparam eLSU_LOAD_CALC_ADDR = 41'b00000000000000000000001000000000000000000;
localparam eLSU_LOAD           = 41'b00000000000000000000010000000000000000000;
localparam eLSU_LOAD_WAIT      = 41'b00000000000000000000100000000000000000000;
localparam eCSRRW_READ_CSR     = 41'b00000000000000000001000000000000000000000;
localparam eCSRRW_READ_WAIT_0  = 41'b00000000000000000010000000000000000000000;
localparam eCSRRW_READ_WAIT_1  = 41'b00000000000000000100000000000000000000000;
localparam eCSRRW_WRITE_CSR    = 41'b00000000000000001000000000000000000000000;
localparam eCSRRW_WRITE_RF     = 41'b00000000000000010000000000000000000000000;
localparam eCSRRSC_READ_CSR    = 41'b00000000000000100000000000000000000000000;
localparam eCSRRSC_READ_WAIT_0 = 41'b00000000000001000000000000000000000000000;
localparam eCSRRSC_READ_WAIT_1 = 41'b00000000000010000000000000000000000000000;
localparam eCSRRSC_WRITE_CSR   = 41'b00000000000100000000000000000000000000000;
localparam eCSRRSC_WRITE_RF    = 41'b00000000001000000000000000000000000000000;
localparam eMRET               = 41'b00000000010000000000000000000000000000000;
localparam eMRET_WAIT          = 41'b00000000100000000000000000000000000000000;
localparam eCALL_SET_ADDR      = 41'b00000001000000000000000000000000000000000;
localparam eCALL               = 41'b00000010000000000000000000000000000000000;
localparam eCALL_WAIT          = 41'b00000100000000000000000000000000000000000;
localparam eBREAK_SET_ADDR     = 41'b00001000000000000000000000000000000000000;
localparam eBREAK              = 41'b00010000000000000000000000000000000000000;
localparam eBREAK_WAIT         = 41'b00100000000000000000000000000000000000000;
localparam eERROR              = 41'b01000000000000000000000000000000000000000;
localparam eINSTR_NOT_VALID    = 41'b10000000000000000000000000000000000000000;

reg  [40:0] state, next;

// Helpfull shorthands for sections of the instruction (see riscv specifications)
wire [6:0]   opcode; 
wire [11:7]  regdest;  
wire [31:12] imm31_12; // U-type immediate 
wire [31:20] imm11_0; // I-type immediate
wire [14:12] funct3;
wire [19:15] regs1;
wire [24:20] regs2;


/*************************************
* RISC-V INSTRUCTION PART SHORTHANDS
*************************************/
assign opcode   = instr_i[6:0];
assign regdest  = instr_i[11:7];
assign imm31_12 = instr_i[31:12]; // U-type immediate 
assign imm11_0  = instr_i[31:20]; // I-type immediate
assign funct3   = instr_i[14:12];
assign regs1    = instr_i[19:15];
assign regs2    = instr_i[24:20];


/*************************************
* BUFFER INSTR ADDR
*************************************/
always @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        instr_addr_ro <= 32'b0;
    end
    else begin
        instr_addr_ro <= instr_addr_i;
    end
end


/*************************************
* FSM UPDATE
*************************************/
always@(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        state <= eOK;
    end
    else begin
        state <= next;
    end
end


/*************************************
* PREVIOUS DESTINATION SAVING
*************************************/
// We save the previous destination register address to see if we need to generate stalls.
always@(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        prev_dest_addr <= 5'b00000;
    end
    else begin
       if (opcode == `OPCODE_BRANCH) begin
            prev_dest_addr <= 5'b00000;
        end
        else begin
            prev_dest_addr <= regdest;
        end 
    end
end


/*************************************
* SAVING THE CALCULATED JUMP ADDRESS
*************************************/
always @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        jmp_addr_save_r <= 0;
    end
    else begin
        if (state == eJALR_WAIT_1) begin
            jmp_addr_save_r <= {alu_res_i[31:1], 1'b0};
        end
        else begin
            jmp_addr_save_r <= jmp_addr_save_r;
        end
    end
end

/*************************************
* SIGN EXTENDERS
*************************************/
// For the I instruction type immediate
sign_extender #(.N(`DATA_WIDTH), .M(12)) sign_extender_I_inst (.in_i(imm11_0),
                                                              .out_o(I_imm_sign_extended_w));
// Used in shift instructions
sign_extender #(.N(`DATA_WIDTH), .M(5))  sign_extender_I_shift_inst(.in_i(imm11_0[24:20]),
                                                                  .out_o(I_shift_imm_sign_extended_w));
// For the J instruction type immediate
sign_extender #(.N(`DATA_WIDTH), .M(21)) sign_extender_J_inst (.in_i({instr_i[31], 
                                                                     instr_i[19:12], 
                                                                     instr_i[20], 
                                                                     instr_i[30:21], 
                                                                     1'b0}),
                                                               .out_o(J_imm_sign_extended_w)
                                                             );

// For the B instruction type immediate
sign_extender #(.N(`DATA_WIDTH), .M(13)) sign_extender_B_inst (.in_i({instr_i[31], 
                                                                     instr_i[7], 
                                                                     instr_i[30:25], 
                                                                     instr_i[11:8], 
                                                                     1'b0}),
                                                              .out_o(B_imm_sign_extended_w));

// For the S instruction type immediate
sign_extender #(.N(`DATA_WIDTH), .M(12)) sign_extender_S_inst (.in_i({instr_i[31:25], 
                                                                     instr_i[11:7]}),
                                                              .out_o(S_imm_sign_extended_w));


/*************************************
* CSR temporary register reading logic
*************************************/
always @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        csr_temp_r <= 0;
    end
    else begin
        if (next == eCSRRW_READ_WAIT_1 || next == eCSRRSC_READ_WAIT_1) 
            csr_temp_r <= csr_data_i;
        else 
            csr_temp_r <= csr_temp_r;
    end
end

/*************************************
* DECODER - SYNCHRONOUS LOGIC
*************************************/
always@(posedge clk_i) begin
  if (rstn_i == 1'b0) begin
    use_alu_jmp_addr_ro <= 0;
    use_pc_ro <= 0;
    illegal_instr_ro <= 0;
    ecall_ro <= 0;
    ebreak_ro <= 0;
    is_alu_write_ro <= 1'b1;
    alu_sel_ro <= 0;
    alu_dest_addr_ro <= 0;
    alu_wb_ro <= 0;
    rf_addr_a_ro <= 0;
    rf_addr_b_ro <= 0;
    is_imm_ro <= 0;
    imm_ext_ro <= 0;
    lsu_ctrl_valid_ro <= 0;
    lsu_ctrl_ro <= 0;
    lsu_regdest_ro <= 0;
    ready_ro <= 1'b1;
    jmp_instr_ro <= 1'b0;
    jmp_addr_ro <= 0;
    csr_addr_ro <= 0;
    csr_uimm_data_ro <= 0;
    csr_we_ro <= 0;
    csr_uimm_we_ro <= 0;
    csr_wmode_ro <= 0;
    csr_mret_ro <= 0;
  end
  else begin
    use_alu_jmp_addr_ro <= use_alu_jmp_addr_w;
    use_pc_ro <= use_pc_w;
    illegal_instr_ro <= illegal_instr_w;
    ecall_ro <= ecall_w;
    ebreak_ro <= ebreak_w;
    is_alu_write_ro <= is_alu_write_w;
    alu_sel_ro <= alu_sel_w;
    alu_dest_addr_ro <= alu_dest_addr_w;
    alu_wb_ro <= alu_wb_w;
    rf_addr_a_ro <= rf_addr_a_w;
    rf_addr_b_ro <= rf_addr_b_w;
    is_imm_ro <= ~(alu_op_a_w & alu_op_b_w);
    imm_ext_ro <= imm_ext_w;
    lsu_ctrl_valid_ro <= lsu_ctrl_valid_w;
    lsu_ctrl_ro <= lsu_ctrl_w;
    lsu_regdest_ro <= lsu_regdest_w;
    ready_ro <= ready_w;
    jmp_instr_ro <= jmp_instr_w;
    jmp_addr_ro <= jmp_addr_w;
    csr_addr_ro <= csr_addr_w;
    csr_uimm_data_ro <= csr_uimm_data_w;
    csr_we_ro <= csr_we_w;
    csr_uimm_we_ro <= csr_uimm_we_w;
    csr_wmode_ro <= csr_wmode_w;
    csr_mret_ro <= csr_mret_w;
  end
end


/*************************************
* DECODER - COMBINATIONAL LOGIC
*************************************/
always@(*)
begin 
  use_alu_jmp_addr_w  = 1'b0;
  use_pc_w            = 1'b0;
  illegal_instr_w     = 1'b0;
  ecall_w             = 1'b0;
  ebreak_w            = 1'b0;
  is_alu_write_w      = 1'b0;
  alu_sel_w           = 4'b0000;
  alu_op_a_w          = 1'b0;
  alu_op_b_w          = 1'b0;
  alu_dest_addr_w     = 5'b0;
  alu_wb_w            = 1'b0; 
  rf_addr_a_w         = 5'b00000;
  rf_addr_b_w         = 5'b00000;
  imm_ext_w           = 0; 
  lsu_ctrl_valid_w    = 1'b0;
  lsu_ctrl_w          = 4'b0000;
  lsu_regdest_w       = 5'b00000;
  ready_w             = 1'b1;
  jmp_instr_w         = 1'b0;
  jmp_addr_w          = 0;
  csr_addr_w          = 0;
  csr_we_w            = 0;
  csr_uimm_data_w     = 0;
  csr_uimm_we_w       = 0;
  csr_wmode_w         = `CSR_WMODE_NORMAL;
  csr_mret_w          = 0;
  next                = eERROR;

  casez ({instr_valid_i, opcode})
    {1'b1, `OPCODE_LOAD}: begin
        alu_sel_w          = `ALU_OP_ADD;
        rf_addr_a_w        = regs1;
        lsu_ctrl_w         = {opcode[5], funct3};
        lsu_regdest_w      = regdest;
        if (regs1 == prev_dest_addr &&
            regs1 != 0 && 
            state != eSTALL &&
            state != eLSU_LOAD_CALC_ADDR &&
            state != eLSU_LOAD &&
            state != eLSU_LOAD_WAIT) begin
            next             = eSTALL;
            alu_op_a_w       = 1'b0;
            imm_ext_w        = 0;
            ready_w          = 1'b0;
        end
        else if((state != eLSU_LOAD_CALC_ADDR &&
                 state != eLSU_LOAD &&
                 state != eLSU_LOAD_WAIT) ||
                 (state == eLSU_LOAD_WAIT && // Condition for when we have 2 consequtive load ops
                  ready_ro && instr_valid_i)) begin
            next             = eLSU_LOAD_CALC_ADDR;
            alu_op_a_w       = 1'b1;
            imm_ext_w        = I_imm_sign_extended_w;
            ready_w          = 1'b0;
        end
        else if (state == eLSU_LOAD_CALC_ADDR) begin
            next             = eLSU_LOAD;
            alu_op_a_w       = 1'b0;
            imm_ext_w        = 0;
            lsu_ctrl_valid_w = 1'b1;
            ready_w          = 1'b0;
        end
        else begin
            next             = eLSU_LOAD_WAIT;
            alu_op_a_w       = 1'b0;
            imm_ext_w        = 0;
            ready_w          = lsu_read_complete_i;
        end
    end

    {1'b1, `OPCODE_MISCMEM}: begin 
        next = eOK;
        ready_w = 1'b1;
    end

    {1'b1, `OPCODE_OPIMM}: begin
        is_alu_write_w     = 1'b1;
        alu_op_a_w         = 1'b1;
        alu_dest_addr_w    = regdest;
        rf_addr_a_w        = regs1;
        if (funct3 == `FUNCT3_SHIFT_INSTR && 
           (imm11_0[31:25] == 0 || imm11_0[31:25] == 7'b0100000)) begin
            imm_ext_w = I_shift_imm_sign_extended_w;
            alu_sel_w = {instr_i[30], funct3};
        end
        else begin
            imm_ext_w = I_imm_sign_extended_w;
            alu_sel_w = {1'b0, funct3};
        end
        if (regs1 == prev_dest_addr && regs1 != 0 && state != eSTALL) begin
            next     = eSTALL;
            alu_wb_w = 1'b0; 
            ready_w  = 1'b0;
        end
        else begin
            next     = eOK;
            alu_wb_w = 1'b1; 
            ready_w  = 1'b1;
        end
    end

    {1'b1, `OPCODE_AUIPC}: begin
        use_pc_w           = 1'b1;
        is_alu_write_w     = 1'b1;
        alu_sel_w          = `ALU_OP_ADD;
        alu_op_a_w         = 1'b1;
        alu_dest_addr_w    = regdest;
        alu_wb_w           = 1'b1; 
        imm_ext_w          = {imm31_12, 12'b0000_0000_0000};
        ready_w            = 1'b1;
        next               = eOK;
    end

    {1'b1, `OPCODE_STORE}: begin
        alu_sel_w          = `ALU_OP_ADD;
        rf_addr_a_w        = regs1;
        rf_addr_b_w        = regs2;
        if (((regs1 == prev_dest_addr && regs1 != 0) ||
             (regs2 == prev_dest_addr && regs2 != 0)) && 
              (state != eSTALL && 
              state != eLSU_CALC_ADDR)) begin
            next             = eSTALL;
            alu_op_a_w       = 1'b0;
            alu_op_b_w       = 1'b0;
            imm_ext_w        = 0;
            lsu_ctrl_valid_w = 1'b0;
            lsu_ctrl_w       = 4'b0000;
            ready_w          = 1'b0;
        end
        else if (state != eLSU_CALC_ADDR) begin
            next             = eLSU_CALC_ADDR;
            alu_op_a_w       = 1'b1;
            alu_op_b_w       = 1'b0;
            imm_ext_w        = S_imm_sign_extended_w;
            lsu_ctrl_valid_w = 1'b0;
            lsu_ctrl_w       = 4'b0000;
            ready_w          = 1'b0;
        end
        else begin
            next             = eLSU_STORE;
            alu_op_a_w       = 1'b0;
            alu_op_b_w       = 1'b1;
            imm_ext_w        = 0;
            lsu_ctrl_valid_w = 1'b1;
            lsu_ctrl_w       = {opcode[5], funct3};
            ready_w          = 1'b1;
        end
    end
    
    {1'b1, `OPCODE_OP}: begin
        is_alu_write_w     = 1'b1;
        alu_sel_w          = {instr_i[30], funct3};
        alu_op_a_w         = 1'b1;
        alu_op_b_w         = 1'b1;
        alu_dest_addr_w    = regdest;
        rf_addr_a_w        = regs1;
        rf_addr_b_w        = regs2;
        if (((regs1 == prev_dest_addr && regs1 != 0 ) || 
            (regs2 == prev_dest_addr && regs2 != 0 )) &&
             state != eSTALL) begin
            next = eSTALL;
            alu_wb_w   = 1'b0;
            ready_w    = 1'b0; 
        end
        else begin
            next = eOK;
            alu_wb_w   = 1'b1; 
            ready_w    = 1'b1; 
        end
    end

    {1'b1, `OPCODE_LUI}: begin
        is_alu_write_w     = 1'b1;
        alu_sel_w          = `ALU_OP_ADD;
        alu_op_a_w         = 1'b1;
        alu_dest_addr_w    = regdest;
        alu_wb_w           = 1'b1; 
        imm_ext_w          = {imm31_12, 12'b0000_0000_0000};
        ready_w            = 1'b1;
        next               = eOK;
    end

    {1'b1, `OPCODE_BRANCH}: begin
        // First cycle of all branch instructions calcules the condition, 
        // the second cycle calculates the jump address, the third cycle
        // stalls and finally if the condition holds, the fourth cycle jumps
        // the fifth cycle is another stall.
        if (((regs1 == prev_dest_addr && regs1 != 0 ) || 
            (regs2 == prev_dest_addr && regs2 != 0 )) &&
             state != eBRANCH_CALC_COND &&
             state != eBRANCH_CALC_ADDR &&
             state != eBRANCH_STALL &&
             state != eBRANCH_JUMP &&
             state != eBRANCH_STALL_2 &&
             state != eSTALL) begin
            use_alu_jmp_addr_w = 1'b0;
            use_pc_w           = 1'b0;
            alu_sel_w          = 4'b0000;
            alu_op_a_w         = 1'b0;
            alu_op_b_w         = 1'b0;
            rf_addr_a_w        = 5'b00000;
            rf_addr_b_w        = 5'b00000;
            imm_ext_w          = 0;   
            ready_w            = 1'b0; 
            next               = eSTALL;
        end
        else if (state != eBRANCH_CALC_COND &&
                 state != eBRANCH_CALC_ADDR &&
                 state != eBRANCH_STALL &&
                 state != eBRANCH_JUMP &&
                 state != eBRANCH_STALL_2) begin
            use_alu_jmp_addr_w = 1'b0;
            use_pc_w           = 1'b0;
            alu_sel_w          = {2'b00, funct3[14:13]};
            alu_op_a_w         = 1'b1;
            alu_op_b_w         = 1'b1;
            if (funct3[12] == 1'b0) begin 
                rf_addr_a_w = regs1;
                rf_addr_b_w = regs2;
            end
            else begin
                rf_addr_a_w = regs2;
                rf_addr_b_w = regs1;
            end
            imm_ext_w          = 0;   
            ready_w            = 1'b0; 
            next               = eBRANCH_CALC_COND;
        end
        else if (state == eBRANCH_CALC_COND) begin
            use_alu_jmp_addr_w = 1'b0;
            use_pc_w           = 1'b1;
            alu_sel_w          = `ALU_OP_ADD;
            alu_op_a_w         = 1'b0;
            alu_op_b_w         = 1'b0;
            rf_addr_a_w        = regs1;
            rf_addr_b_w        = regs2;
            imm_ext_w          = B_imm_sign_extended_w;   
            ready_w            = 1'b0; 
            next               = eBRANCH_CALC_ADDR;
        end
        else if (state == eBRANCH_CALC_ADDR) begin
            use_alu_jmp_addr_w = 1'b0;
            use_pc_w           = 1'b1;
            alu_sel_w          = `ALU_OP_ADD;
            alu_op_a_w         = 1'b0;
            alu_op_b_w         = 1'b0;
            rf_addr_a_w        = regs1;
            rf_addr_b_w        = regs2;
            imm_ext_w          = B_imm_sign_extended_w; 
            ready_w            = 1'b0; 
            if (funct3 != 3'b000 && funct3 != 3'b001 && alu_res_i == 1 ||
               ((funct3 == 3'b101 || funct3 == 3'b111) && alu_ops_eq_i == 1'b1) ||
               (funct3 == 3'b000 && alu_ops_eq_i == 1'b1) ||
               (funct3 == 3'b001 && alu_ops_eq_i == 1'b0)) begin
                next = eBRANCH_STALL;
            end
            else begin
                next = eBRANCH_STALL_2;
            end
        end
        else if (state == eBRANCH_STALL) begin
            use_alu_jmp_addr_w = 1'b1;
            use_pc_w           = 1'b0; 
            alu_sel_w          = 4'b0000;
            alu_op_a_w         = 1'b0;
            alu_op_b_w         = 1'b0;
            rf_addr_a_w        = 5'b00000;
            rf_addr_b_w        = 5'b00000;
            imm_ext_w          = 0;   
            ready_w            = 1'b0; 
            next               = eBRANCH_JUMP;
        end
        else begin
            use_alu_jmp_addr_w = 1'b0;
            use_pc_w           = 1'b0; 
            alu_sel_w          = 4'b0000;
            alu_op_a_w         = 1'b0;
            alu_op_b_w         = 1'b0;
            rf_addr_a_w        = 5'b00000;
            rf_addr_b_w        = 5'b00000;
            imm_ext_w          = 0;   
            ready_w            = 1'b1; 
            next               = eBRANCH_STALL_2;
        end
    end

    {1'b1, `OPCODE_JALR}: begin
        // First cycle of JALR instr calculates pc+4 and stores it to rd,
        // in the next cycle the offset is calculated. This way stalls are
        // impossible, as we only use regs1 in the second cycle (instr can
        // be delayed at most 1 cycle). The third cycle takes the jump.
        is_alu_write_w     = 1'b1;
        alu_sel_w          = `ALU_OP_ADD;
        if ((regs1 == prev_dest_addr && regs1 != 0) &&
             state != eJALR_JMP_ADDR_CALC &&
             state != eJALR_WAIT_1 &&
             state != eJALR_PC_CALC &&
             state != eJALR_JMP &&
             state != eJALR_WAIT_2 &&
             state != eSTALL) begin
            use_pc_w           = 1'b0;
            alu_op_a_w         = 1'b0;
            alu_dest_addr_w    = 5'b00000;
            alu_wb_w           = 1'b0; 
            rf_addr_a_w        = 5'b00000;
            imm_ext_w          = 0;   
            ready_w            = 1'b0; 
            next               = eSTALL;
        end
        else if (state != eJALR_JMP_ADDR_CALC &&
            state != eJALR_WAIT_1 &&
            state != eJALR_PC_CALC &&
            state != eJALR_JMP &&
            state != eJALR_WAIT_2) begin
            use_pc_w           = 1'b0; 
            alu_op_a_w         = 1'b1;
            alu_dest_addr_w    = 5'b00000;
            alu_wb_w           = 1'b0; 
            rf_addr_a_w        = regs1;
            imm_ext_w          = I_imm_sign_extended_w;   
            ready_w            = 1'b0; 
            next               = eJALR_JMP_ADDR_CALC;
        end
        else if (state == eJALR_JMP_ADDR_CALC) begin
            ready_w = 1'b0;
            next    = eJALR_WAIT_1;
        end
        else if (state == eJALR_WAIT_1) begin
            use_pc_w           = 1'b1;
            alu_op_a_w         = 1'b0;
            alu_dest_addr_w    = regdest;
            alu_wb_w           = ~alu_res_i[1]; // proper alignment check
            rf_addr_a_w        = 5'b00000;
            imm_ext_w          = 32'b00000000_00000000_00000000_00000100; // pc + 4 
            ready_w            = 1'b0; 
            next               = eJALR_PC_CALC;
        end
        else if (state == eJALR_PC_CALC) begin
            jmp_instr_w        = 1'b1;
            jmp_addr_w         = jmp_addr_save_r;
            use_pc_w           = 1'b0; 
            alu_op_a_w         = 1'b0;
            alu_dest_addr_w    = 5'b00000;
            alu_wb_w           = 1'b0; 
            rf_addr_a_w        = 5'b00000;
            imm_ext_w          = I_imm_sign_extended_w;   
            ready_w            = 1'b0; 
            next               = eJALR_JMP;
        end
        else begin
            ready_w = 0;
            next = eJALR_WAIT_2;
        end
    end

    {1'b1, `OPCODE_JAL}: begin
        is_alu_write_w     = 1'b1;
        alu_sel_w          = `ALU_OP_ADD;
        use_pc_w           = 1'b1;
        if (state != eJAL_JMP_ADDR_CALC &&
            state != eJAL_WAIT_1 &&
            state != eJAL_WRITE_RF_JMP &&
            state != eJAL_WAIT_2) begin
            imm_ext_w = J_imm_sign_extended_w;  
            alu_wb_w  = 1'b1;
            ready_w   = 1'b0;
            next      = eJAL_JMP_ADDR_CALC;
        end
        else if (state == eJAL_JMP_ADDR_CALC) begin
            ready_w = 1'b0;
            next = eJAL_WAIT_1;
        end
        else if (state == eJAL_WAIT_1) begin
            alu_wb_w        = ~alu_res_i[1];
            imm_ext_w       = 32'b00000000_00000000_00000000_00000100;  
            alu_dest_addr_w = regdest;
            jmp_instr_w     = 1'b1;
            jmp_addr_w      = {alu_res_i[31:1],1'b0};
            ready_w         = 1'b0;
            next            = eJAL_WRITE_RF_JMP;
        end
        else begin
            ready_w = 1'b1;
            next = eJAL_WAIT_2;
        end
    end

    {1'b1, `OPCODE_SYSTEM}: begin
        if (funct3 != 3'b000) begin // CSR INSTRUCTIONS
            if (funct3 == `CSRRW_INSTR_FUNCT3  |
                funct3 == `CSRRWI_INSTR_FUNCT3) begin // CSRRW and CSRRWI instructions
                csr_addr_w = imm11_0;
                if (state != eCSRRW_READ_CSR &&
                    state != eCSRRW_READ_WAIT_0 &&
                    state != eCSRRW_READ_WAIT_1 &&
                    state != eCSRRW_WRITE_CSR &&
                    regdest != 5'b00000) begin
                    next = eCSRRW_READ_CSR;
                    ready_w    = 1'b0;
                end
                else if (state == eCSRRW_READ_CSR) begin
                    next = eCSRRW_READ_WAIT_0;
                    ready_w = 1'b0;
                end
                else if (state == eCSRRW_READ_WAIT_0) begin
                    // csr read result gets stored into csr_temp_r here
                    next = eCSRRW_READ_WAIT_1;
                    ready_w = 1'b0;
                end
                else if (regdest == 5'b00000 &&
                         prev_dest_addr == regs1) begin
                    next = eSTALL;
                    ready_w = 1'b0;
                end
                else if (state == eCSRRW_READ_WAIT_1 ||
                         regdest == 5'b00000) begin
                    if (funct3 == `CSRRW_INSTR_FUNCT3) begin
                        rf_addr_a_w = regs1;
                        alu_op_a_w = 1'b1;
                        csr_we_w   = 1'b1;
                    end
                    else begin // funct3 == CSRRWI
                        csr_uimm_data_w = regs1; // regs1 encodes the uimm 
                        csr_uimm_we_w   = 1'b1;
                    end
                    next = eCSRRW_WRITE_CSR;
                    if (regdest == 5'b00000)
                        ready_w = 1'b1;
                    else
                        ready_w = 1'b0;
                end
                else begin
                    alu_op_a_w  = 1'b1;
                    rf_addr_a_w = 5'b00000;                                   
                    is_alu_write_w  = 1'b1;
                    alu_sel_w       = `ALU_OP_ADD;
                    alu_dest_addr_w = regdest;
                    alu_wb_w        = 1'b1;
                    imm_ext_w       = csr_temp_r;
                    next            = eCSRRW_WRITE_RF;
                    ready_w         = 1'b1;
                end

            end
            else begin // CSRRS/I and CSRRC/I instructions
                csr_addr_w = imm11_0;
                if (state != eCSRRSC_READ_CSR &&
                    state != eCSRRSC_READ_WAIT_0 &&
                    state != eCSRRSC_READ_WAIT_1 &&
                    state != eCSRRSC_WRITE_CSR) begin
                    next = eCSRRSC_READ_CSR;
                    ready_w = 1'b0;
                end
                else if (state == eCSRRSC_READ_CSR) begin
                    next = eCSRRSC_READ_WAIT_0;
                    ready_w = 1'b0;
                end
                else if (state == eCSRRSC_READ_WAIT_0) begin
                    next = eCSRRSC_READ_WAIT_1;
                    ready_w = 1'b0;
                end
                else if (state == eCSRRSC_READ_WAIT_1 &&
                         regs1 != 5'b00000) begin
                    if (funct3[12] == 1'b0)
                        csr_wmode_w = `CSR_WMODE_SET_BITS;
                    else
                        csr_wmode_w = `CSR_WMODE_CLEAR_BITS;
                    
                    if (funct3[14] == 1'b0) begin // register form
                        alu_op_a_w = 1'b1;
                        rf_addr_a_w = regs1;
                        csr_we_w = 1'b1;
                    end
                    else begin // immidiate form
                        csr_uimm_data_w = regs1;
                        csr_uimm_we_w = 1'b1;
                    end
                    next = eCSRRSC_WRITE_CSR;
                    ready_w = 1'b0;
                end 
                else begin
                    alu_op_a_w  = 1'b1;
                    rf_addr_a_w = 5'b00000;
                    is_alu_write_w  = 1'b1;
                    alu_sel_w       = `ALU_OP_ADD;
                    alu_dest_addr_w = regdest;
                    alu_wb_w        = 1'b1;
                    imm_ext_w       = csr_temp_r;
                    next            = eCSRRSC_WRITE_RF;
                    ready_w         = 1'b1;
                end 
            end
        end
        else begin // Other instructions
            if (instr_i == `MRET_INSTR) begin
                if (state != eMRET && state != eMRET_WAIT) begin
                    csr_mret_w = 1'b1;
                    ready_w    = 1'b0;
                    next       = eMRET;
                end
                else begin
                    csr_mret_w = 1'b0;
                    ready_w    = 1'b1;
                    next       = eMRET_WAIT;
                end
            end
            else if (instr_i == `ECALL_INSTR) begin
                if (state != eCALL_SET_ADDR &&
                    state != eCALL &&
                    state != eCALL_WAIT) begin
                    ready_w = 0;
                    next = eCALL_SET_ADDR;
                end
                else if (state == eCALL_SET_ADDR) begin
                    ecall_w = 1;
                    ready_w = 0;
                    next    = eCALL;
                end
                else begin
                    ready_w = 0;
                    next    = eCALL_WAIT;
                end
            end
            else if (instr_i == `EBREAK_INSTR) begin
                if (state != eBREAK_SET_ADDR &&
                    state != eBREAK &&
                    state != eBREAK_WAIT) begin
                    ready_w = 0;
                    next = eBREAK_SET_ADDR;
                end
                else if (state == eBREAK_SET_ADDR) begin
                    ebreak_w = 1;
                    ready_w = 0;
                    next = eBREAK;
                end
                else begin
                    ready_w = 0;
                    next = eBREAK_WAIT;
                end
            end
            else if (instr_i == `WFI_INSTR) begin
                ready_w = 1'b1;
                next = eOK;
            end
            else begin
                ready_w         = 1'b0;
                illegal_instr_w = 1'b1;
                next            = eERROR;
            end
        end
    end

    {1'b0, 7'b???????}: begin
        ready_w            = 1'b1;
        illegal_instr_w    = 1'b0;
        next               = eINSTR_NOT_VALID;
    end 

    default: begin
        use_alu_jmp_addr_w = 1'b0;
        use_pc_w           = 1'b0;
        illegal_instr_w    = 1'b1;
        is_alu_write_w     = 1'b0;
        alu_sel_w          = 4'b0000;
        alu_op_a_w         = 1'b0;
        alu_op_b_w         = 1'b0;
        alu_dest_addr_w    = 5'b0;
        alu_wb_w           = 1'b0; 
        rf_addr_a_w        = 5'b00000;
        rf_addr_b_w        = 5'b00000;
        imm_ext_w          = 0;   
        lsu_ctrl_valid_w   = 1'b0;
        lsu_ctrl_w         = 4'b0000;
        lsu_regdest_w      = 5'b00000;
        csr_mret_w         = 0;
        ready_w            = 1'b0;
        jmp_instr_w        = 1'b0;
        jmp_addr_w         = 0;
        next               = eERROR;
    end
  endcase
end

endmodule // jedro_1_decoder
