/*
 *  @Name:     instr
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 22-06-2018 22:56:42 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 26-06-2018 14:27:44 UTC-5
 *  
 *  @Description:
 *  
 */

package riscv

import "core:fmt"



Instr :: struct {
    imm : u64,
    
    mask : u32,

    rd  : u32,
    rs1 : u32,
    rs2 : u32,
    rs3 : u32,

    succ : u32,
    pred : u32,

    csr : u32,
}

mask_to_string :: proc(mask : u32) -> string {
    switch mask {
    case LUI:     return "lui";
    case AUIPC:   return "auipc";
    case JAL:     return "jal";
    case JALR:    return "jalr";
    case BEQ:     return "beq";
    case BNE:     return "bne";
    case BLT:     return "blt";
    case BGE:     return "bge";
    case BLTU:    return "bltu";
    case BGEU:    return "bgeu";
    case LB:      return "lb";
    case LH:      return "lh";
    case LW:      return "lw";
    case LBU:     return "lbu";
    case LHU:     return "lhu";
    case SB:      return "sb";
    case SH:      return "sh";
    case SW:      return "sw";
    case ADDI:    return "addi";
    case SLTI:    return "slti";
    case SLTIU:   return "sltiu";
    case XORI:    return "xori";
    case ORI:     return "ori";
    case ANDI:    return "andi";
    case ADD:     return "add";
    case SUB:     return "sub";
    case SLL:     return "sll";
    case SLT:     return "slt";
    case SLTU:    return "sltu";
    case XOR:     return "xor";
    case SRL:     return "srl";
    case SRA:     return "sra";
    case OR:      return "or";
    case AND:     return "and";
    case CSRRW:   return "csrrw";
    case CSRRS:   return "csrrs";
    case CSRRC:   return "csrrc";
    case CSRRWI:  return "csrrwi";
    case CSRRSI:  return "csrrsi";
    case CSRRCI:  return "csrrci";
    case FENCE:   return "fence";
    case FENCE_I: return "fence_i";
    case ECALL:   return "ecall";
    case EBREAK:  return "ebreak";
    case LWU:     return "lwu";
    case LD:      return "ld";
    case SD:      return "sd";
    case SLLI:    return "slli";
    case SRLI:    return "srli";
    case SRAI:    return "srai";
    case ADDIW:   return "addiw";
    case SLLIW:   return "slliw";
    case SRLIW:   return "srliw";
    case SRAIW:   return "sraiw";
    case ADDW:    return "addw";
    case SUBW:    return "subw";
    case SLLW:    return "sllw";
    case SRLW:    return "srlw";
    case SRAW:    return "sraw";
    case MUL:     return "mul";
    case MULH:    return "mulh";
    case MULHSU:  return "mulhsu";
    case MULHU:   return "mulhu";
    case DIV:     return "div";
    case DIVU:    return "divu";
    case REM:     return "rem";
    case REMU:    return "remu";
    case MULW:    return "mulw";
    case DIVW:    return "divw";
    case DIVUW:   return "divuw";
    case REMW:    return "remw";
    case REMUW:   return "remuw";
    }
    
    return "ILLEGAL";
}

print :: inline proc(using instr : Instr) {
    switch mask {
    case LUI, AUIPC:
        fmt.printf("%s x%d, %d", mask_to_string(mask), rd, imm);
    
    case JAL:
        fmt.printf("%s x%d, [pc + %d]", mask_to_string(mask), rd, imm);
    
    case JALR:
        fmt.printf("%s x%d, [x%d, %d]", mask_to_string(mask), rd, rs1, imm);
    
    case BEQ, BNE, BLT, BGE, BLTU, BGEU:
        fmt.printf("%s x%d, x%d, [pc + %d]", mask_to_string(mask), rs1, rs2, imm);
    
    case LB, LH, LW, LD, LBU, LHU, LWU:
        fmt.printf("%s x%d, [x%d, %d]", mask_to_string(mask), rd, rs1, imm);
    
    case SB, SH, SW, SD:
        fmt.printf("%s [x%d, %d], x%d", mask_to_string(mask), rs1, imm, rs2);
    
    case ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI, ADDIW, SLLIW, SRLIW, SRAIW:
        fmt.printf("%s x%d, x%d, %d", mask_to_string(mask), rd, rs1, imm);
    
    case MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU, MULW, DIVW, DIVUW, REMW, REMUW: fallthrough;
    case ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND, ADDW, SUBW, SLLW, SRLW, SRAW:
        fmt.printf("%s x%d, x%d, x%d", mask_to_string(mask), rd, rs1, rs2);
    
    case CSRRW, CSRRS, CSRRC:
        // @todo(bpunsky): implement
    
    case CSRRWI, CSRRSI, CSRRCI:
        // @todo(bpunsky): implement
    
    case FENCE, FENCE_I, ECALL, EBREAK:
        // @todo(bpunsky): implement?
    
    case:
        fmt.printf("%s %v", mask_to_string(mask), instr);
    }

    fmt.println();
}

encode_immediate_u :: inline proc(imm : u64) -> u32 {
    imm_12_31 := bits(imm, 12, 20) << 12;

    return u32(imm_12_31);
}

encode_immediate_i :: inline proc(imm : u64) -> u32 {
    imm_0_11 := bits(imm, 0, 12) << 20;

    return u32(imm_0_11);
}

encode_immediate_s :: inline proc(imm : u64) -> u32 {
    imm_0_4  := bits(imm, 0, 5) << 7;
    imm_5_11 := bits(imm, 5, 7) << 25;

    return u32(imm_0_4 | imm_5_11);
}

