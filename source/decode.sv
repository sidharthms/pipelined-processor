`include "register_file_if.vh"
`include "fetch_decode_if.vh"
`include "decode_exec_if.vh"

typedef enum {
  ALUIN1_RS,
  ALUIN1_CUSTOM } alu_in1_t;

typedef enum {
  ALUIN2_RT,
  ALUIN2_SIMM,
  ALUIN2_ZIMM,
  ALUIN2_CUSTOM } alu_in2_t;

import cpu_types_pkg::*;

module decode (
  input logic CLK, nRST,
  input logic en, zero,
  input word_t rdat1, rdat2,
  output regbits_t rsel1, rsel2,
  output logic jump_instr, branch_instr,
  output word_t branch_target,
  fetch_decode_if.decode in,
  decode_exec_if.decode out
);

  word_t        next_alu_in1, next_alu_in2;
  alu_in1_t     alu_in1_src;
  alu_in2_t     alu_in2_src;
  aluop_t       next_alu_aluop, funct_aluop;
  regbits_t     next_rs_alu_in, next_rt_alu_in;

  regbits_t     next_wsel;
  write_t       next_wdat_source;

  logic         next_branch_if_zero;

  logic         next_halt;
  word_t        next_instr_npc;

  logic         next_dmemREN, next_dmemWEN;
  word_t        next_dmemstore;

  regbits_t     custom_rsel1, custom_rsel2;
  word_t        custom_alu_in1, custom_alu_in2;

  r_t           rtype_instruction;
  i_t           itype_instruction;
  j_t           jtype_instruction;

  assign rtype_instruction = r_t'(in.instruction);
  assign itype_instruction = i_t'(in.instruction);
  assign jtype_instruction = j_t'(in.instruction);

  always_ff @(posedge CLK, negedge nRST)
  begin
    if(!nRST) begin
      out.halt              <= 0;
      out.decode_alu_in1    <= 0;
      out.decode_alu_in2    <= 0;
      out.alu_aluop         <= aluop_t'(0);
      out.rs_alu_in         <= 0;
      out.rt_alu_in         <= 0;

      out.wsel              <= 0;
      out.wdat_source       <= write_t'(0);

      out.branch_instr      <= 0;
      out.branch_if_zero    <= 0;
      out.branch_target     <= 0;

      out.instr_npc         <= 0;

      out.dmemREN           <= 0;
      out.dmemWEN           <= 0;
      out.decode_dmemstore  <= 0;
      out.branch_taken      <= 0;
    end else if (en && zero) begin
      out.halt              <= 0;
      out.decode_alu_in1    <= 0;
      out.decode_alu_in2    <= 0;
      out.alu_aluop         <= aluop_t'(0);
      out.rs_alu_in         <= 0;
      out.rt_alu_in         <= 0;

      out.wsel              <= 0;
      out.wdat_source       <= write_t'(0);

      out.branch_instr      <= 0;
      out.branch_if_zero    <= 0;
      out.branch_target     <= 0;
      out.branch_taken      <= 0;

      out.instr_npc         <= 0;

      out.dmemREN           <= 0;
      out.dmemWEN           <= 0;
      out.decode_dmemstore  <= 0;
    end else if (en && !zero) begin
      out.halt              <= next_halt;
      out.decode_alu_in1    <= next_alu_in1;
      out.decode_alu_in2    <= next_alu_in2;
      out.alu_aluop         <= next_alu_aluop;
      out.rs_alu_in         <= next_rs_alu_in;
      out.rt_alu_in         <= next_rt_alu_in;

      out.wsel              <= next_wsel;
      out.wdat_source       <= next_wdat_source;

      out.branch_instr      <= branch_instr;
      out.branch_if_zero    <= next_branch_if_zero;
      out.branch_target     <= branch_target;
      out.branch_taken      <= in.branch_taken;

      out.instr_npc         <= next_instr_npc;

      out.dmemREN           <= next_dmemREN;
      out.dmemWEN           <= next_dmemWEN;
      out.decode_dmemstore  <= next_dmemstore;
    end
  end

  always_comb begin
    alu_in1_src           = ALUIN1_RS;
    alu_in2_src           = ALUIN2_RT;
    next_alu_aluop        = funct_aluop;
    if (rtype_instruction.opcode == RTYPE)
      next_wsel           = rtype_instruction.rd;
    else
      next_wsel           = rtype_instruction.rt;
    next_wdat_source      = WRITE_ALU;

    next_branch_if_zero   = 0;
    branch_target         = in.instr_npc + $signed({ itype_instruction.imm, 2'b0 });

    next_halt             = 0;
    next_instr_npc        = in.instr_npc;

    next_dmemREN          = 0;
    next_dmemWEN          = 0;
    next_dmemstore        = 0;

    custom_rsel1          = 0;
    custom_rsel2          = 0;
    custom_alu_in1        = 0;
    custom_alu_in2        = 0;

    jump_instr            = 0;
    branch_instr          = 0;

    case (rtype_instruction.opcode)
      RTYPE : begin
        next_alu_aluop = funct_aluop;
        case (rtype_instruction.funct)
          JR :  begin
            alu_in2_src = ALUIN2_CUSTOM;
            custom_rsel2 = 31;
            next_wsel = 0;
            branch_target = rdat2;
            jump_instr = 1;
          end
          SLL,
          SRL : begin
            alu_in2_src = ALUIN2_CUSTOM;
            custom_alu_in2 = rtype_instruction.shamt;
          end
        endcase
      end
      ADDIU: begin
        alu_in2_src = ALUIN2_SIMM;
        next_alu_aluop = ALU_ADD;
      end
      ANDI : begin
        alu_in2_src = ALUIN2_ZIMM;
        next_alu_aluop = ALU_AND;
      end
      BEQ, BNE : begin
        next_alu_aluop = ALU_SUB;
        next_branch_if_zero = rtype_instruction.opcode == BEQ;
        next_wsel = 0;
        branch_instr = 1;
      end
      LUI : begin
        alu_in1_src = ALUIN1_CUSTOM;
        custom_alu_in1 = itype_instruction.imm;
        alu_in2_src = ALUIN2_CUSTOM;
        custom_alu_in2 = 16;
        next_alu_aluop = ALU_SLL;
      end
      LW : begin
        alu_in2_src = ALUIN2_SIMM;
        next_alu_aluop = ALU_ADD;
        next_wdat_source = WRITE_RAM;
        next_wsel = rtype_instruction.rt;
        next_dmemREN = 1;
      end
      ORI : begin
        alu_in2_src = ALUIN2_ZIMM;
        next_alu_aluop = ALU_OR;
      end
      SLTI : begin
        alu_in2_src = ALUIN2_SIMM;
        next_alu_aluop = ALU_SLT;
      end
      SLTIU : begin
        alu_in2_src = ALUIN2_SIMM;
        next_alu_aluop = ALU_SLTU;
      end
      SW : begin
        alu_in2_src = ALUIN2_SIMM;
        custom_rsel2 = rtype_instruction.rt;
        next_alu_aluop = ALU_ADD;
        next_wsel = 0;
        next_dmemWEN = 1;
        next_dmemstore = rdat2;
      end
      XORI : begin
        alu_in2_src = ALUIN2_ZIMM;
        next_alu_aluop = ALU_XOR;
      end
      J : begin
        next_wsel = 0;
        branch_target = { in.instr_npc[31:28], jtype_instruction.addr, 2'b0 };
        jump_instr = 1;
      end
      JAL : begin
        next_wdat_source = WRITE_NPC;
        next_wsel = 31;
        branch_target = { in.instr_npc[31:28], jtype_instruction.addr, 2'b0 };
        jump_instr = 1;
      end
      HALT : begin
        next_wsel = 0;
        next_halt = 1;
      end
    endcase
  end
  always_comb begin
    case (rtype_instruction.funct)
      SLL  : funct_aluop = ALU_SLL;
      SRL  : funct_aluop = ALU_SRL;
      ADDU : funct_aluop = ALU_ADD;
      SUBU : funct_aluop = ALU_SUB;
      default : funct_aluop = aluop_t'(rtype_instruction.funct[3:0]);
    endcase
  end
  always_comb begin
    rsel1 = 0;
    rsel2 = 0;

    if (alu_in1_src != ALUIN1_RS)
      rsel1 = custom_rsel1;
    else
      rsel1 = rtype_instruction.rs;

    if (alu_in2_src != ALUIN2_RT)
      rsel2 = custom_rsel2;
    else
      rsel2 = rtype_instruction.rt;

    if(alu_in1_src == ALUIN1_RS)
      next_alu_in1 = rdat1;
    else
      next_alu_in1 = custom_alu_in1;

    case (alu_in2_src)
      ALUIN2_RT     : next_alu_in2 = rdat2;
      ALUIN2_SIMM   : next_alu_in2 = $signed(itype_instruction.imm);
      ALUIN2_ZIMM   : next_alu_in2 = itype_instruction.imm;
      ALUIN2_CUSTOM : next_alu_in2 = custom_alu_in2;
    endcase

    next_rs_alu_in = 0;
    next_rt_alu_in = 0;
    casez(rtype_instruction.opcode)
      RTYPE: begin
        next_rs_alu_in = rtype_instruction.rs;
        if (rtype_instruction.funct != JR && rtype_instruction.funct != SLL
            && rtype_instruction.funct != SRL)
          next_rt_alu_in = rtype_instruction.rt;
      end
      SW: begin
        next_rs_alu_in = rtype_instruction.rs;
        next_rt_alu_in = rtype_instruction.rt;
      end
      LUI,
      J,
      JAL: ;
      default: begin
        next_rs_alu_in = rtype_instruction.rs;
      end
    endcase
  end
endmodule
