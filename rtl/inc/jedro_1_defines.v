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
// This document contains the opcode definitions of RISC-V
`timescale 1ns/1ps

// General defines
`define DATA_WIDTH      (32)
`define REG_ADDR_WIDTH  ($clog2(`DATA_WIDTH))

`ifndef JEDRO_1_BOOT_ADDR
    `define JEDRO_1_BOOT_ADDR (32'h8000_0000)  // this can be overriden by comand line define
`endif
 
`define NOP_INSTR       (32'b000000000000_00000_000_00000_0010011)
`define MRET_INSTR      (32'b001100000010_00000_000_00000_1110011)
`define ECALL_INSTR     (32'b000000000000_00000_000_00000_1110011) 
`define EBREAK_INSTR    (32'b000000000001_00000_000_00000_1110011)
`define WFI_INSTR       (32'b000100000101_00000_000_00000_1110011)


// OPCODES for RV32G/RV64G (All are defined but not necessarily implemented)
`define OPCODE_LOAD     (7'b0000011)
`define OPCODE_LOADFP   (7'b0000111)
`define OPCODE_CUSTOM0  (7'b0001011)
`define OPCODE_MISCMEM  (7'b0001111)
`define OPCODE_OPIMM    (7'b0010011)
`define OPCODE_AUIPC    (7'b0010111)
`define OPCODE_OPIMM32  (7'b0011011)
`define OPCODE_STORE    (7'b0100011)
`define OPCODE_STOREFP  (7'b0100111)
`define OPCODE_CUSTOM1  (7'b0101011)
`define OPCODE_AMO      (7'b0101111)
`define OPCODE_OP       (7'b0110011)
`define OPCODE_LUI      (7'b0110111)
`define OPCODE_OP32     (7'b0111011)
`define OPCODE_MADD     (7'b1000011)
`define OPCODE_MSUB     (7'b1000111)
`define OPCODE_NMSUB    (7'b1001011)
`define OPCODE_NMADD    (7'b1001111)
`define OPCODE_OPFP     (7'b1010011)
`define OPCODE_BRANCH   (7'b1100011)
`define OPCODE_JALR     (7'b1100111)
`define OPCODE_JAL      (7'b1101111)
`define OPCODE_SYSTEM   (7'b1110011)

// ALU defines
`define ALU_OP_WIDTH  (4)       // Number of bits used to encode the operator of the ALU operation
`define ALU_OP_ADD    (4'b0000)
`define ALU_OP_SUB    (4'b1000)
`define ALU_OP_SLL    (4'b0001)
`define ALU_OP_SLT    (4'b0010)
`define ALU_OP_SLTU   (4'b0011)
`define ALU_OP_XOR    (4'b0100)
`define ALU_OP_SRL    (4'b0101)
`define ALU_OP_SRA    (4'b1101)
`define ALU_OP_OR     (4'b0110)
`define ALU_OP_AND    (4'b0111)

// funct3 defines
`define FUNCT3_SHIFT_INSTR  (3'b101)

// Load-Store Unit
`define LSU_CTRL_WIDTH        (4) // we need to encode 8 states 
`define LSU_LOAD_BYTE         (4'b0000)
`define LSU_LOAD_HALF_WORD    (4'b0001)
`define LSU_LOAD_WORD         (4'b0010)
`define LSU_LOAD_BYTE_U       (4'b0100)
`define LSU_LOAD_HALF_WORD_U  (4'b0101)
`define LSU_STORE_BYTE        (4'b1000)
`define LSU_STORE_HALF_WORD   (4'b1001)
`define LSU_STORE_WORD        (4'b1010)


// CONTROL AND STATUS REGISTERS
`define TRAP_VEC_BASE_ADDR        (30'h0010_0000)
`define TRAP_VEC_MODE             (2'b00) // direct mode (vectored == 01)
`define CSRRW_INSTR_FUNCT3        (3'b001)
`define CSRRWI_INSTR_FUNCT3       (3'b101)
`define CSRRS_INSTR_FUCNT3        (3'b010)
`define CSRRSI_INSTR_FUCNT3       (3'b110)
`define CSR_ADDR_WIDTH            (12)
`define CSR_UIMM_WIDTH            (5)
`define CSR_WMODE_WIDTH           (2)
`define CSR_WMODE_NORMAL          (2'b00)
`define CSR_WMODE_SET_BITS        (2'b01)
`define CSR_WMODE_CLEAR_BITS      (2'b10)

`define CSR_MCAUSE_INSTR_ADDR_MISALIGNED  (0)
`define CSR_MCAUSE_ILLEGAL_INSTRUCTION    (2)
`define CSR_MCAUSE_EBREAK                 (3)
`define CSR_MCAUSE_LOAD_ADDR_MISALIGNED   (4)
`define CSR_MCAUSE_LOAD_ACCESS_FAULT      (5)
`define CSR_MCAUSE_STORE_ADDR_MISALIGNED  (6)
`define CSR_MCAUSE_ECALL_M_MODE           (11)

// Machine Information Registers 
`define CSR_ADDR_MVENDORID        (12'hF11)
`define CSR_DEF_VAL_MVENDORID     (32'b0)
`define CSR_ADDR_MARCHID          (12'hF12)
`define CSR_DEF_VAL_MARCHID       (32'b0)
`define CSR_ADDR_MIMPID           (12'hF13)
`define CSR_DEF_VAL_MIMPID        (32'b0)
`define CSR_ADDR_MHARTID          (12'hF14)
`define CSR_DEF_VAL_MHARTID       (32'b0)

// Machine Trap Registers
`define CSR_ADDR_MSTATUS          (12'h300)
`define CSR_MSTATUS_BIT_MIE       (3) // machine interrupt enable
`define CSR_MSTATUS_BIT_MPIE      (7) // previous machine interrupt enable
`define CSR_DEF_VAL_MSTATUS       (32'b00000000_0000000_0000000_00000000)
`define CSR_ADDR_MISA             (12'h301)
`define CSR_DEF_VAL_MISA          (32'b01_0000_00000000000000000100000000)

`define CSR_ADDR_MTVEC            (12'h305)
`define CSR_MTVEC_BASE_LEN        (30)
`define CSR_DEF_VAL_MTVEC         ({TRAP_VEC_BASE_ADDR, TRAP_VEC_MODE})

`define CSR_ADDR_MIP              (12'h344)
`define CSR_MIP_BIT_MSIP          (3) // machine software interrupt pending
`define CSR_MIP_BIT_MTIP          (7) // machine timer interrupt pending
`define CSR_MIP_BIT_MEIP          (11) // machine external interrupt pending
`define CSR_DEF_VAL_MIP           (32'b00000000_00000000_00000000_00000000)

`define CSR_ADDR_MIE              (12'h304)
`define CSR_MIE_BIT_MSIE          (3) // machine software interrupt enabled
`define CSR_MIE_BIT_MTIE          (7) // machine timer interrupt enabled
`define CSR_MIE_BIT_MEIE          (11) // machine external interrupt enabled
`define CSR_DEF_VAL_MIE           (32'b00000000_00000000_00000000_00000000)

`define CSR_ADDR_MSCRATCH         (12'h340)
`define CSR_DEF_VAL_MSCRATCH      (32'b00000000_00000000_00000000_00000000)

`define CSR_ADDR_MEPC             (12'h341)
`define CSR_DEF_VAL_MEPC          (32'b00000000_00000000_00000000_00000000)

`define CSR_ADDR_MCAUSE           (12'h342)
`define CSR_DEF_VAL_MCAUSE        (32'b00000000_00000000_00000000_00000000)

`define CSR_ADDR_MTVAL            (12'h343)
`define CSR_DEF_VAL_MTVAL         (32'b00000000_00000000_00000000_00000000)


