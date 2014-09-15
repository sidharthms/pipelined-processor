/*
  Eric Villasenor
  evillase@gmail.com

  this block is the coherence protocol
  and artibtration for ram
*/

// interface include
`include "cache_control_if.vh"

// memory types
`include "cpu_types_pkg.vh"

module memory_control (
  input CLK, nRST,
  cache_control_if.cc ccif
);
  // type import
  import cpu_types_pkg::*;

  // number of cpus for cc
  parameter CPUS = 2;
  parameter CPUID = 0;

  always_comb
  begin
    if (ccif.iREN[CPUID] && (ccif.dREN[CPUID] || ccif.dWEN[CPUID]))
    begin
      ccif.ramREN = ccif.dREN[CPUID];
      ccif.ramaddr = ccif.daddr[CPUID];
    end
    else
    begin
      ccif.ramREN = ccif.iREN[CPUID] || ccif.dREN[CPUID];
      ccif.ramaddr = ccif.iREN[CPUID] ? ccif.iaddr[CPUID] :
          ccif.daddr[CPUID];
    end

    ccif.ramWEN = ccif.dWEN[CPUID];
    ccif.ramstore = ccif.dstore[CPUID];

    ccif.iwait[CPUID] = ccif.iaddr[CPUID] == ccif.ramaddr &&
        ccif.ramstate == ACCESS;
    ccif.dwait[CPUID] = ccif.daddr[CPUID] == ccif.ramaddr &&
        ccif.ramstate == ACCESS;
    ccif.iload[CPUID] = ccif.ramload;
    ccif.dload[CPUID] = ccif.ramload;
  end
endmodule
