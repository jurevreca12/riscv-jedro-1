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
// Design Name:    jedro_1_regfile                                            //
// Project Name:   riscv-jedro-1                                              //
// Language:       System Verilog                                             //
//                                                                            //
// Description:    The register file and its interface.                       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


module jedro_1_regfile
#(
  parameter DATA_WIDTH = 32,
  parameter REG_ADDR_WIDTH = $clog2(DATA_WIDTH)
)
(
  input wire clk_i,
  input wire rstn_i,

  // Read port A
  input wire [REG_ADDR_WIDTH-1:0] rpa_addr_i,
  output wire [DATA_WIDTH-1:0]    rpa_data_co,

  // Read port B
  input wire [REG_ADDR_WIDTH-1:0] rpb_addr_i,
  output wire [DATA_WIDTH-1:0]    rpb_data_co,

  // Write port C
  input wire [REG_ADDR_WIDTH-1:0] wpc_addr_i,
  input wire [DATA_WIDTH-1:0]     wpc_data_i,
  input wire                      wpc_we_i
);

localparam NUM_REGISTERS = 2 ** (REG_ADDR_WIDTH);

// Integer register file x0-x31
reg [DATA_WIDTH-1:0] regfile [NUM_REGISTERS-1:0];

/******************************
* WRITE LOGIC
******************************/
// Write to the registers (register x0 should always be zero)
integer i;
always@(posedge clk_i) begin
  if (rstn_i == 1'b0) begin
    for (i=0; i < NUM_REGISTERS; i=i+1)
      regfile[i] <= 32'b0;
  end
  else begin
  if (wpc_we_i == 1'b1 & wpc_addr_i != 0) 
    regfile[wpc_addr_i] <= wpc_data_i;
  end
end


/******************************
* READ LOGIC
******************************/
// Mux the appropriate register to the data_o line
assign rpa_data_co = regfile[rpa_addr_i];
assign rpb_data_co = regfile[rpb_addr_i];


endmodule

