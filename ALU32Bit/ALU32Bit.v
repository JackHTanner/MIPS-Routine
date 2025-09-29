`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
// 
// Module - ALU32Bit.v
// Description - 32-Bit wide arithmetic logic unit (ALU).
//
// INPUTS:-
// ALUControl: N-Bit input control bits to select an ALU operation.
// A: 32-Bit input port A.
// B: 32-Bit input port B.
//
// OUTPUTS:-
// ALUResult: 32-Bit ALU result output.
// ZERO: 1-Bit output flag. 
//
// FUNCTIONALITY:-
// Design a 32-Bit ALU, so that it supports all arithmetic operations 
// needed by the MIPS instructions given in Labs5-8.docx document. 
//   The 'ALUResult' will output the corresponding result of the operation 
//   based on the 32-Bit inputs, 'A', and 'B'. 
//   The 'Zero' flag is high when 'ALUResult' is '0'. 
//   The 'ALUControl' signal should determine the function of the ALU 
//   You need to determine the bitwidth of the ALUControl signal based on the number of 
//   operations needed to support. 
////////////////////////////////////////////////////////////////////////////////

module ALU32Bit(ALUControl, A, B, ALUResult, Zero);

    input [3:0] ALUControl; // control bits for ALU operation
                            // you need to adjust the bitwidth as needed
    input [31:0] A, B;      // inputs

    output [31:0] ALUResult;    // answer
    output Zero;                // Zero=1 if ALUResult == 0

    // Internal result register, then drive output via continuous assign
    reg [31:0] result;
    assign ALUResult = result;

    // Zero flag asserted when ALUResult is all zeros
    assign Zero = (ALUResult == 32'b0);

    // Combinational ALU
    always @(*) begin
        case (ALUControl)
            4'b0000: result = A & B;                          // AND
            4'b0001: result = A | B;                          // OR
            4'b0010: result = A + B;                          // ADD
            4'b0011: result = A ^ B;                          // XOR
            4'b0100: result = ~(A | B);                       // NOR
            4'b0110: result = A - B;                          // SUB
            4'b0111: result = ($signed(A) < $signed(B)) 
                              ? 32'd1 : 32'd0;                // SLT (signed)
            4'b1000: result = B << A[4:0];                    // SLLV: shift amt in A[4:0]
            4'b1001: result = B >> A[4:0];                    // SRLV: logical right
            4'b1010: result = $signed(B) >>> A[4:0];          // SRAV: arithmetic right
            4'b1011: result = (A < B) ? 32'd1 : 32'd0;        // SLTU (unsigned)
            4'b1100: result = ~(A & B);                       // NAND (optional)
            4'b1111: result = {B[15:0], 16'b0};               // LUI-style
            default: result = 32'b0;
        endcase
    end

endmodule