// interfaces
`include "datapath_cache_if.vh"
`include "cache_control_if.vh"

// cpu types
`include "cpu_types_pkg.vh"
import cpu_types_pkg::*;

typedef struct {
  logic valid;
  logic [25:0] tag;
  word_t block; //only one column for word
} icache_entry;

module icache (
  input logic CLK, nRST,
  datapath_cache_if.cache dcif,
  cache_control_if.caches ccif
);
 parameter CPUID = 0;

  icache_entry instr_cache [16];
  icache_entry entry;

  logic hit;
  word_t idata;
  word_t instr;

  enum bit {IDLE, RAMREAD} state;

  assign entry = instr_cache[dcif.imemaddr[5:2]];
  assign hit = entry.valid && (entry.tag == dcif.imemaddr[31:6]);
  assign idata = entry.block;

  assign ccif.iREN[CPUID] = dcif.imemREN && !hit;
  assign ccif.iaddr[CPUID] = dcif.imemaddr;

  //hit to datapath
  assign dcif.ihit = dcif.imemREN && (hit || !ccif.iwait[CPUID]);
  assign dcif.imemload = hit ? entry.block :
      (ccif.iwait[CPUID] ? instr : ccif.iload[CPUID]);

//  always_comb begin
//    if (hit) begin
//      dcif.imemload = entry.block;
//    end else if (ccif.iwait[CPUID]) begin
//      dcif.imemload = instr;
//    end else begin
//      dcif.imemload = ccif.iload[CPUID];
//    end
//  end

  always_ff @ (posedge CLK, negedge nRST) begin
    if(!nRST) begin
      state <= IDLE;
      instr <= 0;
      for (int i = 0; i < 16; i +=1)
        instr_cache[i].valid <= 0;
    end else begin
      instr <= dcif.imemload;
      if(dcif.imemREN && !ccif.iwait[CPUID]) begin //ram hit
        state <= IDLE;
        instr_cache[dcif.imemaddr[5:2]].block <= ccif.iload[CPUID];
        instr_cache[dcif.imemaddr[5:2]].tag   <= dcif.imemaddr[31:6];
        instr_cache[dcif.imemaddr[5:2]].valid <= 1;
      end else if(dcif.imemREN && !hit)
        state <= RAMREAD;
    end
  end

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
