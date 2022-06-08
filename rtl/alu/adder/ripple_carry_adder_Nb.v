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
// Design Name:    ripple_carry_adder_Nb                                      //
// Project Name:   riscv-jedro-1                                              //
// Language:       Verilog                                                    //
//                                                                            //
// Description:    An implemenation of a (combinatorial) ripple carry adder.  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


module ripple_carry_adder_Nb #(parameter N = 32) (
	input  carry_i,
	input  [N-1:0] opa_i,
	input  [N-1:0] opb_i,
	input  inv_b_i, 		// Should input b be inverted?
	output [N-1:0] res_o,
	output carry_o
);

wire [N:0] carry;	  // carry[0] is used to implement substraction
wire [N-1:0] b_mod;

// inv_b = 0 and ci = 0 -> a + b + 0
// inb_b = 0 and ci = 1 -> a + b + 1
// inv_b = 1 and ci = 0 -> a + (~b + 1) = a + ~b + 1
// inv_b = 1 and ci = 1 -> a + (~b + 1) + 1 = a + ~b
assign b_mod  = (inv_b_i)?(~opb_i):opb_i;
assign carry[0] = (inv_b_i)?(~carry_i):carry_i;
assign carry_o = carry[N];

full_adder_1b FA_1b_0(opa_i[0], b_mod[0], carry[0], res_o[0], carry[1]);
genvar i;
generate
for (i = 1; i < N; i = i + 1) begin
	full_adder_1b FA_1b(opa_i[i], b_mod[i], carry[i], res_o[i], carry[i+1]);
end
endgenerate

endmodule