encode_immediate_b :: inline proc(imm : u64) -> u32 {
    imm_1_4  := bits(imm, 0, 5)  << 8;
    imm_5_10 := bits(imm, 5, 6)  << 25;
    imm_11   := bits(imm, 11, 1) << 7;
    imm_12   := bits(imm, 12, 1) << 31;

    return u32(imm_1_4 | imm_5_10 | imm_11 | imm_12);
}

encode_immediate_j :: inline proc(imm : u64) -> u32 {
    imm_1_10  := bits(imm, 1, 10) << 21;
    imm_11    := bits(imm, 11, 1) << 20;
    imm_12_19 := bits(imm, 12, 8) << 12;
    imm_20    := bits(imm, 20, 1) << 31;

    return u32(imm_1_10 | imm_11 | imm_12_19 | imm_20);
}

encode :: inline proc(mask : u32, rd : u32 = 0, rs1 : u32 = 0, rs2 : u32 = 0, rs3 : u32 = 0, csr : u32 = 0, rm : u32 = 0, aq : u32 = 0, rl : u32 = 0, succ : u32 = 0, pred : u32 = 0, imm : u64 = 0) -> u32 {
    rd   <<=  7;
    rs1  <<= 15;
    rs2  <<= 20;
    rs3  <<= 27;
    csr  <<= 20;
    rm   <<= 12;
    aq   <<= 25;
    rl   <<= 26;
    succ <<= 20;
    pred <<= 24;

    switch mask {
    case LUI, AUIPC:
        return mask | rd | encode_immediate_u(imm);
    
    case JAL:
        return mask | rd | encode_immediate_j(imm);
    
    case BEQ, BNE, BLT, BGE, BLTU, BGEU:
        return mask | rs1 | rs2 | encode_immediate_b(imm);
    
    case JALR, LB, LH, LW, LBU, LHU, ADDI, SLTI, SLTIU, XORI, ORI, ANDI, LWU, LD, ADDIW:
        return mask | rd | rs1 | encode_immediate_i(imm);
    
    case MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU, MULW, DIVW, DIVUW, REMW, REMUW: fallthrough;
    case ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND, ADDW, SUBW, SLLW, SRLW, SRAW:
        return mask | rd | rs1 | rs2;
    
    case SLLI, SRLI, SRAI, SLLIW, SRLIW, SRAIW:
        return mask | rd | rs1 | u32(bits(imm, 0, 5) << 20);
    
    case SB, SH, SW, SD:
        return mask | rs1 | rs2 | encode_immediate_s(imm);
    
    case FENCE:
        return mask | succ | pred;
    
    case FENCE_I, ECALL, EBREAK:
        return mask;
    
    case CSRRW, CSRRS, CSRRC:
        return mask | rd | rs1 | csr;
    
    case CSRRWI, CSRRSI, CSRRCI:
        return mask | rd | u32(bits(imm, 0, 5) << 15) | csr;
    }

    return 0;
}

decode_immediate_u :: inline proc(imm : u32) -> u64 {
    imm_12_31 := bits(imm, 12, 20) << 12;

    return sext(u64(imm_12_31), 21);
}

decode_immediate_j :: inline proc(imm : u32) -> u64 {
    imm_1_10  := bits(imm, 21, 10) <<  1;
    imm_11    := bits(imm, 20,  1) << 11;
    imm_12_19 := bits(imm, 12,  8) << 12;
    imm_20    := bits(imm, 31,  1) << 20;

    return sext(u64(imm_1_10 | imm_11 | imm_12_19 | imm_20), 13);
}

decode_immediate_b :: inline proc(imm : u32) -> u64 {
    imm_1_4  := bits(imm,  8, 4) <<  1;
    imm_5_10 := bits(imm, 25, 6) <<  5;
    imm_11   := bits(imm,  7, 1) << 11;
    imm_12   := bits(imm, 31, 1) << 12;

    return sext(u64(imm_1_4 | imm_5_10 | imm_11 | imm_12), 13);
}

decode_immediate_i :: inline proc(imm : u32) -> u64 {
    imm_0_11 := bits(imm, 20, 12);

    return sext(u64(imm_0_11), 12);
}

decode_immediate_s :: inline proc(imm : u32) -> u64 {
    imm_0_4  := bits(imm,  7, 5);
    imm_5_11 := bits(imm, 25, 7) << 5;

    return sext(u64(imm_0_4 | imm_5_11), 12);
}

