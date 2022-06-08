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
// Design Name:    jedro_1_top                                                //
// Project Name:   riscv-jedro-1                                              //
// Language:       System Verilog                                             //
//                                                                            //
// Description:    The top file of the jedro_1 riscv core.                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
  
`include "jedro_1_defines.v"

module jedro_1_top #(
    parameter JEDRO_1_BOOT_ADDR = `JEDRO_1_BOOT_ADDR
)
(
  input wire clk_i,
  input wire rstn_i,

  // Interface to the ROM memory
  output wire [`DATA_WIDTH-1:0]  iram_addr,
  input wire  [`DATA_WIDTH-1:0]  iram_rdata,

  // Interface to data RAM
  output wire [3:0]                 dram_we,
  output wire                       dram_stb,
  output wire [`DATA_WIDTH-1:0]     dram_addr,
  output wire [`DATA_WIDTH-1:0]     dram_wdata,
  input  wire [`DATA_WIDTH-1:0]     dram_rdata,
  input  wire                       dram_ack,
  input  wire                       dram_err

 // IRQ/Debug interface TODO

);

/****************************************
* SIGNAL DECLARATION
****************************************/
wire                        ifu_decoder_instr_valid;
wire [`DATA_WIDTH-1:0]      ifu_decoder_instr_addr;
wire [`DATA_WIDTH-1:0]      ifu_decoder_instr;
reg  [`DATA_WIDTH-1:0]      mux3_ifu_jmp_addr;
wire                        decoder_ifu_ready; 
wire                        decoder_ifu_jmp_instr;
wire [`DATA_WIDTH-1:0]      decoder_ifu_jmp_addr;
wire                        decoder_mux3_use_alu_jmp_addr;
wire [`ALU_OP_WIDTH-1:0]    decoder_alu_sel;
wire [`REG_ADDR_WIDTH-1:0]  decoder_alu_dest_addr;
wire                        decoder_alu_wb;
wire [`REG_ADDR_WIDTH-1:0]  decoder_rf_addr_a;
wire [`REG_ADDR_WIDTH-1:0]  decoder_rf_addr_b;
wire [`DATA_WIDTH-1:0]      decoder_mux_imm_ex;
wire                        decoder_mux_is_imm;
wire [`DATA_WIDTH-1:0]      decoder_mux2_instr_addr;
reg  [`DATA_WIDTH-1:0]      decoder_1_mux2_instr_addr;
wire                        decoder_mux2_use_pc;
wire [`CSR_ADDR_WIDTH-1:0]  decoder_csr_addr;
wire [`DATA_WIDTH-1:0]      csr_decoder_data;
wire                        decoder_csr_we;
wire [`CSR_UIMM_WIDTH-1:0]  decoder_csr_uimm;
wire                        decoder_csr_uimm_we;
wire [`CSR_WMODE_WIDTH-1:0] decoder_csr_wmode;
wire                        decoder_csr_mret;
wire                        decoder_csr_illegal_instr;
wire                        decoder_csr_ecall;
wire                        decoder_csr_ebreak;
wire [`DATA_WIDTH-1:0]      alu_mux4_res;
wire [`REG_ADDR_WIDTH-1:0]  alu_mux4_dest_addr;
wire                        alu_mux4_wb;
wire                        alu_decoder_ops_eq;
wire [`DATA_WIDTH-1:0]      rf_alu_data_a;
wire [`DATA_WIDTH-1:0]      rf_alu_data_b;
wire [`DATA_WIDTH-1:0]      mux_alu_op_b;
wire [`DATA_WIDTH-1:0]      mux2_alu_op_a;
wire                        decoder_lsu_ctrl_valid;
wire [`LSU_CTRL_WIDTH-1:0]  decoder_lsu_ctrl;
wire [`REG_ADDR_WIDTH-1:0]  decoder_lsu_regdest;
reg                         decoder_1_mux4_is_alu_write;
wire                        decoder_mux4_is_alu_write;
wire [`DATA_WIDTH-1:0]      lsu_mux4_rdata;
wire                        lsu_mux4_wb;
wire [`REG_ADDR_WIDTH-1:0]  lsu_mux4_regdest;
wire                        lsu_csr_misaligned_load;
wire                        lsu_csr_misaligned_store;
wire [`DATA_WIDTH-1:0]      lsu_csr_misaligned_addr;
wire                        lsu_csr_bus_error;
reg  [`DATA_WIDTH-1:0]      mux4_rf_data;
reg                         mux4_rf_wb;
reg  [`REG_ADDR_WIDTH-1:0]  mux4_rf_dest_addr;
wire                        csr_ifu_trap;
wire [`DATA_WIDTH-1:0]      csr_ifu_mtvec;
wire                        ifu_csr_exception;
wire [`DATA_WIDTH-1:0]      ifu_csr_fault_addr;


/****************************************
* INSTRUCTION FETCH STAGE
****************************************/
jedro_1_ifu #(.BOOT_ADDR(JEDRO_1_BOOT_ADDR)) ifu_inst(.clk_i            (clk_i),
                                                     .rstn_i           (rstn_i),
                                                     .jmp_instr_i      (decoder_ifu_jmp_instr | 
                                                                        decoder_mux3_use_alu_jmp_addr |
                                                                        csr_ifu_trap),
                                                     .jmp_address_i    (mux3_ifu_jmp_addr),
                                                     .exception_ro     (ifu_csr_exception),
                                                     .fault_addr_ro    (ifu_csr_fault_addr),
                                                     .instr_o          (ifu_decoder_instr),
                                                     .addr_o           (ifu_decoder_instr_addr),
                                                     .valid_o          (ifu_decoder_instr_valid), 
                                                     .ready_i          (decoder_ifu_ready), 
                                                     .ram_addr         (iram_addr),
                                                     .ram_rdata        (iram_rdata));  

always@(*) begin
    if      (csr_ifu_trap)                  mux3_ifu_jmp_addr = csr_ifu_mtvec;
    else if (decoder_mux3_use_alu_jmp_addr) mux3_ifu_jmp_addr = {alu_mux4_res[31:1], 1'b0};
    else                                    mux3_ifu_jmp_addr = decoder_ifu_jmp_addr;
end


/****************************************
* INSTRUCTION DECODE STAGE
****************************************/
jedro_1_decoder decoder_inst(.clk_i                (clk_i),
                             .rstn_i               (rstn_i),                  
                             .instr_addr_i         (ifu_decoder_instr_addr),
                             .instr_addr_ro        (decoder_mux2_instr_addr),
                             .use_pc_ro            (decoder_mux2_use_pc),
                             .instr_i              (ifu_decoder_instr),
                             .instr_valid_i        (ifu_decoder_instr_valid),
                             .ready_ro             (decoder_ifu_ready),
                             .jmp_instr_ro         (decoder_ifu_jmp_instr),
                             .jmp_addr_ro          (decoder_ifu_jmp_addr),
                             .use_alu_jmp_addr_ro  (decoder_mux3_use_alu_jmp_addr),
                             .illegal_instr_ro     (decoder_csr_illegal_instr), 
                             .ecall_ro             (decoder_csr_ecall),
                             .ebreak_ro            (decoder_csr_ebreak),
                             .is_alu_write_ro      (decoder_mux4_is_alu_write),
                             .alu_sel_ro           (decoder_alu_sel), 
                             .alu_dest_addr_ro     (decoder_alu_dest_addr),
                             .alu_wb_ro            (decoder_alu_wb),
                             .alu_res_i            (alu_mux4_res),
                             .alu_ops_eq_i         (alu_decoder_ops_eq),
                             .rf_addr_a_ro         (decoder_rf_addr_a), 
                             .rf_addr_b_ro         (decoder_rf_addr_b),
                             .is_imm_ro            (decoder_mux_is_imm), 
                             .imm_ext_ro           (decoder_mux_imm_ex),
                             .lsu_ctrl_valid_ro    (decoder_lsu_ctrl_valid), 
                             .lsu_ctrl_ro          (decoder_lsu_ctrl),
                             .lsu_regdest_ro       (decoder_lsu_regdest),
                             .lsu_read_complete_i  (lsu_mux4_wb),
                             .csr_addr_ro          (decoder_csr_addr),
                             .csr_we_ro            (decoder_csr_we),
                             .csr_data_i           (csr_decoder_data),
                             .csr_uimm_data_ro     (decoder_csr_uimm),
                             .csr_uimm_we_ro       (decoder_csr_uimm_we),
                             .csr_wmode_ro         (decoder_csr_wmode),
                             .csr_mret_ro          (decoder_csr_mret) 
                           );


/*********************************************
* INSTRUCTION EXECUTE STAGE - ALU/REGFILE/MUX
*********************************************/
jedro_1_regfile #(.DATA_WIDTH(32)) regfile_inst(.clk_i        (clk_i),
                                                .rstn_i       (rstn_i),
                                                .rpa_addr_i   (decoder_rf_addr_a),
                                                .rpa_data_co  (rf_alu_data_a),
                                                .rpb_addr_i   (decoder_rf_addr_b),
                                                .rpb_data_co  (rf_alu_data_b),
                                                .wpc_addr_i   (mux4_rf_dest_addr),  
                                                .wpc_data_i   (mux4_rf_data),     
                                                .wpc_we_i     (mux4_rf_wb)
                                              );   

assign mux2_alu_op_a = decoder_mux2_use_pc ? decoder_mux2_instr_addr : rf_alu_data_a;
// decoder_mux_is_imm signal tells if an operation is between 2 registers or an
// register and an immediate. Based on this the 2:1 MUX bellow selects the 
// mux_alu_op_b
assign mux_alu_op_b = decoder_mux_is_imm ? decoder_mux_imm_ex : rf_alu_data_b;

always @(posedge clk_i) begin
    if (rstn_i == 1'b0) decoder_1_mux2_instr_addr <= 0;
    else                decoder_1_mux2_instr_addr <= decoder_mux2_instr_addr;
end

jedro_1_csr csr_inst (.clk_i                   (clk_i),
                      .rstn_i                  (rstn_i),
                      .addr_i                  (decoder_csr_addr), 
                      .data_i                  (mux2_alu_op_a),
                      .uimm_data_i             (decoder_csr_uimm),
                      .uimm_we_i               (decoder_csr_uimm_we),
                      .data_ro                 (csr_decoder_data),
                      .we_i                    (decoder_csr_we),
                      .wmode_i                 (decoder_csr_wmode),
                       
                      .curr_pc_i               (decoder_mux2_instr_addr),
                      .prev_pc_i               (decoder_1_mux2_instr_addr),
                      .traphandler_addr_ro     (csr_ifu_mtvec),
                      .trap_ro                 (csr_ifu_trap),

                      .ifu_exception_i         (ifu_csr_exception),
                      .ifu_mtval_i             (ifu_csr_fault_addr),
    
                      .lsu_exception_load_i    (lsu_csr_misaligned_load),
                      .lsu_exception_store_i   (lsu_csr_misaligned_store),
                      .lsu_exception_bus_err_i (lsu_csr_bus_error),
                      .lsu_exception_addr_i    (lsu_csr_misaligned_addr),

                      .decoder_exc_illegal_instr_i (decoder_csr_illegal_instr),
                      .decoder_exc_ecall_i         (decoder_csr_ecall),
                      .decoder_exc_ebreak_i        (decoder_csr_ebreak),

                      .sw_irq_i    (1'b0), // TODO
                      .timer_irq_i (1'b0),
                      .ext_irq_i   (1'b0),

                      .mret_i      (decoder_csr_mret)
                     );

jedro_1_alu alu_inst(.clk_i       (clk_i),
                     .rstn_i      (rstn_i),
                     .sel_i       (decoder_alu_sel),
                     .op_a_i      (mux2_alu_op_a),
                     .op_b_i      (mux_alu_op_b),
                     .res_ro      (alu_mux4_res),
                     .ops_eq_ro   (alu_decoder_ops_eq),
                     .overflow_ro (),
                     .dest_addr_i (decoder_alu_dest_addr),
                     .dest_addr_ro(alu_mux4_dest_addr),
                     .wb_i        (decoder_alu_wb & ~csr_ifu_trap),
                     .wb_ro       (alu_mux4_wb) 
                   ); 


/*********************************************
* WRITEBACK STAGE 
*********************************************/
// We delay the signals by 1 clock cycle that is used
// for computing the target address.
always @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin        
        decoder_1_mux4_is_alu_write <= 1'b1;
    end
    else begin
        decoder_1_mux4_is_alu_write <= decoder_mux4_is_alu_write;
    end
end

// MUX4
always@(*) begin
    if (decoder_1_mux4_is_alu_write == 1'b1) begin
        mux4_rf_dest_addr = alu_mux4_dest_addr;
        mux4_rf_data      = alu_mux4_res;
        mux4_rf_wb        = alu_mux4_wb;
    end
    else begin
        mux4_rf_dest_addr = lsu_mux4_regdest;
        mux4_rf_data      = lsu_mux4_rdata;
        mux4_rf_wb        = lsu_mux4_wb;
    end
end


jedro_1_lsu lsu_inst(.clk_i               (clk_i),
                     .rstn_i              (rstn_i),
                     .ctrl_valid_i        (decoder_lsu_ctrl_valid),
                     .ctrl_i              (decoder_lsu_ctrl),
                     .addr_i              (alu_mux4_res),
                     .wdata_i             (rf_alu_data_b),
                     .rdata_ro            (lsu_mux4_rdata),
                     .rf_wb_ro            (lsu_mux4_wb),
                     .regdest_i           (decoder_lsu_regdest),
                     .regdest_ro          (lsu_mux4_regdest),
                     .misaligned_load_ro  (lsu_csr_misaligned_load),
                     .misaligned_store_ro (lsu_csr_misaligned_store),
                     .bus_error_ro        (lsu_csr_bus_error),
                     .exception_addr_ro   (lsu_csr_misaligned_addr),
                     .ram_we              (dram_we),
                     .ram_stb             (dram_stb),
                     .ram_addr            (dram_addr),
                     .ram_wdata           (dram_wdata),
                     .ram_rdata           (dram_rdata),
                     .ram_ack             (dram_ack),
                     .ram_err             (dram_err)
                    );

// Note that the ICARUS flag needs to be set in the makefile arguments
`ifdef COCOTB_SIM
`ifdef ICARUS
initial begin
  $dumpfile ("jedro_1_top_testing.vcd");
  $dumpvars (0, jedro_1_top);
end
`endif
`endif

endmodule
