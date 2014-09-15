/*
  Eric Villasenor
  evillase@gmail.com

  system test bench, for connected processor (datapath+cache)
  and memory (ram).

*/

// interface
`include "cpu_ram_if.vh"
`include "cache_control_if.vh"
`include "system_if.vh"

// types
`include "cpu_types_pkg.vh"

// mapped timing needs this. 1ns is too fast
`timescale 1 ns / 1 ns

module memory_control_tb;
  // clock period
  parameter PERIOD = 20;
  parameter CPUID = 0;
  parameter LAT = 10;

  // signals
  logic CLK = 1, nRST;

  // clock
  always #(PERIOD/2) CLK++;

  // interface
  cpu_ram_if prif();
  cache_control_if ccif();
  system_if syif();

  // test program
  test #(.CPUID(CPUID), .LAT(LAT))    PROG (CLK,nRST, ccif, syif);

  // memory
  ram #(.LAT(LAT))                    RAM (CLK, nRST, prif);

  // dut
//`ifndef MAPPED
  memory_control                      DUT (CLK,nRST,ccif);
//`else
//  memory_control                      DUT (,,,,//for altera debug ports
//    CLK,
//    nRST,
//    ccif.ramWEN,
//    ccif.ramREN,
//    ccif.ramaddr,
//    ccif.ramstore,
//    ccif.ramload,
//    ccif.ramstate,
//    ccif.iwait,
//    ccif.dwait,
//    ccif.iREN,
//    ccif.dREN,
//    ccif.dWEN,
//    ccif.iload,
//    ccif.dload,
//    ccif.dstore,
//    ccif.iaddr,
//    ccif.daddr,
//    ccif.ccwait,
//    ccif.ccinv,
//    ccif.ccwrite,
//    ccif.cctrans,
//    ccif.ccsnoopaddr);
//`endif

  always_comb
  begin
    prif.memWEN = ccif.ramWEN;
    prif.memREN = ccif.ramREN;
    prif.memaddr = ccif.ramaddr;
    prif.memstore = ccif.ramstore;
    ccif.ramload = prif.ramload;
    ccif.ramstate = prif.ramstate;

    prif.ramWEN = (syif.tbCTRL) ? syif.WEN : prif.memWEN;
    prif.ramREN = (syif.tbCTRL) ? syif.REN : prif.memREN;
    prif.ramaddr = (syif.tbCTRL) ? syif.addr : prif.memaddr;
    prif.ramstore = (syif.tbCTRL) ? syif.store : prif.memstore;
    syif.load = prif.ramload;
  end
endmodule

program test(input logic CLK, output logic nRST, cache_control_if ccif,
  system_if.tb syif);
  parameter CPUID = 0;
  parameter LAT = 0;

  // import word type
  import cpu_types_pkg::word_t;

  initial
  begin
    static word_t v1 = 32'h1234abcd;
    static word_t v2 = 32'h5678abcd;

    @(posedge CLK);
    nRST = 0;
    @(posedge CLK);
    @(negedge CLK);
    nRST = 1;
    @(posedge CLK);
    syif.tbCTRL = 0;
    ccif.iREN[CPUID] = 0;
    ccif.iaddr[CPUID] = 0;
    ccif.dREN[CPUID] = 0;
    ccif.dWEN[CPUID] = 1;
    ccif.dstore[CPUID] = v1;
    ccif.daddr[CPUID] = 'h10;
    @(posedge CLK);
    while (!ccif.dwait[CPUID])
      @(negedge CLK);
    @(posedge CLK);
    ccif.dWEN[CPUID] = 0;
    ccif.iREN[CPUID] = 1;
    ccif.iaddr[CPUID] = 'h10;
    @(posedge CLK);
    while (!ccif.iwait[CPUID])
      @(negedge CLK);
    @(posedge CLK);
    assert(ccif.iload[CPUID] == v1)
      $display("Write 1 succeeded!");
    else
      $display("Write 1 failed!!");

    ccif.dWEN[CPUID] = 1;
    ccif.dstore[CPUID] = v2;
    ccif.daddr[CPUID] = 'h100;
    @(posedge CLK);
    while (!ccif.dwait[CPUID])
      @(negedge CLK);
    @(posedge CLK);
    ccif.dWEN[CPUID] = 0;
    ccif.iREN[CPUID] = 0;
    ccif.dREN[CPUID] = 1;
    ccif.iaddr[CPUID] = 'h100;
    @(posedge CLK);
    while (!ccif.iwait[CPUID])
      @(negedge CLK);
    @(posedge CLK);
    assert(ccif.iload[CPUID] == v2)
      $display("Write 2 succeeded!");
    else
      $display("Write 2 failed!!");

    dump_memory();
    $finish;
  end

  task automatic dump_memory();
    string filename = "memcpu.hex";
    int memfd;

    syif.tbCTRL = 1;
    syif.addr = 0;
    syif.WEN = 0;
    syif.REN = 0;

    memfd = $fopen(filename,"w");
    if (memfd)
      $display("Starting memory dump.");
    else
      begin $display("Failed to open %s.",filename); $finish; end

    for (int unsigned i = 0; memfd && i < 16384; i++)
    begin
      int chksum = 0;
      bit [7:0][7:0] values;
      string ihex;

      syif.addr = i << 2;
      syif.REN = 1;
      repeat (LAT + 1) @(posedge CLK);
      if (syif.load === 0)
        continue;
      values = {8'h04,16'(i),8'h00,syif.load};
      foreach (values[j])
        chksum += values[j];
      chksum = 16'h100 - chksum;
      ihex = $sformatf(":04%h00%h%h",16'(i),syif.load,8'(chksum));
      $fdisplay(memfd,"%s",ihex.toupper());
    end //for
    if (memfd)
    begin
      syif.tbCTRL = 0;
      syif.REN = 0;
      $fdisplay(memfd,":00000001FF");
      $fclose(memfd);
      $display("Finished memory dump.");
    end
  endtask
endprogram
