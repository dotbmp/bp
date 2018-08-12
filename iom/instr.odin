/*
 *  @Name:     instr
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 26-06-2018 15:44:00 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 06-07-2018 09:52:53 UTC-5
 *  
 *  @Description:
 *  
 */

package fiber

import "core:fmt"



Op :: enum u16 #export {
    INVALID,

    QUIT,
    BRK,

    IHI,
    ILO,

    GOTO,
    JUMP,

    JEQ,
    JNE,
    JLT,
    JGE,
    JLTU,
    JGEU,

    ADDI,

    SV8,
    SV16,
    SV32,
    SV64,

    LD8,
    LD16,
    LD32,
    LD64,

    ADD,
    ADDF,
    
    SUB,
    SUBF,
    
    MUL,
    MULU,
    MULF,
    
    DIV,
    DIVU,
    DIVF,
    
    MOD,
    MODU,

    SHL,
    SHR,
    SHA,

    SHLI,
    SHRI,
    SHAI,

    AND,
    OR,
    XOR,

    ANDI,
    ORI,
    XORI,

    FCALL,

    // PSEUDOINSTRUCTIONS

    NOP,
    MOV,

    CALL,
    TAIL,
    
    RET,

    PUSH,
    POP,
}

Reg :: enum u16 #export {
    x0,  x1,  x2,  x3,
    x4,  x5,  x6,  x7,
    x8,  x9,  x10, x11,
    x12, x13, x14, x15,
    x16, x17, x18, x19,
    x20, x21, x22, x23,
    x24, x25, x26, x27,
    x28, x29, x30, x31,
    x32, x33, x34, x35,
    x36, x37, x38, x39,
    x40, x41, x42, x43,
    x44, x45, x46, x47,
    x48, x49, x50, x51,
    x52, x53, x54, x55,
    x56, x57, x58, x59,
    x60, x61, x62, x63,

    rz = x0,

    gp = x1,
    sp = x2,
    hp = x3,
    fp = x4,

    ra = x5,

    r0 = x6,
    r1 = x7,
    
    a0 = x8,
    a1 = x9,
    a2 = x10,
    a3 = x11,
    a4 = x12,
    a5 = x13,
    a6 = x14,
    a7 = x15,

    s0 = x16,
    s1 = x17,
    s2 = x18,
    s3 = x19,
    s4 = x20,
    s5 = x21,
    s6 = x22,
    s7 = x23,

    t0 = x24,
    t1 = x25,
    t2 = x26,
    t3 = x27,
    t4 = x28,
    t5 = x29,
    t6 = x30,
    t7 = x31,
}



Instr :: struct {
    op : Op,

    rd  : Reg,
    rs1 : Reg,
    rs2 : Reg,
    rs3 : Reg,

    im : i64,
}

instr_to_string :: proc(using instr : Instr) -> string {
    switch op {
    case QUIT, BRK:
        return fmt.aprintf("%v", op);

    case ILO, IHI, ADDI, FCALL:
        return fmt.aprintf("%v %v, %d", op, rd, im);

    case GOTO:
        return fmt.aprintf("%v %v, %v", op, rd, rs1);

    case JUMP:
        return fmt.aprintf("%v %v", op, im);

    case JEQ, JNE, JLT, JGE, JLTU, JGEU:
        return fmt.aprintf("%v %v, %v, %d", op, rs1, rs2, im);

    case SV8, SV16, SV32, SV64:
        return fmt.aprintf("%v [%v + %d], %v", op, rd, im, rs1);

    case LD8, LD16, LD32, LD64:
        return fmt.aprintf("%v %v, [%v + %d]", op, rd, rs1, im);

    case SHLI, SHRI, SHAI, ANDI, ORI, XORI:
        return fmt.aprintf("%v %v, %v, %d", op, rd, rs1, im);

    case ADD, SUB, MUL, DIV, MOD, MULU, DIVU, MODU, ADDF, SUBF, MULF, DIVF, SHL, SHR, SHA, AND, OR, XOR:
        return fmt.aprintf("%v %v, %v, %v", op, rd, rs1, rs2);
    }

    return "";
}