decode :: inline proc(op : u32) -> Instr {
    opcode := bits(op, 0,  7);
    funct3 := bits(op, 12, 3);
    funct7 := bits(op, 25, 7);
    rd     := bits(op,  7, 5);
    rs1    := bits(op, 15, 5);
    rs2    := bits(op, 20, 5);
    csr    := bits(op, 20, 12);

    switch opcode {
    case 0b0110111: // LUI
        return Instr{mask=LUI, rd=rd, imm=decode_immediate_u(op)};

    case 0b0010111: // AUIPC
        return Instr{mask=AUIPC, rd=rd, imm=decode_immediate_u(op)};

    case 0b1101111: // JAL
        return Instr{mask=JAL, rd=rd, imm=decode_immediate_j(op)};

    case 0b1100111: // JALR
        if funct3 == 0b000 {
            return Instr{mask=JALR, rd=rd, rs1=rs1, imm=decode_immediate_i(op)};
        }

    case 0b1100011: // BRANCH
        switch funct3 {
        case 0b000: return Instr{mask=BEQ,  rs1=rs1, rs2=rs2, imm=decode_immediate_b(op)};
        case 0b001: return Instr{mask=BNE,  rs1=rs1, rs2=rs2, imm=decode_immediate_b(op)};
        case 0b100: return Instr{mask=BLT,  rs1=rs1, rs2=rs2, imm=decode_immediate_b(op)};
        case 0b101: return Instr{mask=BGE,  rs1=rs1, rs2=rs2, imm=decode_immediate_b(op)};
        case 0b110: return Instr{mask=BLTU, rs1=rs1, rs2=rs2, imm=decode_immediate_b(op)};
        case 0b111: return Instr{mask=BGEU, rs1=rs1, rs2=rs2, imm=decode_immediate_b(op)};
        }

    case 0b0000011: // LOAD
        switch funct3 {
        case 0b000: return Instr{mask=LB,  rd=rd, rs1=rs1, imm=decode_immediate_i(op)};
        case 0b001: return Instr{mask=LH,  rd=rd, rs1=rs1, imm=decode_immediate_i(op)};
        case 0b010: return Instr{mask=LW,  rd=rd, rs1=rs1, imm=decode_immediate_i(op)};
        case 0b011: return Instr{mask=LD,  rd=rd, rs1=rs1, imm=decode_immediate_i(op)};
        case 0b100: return Instr{mask=LBU, rd=rd, rs1=rs1, imm=decode_immediate_i(op)};
        case 0b101: return Instr{mask=LHU, rd=rd, rs1=rs1, imm=decode_immediate_i(op)};
        case 0b110: return Instr{mask=LWU, rd=rd, rs1=rs1, imm=decode_immediate_i(op)};
        }

    case 0b0100011: // STORE
        switch funct3 {
        case 0b000: return Instr{mask=SB, rs1=rs1, rs2=rs2, imm=decode_immediate_s(op)};
        case 0b001: return Instr{mask=SH, rs1=rs1, rs2=rs2, imm=decode_immediate_s(op)};
        case 0b010: return Instr{mask=SW, rs1=rs1, rs2=rs2, imm=decode_immediate_s(op)};
        case 0b011: return Instr{mask=SD, rs1=rs1, rs2=rs2, imm=decode_immediate_s(op)};
        }

    case 0b0010011: // OP-IMM
        switch funct3 {
        case 0b000: return Instr{mask=ADDI,  rd=rd, rs1=rs1, imm=decode_immediate_i(op)};
        case 0b010: return Instr{mask=SLTI,  rd=rd, rs1=rs1, imm=decode_immediate_i(op)};
        case 0b011: return Instr{mask=SLTIU, rd=rd, rs1=rs1, imm=decode_immediate_i(op)};
        case 0b100: return Instr{mask=XORI,  rd=rd, rs1=rs1, imm=decode_immediate_i(op)};
        case 0b110: return Instr{mask=ORI,   rd=rd, rs1=rs1, imm=decode_immediate_i(op)};
        case 0b111: return Instr{mask=ANDI,  rd=rd, rs1=rs1, imm=decode_immediate_i(op)};

        case 0b001:
            switch funct7 {
            case 0b0000000: return Instr{mask=SLLI, rd=rd, rs1=rs1, imm=u64(rs2)};
            }

        case 0b101:
            switch funct7 {
            case 0b0000000: return Instr{mask=SRLI, rd=rd, rs1=rs1, imm=u64(rs2)};
            case 0b0100000: return Instr{mask=SRAI, rd=rd, rs1=rs1, imm=u64(rs2)};
            }
        }

    case 0b0011011: // OP-IMM64
        switch funct3 {
        case 0b000: return Instr{mask=ADDIW, rd=rd, rs1=rs1, imm=decode_immediate_i(op)};
        case 0b001: return Instr{mask=SLLIW, rd=rd, rs1=rs1, imm=decode_immediate_i(op)};

        case 0b101:
            switch funct7 {
            case 0b00000000: return Instr{mask=SRLIW, rd=rd, rs1=rs1, imm=decode_immediate_i(op)};
            case 0b01000000: return Instr{mask=SRAIW, rd=rd, rs1=rs1, imm=decode_immediate_i(op)};
            }
        }

    case 0b0110011: // OP
        switch funct7 {
        case 0b0000000:
            switch funct3 {
            case 0b000:
                switch funct7 {
                case 0b0000000: return Instr{mask=ADD, rd=rd, rs1=rs1, rs2=rs2};
                }

            case 0b001:
                switch funct7 {
                case 0b0000000: return Instr{mask=SLL, rd=rd, rs1=rs1, rs2=rs2};
                }

            case 0b010: return Instr{mask=SLT,  rd=rd, rs1=rs1, rs2=rs2};
            case 0b011: return Instr{mask=SLTU, rd=rd, rs1=rs1, rs2=rs2};
            case 0b100: return Instr{mask=XOR,  rd=rd, rs1=rs1, rs2=rs2};
            case 0b101:
                switch funct7 {
                case 0b0000000: return Instr{mask=SRL, rd=rd, rs1=rs1, rs2=rs2};
                }

            case 0b110: return Instr{mask=OR,  rd=rd, rs1=rs1, rs2=rs2};
            case 0b111: return Instr{mask=AND, rd=rd, rs1=rs1, rs2=rs2};
            }

        case 0b0000001:
            switch funct3 {
            case 0b000: return Instr{mask=MUL,    rd=rd, rs1=rs1, rs2=rs2};
            case 0b001: return Instr{mask=MULH,   rd=rd, rs1=rs1, rs2=rs2};
            case 0b010: return Instr{mask=MULHSU, rd=rd, rs1=rs1, rs2=rs2};
            case 0b011: return Instr{mask=MULHU,  rd=rd, rs1=rs1, rs2=rs2};
            case 0b100: return Instr{mask=DIV,    rd=rd, rs1=rs1, rs2=rs2};
            case 0b101: return Instr{mask=DIVU,   rd=rd, rs1=rs1, rs2=rs2};
            case 0b110: return Instr{mask=REM,    rd=rd, rs1=rs1, rs2=rs2};
            case 0b111: return Instr{mask=REMU,   rd=rd, rs1=rs1, rs2=rs2};
            }

        case 0b0100000:
            switch funct3 {
            case 0b000: return Instr{mask=SUB, rd=rd, rs1=rs1, rs2=rs2};
            case 0b101: return Instr{mask=SRA, rd=rd, rs1=rs1, rs2=rs2};
            }
        }

    case 0b0111011: // OP64
        switch funct7 {
        case 0b0000000:
            switch funct3 {
            case 0b000:
                switch funct7 {
                case 0b0000000: return Instr{mask=ADDW, rd=rd, rs1=rs1, rs2=rs2};
                }

            case 0b001: return Instr{mask=SLLW, rd=rd, rs1=rs1, rs2=rs2};
            
            case 0b101:
                switch funct7 {
                case 0b0000000: return Instr{mask=SRLW, rd=rd, rs1=rs1, rs2=rs2};
                }
            }

        case 0b0000001:
            switch funct3 {
            case 0b000: return Instr{mask=MULW,  rd=rd, rs1=rs1, rs2=rs2};
            case 0b100: return Instr{mask=DIVW,  rd=rd, rs1=rs1, rs2=rs2};
            case 0b101: return Instr{mask=DIVUW, rd=rd, rs1=rs1, rs2=rs2};
            case 0b110: return Instr{mask=REMW,  rd=rd, rs1=rs1, rs2=rs2};
            case 0b111: return Instr{mask=REMUW, rd=rd, rs1=rs1, rs2=rs2};
            }

        case 0b0100000:
            switch funct3 {
            case 0b000: return Instr{mask=SUBW, rd=rd, rs1=rs1, rs2=rs2};
            case 0b101: return Instr{mask=SRAW, rd=rd, rs1=rs1, rs2=rs2};
            }
        }

    case 0b0001111: // MISC-MEM
        switch funct3 {
        case 0b000: return Instr{mask=FENCE, succ=bits(op, 20, 4), pred=bits(op, 24, 4)};
        case 0b001: return Instr{mask=FENCE_I};
        }

    case 0b1110011: // SYSTEM
        switch funct3 {
        case 0b000:
            switch csr {
            case 0b000000000000: return Instr{mask=ECALL};
            case 0b000000000001: return Instr{mask=EBREAK};
            }

        case 0b001: return Instr{mask=CSRRW, rd=rd, rs1=rs1, csr=csr};
        case 0b010: return Instr{mask=CSRRS, rd=rd, rs1=rs1, csr=csr};
        case 0b011: return Instr{mask=CSRRC, rd=rd, rs1=rs1, csr=csr};
        case 0b101: return Instr{mask=CSRRWI, rd=rd, csr=csr, imm=sext(u64(bits(op, 15, 5)), 31)};
        case 0b110: return Instr{mask=CSRRSI, rd=rd, csr=csr, imm=sext(u64(bits(op, 15, 5)), 31)};
        case 0b111: return Instr{mask=CSRRCI, rd=rd, csr=csr, imm=sext(u64(bits(op, 15, 5)), 31)};
        }
    }

    return Instr{};
}



