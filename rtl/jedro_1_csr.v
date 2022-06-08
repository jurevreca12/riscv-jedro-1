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
// Design Name:    jedro_1_csr                                                //
// Project Name:   riscv-jedro-1                                              //
// Language:       System Verilog                                             //
//                                                                            //
// Description:    The control and status registers.                          //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

`include "jedro_1_defines.v"

module jedro_1_csr
(
  input wire clk_i,
  input wire rstn_i,

  // Read/write port
  input wire [`CSR_ADDR_WIDTH-1:0]  addr_i,
  input wire [`DATA_WIDTH-1:0]      data_i,
  input wire [`CSR_UIMM_WIDTH-1:0]  uimm_data_i,
  input wire                       uimm_we_i,
  output reg [`DATA_WIDTH-1:0]      data_ro,
  input wire                       we_i,
  input wire [`CSR_WMODE_WIDTH-1:0] wmode_i,
 
  input  wire [`DATA_WIDTH-1:0]     curr_pc_i, // current pc in decoder
  input  wire [`DATA_WIDTH-1:0]     prev_pc_i, // previous clock cycle pc

  // IFU interface main
  output reg [`DATA_WIDTH-1:0]      traphandler_addr_ro,
  output reg                       trap_ro,

  // IFU exception interface
  input  wire                      ifu_exception_i,
  input  wire [`DATA_WIDTH-1:0]     ifu_mtval_i,

  // LSU exception iterface
  input wire                   lsu_exception_load_i,
  input wire                   lsu_exception_store_i,
  input wire                   lsu_exception_bus_err_i,
  input wire [`DATA_WIDTH-1:0]  lsu_exception_addr_i,

  input wire                   decoder_exc_illegal_instr_i,
  input wire                   decoder_exc_ecall_i,
  input wire                   decoder_exc_ebreak_i,

  // interrupt lines
  input wire                   sw_irq_i,
  input wire                   timer_irq_i,
  input wire                   ext_irq_i,

  input wire                   mret_i
);

reg  [`DATA_WIDTH-1:0] data_n;
reg  [`DATA_WIDTH-1:0] data_mod;
wire [`DATA_WIDTH-1:0] data_mux;

// MSTATUS
reg csr_mstatus_mie_r, csr_mstatus_mie_n, csr_mstatus_mie_exc;  // machine interrupt enable
reg csr_mstatus_mpie_r, csr_mstatus_mpie_n, csr_mstatus_mpie_exc; // previous machine interrupt enable

// MTVEC
reg [`CSR_MTVEC_BASE_LEN-1:0] csr_mtvec_base_r,  csr_mtvec_base_n;

// MIP
reg csr_mip_msip_r; // machine software interrupt pending
reg csr_mip_mtip_r; // machine timmer interrupt pending
reg csr_mip_meip_r; // machine external interrupt pending

// MIE
reg csr_mie_msie_r, csr_mie_msie_n; // machine software interrupt enable
reg csr_mie_mtie_r, csr_mie_mtie_n; // machine timer interrupt enable
reg csr_mie_meie_r, csr_mie_meie_n; // machine external interrupt enable

// MSCRATCH
reg [`DATA_WIDTH-1:0] csr_mscratch_r, csr_mscratch_n;

// MEPC
reg [`DATA_WIDTH-1:0] csr_mepc_r, csr_mepc_n, csr_mepc_exc;

// MCAUSE
reg [`DATA_WIDTH-1:0] csr_mcause_r, csr_mcause_n, csr_mcause_exc;

// MTVAL
reg [`DATA_WIDTH-1:0] csr_mtval_r, csr_mtval_n, csr_mtval_exc;

// Other signals
reg                    csr_illegal_instr_exc; // Signals illegal csr write 
wire                   is_exception;
wire                   is_write;
reg  [`DATA_WIDTH-1:0] exception_code;
reg  [`DATA_WIDTH-1:0] exception_mtval;
reg  [`DATA_WIDTH-1:0] exception_addr;