encode :: proc(using instr : Instr) -> (x : u64) {
    switch op {
    case QUIT, BRK:
        x = u64(op);

    case ILO, IHI, ADDI, JUMP, FCALL:
        x = u64(op) | u64(rd) << 16 | u64(im << 32);

    case GOTO:
        x = u64(op) | u64(rd) << 16 | u64(rs1) << 32 | u64(im << 48);

    case JEQ, JNE, JLT, JGE, JLTU, JGEU:
        x = u64(op) | u64(im << 16) | u64(rs1) << 32 | u64(rs2) << 48;

    case SV8, SV16, SV32, SV64, LD8, LD16, LD32, LD64, SHLI, SHRI, SHAI, ANDI, ORI, XORI:
        x = u64(op) | u64(rd) << 16 | u64(rs1) << 32 | u64(u16(i16(im))) << 48;

    case ADD, SUB, MUL, DIV, MOD, MULU, DIVU, MODU, ADDF, SUBF, MULF, DIVF, SHL, SHR, SHA, AND, OR, XOR:
        x = u64(op) | u64(rd) << 16 | u64(rs1) << 32 | u64(rs2) << 48;
    }

    return;
}

decode :: proc(x : u64) -> (instr : Instr) {
    using instr;

    op = Op(x & 0xFFFF);

    switch op {
    case QUIT, BRK:
        return;

    case ILO, IHI, ADDI, JUMP, FCALL:
        rd = Reg(x >> 16 & 0xFFFF);
        im = i64(i32(x >> 32 & 0xFFFFFFFF));

    case GOTO:
        rd  = Reg(x >> 16 & 0xFFFF);
        rs1 = Reg(x >> 32 & 0xFFFF);

    case JEQ, JNE, JLT, JGE, JLTU, JGEU:
        im  = i64(i16(x >> 16 & 0xFFFF));
        rs1 = Reg(x >> 32 & 0xFFFF);
        rs2 = Reg(x >> 48 & 0xFFFF);
    
    case SV8, SV16, SV32, SV64, LD8, LD16, LD32, LD64, SHLI, SHRI, SHAI, ANDI, ORI, XORI:
        rd  = Reg(x >> 16 & 0xFFFF);
        rs1 = Reg(x >> 32 & 0xFFFF);
        im  = i64(i16(x >> 48 & 0xFFFF));

    case ADD, SUB, MUL, DIV, MOD, MULU, DIVU, MODU, ADDF, SUBF, MULF, DIVF, SHL, SHR, SHA, AND, OR, XOR:
        rd  = Reg(x >> 16 & 0xFFFF);
        rs1 = Reg(x >> 32 & 0xFFFF);
        rs2 = Reg(x >> 48 & 0xFFFF);
    }

    return;
}



quit :: inline proc() -> u64 do return encode(Instr{op=QUIT});
brk  :: inline proc() -> u64 do return encode(Instr{op=BRK});

ihi :: inline proc(rd : Reg, im : i64) -> u64 do return encode(Instr{op=IHI, rd=rd, im=i64(u64(im) >> 32)});
ilo :: inline proc(rd : Reg, im : i64) -> u64 do return encode(Instr{op=ILO, rd=rd, im=i64(u64(im) & 0xFFFFFFFF)});

goto_ :: inline proc(rd, rs : Reg, im : i16) -> u64 do return encode(Instr{op=GOTO, rd=rd, rs1=rs, im=i64(im)});
jump_ :: inline proc(rd : Reg, im : i32)     -> u64 do return encode(Instr{op=JUMP, rd=rd, im=i64(im)});

jeq  :: inline proc(rs1, rs2 : Reg, im : i16) -> u64 do return encode(Instr{op=JEQ,  rs1=rs1, rs2=rs2, im=i64(im)});
jne  :: inline proc(rs1, rs2 : Reg, im : i16) -> u64 do return encode(Instr{op=JNE,  rs1=rs1, rs2=rs2, im=i64(im)});
jlt  :: inline proc(rs1, rs2 : Reg, im : i16) -> u64 do return encode(Instr{op=JLT,  rs1=rs1, rs2=rs2, im=i64(im)});
jge  :: inline proc(rs1, rs2 : Reg, im : i16) -> u64 do return encode(Instr{op=JGE,  rs1=rs1, rs2=rs2, im=i64(im)});
jltu :: inline proc(rs1, rs2 : Reg, im : i16) -> u64 do return encode(Instr{op=JLTU, rs1=rs1, rs2=rs2, im=i64(im)});
jgeu :: inline proc(rs1, rs2 : Reg, im : i16) -> u64 do return encode(Instr{op=JGEU, rs1=rs1, rs2=rs2, im=i64(im)});