// RV32I

lui     :: inline proc(rd       : u32, imm : u64)       -> u32 do return encode(mask=LUI,   rd=rd, imm=imm);
auipc   :: inline proc(rd       : u32, imm : u64)       -> u32 do return encode(mask=AUIPC, rd=rd, imm=imm);
jal_    :: inline proc(rd       : u32, imm : u64)       -> u32 do return encode(mask=JAL,   rd=rd, imm=imm);
jalr_   :: inline proc(rd, rs   : u32, imm : u64)       -> u32 do return encode(mask=JALR,  rd=rd, imm=imm);
beq     :: inline proc(rs1, rs2 : u32, imm : u64)       -> u32 do return encode(mask=BEQ,  rs1=rs1, rs2=rs2, imm=imm);
bne     :: inline proc(rs1, rs2 : u32, imm : u64)       -> u32 do return encode(mask=BNE,  rs1=rs1, rs2=rs2, imm=imm);
blt     :: inline proc(rs1, rs2 : u32, imm : u64)       -> u32 do return encode(mask=BLT,  rs1=rs1, rs2=rs2, imm=imm);
bge     :: inline proc(rs1, rs2 : u32, imm : u64)       -> u32 do return encode(mask=BGE,  rs1=rs1, rs2=rs2, imm=imm);
bltu    :: inline proc(rs1, rs2 : u32, imm : u64)       -> u32 do return encode(mask=BLTU, rs1=rs1, rs2=rs2, imm=imm);
bgeu    :: inline proc(rs1, rs2 : u32, imm : u64)       -> u32 do return encode(mask=BGEU, rs1=rs1, rs2=rs2, imm=imm);
lb      :: inline proc(rd, rs1 : u32, imm : u64)        -> u32 do return encode(mask=LB,  rd=rd, rs1=rs1, imm=imm);
lh      :: inline proc(rd, rs1 : u32, imm : u64)        -> u32 do return encode(mask=LH,  rd=rd, rs1=rs1, imm=imm);
lw      :: inline proc(rd, rs1 : u32, imm : u64)        -> u32 do return encode(mask=LW,  rd=rd, rs1=rs1, imm=imm);
lbu     :: inline proc(rd, rs1 : u32, imm : u64)        -> u32 do return encode(mask=LBU, rd=rd, rs1=rs1, imm=imm);
lhu     :: inline proc(rd, rs1 : u32, imm : u64)        -> u32 do return encode(mask=LHU, rd=rd, rs1=rs1, imm=imm);
sb      :: inline proc(rs1 : u32, imm : u64, rs2 : u32) -> u32 do return encode(mask=SB, rs1=rs1, rs2=rs2, imm=imm);
sh      :: inline proc(rs1 : u32, imm : u64, rs2 : u32) -> u32 do return encode(mask=SH, rs1=rs1, rs2=rs2, imm=imm);
sw      :: inline proc(rs1 : u32, imm : u64, rs2 : u32) -> u32 do return encode(mask=SW, rs1=rs1, rs2=rs2, imm=imm);
addi    :: inline proc(rd, rs : u32, imm : u64)         -> u32 do return encode(mask=ADDI,  rd=rd, rs1=rs, imm=imm);
slti    :: inline proc(rd, rs : u32, imm : u64)         -> u32 do return encode(mask=SLTI,  rd=rd, rs1=rs, imm=imm);
sltiu   :: inline proc(rd, rs : u32, imm : u64)         -> u32 do return encode(mask=SLTIU, rd=rd, rs1=rs, imm=imm);
xori    :: inline proc(rd, rs : u32, imm : u64)         -> u32 do return encode(mask=XORI,  rd=rd, rs1=rs, imm=imm);
ori     :: inline proc(rd, rs : u32, imm : u64)         -> u32 do return encode(mask=ORI,   rd=rd, rs1=rs, imm=imm);
andi    :: inline proc(rd, rs : u32, imm : u64)         -> u32 do return encode(mask=ANDI,  rd=rd, rs1=rs, imm=imm);
add     :: inline proc(rd, rs1, rs2 : u32)              -> u32 do return encode(mask=ADD,  rd=rd, rs1=rs1, rs2=rs2);
sub     :: inline proc(rd, rs1, rs2 : u32)              -> u32 do return encode(mask=SUB,  rd=rd, rs1=rs1, rs2=rs2);
sll     :: inline proc(rd, rs1, rs2 : u32)              -> u32 do return encode(mask=SLL,  rd=rd, rs1=rs1, rs2=rs2);
slt     :: inline proc(rd, rs1, rs2 : u32)              -> u32 do return encode(mask=SLT,  rd=rd, rs1=rs1, rs2=rs2);
sltu    :: inline proc(rd, rs1, rs2 : u32)              -> u32 do return encode(mask=SLTU, rd=rd, rs1=rs1, rs2=rs2);
xor     :: inline proc(rd, rs1, rs2 : u32)              -> u32 do return encode(mask=XOR,  rd=rd, rs1=rs1, rs2=rs2);
srl     :: inline proc(rd, rs1, rs2 : u32)              -> u32 do return encode(mask=SRL,  rd=rd, rs1=rs1, rs2=rs2);
sra     :: inline proc(rd, rs1, rs2 : u32)              -> u32 do return encode(mask=SRA,  rd=rd, rs1=rs1, rs2=rs2);
or      :: inline proc(rd, rs1, rs2 : u32)              -> u32 do return encode(mask=OR,   rd=rd, rs1=rs1, rs2=rs2);
and     :: inline proc(rd, rs1, rs2 : u32)              -> u32 do return encode(mask=AND,  rd=rd, rs1=rs1, rs2=rs2);
csrrw   :: inline proc(rd, rs1, rs2 : u32, imm : u64)   -> u32 do return encode(mask=CSRRW,  rs1=rs1, rs2=rs2, imm=imm);
csrrs   :: inline proc(rd, rs1, rs2 : u32, imm : u64)   -> u32 do return encode(mask=CSRRS,  rs1=rs1, rs2=rs2, imm=imm);
csrrc   :: inline proc(rd, rs1, rs2 : u32, imm : u64)   -> u32 do return encode(mask=CSRRC,  rs1=rs1, rs2=rs2, imm=imm);
csrrwi  :: inline proc(rd, rs1, rs2 : u32, imm : u64)   -> u32 do return encode(mask=CSRRWI, rs1=rs1, rs2=rs2, imm=imm);
csrrsi  :: inline proc(rd, rs1, rs2 : u32, imm : u64)   -> u32 do return encode(mask=CSRRSI, rs1=rs1, rs2=rs2, imm=imm);
csrrci  :: inline proc(rd, rs1, rs2 : u32, imm : u64)   -> u32 do return encode(mask=CSRRCI, rs1=rs1, rs2=rs2, imm=imm);
fence   :: inline proc(succ, pred : u32)                -> u32 do return encode(mask=FENCE, succ=succ, pred=pred);
fence_i :: inline proc()                                -> u32 do return encode(mask=FENCE_I); // @todo(bpunsky): imm?
ecall   :: inline proc()                                -> u32 do return encode(mask=ECALL);
ebreak  :: inline proc()                                -> u32 do return encode(mask=EBREAK);



