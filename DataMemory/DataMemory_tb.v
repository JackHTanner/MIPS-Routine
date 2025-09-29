`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
// 
// Module - DataMemory_tb.v
// Description - Test the 'DataMemory.v' module.
////////////////////////////////////////////////////////////////////////////////

module DataMemory_tb(); 

    reg     [31:0]  Address;
    reg     [31:0]  WriteData;
    reg             Clk;
    reg             MemWrite;
    reg             MemRead;

    wire [31:0] ReadData;

    DataMemory u0(
        .Address(Address), 
        .WriteData(WriteData), 
        .Clk(Clk), 
        .MemWrite(MemWrite), 
        .MemRead(MemRead), 
        .ReadData(ReadData)
    ); 

    initial begin
        Clk <= 1'b0;
        forever #10 Clk <= ~Clk;
    end

    // handy tasks
    task automatic write_word(input [31:0] addr, input [31:0] data);
    begin
        @(negedge Clk);
        Address   = addr;
        WriteData = data;
        MemWrite  = 1'b1;
        MemRead   = 1'b0;
        @(posedge Clk); // perform write on posedge
        @(negedge Clk);
        MemWrite  = 1'b0;
    end
    endtask

    task automatic read_word(input [31:0] addr, input [31:0] expected);
        reg [31:0] got;
    begin
        @(negedge Clk);
        Address  = addr;
        MemRead  = 1'b1;
        MemWrite = 1'b0;
        #1; // allow combinational read to settle
        got = ReadData;
        if (got !== expected) begin
            $display("READ FAIL @ %t : addr=%h got=%h expected=%h", $time, addr, got, expected);
        end else begin
            $display("READ PASS @ %t : addr=%h = %h", $time, addr, got);
        end
        @(negedge Clk);
    end
    endtask

    task automatic read_disabled_zero(output bit ok);
        reg [31:0] got;
    begin
        MemRead = 1'b0;
        #1;
        got = ReadData;
        ok  = (got === 32'h0000_0000);
        if (!ok)
            $display("ZERO-GATE FAIL @ %t : ReadData=%h (expected 0)", $time, got);
        else
            $display("ZERO-GATE PASS @ %t : ReadData=0", $time);
    end
    endtask

    initial begin
        // Optional waveform dump
        $dumpfile("data_memory_tb.vcd");
        $dumpvars(0, DataMemory_tb);

        // Defaults
        Address   = 32'h0;
        WriteData = 32'h0;
        MemWrite  = 1'b0;
        MemRead   = 1'b0;

        // 1) When MemRead=0, output must be zero regardless of contents
        bit ok;
        read_disabled_zero(ok);

        // 2) Write a word to index 0 (Address[11:2] = 0)
        write_word(32'h0000_0000, 32'hDEAD_BEEF);
        // Read it back
        read_word(32'h0000_0000, 32'hDEAD_BEEF);

        // 3) Write to next word (index 1 → any address with Address[11:2]=1)
        write_word(32'h0000_0004, 32'hCAFE_BABE);
        // Read exact address
        read_word(32'h0000_0004, 32'hCAFE_BABE);
        // 3a) Prove byte addressing (low 2 bits ignored): read 0x5, 0x6, 0x7 -> same word
        read_word(32'h0000_0005, 32'hCAFE_BABE);
        read_word(32'h0000_0006, 32'hCAFE_BABE);
        read_word(32'h0000_0007, 32'hCAFE_BABE);

        // 4) Verify other address unchanged
        read_word(32'h0000_0000, 32'hDEAD_BEEF);

        // 5) Verify MemWrite gating (attempt write with MemWrite=0 should not change)
        @(negedge Clk);
        Address   = 32'h0000_0004;
        WriteData = 32'h1111_2222;
        MemWrite  = 1'b0; // not writing
        @(posedge Clk);
        read_word(32'h0000_0004, 32'hCAFE_BABE);

        // 6) Gate-to-zero again check
        MemRead = 1'b0;
        read_disabled_zero(ok);

        $display("DataMemory_tb complete.");
        $finish;
    end

endmodule
