`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
// 
// Module - ALU32Bit_tb.v
// Description - Test the 'ALU32Bit.v' module.
////////////////////////////////////////////////////////////////////////////////

module ALU32Bit_tb(); 

    reg [3:0]  ALUControl;   // control bits for ALU operation
    reg [31:0] A, B;         // inputs

    wire [31:0] ALUResult;   // answer
    wire        Zero;        // Zero=1 if ALUResult == 0

    ALU32Bit u0(
        .ALUControl(ALUControl), 
        .A(A), 
        .B(B), 
        .ALUResult(ALUResult), 
        .Zero(Zero)
    );

    // Simple checker task
    task automatic check;
        input [3:0]  ctrl;
        input [31:0] a, b;
        input [31:0] expected;
        reg          expectedZero;
    begin
        expectedZero = (expected == 32'h0000_0000);
        ALUControl = ctrl; A = a; B = b;
        #1; // allow combinational settle
        if (ALUResult !== expected || Zero !== expectedZero) begin
            $display("FAIL: ctrl=%b A=%h B=%h | got ALUResult=%h Zero=%b | expected %h %b",
                      ctrl, a, b, ALUResult, Zero, expected, expectedZero);
        end else begin
            $display("PASS: ctrl=%b A=%h B=%h -> %h (Zero=%b)",
                      ctrl, a, b, ALUResult, Zero);
        end
    end
    endtask

    initial begin
        // Optional waveform dump (useful if your simulator supports VCD)
        $dumpfile("alu32_tb.vcd");
        $dumpvars(0, ALU32Bit_tb);

        // Initialize
        ALUControl = 4'b0; A = 32'b0; B = 32'b0;
        #1;

        // AND (0000)
        check(4'b0000, 32'h0000_F0F0, 32'h0000_0FF0, 32'h0000_00F0);

        // OR (0001)
        check(4'b0001, 32'h0000_F0F0, 32'h0000_0FF0, 32'h0000_FFF0);

        // ADD (0010)
        check(4'b0010, 32'd5, 32'd7, 32'd12);

        // XOR (0011)
        check(4'b0011, 32'hAAAA_0000, 32'h0F0F_0F0F, 32'hA5A5_0F0F);

        // NOR (0100)
        check(4'b0100, 32'h0000_00FF, 32'h0000_F000, 32'hFFFF_0F00);

        // SUB (0110) -> Zero should assert
        check(4'b0110, 32'd10, 32'd10, 32'd0);

        // SLT signed (0111): (-1) < 5 -> 1
        check(4'b0111, 32'hFFFF_FFFF, 32'd5, 32'd1);

        // SLLV (1000): B << A[4:0]
        check(4'b1000, 32'd5, 32'h0000_0001, 32'h0000_0020);

        // SRLV (1001): logical right
        check(4'b1001, 32'd1, 32'h8000_0000, 32'h4000_0000);

        // SRAV (1010): arithmetic right
        check(4'b1010, 32'd1, 32'h8000_0000, 32'hC000_0000);

        // SLTU unsigned (1011): 0xFFFF_FFFF < 5 (unsigned)? -> 0
        check(4'b1011, 32'hFFFF_FFFF, 32'd5, 32'd0);

        // NAND (1100): ~(A & B)
        check(4'b1100, 32'hFFFF_0000, 32'h0F0F_F0F0, 32'hF0F0_FFFF);

        // LUI style (1111): {B[15:0], 16'h0}
        check(4'b1111, 32'hDEAD_BEEF, 32'h0000_1234, 32'h1234_0000);

        // Default / unused control -> expect 0 (uses 0101 here which isn't mapped)
        check(4'b0101, 32'h1234_5678, 32'h9ABC_DEF0, 32'h0000_0000);

        $display("ALU32Bit_tb complete.");
        $finish;
    end

endmodule
