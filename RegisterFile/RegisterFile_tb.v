`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
// 
// Module - RegisterFile.v
// Description - Test the register_file
// Suggested test case - First write arbitrary values into 
// the saved and temporary registers (i.e., register 8 through 25). Then, 2-by-2, 
// read values from these registers.
////////////////////////////////////////////////////////////////////////////////

module RegisterFile_tb();

    reg [4:0]  ReadRegister1;
    reg [4:0]  ReadRegister2;
    reg [4:0]  WriteRegister;
    reg [31:0] WriteData;
    reg        RegWrite;
    reg        Clk;

    wire [31:0] ReadData1;
    wire [31:0] ReadData2;

    RegisterFile u0(
        .ReadRegister1(ReadRegister1), 
        .ReadRegister2(ReadRegister2), 
        .WriteRegister(WriteRegister), 
        .WriteData(WriteData), 
        .RegWrite(RegWrite), 
        .Clk(Clk), 
        .ReadData1(ReadData1), 
        .ReadData2(ReadData2)
    );

    initial begin
        Clk <= 1'b0;
        forever #10 Clk <= ~Clk;
    end

    // --- helper tasks --------------------------------------------------------

    // Write one register at next rising edge (RegWrite must be 1 to commit)
    task automatic write_reg(input [4:0] rd, input [31:0] data);
    begin
        @(negedge Clk);
        WriteRegister = rd;
        WriteData     = data;
        RegWrite      = 1'b1;
        @(posedge Clk); // write happens here (posedge)
        @(negedge Clk);
        RegWrite      = 1'b0;
    end
    endtask

    // Set read addresses, then capture outputs after the falling edge
    task automatic read_pair_and_check(
        input [4:0] r1, input [4:0] r2,
        input [31:0] exp1, input [31:0] exp2
    );
    begin
        @(negedge Clk);
        ReadRegister1 = r1;
        ReadRegister2 = r2;
        // Outputs ReadData1/2 update on the *falling* edge inside the DUT.
        // Wait a tiny delay for them to settle and then check.
        #1;
        if (ReadData1 !== exp1 || ReadData2 !== exp2) begin
            $display("READ FAIL @ %0t : r1=%0d r2=%0d | got (%h,%h) exp (%h,%h)",
                     $time, r1, r2, ReadData1, ReadData2, exp1, exp2);
        end else begin
            $display("READ PASS @ %0t : r1=%0d r2=%0d -> (%h,%h)",
                     $time, r1, r2, ReadData1, ReadData2);
        end
    end
    endtask

    // -------------------------------------------------------------------------

    integer i;
    reg [31:0] refvals [0:31];

    initial begin
        // Optional waveform dump
        $dumpfile("register_file_tb.vcd");
        $dumpvars(0, RegisterFile_tb);

        // defaults
        ReadRegister1 = 5'd0;
        ReadRegister2 = 5'd0;
        WriteRegister = 5'd0;
        WriteData     = 32'h0;
        RegWrite      = 1'b0;

        // Prepare reference values for registers 8..25
        for (i = 0; i < 32; i = i + 1) refvals[i] = 32'h0000_0000;
        for (i = 8; i <= 25; i = i + 1) refvals[i] = 32'h1000_0000 + i;

        // 0) Prove $zero stays zero even if we "write" to it
        write_reg(5'd0, 32'hDEAD_BEEF); // should be ignored
        read_pair_and_check(5'd0, 5'd0, 32'h0000_0000, 32'h0000_0000);

        // 1) Write arbitrary values into registers 8..25
        for (i = 8; i <= 25; i = i + 1) begin
            write_reg(i[4:0], refvals[i]);
        end

        // 2) Read them back 2-by-2: (8,9), (10,11), ..., (24,25)
        for (i = 8; i <= 24; i = i + 2) begin
            read_pair_and_check(i[4:0], (i+1)[4:0], refvals[i], refvals[i+1]);
        end

        // 3) Spot check a couple of non-written regs still zero (e.g., 1 and 31)
        read_pair_and_check(5'd1, 5'd31, 32'h0000_0000, 32'h0000_0000);

        $display("RegisterFile_tb complete.");
        $finish;
    end

endmodule
