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
// Engineer:       Jure Vreča - jurevreca12@gmail.com                       //
//                                                                            //
//                                                                            //
//                                                                            //
// Design Name:    sign_extender                                              //
// Project Name:   riscv-jedro-1                                              //
// Language:       Verilog                                                    //
//                                                                            //
// Description:    Sign extension circuit for 2s complement numbers.          //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module sign_extender #(parameter N=32, parameter M = 12) (
	input  [M-1:0] in_i,
	output [N-1:0] out_o
);

	assign out_o = { {(N-M){in_i[M-1]}}, in_i[M-1:0]};

endmodule
