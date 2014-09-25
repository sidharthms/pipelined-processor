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
  WRITE_ALU_RD,
  WRITE_ALU_RT,
  WRITE_UI_RT,
  WRITE_RAM_RT,
  WRITE_NPC_31,
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
  logic pause_pc;

  // ALU signals
  aluop_t alu_aluop;
  word_t  alu_port_a;
  word_t  alu_port_b;
  logic   alu_negative;
  logic   alu_overflow;
  logic   alu_zero;
  word_t  alu_result;

  // Interface signals
  logic dmemREN, dmemWEN, halt;
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


  // Fetch block
  logic exec_branch, jump_instr;
  opcode_t decode_opcode;
  logic [4:0] decode_rs, decode_rt, decode_rd, decode_shamt;
  funct_t decode_funct;
  logic [15:0] decode_immediate;
  logic [25:0] decode_address;
  word_t instruction, pc, decode_npc_default, fetch_npc, jump_addr;

  always @(posedge CLK, negedge nRST) begin
    if (!nRST) begin
      pc <= PC_INIT;
      decode_npc_default <= PC_INIT + 4;
      instruction <= 'd0;
    end
    else if (!pause_pc) begin
      instruction <= dpif.imemload;
      if (exec_branch)
        fetch_npc = alu_result;
      else if (jump_instr)
        fetch_npc = jump_addr;
      else
        fetch_npc = decode_npc_default;
      pc <= fetch_npc;
      decode_npc_default <= fetch_npc + 4;
    end
  end
  always_comb begin
    decode_opcode    = opcode_t'(instruction[31:26]);
    decode_rs        = instruction[25:21];
    decode_rt        = instruction[20:16];
    decode_rd        = instruction[15:11];
    decode_shamt     = instruction[10:6];
    decode_funct     = funct_t'(instruction[5:0]);
    decode_immediate = instruction[15:0];
    decode_address   = instruction[25:0];
  end

  // Decode block
  write_t  exec_write_info;
  aluin1_t exec_aluin1;
  aluin2_t exec_aluin2;
  aluop_t  funct_aluop, exec_alu_aluop;
  logic exec_dmemREN, exec_dmemWEN, exec_halt;
  word_t exec_npc_default, exec_dmemstore, exec_custom_aluin1, exec_custom_aluin2;
  regbits_t custom_rsel1, custom_rsel2;
  word_t exec_rdat1, exec_rdat2;
  logic [4:0] exec_rd, exec_rt;
  logic [15:0] exec_immediate;

  write_t  comb_write_info;
  aluin1_t comb_aluin1;
  aluin2_t comb_aluin2;
  aluop_t  comb_alu_aluop;
  logic comb_dmemREN, comb_dmemWEN, comb_halt, comb_branch;
  word_t comb_npc_default, comb_dmemstore, comb_custom_aluin1, comb_custom_aluin2;
  word_t comb_rdat1, comb_rdat2;
  logic [4:0] comb_rd, comb_rt;
  logic [15:0] comb_immediate;

  always @(posedge CLK, negedge nRST)
  begin
    if(!nRST) begin
      exec_halt          <= 0;
    end
    else begin
      exec_halt          <= comb_halt;
    end
    if (!pause_pc) begin
      exec_write_info    <= comb_write_info;
      exec_aluin1        <= comb_aluin1;
      exec_aluin2        <= comb_aluin2;
      exec_dmemREN       <= comb_dmemREN;
      exec_dmemWEN       <= comb_dmemWEN;
      exec_branch        <= comb_branch;

      exec_dmemstore     <= comb_dmemstore;
      exec_custom_aluin1 <= comb_custom_aluin1;
      exec_custom_aluin2 <= comb_custom_aluin2;
      exec_alu_aluop     <= comb_alu_aluop;

      exec_rd            <= comb_rd;
      exec_rt            <= comb_rt;
      exec_immediate     <= comb_immediate;
      exec_npc_default   <= comb_npc_default;

      exec_rdat1         <= comb_rdat1;
      exec_rdat2         <= comb_rdat2;
    end
  end
  always_comb begin
    if (decode_opcode == RTYPE)
      comb_write_info  = WRITE_ALU_RD;
    else
      comb_write_info  = WRITE_ALU_RT;
    comb_aluin1        = ALUIN1_RS;
    comb_aluin2        = ALUIN2_RT;
    comb_dmemREN       = 0;
    comb_dmemWEN       = 0;
    comb_branch        = 0;
    comb_halt          = 0;

    comb_dmemstore     = 0;
    custom_rsel1       = 0;
    custom_rsel2       = 0;
    comb_custom_aluin1 = 0;
    comb_custom_aluin2 = 0;
    comb_alu_aluop     = ALU_SLL;

    comb_rd            = decode_rd;
    comb_rt            = decode_rt;
    comb_immediate     = decode_immediate;
    comb_npc_default   = decode_npc_default;

    comb_rdat1         = rfif.rdat1;
    comb_rdat2         = rfif.rdat2;

    jump_instr         = 0;
    jump_addr          = 0;

    case (decode_opcode)
      RTYPE : begin
        comb_aluin2 = ALUIN2_RT;
        comb_alu_aluop = funct_aluop;
        case (decode_funct)
          JR :  begin
            comb_aluin2 = ALUIN2_CUSTOM;
            custom_rsel2 = 31;
            comb_write_info = WRITE_NONE;
            jump_addr = rfif.rdat2;
            jump_instr = 1;
          end
          SLL,
          SRL : begin
            comb_aluin2 = ALUIN2_CUSTOM;
            comb_custom_aluin2 = decode_shamt;
          end
        endcase
      end
      ADDIU: begin
        comb_aluin2 = ALUIN2_SIMM;
        comb_alu_aluop = ALU_ADD;
      end
      ANDI : begin
        comb_aluin2 = ALUIN2_ZIMM;
        comb_alu_aluop = ALU_AND;
      end
      BEQ, BNE : begin
        comb_aluin1 = ALUIN1_CUSTOM;
        comb_custom_aluin1 = decode_npc_default;
        comb_aluin2 = ALUIN2_CUSTOM;
        comb_custom_aluin2 = $signed({ decode_immediate, 2'b0 });
        comb_alu_aluop = ALU_ADD;
        comb_write_info = WRITE_NONE;
        custom_rsel1 = decode_rs;
        custom_rsel2 = decode_rt;
        if (decode_opcode == BEQ && rfif.rdat1 == rfif.rdat2)
          comb_branch = 1;
        else if (decode_opcode == BNE && rfif.rdat1 != rfif.rdat2)
          comb_branch = 1;
      end
      LUI : begin
        comb_aluin1 = ALUIN1_CUSTOM;
        comb_custom_aluin1 = decode_immediate;
        comb_aluin2 = ALUIN2_CUSTOM;
        comb_custom_aluin2 = 16;
        comb_alu_aluop = ALU_SLL;
      end
      LW : begin
        comb_aluin2 = ALUIN2_SIMM;
        comb_alu_aluop = ALU_ADD;
        comb_write_info = WRITE_RAM_RT;
        comb_dmemREN = 1;
      end
      ORI : begin
        comb_aluin2 = ALUIN2_ZIMM;
        comb_alu_aluop = ALU_OR;
      end
      SLTI : begin
        comb_aluin2 = ALUIN2_SIMM;
        comb_alu_aluop = ALU_SLT;
      end
      SLTIU : begin
        comb_aluin2 = ALUIN2_SIMM;
        comb_alu_aluop = ALU_SLTU;
      end
      SW : begin
        comb_aluin2 = ALUIN2_SIMM;
        custom_rsel2 = decode_rt;
        comb_alu_aluop = ALU_ADD;
        comb_write_info = WRITE_NONE;
        comb_dmemWEN = 1;
        comb_dmemstore = rfif.rdat2;
      end
      XORI : begin
        comb_aluin2 = ALUIN2_ZIMM;
        comb_alu_aluop = ALU_XOR;
      end
      J : begin
        comb_write_info = WRITE_NONE;
        jump_addr = { decode_npc_default[31:28], decode_address, 2'b0 };
        jump_instr = 1;
      end
      JAL : begin
        comb_write_info = WRITE_NPC_31;
        jump_addr = { decode_npc_default[31:28], decode_address, 2'b0 };
        jump_instr = 1;
      end
      HALT : begin
        comb_write_info = WRITE_NONE;
        comb_halt = 1;
      end
    endcase
  end
  always_comb begin
    case (decode_funct)
      SLL  : funct_aluop = ALU_SLL;
      SRL  : funct_aluop = ALU_SRL;
      ADDU : funct_aluop = ALU_ADD;
      SUBU : funct_aluop = ALU_SUB;
      default : funct_aluop = aluop_t'(decode_funct[3:0]);
    endcase
  end
  always_comb begin
    rfif.rsel1 = 0;
    rfif.rsel2 = 0;

    if (comb_aluin1 != ALUIN1_RS)
      rfif.rsel1 = custom_rsel1;
    else
      rfif.rsel1 = decode_rs;

    if (comb_aluin2 != ALUIN2_RT)
      rfif.rsel2 = custom_rsel2;
    else
      rfif.rsel2 = decode_rt;
  end

  // ALU block
  logic data_dmemWEN, data_dmemREN, data_halt;
  write_t data_write_info;
  logic [4:0] data_rd, data_rt;
  logic [15:0] data_immediate;
  word_t data_alu_result, data_npc_default, data_dmemstore;

  always @ (posedge CLK, negedge nRST)
  begin
    if(!nRST)
    begin
      data_dmemWEN <= 0;
      data_dmemREN <= 0;
      data_halt    <= 0;
    end
    else if (!pause_pc) begin
      data_dmemWEN <= exec_dmemWEN;
      data_dmemREN <= exec_dmemREN;
      data_halt    <= exec_halt;
    end
    if (!pause_pc) begin
      data_write_info   <= exec_write_info;
      data_rd           <= exec_rd;
      data_rt           <= exec_rt;
      data_alu_result   <= alu_result;
      data_immediate    <= exec_immediate;
      data_npc_default  <= exec_npc_default;
      data_dmemstore    <= exec_dmemstore;
    end
  end
  always_comb begin
    alu_aluop = exec_alu_aluop;
    if(exec_aluin1 == ALUIN1_RS)
      alu_port_a = exec_rdat1;
    else
      alu_port_a = exec_custom_aluin1;

    case (exec_aluin2)
      ALUIN2_RT     : alu_port_b = exec_rdat2;
      ALUIN2_SIMM   : alu_port_b = $signed(exec_immediate);
      ALUIN2_ZIMM   : alu_port_b = exec_immediate;
      ALUIN2_CUSTOM : alu_port_b = exec_custom_aluin2;
    endcase
  end

  // RAM stage
  write_t reg_wr_write_info;
  logic [4:0] reg_wr_rd, reg_wr_rt;
  logic [15:0] reg_wr_immediate;
  word_t reg_wr_alu_result, reg_wr_npc_default, reg_wr_dmemload;
  logic op_complete, reg_wr_halt;

  always_ff @ (posedge CLK, negedge nRST)
  begin
    if(!nRST) begin
      op_complete <= 0;
      reg_wr_halt <= 0;
    end
    else begin
      reg_wr_halt <= data_halt;
      if (dpif.dhit)
        op_complete <= 1;
      else if (dpif.ihit)
        op_complete <= 0;
    end
    reg_wr_dmemload <= dpif.dmemload;
    reg_wr_rd <= data_rd;
    reg_wr_rt <= data_rt;
    reg_wr_alu_result <= data_alu_result;
    reg_wr_immediate <= data_immediate;
    reg_wr_npc_default <= data_npc_default;
    reg_wr_write_info <= op_complete ? WRITE_NONE : data_write_info;
  end
  always_comb begin
    dpif.imemREN = 1;
    dpif.imemaddr = pc;
    dpif.dmemaddr = data_alu_result;
    dpif.dmemREN = data_dmemREN && !op_complete;
    dpif.dmemWEN = data_dmemWEN && !op_complete;
    dpif.dmemstore = data_dmemstore;

    if (data_dmemREN || data_dmemWEN)
      pause_pc = (!dpif.dhit && !dpif.ihit) || !op_complete;
    else
      pause_pc = !dpif.ihit || exec_halt;
  end

  // Write back stage
  always @ (posedge CLK, negedge nRST) begin
    if (!nRST)
      dpif.halt <= 0;
    else
      dpif.halt <= reg_wr_halt;
  end
  always_comb begin
    rfif.WEN = 1;
    rfif.wsel = 0;
    rfif.wdat = reg_wr_alu_result;
    case (reg_wr_write_info)
      WRITE_ALU_RD     : rfif.wsel = reg_wr_rd;
      WRITE_ALU_RT     : rfif.wsel = reg_wr_rt;
      WRITE_UI_RT      : begin
        rfif.wsel = reg_wr_rt;
        rfif.wdat = { reg_wr_immediate, 16'b0 };
      end
      WRITE_RAM_RT     : begin
        rfif.wsel = reg_wr_rt;
        rfif.wdat = reg_wr_dmemload;
      end
      WRITE_NPC_31     : begin
        rfif.wsel = 31;
        rfif.wdat = reg_wr_npc_default;
      end
      WRITE_NONE   : rfif.WEN = 0;
    endcase
  end


endmodule
