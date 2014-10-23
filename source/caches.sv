/*
  Eric Villasenor
  evillase@gmail.com

  this block holds the i and d cache
*/


// interfaces
`include "datapath_cache_if.vh"
`include "cache_control_if.vh"

// cpu types
`include "cpu_types_pkg.vh"

`define USE_ICACHE
`define USE_DCACHE

module caches (
  input logic CLK, nRST,
  datapath_cache_if.cache dcif,
  cache_control_if.caches ccif
);
  // import types
  import cpu_types_pkg::word_t;

  parameter CPUID = 0;

  word_t instr;

  // dcache
`ifdef USE_DCACHE
  dcache  DCACHE(.CLK, .nRST, .dcif, .ccif);
`endif

`ifdef USE_ICACHE
  // icache
  icache  ICACHE(.CLK, .nRST, .dcif, .ccif);
`endif

`ifndef USE_ICACHE
  // single cycle instr saver (for memory ops)
  always_ff @(posedge CLK)
  begin
    if (!nRST)
    begin
      instr <= '0;
    end
    else
    if (!ccif.iwait[CPUID])
    begin
      instr <= ccif.iload[CPUID];
    end
  end

  assign dcif.ihit = (dcif.imemREN) ? ~ccif.iwait[CPUID] : 0;
  assign dcif.imemload = (ccif.iwait[CPUID]) ? instr : ccif.iload[CPUID];
  assign ccif.iaddr[CPUID] = dcif.imemaddr;
  assign ccif.iREN[CPUID] = dcif.imemREN;
`endif

`ifndef USE_DCACHE
  // dcache invalidate before halt
  assign dcif.flushed = dcif.halt;

  assign ccif.dREN[CPUID] = dcif.dmemREN;
  assign ccif.dWEN[CPUID] = dcif.dmemWEN;
  assign ccif.dstore[CPUID] = dcif.dmemstore;
  assign ccif.daddr[CPUID] = dcif.dmemaddr;

  assign dcif.dhit = (dcif.dmemREN|dcif.dmemWEN) ? ~ccif.dwait[CPUID] : 0;
  assign dcif.dmemload = ccif.dload[CPUID];
`endif
endmodule
