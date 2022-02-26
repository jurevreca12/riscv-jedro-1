////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jure Vreca - jurevreca12@gmail.com                         //
//                                                                            //
//                                                                            //
//                                                                            //
// Design Name:    jedro_1_lsu                                                //
// Project Name:   riscv-jedro-1                                              //
// Language:       System Verilog                                             //
//                                                                            //
// Description:    The load-store unit of the jedro-1 riscv core. The LSU     //
//                 assumes a single cycle delay write, with no-change on      //
//                 the read port when writing (Xilinx 7 Series Block RAM in   //
//                 no-change mode using only a single port.                   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
  
import jedro_1_defines::*;

module jedro_1_lsu
(
  input logic clk_i,
  input logic rstn_i,
  
  // Inputs from the decoder/ALU
  input logic                       ctrl_valid_i,
  input logic  [LSU_CTRL_WIDTH-1:0] ctrl_i,
  input logic  [DATA_WIDTH-1:0]     addr_i,        // Address of the memory to ready/write.
  input logic  [DATA_WIDTH-1:0]     wdata_i,       // The data to write to memory.
  input  logic [REG_ADDR_WIDTH-1:0] regdest_i,     // Writeback to which register?
 
  // Interface to the register file
  output logic [DATA_WIDTH-1:0]     rdata_ro,       // Goes to the register file.
  output logic                      rf_wb_ro,       // Enables the write pin of the reg file.
  output logic [REG_ADDR_WIDTH-1:0] regdest_ro,

  // Interface to data RAM
  ram_rw_io.MASTER                  data_mem_if
);

localparam READ_CYCLE_DELAY = 3;

logic [DATA_WIDTH-1:0]     data_r; // stores unaligned data directly from memory
logic [DATA_WIDTH-1:0]     byte_sign_extended_w;
logic [DATA_WIDTH-1:0]     hword_sign_extended_w;
logic [DATA_WIDTH/8 - 1:0] byte_select; 
logic                      hword_select;
logic                      read_enable;
logic [7:0]                active_byte;
logic [15:0]               active_hword;
logic [1:0]                byte_addr_r;


/**************************************
* WRITE ENABLE SIGNAL
**************************************/
logic is_write; // Is the current ctrl input a write
logic [DATA_WIDTH/8 - 1:0] we; // write enable signal

assign is_write = ctrl_i[LSU_CTRL_WIDTH-1];

always_comb begin
    if (is_write == 1'b1) begin
        if (ctrl_i[LSU_CTRL_WIDTH-2:0] == 3'b010)
            we = 4'b1111; // word write
        else if (ctrl_i[LSU_CTRL_WIDTH-2:0] == 3'b001)
            we = 4'b0011; // half-word write
        else if (ctrl_i[LSU_CTRL_WIDTH-2:0] == 3'b000)
            we = 4'b0001; // byte write
        else
            we = 4'b0000;
    end
    else begin
        we = 4'b0000;
    end
end

/**************************************
* REGDEST
**************************************/
always @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        regdest_ro <= 0;
    end
    else begin
        regdest_ro <= regdest_i;
    end
end


/**************************************
* READ_ENABLE / REGISTER WRITEBACK / BYTE_ADDR
**************************************/
always @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        read_enable <= 1'b0;
    end
    else begin
        if (ctrl_valid_i == 1'b1 && is_write == 1'b0 && read_enable == 1'b0) 
            read_enable <= 1'b1;
        else
            read_enable <= 1'b0;    
    end
end

always_ff @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        rf_wb_ro <= 0;
    end
    else begin
        rf_wb_ro <= read_enable;
    end
end

always @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        byte_addr_r <= 2'b00;
    end
    else begin
        if (ctrl_valid_i == 1'b1 && is_write == 1'b0 && read_enable == 1'b0) 
            byte_addr_r <= addr_i[1:0];
        else
            byte_addr_r <= byte_addr_r;
    end
end


/**************************************
* HANDLE MEM INTERFACE
**************************************/
always_ff @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        data_r <= 0;
    end
    else begin
        if (read_enable == 1'b1)
            data_r <= data_mem_if.rdata;
        else
            data_r <= data_r;
    end
end

always_ff @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
       data_mem_if.addr <= 0;
       data_mem_if.we <= 0;
       data_mem_if.wdata <= 0; 
    end
    else begin
       data_mem_if.addr <= addr_i;
       data_mem_if.we <= we & {4{ctrl_valid_i}};
       data_mem_if.wdata <= wdata_i; 
    end
end


/**************************************
* RESULT MUXING
**************************************/
always_comb begin
    active_byte  = 8'b00000000;
    active_hword = 16'b00000000_00000000;
    unique casez (ctrl_i)
        LSU_LOAD_BYTE: begin
            if      (byte_addr_r == 2'b00) 
                active_byte = data_r[7:0];
            else if (byte_addr_r == 2'b01)
                active_byte = data_r[15:8];
            else if (byte_addr_r == 2'b10)
                active_byte = data_r[23:16];
            else
                active_byte = data_r[31:24];
        end
        
        LSU_LOAD_HALF_WORD: begin
            if      (byte_addr_r == 2'b00)
                active_hword = data_r[15:0];
            else 
                active_hword = data_r[31:16];
        end

        default: begin
            active_byte  = 8'b00000000;
            active_hword = 16'b00000000_00000000;
        end
    endcase
end

sign_extender #(.N(DATA_WIDTH), .M(8)) sign_extender_byte(.in_i(active_byte),
                                                          .out_o(byte_sign_extended_w));
sign_extender #(.N(DATA_WIDTH), .M(16)) sign_extender_halfword(.in_i(active_hword),
                                                               .out_o(hword_sign_extended_w));

always_comb begin
    if (is_write == 1'b1) begin
        rdata_ro = 0;
    end 
    else begin
        rdata_ro = 0;
        unique casez (ctrl_i)
            LSU_LOAD_BYTE:      rdata_ro = byte_sign_extended_w;
            LSU_LOAD_HALF_WORD: rdata_ro = hword_sign_extended_w;
            LSU_LOAD_WORD:      rdata_ro = data_r;
            default:            rdata_ro = 0;
        endcase
    end
end


endmodule : jedro_1_lsu