addi :: inline proc(rd : Reg, im : i32) -> u64 do return encode(Instr{op=ADDI, rd=rd, im=i64(im)});

sv8_  :: inline proc(rd : Reg, im : i16, rs : Reg) -> u64 do return encode(Instr{op=SV8,  rd=rd, rs1=rs, im=i64(im)});
sv16_ :: inline proc(rd : Reg, im : i16, rs : Reg) -> u64 do return encode(Instr{op=SV16, rd=rd, rs1=rs, im=i64(im)});
sv32_ :: inline proc(rd : Reg, im : i16, rs : Reg) -> u64 do return encode(Instr{op=SV32, rd=rd, rs1=rs, im=i64(im)});
sv64_ :: inline proc(rd : Reg, im : i16, rs : Reg) -> u64 do return encode(Instr{op=SV64, rd=rd, rs1=rs, im=i64(im)});

ld8_  :: inline proc(rd, rs : Reg, im : i16) -> u64 do return encode(Instr{op=LD8,  rd=rd, rs1=rs, im=i64(im)});
ld16_ :: inline proc(rd, rs : Reg, im : i16) -> u64 do return encode(Instr{op=LD16, rd=rd, rs1=rs, im=i64(im)});
ld32_ :: inline proc(rd, rs : Reg, im : i16) -> u64 do return encode(Instr{op=LD32, rd=rd, rs1=rs, im=i64(im)});
ld64_ :: inline proc(rd, rs : Reg, im : i16) -> u64 do return encode(Instr{op=LD64, rd=rd, rs1=rs, im=i64(im)});

add_  :: inline proc(rd, rs1, rs2 : Reg) -> u64 do return encode(Instr{op=ADD,  rd=rd, rs1=rs1, rs2=rs2});
addf_ :: inline proc(rd, rs1, rs2 : Reg) -> u64 do return encode(Instr{op=ADDF, rd=rd, rs1=rs1, rs2=rs2});

sub_  :: inline proc(rd, rs1, rs2 : Reg) -> u64 do return encode(Instr{op=SUB,  rd=rd, rs1=rs1, rs2=rs2});
subf_ :: inline proc(rd, rs1, rs2 : Reg) -> u64 do return encode(Instr{op=SUBF, rd=rd, rs1=rs1, rs2=rs2});

mul_  :: inline proc(rd, rs1, rs2 : Reg) -> u64 do return encode(Instr{op=MUL,  rd=rd, rs1=rs1, rs2=rs2});
mulu_ :: inline proc(rd, rs1, rs2 : Reg) -> u64 do return encode(Instr{op=MULU, rd=rd, rs1=rs1, rs2=rs2});
mulf_ :: inline proc(rd, rs1, rs2 : Reg) -> u64 do return encode(Instr{op=MULF, rd=rd, rs1=rs1, rs2=rs2});

div_  :: inline proc(rd, rs1, rs2 : Reg) -> u64 do return encode(Instr{op=DIV,  rd=rd, rs1=rs1, rs2=rs2});
divu_ :: inline proc(rd, rs1, rs2 : Reg) -> u64 do return encode(Instr{op=DIVU, rd=rd, rs1=rs1, rs2=rs2});
divf_ :: inline proc(rd, rs1, rs2 : Reg) -> u64 do return encode(Instr{op=DIVF, rd=rd, rs1=rs1, rs2=rs2});

mod_  :: inline proc(rd, rs1, rs2 : Reg) -> u64 do return encode(Instr{op=MOD,  rd=rd, rs1=rs1, rs2=rs2});
modu_ :: inline proc(rd, rs1, rs2 : Reg) -> u64 do return encode(Instr{op=MODU, rd=rd, rs1=rs1, rs2=rs2});

