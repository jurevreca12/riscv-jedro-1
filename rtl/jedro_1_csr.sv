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


module jedro_1_csr
#(
  parameter DATA_WIDTH = 32,
  parameter REG_ADDR_WIDTH = 12
)
(
  input logic clk_i,
  input logic rstn_i,

  // Read/write port
  input logic [REG_ADDR_WIDTH-1:0] addr_i,
  input logic [DATA_WIDTH-1:0]     data_i,
  output logic [DATA_WIDTH-1-:0]   data_ro,
  input logic                      we_i
);

logic [DATA_WIDTH-1:0] data_n;

// MSTATUS
logic csr_mstatus_mie_r;  // machine interrupt enable
logic csr_mstatus_mie_n;  
logic csr_mstatus_mpie_r; // previous machine interrupt enable
logic csr_mstatus_mpie_n; 

// MTVEC
logic [CSR_MTVEC_BASE_LEN-1:0] csr_mtvec_base_r;
logic [CSR_MTVEC_BASE_LEN-1:0] csr_mtvec_base_n;


always_comb @(posedge clk_i) begin
    data_n <= 0;
    unique casez (addr_i)
    {
        CSR_ADDR_MVENDORID: begin
            data_n = CSR_DEF_VAL_MVENDORID; // read-only
        end

        CSR_ADDR_MARCHID: begin
            data_n = CSR_DEF_VAL_MARCHID; // read-only
        end

        CSR_ADDR_MIMPID: begin
            data_n = CSR_DEF_VAL_MIMPID; // read-only
        end

        CSR_ADDR_MHARTID: begin
            data_n = CSR_DEF_VAL_MHARTID; // read-only
        end
        
        CSR_ADDR_MSTATUS: begin
            // CSR_DEF_VAL_MSTATUS is all zeros
            data_n = CSR_DEF_VAL_MSTATUS | 
                     (csr_mstatus_mie_r << CSR_MSTATUS_BIT_MIE) |
                     (csr_mstatus_mpie_r << CSR_MSTATUS_BIT_MPIE);
            if (we_i == 1'b1) begin
                csr_mstatus_mie_n = data_i[CSR_MSTATUS_BIT_MIE];
                csr_mstatus_mpie_n = data_i[CSR_MSTATUS_BIT_MPIE];
            end
            else begin
                csr_mstatus_mie_n = csr_mstatus_mie_r;
                csr_mstatus_mpie_n = csr_mstatus_mpie_r;
            end
        end

        CSR_ADDR_MISA: begin
            data_n = CSR_DEF_VAL_MISA; // read-only
        end

        CSR_ADDR_MTVEC: begin
            data_n = {csr_mtvec_base_r, TRAP_VEC_MODE};
            if (we_i == 1'b1) begin
                csr_mtvec_base_n = data_n[DATA_WIDTH-1:DATA_WIDTH-1-CSR_MTVEC_BASE_LEN];
            end
            else begin
                csr_mtvec_base_n = csr_mtvec_base_r;
            end
        end
    }
end


always_ff @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        data_ro <= 0;
        csr_mstatus_mie_r <= 0;
        csr_mstatus_mpie_r <= 0;
        csr_mtvec_base_r  <= TRAP_VEC_BASE_ADDR;
    end
    else begin
        data_ro <= data_n;
        csr_mstatus_mie_r <= csr_mstatus_mie_n;
        csr_mstatus_mpie_r <= csr_mstatus_mpie_n;
        csr_mtvec_base_r  <= csr_mtvec_base_n;
    end
end

endmodule

