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
`timescale 1ns/1ps

interface ram_rw_io #(
	parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
);	
	logic [DATA_WIDTH/8-1:0]        we;
    logic                           stb;
    logic                           ack;
    logic                           err; 
	logic [ADDR_WIDTH-1:0]          addr;
	logic [DATA_WIDTH-1:0]          wdata;
	logic [DATA_WIDTH-1:0]          rdata;

	modport MASTER(input rdata, ack, err,
				   output we, stb, addr, wdata);
	modport SLAVE (output rdata, ack, err,
				   input  we, stb, addr, wdata);

endinterface: ram_rw_io

