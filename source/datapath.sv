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

typedef enum {
  WRITE_RD,
  WRITE_RT,
  WRITE_CUSTOM,
  WRITE_NONE } write_t;

typedef enum {
  ALUIN1_RS,
  ALUIN1_CUSTOM } aluin1_t;

typedef enum {
  ALUIN2_RT,
  ALUIN2_SIMM,
  ALUIN2_ZIMM,
  ALUIN2_CUSTOM } aluin2_t;

module datapath (
  input logic CLK, nRST,
  datapath_cache_if.dp dpif
);
  // import types
  import cpu_types_pkg::*;

  // pc init
  parameter PC_INIT = 0;

  // PC
  word_t pc, npc, npc_default;
  logic pause_pc;

  logic phase, last_phase, next_phase_condition;

  // Control Singals
  write_t  write_dest;
  aluin1_t aluin1;
  aluin2_t aluin2;
  aluop_t  funct_aluop;

  // Instruction Fields
  opcode_t opcode;
  logic [4:0] rs, rt, rd, shamt, funct;
  logic [15:0] immediate;
  logic [25:0] address;

  // ALU signals
  aluop_t alu_aluop;
  word_t  alu_port_a;
  word_t  alu_port_b;
  logic   alu_negative;
  logic   alu_overflow;
  logic   alu_zero;
  word_t  alu_result;

  word_t custom_aluin1, custom_aluin2, custom_wdat;
  regbits_t custom_rsel1, custom_rsel2, custom_wsel;

  word_t rdat1, rdat2;

  // Interface signals
  logic imemREN, dmemREN, dmemWEN, halt;
  word_t imemload, dmemload, dmemstore;

  // Register File
  register_file_if rfif();

  alu alu_module(
    .aluop(alu_aluop),
    .port_a(alu_port_a),
    .port_b(alu_port_b),
    .negative(alu_negative),
    .overflow(alu_overflow),
    .zero(alu_zero),
    .result(alu_result));

  register_file register_file_module(
    .CLK,
    .nRST,
    .rfif);

  always_comb begin
    opcode    = opcode_t'(imemload[31:26]);
    rs        = imemload[25:21];
    rt        = imemload[20:16];
    rd        = imemload[15:11];
    shamt     = imemload[10:6];
    funct     = imemload[5:0];
    immediate = imemload[15:0];
    address   = imemload[25:0];
  end

  always_ff @(posedge CLK, negedge nRST) begin
    if (!nRST)
      pc <= PC_INIT;
    else if (!pause_pc)
      pc <= npc;
  end

  always_ff @(posedge CLK, negedge nRST) begin
    if (!nRST)
      phase <= 1;
    else if (last_phase)
      phase <= 1;
    else if (next_phase_condition)
      phase <= phase + 1;
  end

  always_comb
  begin
    npc_default = pc + 4;
    npc = npc_default;

    last_phase = 1;
    next_phase_condition = 0;

    if (opcode == RTYPE)
      write_dest = WRITE_RD;
    else
      write_dest = WRITE_RT;
    aluin1 = ALUIN1_RS;
    dmemREN = 0;
    dmemWEN = 0;
    halt = 0;

    case (opcode)
      RTYPE : begin
        aluin2 = ALUIN2_RT;
        alu_aluop = funct_aluop;
        case (funct)
          JR :  begin
            write_dest = WRITE_NONE;
            npc = rfif.rdat1;
          end
          SLL,
          SRL : begin
            aluin2 = ALUIN2_CUSTOM;
            custom_aluin2 = shamt;
          end
        endcase
      end
      ADDIU: begin
        aluin2 = ALUIN2_SIMM;
        alu_aluop = ALU_ADD;
      end
      ANDI : begin
        aluin2 = ALUIN2_ZIMM;
        alu_aluop = ALU_AND;
      end
      BEQ, BNE : begin
        aluin1 = ALUIN1_CUSTOM;
        custom_aluin1 = npc_default;
        aluin2 = ALUIN2_SIMM;
        alu_aluop = ALU_ADD;
        write_dest = WRITE_NONE;
        custom_rsel1 = rs;
        custom_rsel2 = rt;
        if (opcode == BEQ && rfif.rdat1 == rfif.rdat2)
          npc = alu_result;
        else if (opcode == BNE && rfif.rdat1 != rfif.rdat2)
          npc = alu_result;
      end
      LUI : begin
        write_dest= WRITE_CUSTOM;
        custom_wsel = rt;
        custom_wdat = { immediate, 16'h0 };
      end
      LW : begin
        case (phase)
          0 : begin
            aluin2 = ALUIN2_SIMM;
            alu_aluop = ALU_ADD;
            write_dest = WRITE_CUSTOM;
            custom_wsel = rt;
            custom_wdat = dmemload;
            dmemREN = 1;
            next_phase_condition = dpif.dhit;
            last_phase = 0;
          end
          1 : begin
            write_dest = WRITE_NONE;
            dmemREN = 0;
          end
        endcase
      end
      ORI : begin
        aluin2 = ALUIN2_ZIMM;
        alu_aluop = ALU_OR;
      end
      SLTI : begin
        aluin2 = ALUIN2_SIMM;
        alu_aluop = ALU_SLT;
      end
      SLTIU : begin
        aluin2 = ALUIN2_SIMM;
        alu_aluop = ALU_SLTU;
      end
      SW : begin
        case (phase)
          0 : begin
            aluin2 = ALUIN2_SIMM;
            alu_aluop = ALU_ADD;
            write_dest = WRITE_NONE;
            dmemWEN = 1;
            custom_rsel2 = rt;
            dmemstore = rfif.rdat2;
            next_phase_condition = dpif.dhit;
            last_phase = 0;
          end
          1 : begin
            write_dest = WRITE_NONE;
            dmemWEN = 0;
          end
        endcase
      end
      XORI : begin
        aluin2 = ALUIN2_ZIMM;
        alu_aluop = ALU_XOR;
      end
      J : begin
        write_dest = WRITE_NONE;
        npc = address;
      end
      JAL : begin
        write_dest = WRITE_CUSTOM;
        custom_wsel = rt;
        custom_wdat = npc_default;
        npc = address;
      end
      HALT : halt = 1;
    endcase

    case (funct)
      SLL  : funct_aluop = ALU_SLL;
      SRL  : funct_aluop = ALU_SRL;
      ADDU : funct_aluop = ALU_ADD;
      SUBU : funct_aluop = ALU_SUB;
      default : funct_aluop = aluop_t'({ 2'b10, funct });
    endcase
  end

  always_comb begin
    rdat1 = rfif.rdat1;
    rdat2 = rfif.rdat2;

    dpif.imemREN = 1;
    dpif.imemaddr = pc;
    dpif.dmemaddr = alu_result;
    dpif.dmemREN = dmemREN;
    dpif.dmemWEN = dmemWEN;
    dpif.dmemstore = dmemstore;
    dpif.dmemstore = dmemstore;
    dpif.halt = halt;
    imemload = dpif.imemload;
    dmemload = dpif.dmemload;

    pause_pc = !dpif.ihit && !halt;
    rfif.WEN = 1;
    rfif.wdat = alu_result;
    case (write_dest)
      WRITE_RD     : rfif.wsel = rd;
      WRITE_RT     : rfif.wsel = rt;
      WRITE_CUSTOM : begin
        rfif.wsel = custom_wsel;
        rfif.wdat = custom_wdat;
      end
      WRITE_NONE   : rfif.WEN = 0;
    endcase

    if (aluin1 != ALUIN1_RS)
      rfif.rsel1 = custom_rsel1;

    if (aluin2 != ALUIN2_RT)
      rfif.rsel2 = custom_rsel2;

    case (aluin1)
      ALUIN1_RS     : begin
        rfif.rsel1 = rs;
        alu_port_a = rfif.rdat1;
      end
      ALUIN1_CUSTOM : alu_port_a = custom_aluin1;
    endcase

    case (aluin2)
      ALUIN2_RT     : begin
        rfif.rsel2 = rt;
        alu_port_b = rfif.rdat2;
      end
      ALUIN2_SIMM   : alu_port_b = immediate;
      ALUIN2_ZIMM   : alu_port_b = $signed(immediate);
      ALUIN2_CUSTOM : alu_port_b = custom_aluin2;
    endcase
  end
endmodule