// RV64I

lwu   :: inline proc(rd, rs1 : u32, imm : u64)        -> u32 do return encode(mask=LWU, rd=rd, rs1=rs1, imm=imm);
ld    :: inline proc(rd, rs1 : u32, imm : u64)        -> u32 do return encode(mask=LD,  rd=rd, rs1=rs1, imm=imm);
sd    :: inline proc(rs1 : u32, imm : u64, rs2 : u32) -> u32 do return encode(mask=SD, rs1=rs1, rs2=rs2, imm=imm);
slli  :: inline proc(rd, rs : u32, imm : u64)         -> u32 do return encode(mask=SLLI, rd=rd, rs1=rs, imm=imm);
srli  :: inline proc(rd, rs : u32, imm : u64)         -> u32 do return encode(mask=SRLI, rd=rd, rs1=rs, imm=imm);
srai  :: inline proc(rd, rs : u32, imm : u64)         -> u32 do return encode(mask=SRAI, rd=rd, rs1=rs, imm=imm);
addiw :: inline proc(rd, rs : u32, imm : u64)         -> u32 do return encode(mask=ADDIW, rd=rd, rs1=rs, imm=imm);
slliw :: inline proc(rd, rs : u32, imm : u64)         -> u32 do return encode(mask=SLLIW, rd=rd, rs1=rs, imm=imm);
srliw :: inline proc(rd, rs : u32, imm : u64)         -> u32 do return encode(mask=SRLIW, rd=rd, rs1=rs, imm=imm);
sraiw :: inline proc(rd, rs : u32, imm : u64)         -> u32 do return encode(mask=SRAIW, rd=rd, rs1=rs, imm=imm);
addw  :: inline proc(rd, rs1, rs2 : u32)              -> u32 do return encode(mask=ADDW, rd=rd, rs1=rs1, rs2=rs2);
subw  :: inline proc(rd, rs1, rs2 : u32)              -> u32 do return encode(mask=SUBW, rd=rd, rs1=rs1, rs2=rs2);
sllw  :: inline proc(rd, rs1, rs2 : u32)              -> u32 do return encode(mask=SLLW, rd=rd, rs1=rs1, rs2=rs2);
srlw  :: inline proc(rd, rs1, rs2 : u32)              -> u32 do return encode(mask=SRLW, rd=rd, rs1=rs1, rs2=rs2);
sraw  :: inline proc(rd, rs1, rs2 : u32)              -> u32 do return encode(mask=SRAW, rd=rd, rs1=rs1, rs2=rs2);



