// interfaces
`include "datapath_cache_if.vh"
`include "cache_control_if.vh"

// cpu types
`include "cpu_types_pkg.vh"
import cpu_types_pkg::*;

typedef struct {
  logic valid;
  logic dirty;
  logic [25:0] tag;
  word_t [1:0] word; //only one column for word
} block_entry;

typedef struct {
  block_entry way[2];
  logic lru;
} dcache_entry;

module dcache (
  input logic CLK, nRST,
  datapath_cache_if.cache dcif,
  cache_control_if.caches ccif
);
 parameter CPUID = 0;

  dcache_entry data_cache[8];
  dcache_entry entry;
  block_entry block, newblock;

  logic [1:0] wayhit;
  logic hit, dirty;
  word_t ddata;
  logic [21:0] requestTag;

  enum logic [2:0] {IDLE, RAMLOAD, RAMWR} state, nextstate;

  assign requestTag = dcif.dmemaddr[31:6];

  assign wayhit[0] = entry.way[0].valid && (entry.way[0].tag == requestTag);
  assign wayhit[1] = entry.way[1].valid && (entry.way[1].tag == requestTag);
  assign hit       = wayhit[0] || wayhit[1];

  assign entry      = data_cache[dcif.dmemaddr[5:3]];
  assign block  = wayhit[0] == 1 ? entry.way[0] : entry.way[1];
  assign ddata      = block.word[dcif.dmemaddr[2]];
  assign dirty = entry.way[entry.lru].dirty;

  always_ff @ (posedge CLK, negedge nRST) begin
    if(!nRST) begin
      state <= IDLE;
      for (int i = 0; i < 8; i +=1) begin
        data_cache[i].way[0].valid  <= 0;
        data_cache[i].way[1].valid  <= 0;
        data_cache[i].way[0].dirty  <= 0;
        data_cache[i].way[1].dirty  <= 0;
        data_cache[i].lru           <= 0;
      end
    end else begin
      state <= nextstate;

      if (state == IDLE && nextstate == RAMLOAD) begin
        data_cache[dcif.dmemaddr[5:3]].way[entry.lru].word[0]          <= ccif.dload[CPUID];
        data_cache[dcif.dmemaddr[5:3]].way[entry.lru].valid   <= 1;
        data_cache[dcif.dmemaddr[5:3]].way[entry.lru].tag     <= requestTag;
      end

      if (state == RAMLOAD && nextstate == IDLE) begin
        data_cache[dcif.dmemaddr[5:3]].way[entry.lru].word[1] <= ccif.dload[CPUID];
        data_cache[dcif.dmemaddr[5:3]].lru <= !data_cache[dcif.dmemaddr[5:3]].lru;
      end

      if (nextstate == IDLE && dcif.dmemWEN) begin
        data_cache[dcif.dmemaddr[5:3]].way[!wayhit[0]].dirty     <= 1;
        data_cache[dcif.dmemaddr[5:3]].way[!wayhit[0]].word[dcif.dmemaddr[2]] <= dcif.dmemstore;
      end
      if (state == RAMWR && nextstate == RAMLOAD)
        data_cache[dcif.dmemaddr[5:3]].way[entry.lru].dirty   <= 0;

      if (nextstate == IDLE && (dcif.dmemREN || dcif.dmemWEN) && hit)
        data_cache[dcif.dmemaddr[5:3]].lru   <= wayhit[0];
    end
  end

  always_comb
  begin
    nextstate = state;
    ccif.dREN = 0;
    ccif.dWEN = 0;
    casez(state)
      IDLE: begin
        if (!hit && (dcif.dmemREN || dcif.dmemWEN)) begin
          if (!dirty) begin
            ccif.dREN = 1;
            ccif.daddr = {dcif.dmemaddr[31:3], 3'b000};
            if (!ccif.dwait[CPUID])
              nextstate = RAMLOAD;
          end else begin
            ccif.dWEN = 1;
            ccif.daddr = {block.tag, dcif.dmemaddr[5:3], 3'b000};
            ccif.dstore = block.word[0];
            if (!ccif.dwait[CPUID])
              nextstate = RAMWR;
          end
        end
      end
      RAMLOAD: begin
        ccif.dREN = 1;
        ccif.daddr = {dcif.dmemaddr[31:3], 3'b100};
        if (!ccif.dwait[CPUID])
          nextstate = IDLE;
      end
      RAMWR: begin
        ccif.dWEN = 1;
        ccif.daddr = {block.tag, dcif.dmemaddr[5:3], 3'b100};
        ccif.dstore = block.word[1];
        if (!ccif.dwait[CPUID])
          nextstate = RAMLOAD;
      end
    endcase

  dcif.dhit = (hit && (dcif.dmemREN || dcif.dmemWEN) && state == IDLE) ||
              (state == RAMLOAD && nextstate == IDLE);

  if (state == RAMLOAD && nextstate == IDLE)
    dcif.dmemload = ccif.dload[CPUID];
  else
    dcif.dmemload = ddata;
  end
endmodule
