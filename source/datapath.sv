/*
  Eric Villasenor
  evillase@gmail.com

  datapath contains register file, control, hazard,
  muxes, and glue logic for processor
*/

// data path interface
`include "datapath_cache_if.vh"

// alu op, mips op, and instruction type
`include "cpu_types_pkg.vh"

module datapath (
  input logic CLK, nRST,
  datapath_cache_if.dp dpif
);
  // import types
  import cpu_types_pkg::*;

  // pc init
  parameter PC_INIT = 0;

  register_file_if rfif();
  fetch_decode_if fdif();
  decode_exec_if  deif();
  exec_mem_if     emif();
  mem_wb_if       mwif();

  logic fetch_en, fetch_zero;
  logic decode_en, decode_zero;
  logic exec_en, exec_zero;
  logic mem_en;

  logic jump_instr, branch_instr, misc_npc_en;
  word_t branch_target, misc_npc;
  logic alu_zero;

  logic data_shadow, data_stall, cancel_fetch, squash;
  word_t alu_result, npc_default;
  logic branch_taken, npc_valid;

  word_t mem_data;

  // Register File

  register_file register_file_module(.CLK, .nRST, .rfif);
  fetch           fetch_module(.CLK, .nRST, .en(fetch_en), .zero(fetch_zero),
                    .misc_npc_en, .misc_npc, .ihit(dpif.ihit),
                    .halt(dpif.halt), .imemload(dpif.imemload), .npc_valid,
                    .npc_default, .imemREN(dpif.imemREN),
                    .imemaddr(dpif.imemaddr), .out(fdif), .branch_taken);
  decode          decode_module(.CLK, .nRST,.en(decode_en), .zero(decode_zero),
                    .rdat1(rfif.rdat1), .rdat2(rfif.rdat2), .rsel1(rfif.rsel1),
                    .rsel2(rfif.rsel2), .jump_instr, .branch_instr,
                    .branch_target, .in(fdif), .out(deif));
  exec            exec_module(.CLK, .nRST, .en(exec_en), .zero(exec_zero),
                    .alu_zero, .alu_result, .in(deif), .out(emif));
  mem             mem_module(.CLK, .nRST, .en(mem_en), .dhit(dpif.dhit),
                    .dmemload(dpif.dmemload), .data_shadow, .data_stall,
                    .mem_data, .dmemREN(dpif.dmemREN), .dmemWEN(dpif.dmemWEN),
                    .dmemaddr(dpif.dmemaddr), .dmemstore(dpif.dmemstore),
                    .in(emif), .out(mwif));
  wb              wb_module(.CLK, .nRST, .halt(dpif.halt), .WEN(rfif.WEN),
                    .wsel(rfif.wsel), .wdat(rfif.wdat), .in(mwif));

  branch          branch_module(.CLK, .nRST, .jump_instr, .branch_taken,
                    .alu_zero(alu_zero), .npc_valid, .npc_default,
                    .branch_target, .misc_npc_en, .misc_npc, .cancel_fetch,
                    .squash, .emif, .deif, .fdif);

  forward         forward_module(.CLK, .nRST, .data_shadow, .data_stall,
                    .alu_result, .dmemload(mem_data), .mwif, .emif, .deif,
                    .fdif);

  always_comb begin
    mem_en    = !data_stall && !dpif.halt;
    exec_en   = mem_en;
    fetch_en  = exec_en;
    decode_en = fetch_en;

    exec_zero = 0;
    fetch_zero = cancel_fetch;
    decode_zero = squash;
  end
endmodule