// RV32M

mul    :: inline proc(rd, rs1, rs2 : u32) -> u32 do return encode(mask=MUL,    rd=rd, rs1=rs1, rs2=rs2);
mulh   :: inline proc(rd, rs1, rs2 : u32) -> u32 do return encode(mask=MULH,   rd=rd, rs1=rs1, rs2=rs2);
mulhsu :: inline proc(rd, rs1, rs2 : u32) -> u32 do return encode(mask=MULHSU, rd=rd, rs1=rs1, rs2=rs2);
mulhu  :: inline proc(rd, rs1, rs2 : u32) -> u32 do return encode(mask=MULHU,  rd=rd, rs1=rs1, rs2=rs2);
div    :: inline proc(rd, rs1, rs2 : u32) -> u32 do return encode(mask=DIV,    rd=rd, rs1=rs1, rs2=rs2);
divu   :: inline proc(rd, rs1, rs2 : u32) -> u32 do return encode(mask=DIVU,   rd=rd, rs1=rs1, rs2=rs2);
rem    :: inline proc(rd, rs1, rs2 : u32) -> u32 do return encode(mask=REM,    rd=rd, rs1=rs1, rs2=rs2);
remu   :: inline proc(rd, rs1, rs2 : u32) -> u32 do return encode(mask=REMU,   rd=rd, rs1=rs1, rs2=rs2);



// RV64M

mulw  :: inline proc(rd, rs1, rs2 : u32) -> u32 do return encode(mask=MULW,  rd=rd, rs1=rs1, rs2=rs2);
divw  :: inline proc(rd, rs1, rs2 : u32) -> u32 do return encode(mask=DIVW,  rd=rd, rs1=rs1, rs2=rs2);
divuw :: inline proc(rd, rs1, rs2 : u32) -> u32 do return encode(mask=DIVUW, rd=rd, rs1=rs1, rs2=rs2);
remw  :: inline proc(rd, rs1, rs2 : u32) -> u32 do return encode(mask=REMW,  rd=rd, rs1=rs1, rs2=rs2);
remuw :: inline proc(rd, rs1, rs2 : u32) -> u32 do return encode(mask=REMUW, rd=rd, rs1=rs1, rs2=rs2);



/*
// RV32A

lr_w      :: inline proc(rd, rs1, aq, rl : u32)      -> u32 do return encode(mask=LR_W,      rd=rd, rs1=rs1, aq=aq, rl=rl);
sc_w      :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=SC_W,      rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
amoswap_w :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=AMOSWAP_W, rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
amoadd_w  :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=AMOADD_W,  rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
amoxor_w  :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=AMOXOR_W,  rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
amoand_w  :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=AMOAND_W,  rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
amoor_w   :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=AMOOR_W,   rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
amomin_w  :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=AMOMIN_W,  rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
amomax_w  :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=AMOMAX_W,  rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
amominu_w :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=AMOMINU_W, rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
amomaxu_w :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=AMOMAXU_W, rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
*/



/*
// RV64A

lr_d      :: inline proc(rd, rs1, aq, rl : u32)      -> u32 do return encode(mask=LR_D,      rd=rd, rs1=rs1, aq=aq, rl=rl);
sc_d      :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=SC_D,      rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
amoswap_d :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=AMOSWAP_D, rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
amoadd_d  :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=AMOADD_D,  rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
amoxor_d  :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=AMOXOR_D,  rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
amoand_d  :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=AMOAND_D,  rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
amoor_d   :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=AMOOR_D,   rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
amomin_d  :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=AMOMIN_D,  rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
amomax_d  :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=AMOMAX_D,  rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
amominu_d :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=AMOMINU_D, rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
amomaxu_d :: inline proc(rd, rs1, rs2, aq, rl : u32) -> u32 do return encode(mask=AMOMAXU_D, rd=rd, rs1=rs1, rs2=rs2, aq=aq, rl=rl);
*/