assign data_mux = uimm_we_i ? {27'b0, uimm_data_i} : data_i;
always@(*) begin
    if (wmode_i == `CSR_WMODE_NORMAL)
        data_mod = data_mux;
    else if (wmode_i == `CSR_WMODE_SET_BITS)
        data_mod = data_ro | data_mux; // the old value is always read before writing
    else
        data_mod = data_ro & (~data_mux);
end


assign is_exception = ifu_exception_i | 
                      lsu_exception_load_i | 
                      lsu_exception_store_i |
                      lsu_exception_bus_err_i |
                      decoder_exc_illegal_instr_i |
                      decoder_exc_ecall_i |
                      decoder_exc_ebreak_i |
                      csr_illegal_instr_exc;


assign is_write = (!is_exception) && (we_i || uimm_we_i);

always@(*) begin
    if      (decoder_exc_illegal_instr_i) exception_code = `CSR_MCAUSE_ILLEGAL_INSTRUCTION;
    else if (csr_illegal_instr_exc)       exception_code = `CSR_MCAUSE_ILLEGAL_INSTRUCTION;
    else if (ifu_exception_i)             exception_code = `CSR_MCAUSE_INSTR_ADDR_MISALIGNED;
    else if (decoder_exc_ecall_i)         exception_code = `CSR_MCAUSE_ECALL_M_MODE;
    else if (decoder_exc_ebreak_i)        exception_code = `CSR_MCAUSE_EBREAK;
    else if (lsu_exception_store_i)       exception_code = `CSR_MCAUSE_STORE_ADDR_MISALIGNED;
    else if (lsu_exception_load_i)        exception_code = `CSR_MCAUSE_LOAD_ADDR_MISALIGNED;
    else if (lsu_exception_bus_err_i)     exception_code = `CSR_MCAUSE_LOAD_ACCESS_FAULT;
    else                                  exception_code = 32'b0;
end

always@(*) begin
    if      (decoder_exc_illegal_instr_i) exception_mtval = curr_pc_i;
    else if (csr_illegal_instr_exc)       exception_mtval = curr_pc_i;
    else if (ifu_exception_i)             exception_mtval = ifu_mtval_i;
    else if (decoder_exc_ecall_i)         exception_mtval = 0;
    else if (decoder_exc_ebreak_i)        exception_mtval = curr_pc_i;
    else if (lsu_exception_store_i)       exception_mtval = lsu_exception_addr_i;
    else if (lsu_exception_load_i)        exception_mtval = lsu_exception_addr_i;
    else if (lsu_exception_bus_err_i)     exception_mtval = lsu_exception_addr_i;
    else                                  exception_mtval = 32'b0;
end

always@(*) begin
    if      (decoder_exc_illegal_instr_i) exception_addr = curr_pc_i;
    else if (csr_illegal_instr_exc)       exception_addr = curr_pc_i;
    else if (ifu_exception_i)             exception_addr = prev_pc_i;
    else if (decoder_exc_ecall_i)         exception_addr = curr_pc_i;
    else if (decoder_exc_ebreak_i)        exception_addr = curr_pc_i;
    else if (lsu_exception_store_i)       exception_addr = prev_pc_i;
    else if (lsu_exception_load_i)        exception_addr = prev_pc_i;
    else if (lsu_exception_load_i)        exception_addr = prev_pc_i;
    else                                  exception_addr = 32'b0;
end

always@(*) begin
    data_n = 0;
    csr_illegal_instr_exc = 0;
    csr_mstatus_mie_n = csr_mstatus_mie_r;
    csr_mstatus_mpie_n = csr_mstatus_mpie_r;
    csr_mtvec_base_n = csr_mtvec_base_r;
    csr_mie_msie_n = csr_mie_msie_r;
    csr_mie_mtie_n = csr_mie_mtie_r;
    csr_mie_meie_n = csr_mie_meie_r;
    csr_mscratch_n = csr_mscratch_r;
    csr_mepc_n = csr_mepc_r;
    csr_mcause_n = csr_mcause_r;
    csr_mtval_n = csr_mtval_r;
    casez (addr_i)
        `CSR_ADDR_MVENDORID: begin
            data_n = `CSR_DEF_VAL_MVENDORID; // read-only
            csr_illegal_instr_exc = we_i|uimm_we_i;
        end

        `CSR_ADDR_MARCHID: begin
            data_n = `CSR_DEF_VAL_MARCHID; // read-only
            csr_illegal_instr_exc = we_i|uimm_we_i;
        end

        `CSR_ADDR_MIMPID: begin
            data_n = `CSR_DEF_VAL_MIMPID; // read-only
            csr_illegal_instr_exc = we_i|uimm_we_i;
        end

        `CSR_ADDR_MHARTID: begin
            data_n = `CSR_DEF_VAL_MHARTID; // read-only
            csr_illegal_instr_exc = we_i|uimm_we_i;
        end
        
        `CSR_ADDR_MSTATUS: begin
            // CSR_DEF_VAL_MSTATUS is all zeros
            data_n = `CSR_DEF_VAL_MSTATUS;
			data_n[`CSR_MSTATUS_BIT_MIE] = csr_mstatus_mie_r;
			data_n[`CSR_MSTATUS_BIT_MPIE] = csr_mstatus_mpie_r;
            if (is_write) begin
                csr_mstatus_mie_n = data_mod[`CSR_MSTATUS_BIT_MIE];
                csr_mstatus_mpie_n = data_mod[`CSR_MSTATUS_BIT_MPIE];
            end
        end

        `CSR_ADDR_MISA: begin
            data_n = `CSR_DEF_VAL_MISA; // read-only
        end

        `CSR_ADDR_MTVEC: begin
            data_n = {csr_mtvec_base_r, `TRAP_VEC_MODE};
            if (is_write) begin
                csr_mtvec_base_n = data_mod[`DATA_WIDTH-1:`DATA_WIDTH-`CSR_MTVEC_BASE_LEN];
            end
        end

        `CSR_ADDR_MIP: begin
            data_n = {20'b0, 
                      csr_mip_meip_r, 3'b0, 
                      csr_mip_mtip_r, 3'b0, 
                      csr_mip_msip_r, 3'b0}; // read-only
        end

        `CSR_ADDR_MIE: begin
            data_n = {20'b0,
                      csr_mie_meie_r, 3'b0,
                      csr_mie_mtie_r, 3'b0,
                      csr_mie_msie_r, 3'b0};

            if (is_write) begin
                csr_mie_msie_n = data_mod[`CSR_MIE_BIT_MSIE];
                csr_mie_mtie_n = data_mod[`CSR_MIE_BIT_MTIE];
                csr_mie_meie_n = data_mod[`CSR_MIE_BIT_MEIE];
            end
        end

        `CSR_ADDR_MSCRATCH: begin
            data_n = csr_mscratch_r;
            if (is_write) begin
                csr_mscratch_n = data_mod;
            end
        end

        `CSR_ADDR_MEPC: begin
            data_n = csr_mepc_r;
            if (is_write) begin
                csr_mepc_n = data_mod;
            end
        end

        `CSR_ADDR_MCAUSE: begin
            data_n = csr_mcause_r; 
            if (is_write) begin
                csr_mcause_n = data_mod;
            end
        end

        `CSR_ADDR_MTVAL: begin
            data_n = csr_mtval_r;
            if (is_write) begin
                csr_mtval_n = data_mod;
            end
        end

        default: begin
            data_n = 0;
            csr_illegal_instr_exc = we_i|uimm_we_i;
        end
    endcase
end

// Exception value generation
always@(*) begin
    csr_mepc_exc = 0;
    csr_mcause_exc = 0;
    csr_mtval_exc = 0;
    csr_mstatus_mie_exc = 0;
    csr_mstatus_mpie_exc = 0;
    if (is_exception) begin 
        csr_mepc_exc = exception_addr;
        csr_mcause_exc = exception_code;
        csr_mtval_exc = exception_mtval;
        csr_mstatus_mie_exc = 1'b0;
        csr_mstatus_mpie_exc = csr_mstatus_mie_r;  
    end
    else if (mret_i) begin
        csr_mstatus_mie_exc = csr_mstatus_mpie_r;
    end
end


always @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        data_ro <= 0;
        csr_mstatus_mie_r <= 0;
        csr_mstatus_mpie_r <= 0;
        csr_mtvec_base_r  <= `TRAP_VEC_BASE_ADDR;
        csr_mip_meip_r <= 1'b0;
        csr_mip_mtip_r <= 1'b0;
        csr_mip_msip_r <= 1'b0;
        csr_mie_msie_r <= 1'b0;
        csr_mie_mtie_r <= 1'b0;
        csr_mie_meie_r <= 1'b0;
        csr_mscratch_r <= `CSR_DEF_VAL_MSCRATCH;
        csr_mepc_r <= `CSR_DEF_VAL_MEPC;
        csr_mcause_r <= `CSR_DEF_VAL_MCAUSE;
        csr_mtval_r <= `CSR_DEF_VAL_MTVAL;
    end
    else begin
        data_ro <= data_n;
        csr_mtvec_base_r  <= csr_mtvec_base_n;
        csr_mip_meip_r <= ext_irq_i;
        csr_mip_mtip_r <= timer_irq_i;
        csr_mip_msip_r <= sw_irq_i;
        csr_mie_msie_r <= csr_mie_msie_n;
        csr_mie_mtie_r <= csr_mie_mtie_n;
        csr_mie_meie_r <= csr_mie_meie_n;
        csr_mscratch_r <= csr_mscratch_n;
        if (is_exception | mret_i) begin
            csr_mepc_r <= csr_mepc_exc;
            csr_mcause_r <= csr_mcause_exc;
            csr_mtval_r <= csr_mtval_exc;
            csr_mstatus_mie_r <= csr_mstatus_mie_exc;
            csr_mstatus_mpie_r <= csr_mstatus_mpie_exc;
        end
        else begin
            csr_mepc_r <= csr_mepc_n;
            csr_mcause_r <= csr_mcause_n;
            csr_mtval_r <= csr_mtval_n;
            csr_mstatus_mie_r <= csr_mstatus_mie_n;
            csr_mstatus_mpie_r <= csr_mstatus_mpie_n;
        end
    end
end


always @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        trap_ro <= 1'b0;
        traphandler_addr_ro <= 0;
    end
    else begin
        trap_ro <= is_exception | mret_i;
        if (is_exception)
            traphandler_addr_ro <= {csr_mtvec_base_r, 2'b00};
        else if (mret_i)
            traphandler_addr_ro <= csr_mepc_r;
        else
            traphandler_addr_ro <= 0;
    end
end

endmodule

