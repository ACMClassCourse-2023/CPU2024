// riscv top module file
// modification allowed for debugging purposes

module riscv_top #(
    parameter SIM = 0  // whether in simulation
) (
    input  wire EXCLK,
    input  wire btnC,
    output wire Tx,
    input  wire Rx,
    output wire led
);

  localparam SYS_CLK_FREQ = 100000000;
  localparam UART_BAUD_RATE = 115200;
  localparam RAM_ADDR_WIDTH = 17;  // 128KiB ram, should not be modified

  reg rst;
  reg rst_delay;

  // assign EXCLK (or your own clock module) to clk
  wire clk = EXCLK;

  always @(posedge clk or posedge btnC) begin
    if (btnC) begin
      rst <= 1'b1;
      rst_delay <= 1'b1;
    end else begin
      rst_delay <= 1'b0;
      rst <= rst_delay;
    end
  end


  //
  // RAM: internal ram
  //
  wire [               7:0] bus_mem_din;
  wire [              31:0] bus_mem_addr;
  wire                      bus_mem_we;  // write enable
  wire                      ram_en;
  wire [RAM_ADDR_WIDTH-1:0] ram_addr;
  wire [               7:0] ram_dout;

  single_port_ram_sync #(
      .ADDR_WIDTH(RAM_ADDR_WIDTH),
      .DATA_WIDTH(8)
  ) ram0 (
      .clk(clk),
      .we(ram_en & bus_mem_we),
      .addr_a(ram_addr),
      .din_a(bus_mem_din),
      .dout_a(ram_dout)
  );


  //
  // CPU: CPU that implements RISC-V 32b integer base user-level real-mode ISA
  //
  wire [31:0] cpu_mem_a;
  wire        cpu_mem_wr;
  wire [ 7:0] cpu_mem_din;
  wire [ 7:0] cpu_mem_dout;
  wire        cpu_rdy;
  wire        cpu_io_buffer_full;
  wire [31:0] cpu_dbgreg_dout;

  wire        hci_program_finish;

  cpu cpu0 (
      .clk_in        (clk),
      .rst_in        (rst | hci_program_finish),
      .rdy_in        (cpu_rdy),
      .mem_din       (cpu_mem_din),
      .mem_dout      (cpu_mem_dout),
      .mem_a         (cpu_mem_a),
      .mem_wr        (cpu_mem_wr),
      .io_buffer_full(cpu_io_buffer_full),

      .dbgreg_dout(cpu_dbgreg_dout)
  );

  //
  // HCI: host communication interface block. Use controller to interact.
  //
  wire                      hci_active_out;
  wire [               7:0] hci_ram_din;
  wire [               7:0] hci_ram_dout;
  wire [RAM_ADDR_WIDTH-1:0] hci_ram_a;
  wire                      hci_ram_wr;

  wire                      hci_io_en;
  wire [               2:0] hci_io_sel;
  wire [               7:0] hci_io_din;
  wire [               7:0] hci_io_dout;
  wire                      hci_io_wr;
  wire                      hci_io_full;

  hci #(
      .SYS_CLK_FREQ(SYS_CLK_FREQ),
      .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
      .BAUD_RATE(UART_BAUD_RATE)
  ) hci0 (
      .clk           (clk),
      .rst           (rst),
      .tx            (Tx),
      .rx            (Rx),
      .active        (hci_active_out),
      .ram_din       (hci_ram_din),
      .ram_dout      (hci_ram_dout),
      .ram_a         (hci_ram_a),
      .ram_wr        (hci_ram_wr),
      .io_sel        (hci_io_sel),
      .io_en         (hci_io_en),
      .io_din        (hci_io_din),
      .io_dout       (hci_io_dout),
      .io_wr         (hci_io_wr),
      .io_full       (hci_io_full),
      .program_finish(hci_program_finish),
      .cpu_dbgreg_din(cpu_dbgreg_dout)
  );

  // hci is always disabled in simulation
  wire hci_active = hci_active_out & ~SIM;

  // For RAM
  // ram will have two ways to access: from cpu or hci
  assign bus_mem_addr = hci_active ? hci_ram_a : cpu_mem_a;
  assign bus_mem_we   = hci_active ? hci_ram_wr : cpu_mem_wr;
  assign bus_mem_din  = hci_active ? hci_ram_dout : cpu_mem_dout;
  assign ram_en       = (bus_mem_addr[RAM_ADDR_WIDTH:RAM_ADDR_WIDTH-1] == 2'b11) ? 1'b0 : 1'b1;
  assign ram_addr     = bus_mem_addr[RAM_ADDR_WIDTH-1:0];

  // For HCI
  assign hci_io_sel   = cpu_mem_a[2:0];
  assign hci_io_en    = (cpu_mem_a[RAM_ADDR_WIDTH:RAM_ADDR_WIDTH-1] == 2'b11) ? 1'b1 : 1'b0;
  assign hci_io_wr    = cpu_mem_wr;
  assign hci_io_din   = cpu_mem_dout;
  assign hci_ram_din  = ram_dout;

  // For CPU
  // pause cpu on hci active
  reg cpu_mem_din_switch;
  assign cpu_rdy            = ~hci_active;
  assign cpu_mem_din        = (cpu_mem_din_switch) ? hci_io_dout : ram_dout;
  assign cpu_io_buffer_full = hci_io_full & ~{1{SIM[0]}};

  always @(posedge clk) begin
    if (cpu_rdy) begin
      cpu_mem_din_switch <= (cpu_mem_a[RAM_ADDR_WIDTH:RAM_ADDR_WIDTH-1] == 2'b11) ? 1'b1 : 1'b0;
    end
  end


  //
  // The following code is for debugging purposes
  //

  // indicates debug break
  assign led = hci_active;

endmodule
