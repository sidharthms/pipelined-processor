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
  datapath_cache_if.dcache dcif,
  cache_control_if.dcache ccif
);
 parameter CPUID = 0;

  dcache_entry data_cache[8];
  dcache_entry entry;
  block_entry block, newblock;

  logic [1:0] wayhit;
  logic hit, dirty;
  word_t ddata;
  logic [21:0] requestTag;
  logic [2:0]  index;

  logic dREN, dWEN;
  word_t daddr, dstore;

  logic flushed;
  logic [2:0] flush_index;
  logic [1:0] flush_col;
  logic flush_WEN;
  word_t flush_addr, flush_store;


  enum logic [2:0] {IDLE, RAMLOAD, RAMWR} state, nextstate;

  assign requestTag = dcif.dmemaddr[31:6];
  assign index      = dcif.dmemaddr[5:3];

  assign wayhit[0]  = entry.way[0].valid && (entry.way[0].tag == requestTag);
  assign wayhit[1]  = entry.way[1].valid && (entry.way[1].tag == requestTag);
  assign hit        = wayhit[0] || wayhit[1];

  assign entry      = data_cache[index];
  assign block      = wayhit[0] == 1 ? entry.way[0] : entry.way[1];
  assign ddata      = block.word[dcif.dmemaddr[2]];
  assign dirty      = entry.way[entry.lru].dirty;

  assign dcif.dhit = (hit && (dcif.dmemREN || dcif.dmemWEN) && state == IDLE) ||
                     (state == RAMLOAD && nextstate == IDLE);

  assign dcif.dmemload = (state == RAMLOAD && nextstate == IDLE &&
                          dcif.dmemaddr[2] == 1) ? ccif.dload[CPUID] : ddata;

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
        data_cache[index].way[entry.lru].word[0] <= ccif.dload[CPUID];
        data_cache[index].way[entry.lru].valid   <= 1;
        data_cache[index].way[entry.lru].tag     <= requestTag;
      end

      if (state == RAMLOAD && nextstate == IDLE) begin
        data_cache[index].way[entry.lru].word[1] <= ccif.dload[CPUID];
        data_cache[index].lru <= !data_cache[index].lru;
      end

      if (state != RAMWR && nextstate == IDLE && dcif.dmemWEN) begin
        if (state == IDLE) begin
          data_cache[index].way[wayhit[1]].dirty  <= 1;
          data_cache[index].way[wayhit[1]].word[dcif.dmemaddr[2]] <=
              dcif.dmemstore;
        end else begin
          data_cache[index].way[entry.lru].dirty  <= 1;
          data_cache[index].way[entry.lru].word[dcif.dmemaddr[2]] <=
              dcif.dmemstore;
        end
      end
      if (state == RAMWR && nextstate == IDLE)
        data_cache[index].way[entry.lru].dirty  <= 0;

      if (nextstate == IDLE && (dcif.dmemREN || dcif.dmemWEN) && hit)
        data_cache[index].lru   <= wayhit[0];
    end
  end

  always_comb
  begin
    nextstate   = state;
    dREN   = 0;
    dWEN   = 0;
    dstore = 0;
    daddr  = 0;
    casez(state)
      IDLE: begin
        if (!hit && (dcif.dmemREN || dcif.dmemWEN)) begin
          if (!dirty) begin
            dREN = 1;
            daddr = {dcif.dmemaddr[31:3], 3'b000};
            if (!ccif.dwait[CPUID])
              nextstate = RAMLOAD;
          end else begin
            dWEN = 1;
            daddr = {entry.way[entry.lru].tag, index, 3'b000};
            dstore = entry.way[entry.lru].word[0];
            if (!ccif.dwait[CPUID])
              nextstate = RAMWR;
          end
        end
      end
      RAMLOAD: begin
        dREN = 1;
        daddr = {dcif.dmemaddr[31:3], 3'b100};
        if (!ccif.dwait[CPUID])
          nextstate = IDLE;
      end
      RAMWR: begin
        dWEN = 1;
        daddr = {entry.way[entry.lru].tag, index, 3'b100};
        dstore = entry.way[entry.lru].word[1];
        if (!ccif.dwait[CPUID])
          nextstate = IDLE;
      end
    endcase
  end

  always_ff @ (posedge CLK, negedge nRST) begin
    if(!nRST) begin
      flush_index <= 0;
      flush_col   <= 0;
      flushed     <= 0;
    end else if (dcif.halt && !dcif.flushed) begin
      if (!ccif.dwait[CPUID] || !flush_WEN) begin
        if (flush_col == 3) begin
          if (flush_index == 7)
            flushed   <= 1;
          else begin
            flush_index <= flush_index + 1;
            flush_col   <= 0;
          end
        end else begin
          flush_col   <= flush_col + 1;
        end
      end
    end
  end
  assign flush_WEN   = !flushed & data_cache[flush_index].way[flush_col[1]].dirty;
  assign flush_addr  = {data_cache[flush_index].way[flush_col[1]].tag,
                        flush_index, flush_col[0], 2'b0};
  assign flush_store =
            data_cache[flush_index].way[flush_col[1]].word[flush_col[0]];

  assign ccif.dREN    = dREN;
  assign ccif.dWEN    = dcif.halt ? flush_WEN : dWEN;
  assign ccif.daddr    = dcif.halt ? flush_addr : daddr;
  assign ccif.dstore  = dcif.halt ? flush_store : dstore;

  assign dcif.flushed = flushed;
endmodule