shl_ :: inline proc(rd, rs1, rs2 : Reg) -> u64 do return encode(Instr{op=SHL, rd=rd, rs1=rs1, rs2=rs2});
shr_ :: inline proc(rd, rs1, rs2 : Reg) -> u64 do return encode(Instr{op=SHR, rd=rd, rs1=rs1, rs2=rs2});
sha_ :: inline proc(rd, rs1, rs2 : Reg) -> u64 do return encode(Instr{op=SHA, rd=rd, rs1=rs1, rs2=rs2});

shli :: inline proc(rd, rs : Reg, im : i16) -> u64 do return encode(Instr{op=SHL, rd=rd, rs1=rs, im=i64(im)});
shri :: inline proc(rd, rs : Reg, im : i16) -> u64 do return encode(Instr{op=SHR, rd=rd, rs1=rs, im=i64(im)});
shai :: inline proc(rd, rs : Reg, im : i16) -> u64 do return encode(Instr{op=SHA, rd=rd, rs1=rs, im=i64(im)});

and_ :: inline proc(rd, rs1, rs2 : Reg) -> u64 do return encode(Instr{op=AND, rd=rd, rs1=rs1, rs2=rs2});
or_  :: inline proc(rd, rs1, rs2 : Reg) -> u64 do return encode(Instr{op=OR,  rd=rd, rs1=rs1, rs2=rs2});
xor_ :: inline proc(rd, rs1, rs2 : Reg) -> u64 do return encode(Instr{op=XOR, rd=rd, rs1=rs1, rs2=rs2});

andi :: inline proc(rd, rs : Reg, im : i16) -> u64 do return encode(Instr{op=ANDI, rd=rd, rs1=rs, im=i64(im)});
ori  :: inline proc(rd, rs : Reg, im : i16) -> u64 do return encode(Instr{op=ORI,  rd=rd, rs1=rs, im=i64(im)});
xori :: inline proc(rd, rs : Reg, im : i16) -> u64 do return encode(Instr{op=XORI, rd=rd, rs1=rs, im=i64(im)});

fcall :: inline proc(rd : Reg, im : i32) -> u64 do return encode(Instr{op=FCALL, rd=rd, im=i64(im)});


// pseudoinstructions

nop :: inline proc() -> u64 do return add(rz, rz, rz);

mov_ :: inline proc(rd, rs : Reg) -> u64 do return add(rd, rs, rz);

mov__ :: inline proc(rd : Reg, im : i64) -> (u64, u64) {
    tmp1 := ihi(rd, im);
    tmp2 := ilo(rd, im);

    return tmp1, tmp2;
}

mov :: proc[mov_, mov__];

goto__   :: inline proc(rd, rs1 : Reg)       -> u64 do return goto_(rd, rs1,  0);
goto___  :: inline proc(rs1 : Reg, im : i16) -> u64 do return goto_(rz, rs1, im);
goto____ :: inline proc(rs1 : Reg)           -> u64 do return goto_(rz, rs1,  0);

goto :: proc[goto_, goto__, goto___, goto____];

jump__ :: inline proc(im : i32) -> u64 do return jump_(rz, im);

jump :: proc[jump_, jump__];

jgt  :: inline proc(rs1, rs2 : Reg, im : i16) -> u64 do return jge(rs2, rs1, im);
jle  :: inline proc(rs1, rs2 : Reg, im : i16) -> u64 do return jlt(rs2, rs1, im);
jgtu :: inline proc(rs1, rs2 : Reg, im : i16) -> u64 do return jgeu(rs2, rs1, im);
jleu :: inline proc(rs1, rs2 : Reg, im : i16) -> u64 do return jltu(rs2, rs1, im);

sv8__  :: inline proc(rd, rs : Reg) -> u64 do return sv8(rd, 0, rs);
sv16__ :: inline proc(rd, rs : Reg) -> u64 do return sv16(rd, 0, rs);
sv32__ :: inline proc(rd, rs : Reg) -> u64 do return sv32(rd, 0, rs);
sv64__ :: inline proc(rd, rs : Reg) -> u64 do return sv64(rd, 0, rs);

sv8  :: proc[sv8_, sv8__];
sv16 :: proc[sv16_, sv16__];
sv32 :: proc[sv32_, sv32__];
sv64 :: proc[sv64_, sv64__];

