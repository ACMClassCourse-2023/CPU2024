// testbench top module file
// for simulation only

`timescale 1ps/1ps
module testbench;

reg clk;
reg rst;
reg rx;

riscv_top #(.SIM(1)) top(
    .EXCLK(clk),
    .btnC(rst),
    .Tx(),
    .Rx(rx),
    .led()
);

initial begin
  clk=0;
  rst=1;
  rx=0;
  repeat(50) #1 clk=!clk;
  rst=0; 
  forever #1 clk=!clk;
end

initial begin
`ifndef ONLINE_JUDGE
  $dumpfile("test.vcd");
  $dumpvars(0, testbench);
`endif
  #300000000 $finish;
end

endmodule
