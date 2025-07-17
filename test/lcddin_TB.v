`timescale 1ns / 1ps
`include "src/lcddin.v"

module LCD1602_controller_TB();

    reg clk;
    reg rst;
    reg [7:0] din;

    wire rs;
    wire rw;
    wire enable;
    wire [7:0] data;


    LCD1602_controller #(8, 256, 16, 8, 50) uut (
        .clk(clk),
        .reset(rst),
        .sw_data(din),
        .rs(rs),
        .rw(rw),
        .enable(enable),
        .data(data)
    );


    always #10 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        din = 8'h00;

        #50 rst = 0;
        #50 rst = 1;
    end

    initial begin: DYNAMIC_INPUTS
        integer i;
        #200;

        for (i = 0; i < 16; i = i + 1) begin
            din = $random % 256;
            #(1600000); 
        end

        #(500000);
        $finish;
    end

    initial begin
        $dumpfile("LCD1602_controller_TB.vcd");
        $dumpvars(0, LCD1602_controller_TB);
    end

endmodule