/*
// RV32F

flw       :: inline proc(rd, rs1 : u32, imm : u64)           -> u32 do return encode(mask=FLW, rd=rd, rs1=rs1, imm=imm);
fsw       :: inline proc(rs1, rs2 : u32, imm : u64)          -> u32 do return encode(mask=FSW, rs1=rs1, rs2=rs2, imm=imm);
fmadd_s   :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FMADD_S,   rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fmsub_s   :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FMSUB_S,   rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fnmsub_s  :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FNMSUB_S,  rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fnmadd_s  :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FNMADD_S,  rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fadd_s    :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FADD_S,    rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fsub_s    :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FSUB_S,    rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fmul_s    :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FMUL_S,    rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fdiv_s    :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FDIV_S,    rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fsqrt_s   :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FSQRT_S,   rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fsgnj_s   :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FSGNJ_S,   rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fsgnjn_s  :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FSGNJN_S,  rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fsgnjx_s  :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FSGNJX_S,  rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fmin_s    :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FMIN_S,    rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fmax_s    :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FMAX_S,    rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fcvt_w_s  :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FCVT_W_S,  rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fcvt_wu_s :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FCVT_WU_S, rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fmv_x_w   :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FMV_X_W,   rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
feq_s     :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FEQ_S,     rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
flt_s     :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FLT_S,     rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fle_s     :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FLE_S,     rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fclass_s  :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FCLASS_S,  rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fcvt_s_w  :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FCVT_S_W,  rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fcvt_s_wu :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FCVT_S_WU, rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
fmv_w_x   :: inline proc(rd, rs1, rs2, rs3 : u32, imm : u64) -> u32 do return encode(mask=FMV_W_X,   rd=rd, rs1=rs1, rs2=rs2, rs3=rs3, imm=imm);
*/



/*
// RV64F

fcvt_l_s  :: inline proc() -> u32 do return encode(mask=FCVT_L_S);
fcvt_lu_s :: inline proc() -> u32 do return encode(mask=FCVT_LU_S);
fcvt_s_l  :: inline proc() -> u32 do return encode(mask=FCVT_S_L);
fcvt_s_lu :: inline proc() -> u32 do return encode(mask=FCVT_S_LU);
*/



/*
// RV32D

fld       :: inline proc() -> u32 do return encode(mask=FLD);
fsd       :: inline proc() -> u32 do return encode(mask=FSD);
fmadd_d   :: inline proc() -> u32 do return encode(mask=FMADD_D);
fmsub_d   :: inline proc() -> u32 do return encode(mask=FMSUB_D);
fnmsub_d  :: inline proc() -> u32 do return encode(mask=FNMSUB_D);
fnmadd_d  :: inline proc() -> u32 do return encode(mask=FNMADD_D);
fadd_d    :: inline proc() -> u32 do return encode(mask=FADD_D);
fsub_d    :: inline proc() -> u32 do return encode(mask=FSUB_D);
fmul_d    :: inline proc() -> u32 do return encode(mask=FMUL_D);
fdiv_d    :: inline proc() -> u32 do return encode(mask=FDIV_D);
fsqrt_d   :: inline proc() -> u32 do return encode(mask=FSQRT_D);
fsgnj_d   :: inline proc() -> u32 do return encode(mask=FSGNJ_D);
fsgnjn_d  :: inline proc() -> u32 do return encode(mask=FSGNJN_D);
fsgnjx_d  :: inline proc() -> u32 do return encode(mask=FSGNJX_D);
fmin_d    :: inline proc() -> u32 do return encode(mask=FMIN_D);
fmax_d    :: inline proc() -> u32 do return encode(mask=FMAX_D);
fcvt_s_d  :: inline proc() -> u32 do return encode(mask=FCVT_S_D);
fcvt_d_s  :: inline proc() -> u32 do return encode(mask=FCVT_D_S);
feq_d     :: inline proc() -> u32 do return encode(mask=FEQ_D);
flt_d     :: inline proc() -> u32 do return encode(mask=FLT_D);
fle_d     :: inline proc() -> u32 do return encode(mask=FLE_D);
fclass_d  :: inline proc() -> u32 do return encode(mask=FCLASS_D);
fcvt_w_d  :: inline proc() -> u32 do return encode(mask=FCVT_W_D);
fcvt_wu_d :: inline proc() -> u32 do return encode(mask=FCVT_wU_D);
fcvt_d_w  :: inline proc() -> u32 do return encode(mask=FCVT_D_W);
fcvt_d_wu :: inline proc() -> u32 do return encode(mask=FCVT_D_WU);
*/



/*
// RV64D

fcvt_l_d  :: inline proc() -> u32 do return encode(mask=FCVT_L_D);  
fcvt_lu_d :: inline proc() -> u32 do return encode(mask=FCVT_LU_D); 
fmv_x_d   :: inline proc() -> u32 do return encode(mask=FMV_X_D);   
fcvt_d_l  :: inline proc() -> u32 do return encode(mask=FCVT_D_L);  
fcvt_d_lu :: inline proc() -> u32 do return encode(mask=FCVT_D_LU); 
fmv_d_x   :: inline proc() -> u32 do return encode(mask=FMV_D_X);   
*/




// pseudoinstructions

nop :: inline proc() -> u32 do return addi(x0, x0, 0);

// @todo(bpunsky): figure out li, this one's just 32 bit
li :: inline proc(rd : u32, imm : u64) -> (u32, u32) do return lui(rd, hi20(imm)), addi(rd, rd, lo12(imm));

mv :: inline proc(rd, rs : u32) -> u32 do return addi(rd, rs, 0);

not  :: inline proc(rd, rs : u32) -> u32 do return xori(rd, rs, -1);
neg  :: inline proc(rd, rs : u32) -> u32 do return sub(rd, x0, rs);
negw :: inline proc(rd, rs : u32) -> u32 do return subw(rd, x0, rs);

sext_w :: inline proc(rd, rs : u32) -> u32 do return addiw(rd, rs, 0);

