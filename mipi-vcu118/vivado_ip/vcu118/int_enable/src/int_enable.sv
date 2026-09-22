`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Aumovio
// Engineer: Samuel Matea
// 
// Create Date: 10/17/2025 10:03:20 AM
// Design Name: 
// Module Name: int_enable
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//  t_user_o - is pass-through signal for t_user
// 
//////////////////////////////////////////////////////////////////////////////////


module int_enable(
    input logic t_user_i,
    input logic def_value_i,
    output logic int_o,
    output logic t_user_o
    );
    
    assign int_o = t_user_i & def_value_i;
    assign t_user_o = t_user_i;
    
endmodule