ld8__  :: inline proc(rd, rs : Reg) -> u64 do return ld8(rd, rs, 0);
ld16__ :: inline proc(rd, rs : Reg) -> u64 do return ld16(rd, rs, 0);
ld32__ :: inline proc(rd, rs : Reg) -> u64 do return ld32(rd, rs, 0);
ld64__ :: inline proc(rd, rs : Reg) -> u64 do return ld64(rd, rs, 0);

ld8  :: proc[ld8_, ld8__];
ld16 :: proc[ld16_, ld16__];
ld32 :: proc[ld32_, ld32__];
ld64 :: proc[ld64_, ld64__];

add__  :: inline proc(rd, rs : Reg) -> u64 do return add (rd, rd, rs);
addf__ :: inline proc(rd, rs : Reg) -> u64 do return addf(rd, rd, rs);
sub__  :: inline proc(rd, rs : Reg) -> u64 do return sub (rd, rd, rs);
subf__ :: inline proc(rd, rs : Reg) -> u64 do return subf(rd, rd, rs);
mul__  :: inline proc(rd, rs : Reg) -> u64 do return mul (rd, rd, rs);
mulu__ :: inline proc(rd, rs : Reg) -> u64 do return mulu(rd, rd, rs);
mulf__ :: inline proc(rd, rs : Reg) -> u64 do return mulf(rd, rd, rs);
div__  :: inline proc(rd, rs : Reg) -> u64 do return div (rd, rd, rs);
divu__ :: inline proc(rd, rs : Reg) -> u64 do return divu(rd, rd, rs);
divf__ :: inline proc(rd, rs : Reg) -> u64 do return divf(rd, rd, rs);
mod__  :: inline proc(rd, rs : Reg) -> u64 do return mod (rd, rd, rs);
modu__ :: inline proc(rd, rs : Reg) -> u64 do return modu(rd, rd, rs);
shl__  :: inline proc(rd, rs : Reg) -> u64 do return shl (rd, rd, rs);
shr__  :: inline proc(rd, rs : Reg) -> u64 do return shr (rd, rd, rs);
sha__  :: inline proc(rd, rs : Reg) -> u64 do return sha (rd, rd, rs);
and__  :: inline proc(rd, rs : Reg) -> u64 do return and (rd, rd, rs);
or__   :: inline proc(rd, rs : Reg) -> u64 do return or  (rd, rd, rs);
xor__  :: inline proc(rd, rs : Reg) -> u64 do return xor (rd, rd, rs);

add  :: proc[add_,  add__];
addf :: proc[addf_, addf__];
sub  :: proc[sub_,  sub__];
subf :: proc[subf_, subf__];
mul  :: proc[mul_,  mul__];
mulu :: proc[mulu_, mulu__];
mulf :: proc[mulf_, mulf__];
div  :: proc[div_,  div__];
divu :: proc[divu_, divu__];
divf :: proc[divf_, divf__];
mod  :: proc[mod_,  mod__];
modu :: proc[modu_, modu__];
shl  :: proc[shl_,  shl__];
shr  :: proc[shr_,  shr__];
sha  :: proc[sha_,  sha__];
and  :: proc[and_,  and__];
or   :: proc[or_,   or__];
xor  :: proc[xor_,  xor__];

inc :: inline proc(rd : Reg) -> u64 do return addi(rd,  1);
dec :: inline proc(rd : Reg) -> u64 do return addi(rd, -1);

call :: inline proc(im : i64) -> (u64, u64, u64) do return mov(t0, im), goto(ra, t0);
tail :: inline proc(im : i64) -> (u64, u64, u64) do return mov(t0, im), goto(rz, t0);

ret  :: inline proc() -> u64 do return goto(rz, ra, 0);

push_ :: inline proc(rs : Reg) -> (u64, u64) do return addi(sp, -8), sv64(sp, rs);
pop   :: inline proc(rs : Reg) -> (u64, u64) do return ld64(rs, sp), addi(sp,  8);

push__ :: inline proc(im : i64) -> (u64, u64, u64, u64) do return addi(sp, -8), mov(t0, im), sv64(sp, t0);

push :: proc[push_, push__];