seqz :: inline proc(rd, rs : u32) -> u32 do return sltiu(rd, rs, 1);
snez :: inline proc(rd, rs : u32) -> u32 do return sltu(rd, x0, rs);
sltz :: inline proc(rd, rs : u32) -> u32 do return slt(rd, rs, x0);
sgtz :: inline proc(rd, rs : u32) -> u32 do return slt(rd, x0, rs);

/*
fmv_s  :: inline proc(rd, rs : u32) -> u32 do return fsgnj_s(rd, rs, rs);
fabs_s :: inline proc(rd, rs : u32) -> u32 do return fsgnjx_s(rd, rs, rs);
fneg_s :: inline proc(rd, rs : u32) -> u32 do return fsgnjn_s(rd, rs, rs);
fmv_d  :: inline proc(rd, rs : u32) -> u32 do return fsgnj_d(rd, rs, rs);
fabs_d :: inline proc(rd, rs : u32) -> u32 do return fsgnjx_d(rd, rs, rs);
fneg_d :: inline proc(rd, rs : u32) -> u32 do return fsgnjn_d(rd, rs, rs);
*/

beqz :: inline proc(rs : u32, offset : u64) -> u32 do return beq(rs, x0, offset);
bnez :: inline proc(rs : u32, offset : u64) -> u32 do return bne(rs, x0, offset);
blez :: inline proc(rs : u32, offset : u64) -> u32 do return bge(x0, rs, offset);
bgez :: inline proc(rs : u32, offset : u64) -> u32 do return bge(rs, x0, offset);
bltz :: inline proc(rs : u32, offset : u64) -> u32 do return blt(rs, x0, offset);
bgtz :: inline proc(rs : u32, offset : u64) -> u32 do return blt(x0, rs, offset);

bgt  :: inline proc(rs1, rs2 : u32, offset : u64) -> u32 do return blt(rs2, rs1, offset);
ble  :: inline proc(rs1, rs2 : u32, offset : u64) -> u32 do return bge(rs2, rs1, offset);
bgtu :: inline proc(rs1, rs2 : u32, offset : u64) -> u32 do return bltu(rs2, rs1, offset);
bleu :: inline proc(rs1, rs2 : u32, offset : u64) -> u32 do return bgeu(rs2, rs1, offset);

j      :: inline proc(offset : u64) -> u32        do return jal(x0, offset);
jal__  :: inline proc(offset : u64) -> u32        do return jal(x1, offset);
jr     :: inline proc(rs : u32)     -> u32        do return jalr(x0, rs, 0);
jalr__ :: inline proc(rs : u32)     -> u32        do return jalr(x1, rs, 0);
ret    :: inline proc()             -> u32        do return jalr(x0, x1, 0);
tail   :: inline proc(offset : u64) -> (u32, u32) do return auipc(x6, hi20(offset)), jalr(x0, x6, lo12(offset));
call   :: inline proc(offset : u64) -> (u32, u32) do return auipc(x6, hi20(offset)), jalr(x1, x6, lo12(offset));

/*
fence__ :: inline proc() -> u32 do return fence(iorw, iorw);

rdinstret  :: inline proc(rd : u32) -> u32 do return csrrs(rd, instret, x0);
rdcycle    :: inline proc(rd : u32) -> u32 do return csrrs(rd, cycle, x0);
rdtime     :: inline proc(rd : u32) -> u32 do return csrrs(rd, time, x0);

csrr :: inline proc(rd, csr : u32) -> u32 do return csrrs(rd, csr, x0);
csrw :: inline proc(csr, rs : u32) -> u32 do return csrrw(x0, csr, rs);
csrs :: inline proc(csr, rs : u32) -> u32 do return csrrs(x0, csr, rs);
csrc :: inline proc(csr, rs : u32) -> u32 do return csrrc(x0, csr, rs);

csrwi :: inline proc(csr : u32, imm : u64) -> u32 do return csrrwi(x0, csr, imm);
csrsi :: inline proc(csr : u32, imm : u64) -> u32 do return csrrsi(x0, csr, imm);
csrci :: inline proc(csr : u32, imm : u64) -> u32 do return csrrci(x0, csr, imm);

frcsr :: inline proc(rd : u32)     -> u32 do return csrrs(rd, fcsr, x0);
fscsr :: inline proc(rd, rs : u32) -> u32 do return csrrw(rd, fcsr, rs);
fscsr :: inline proc(rs : u32)     -> u32 do return csrrw(x0, fcsr, rs);

frrm  :: inline proc(rd : u32)            -> u32 do return csrrs(rd, frm, x0);
fsrm  :: inline proc(rd, rs : u32)        -> u32 do return csrrw(rd, frm, rs);
fsrm  :: inline proc(rs : u32)            -> u32 do return csrrw(x0, frm, rs);
fsrmi :: inline proc(rd : u32, imm : u64) -> u32 do return csrrwi(rd, frm, imm);
fsrmi :: inline proc(imm : u32)          -> u32 do return csrrwi(x0, frm, imm);

frflags  :: inline proc(rd : u32)            -> u32 do return csrrs(rd, fflags, x0);
fsflags  :: inline proc(rd, rs : u32)        -> u32 do return csrrw(rd, fflags, rs);
fsflags  :: inline proc(rs : u32)            -> u32 do return csrrw(x0, fflags, rs);
fsflagsi :: inline proc(rd : u32, imm : u64) -> u32 do return csrrwi(rd, fflags, imm);
fsflagsi :: inline proc(imm : u64)          -> u32 do return csrrwi(x0, fflags, imm);
*/



jal  :: proc[jal_, jal__];
jalr :: proc[jalr_, jalr__];
