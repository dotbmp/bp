/*
 *  @Name:     thread
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 21-06-2018 13:15:40 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 06-07-2018 00:13:59 UTC-5
 *  
 *  @Description:
 *  
 */

package fiber

import "core:fmt"
import "core:mem"

import "bp:allocators"



Thread :: struct {
    runcode : Runcode,

    pc     : u64,
    cycles : u64,
    time   : u64,

    spawn : bool,

    memory : []byte,
    
    registers : [64]u64,
}

make_thread :: proc(using bytecode : ^Bytecode) -> Thread {
    length := len(code) + len(data) + (stack_size == 0 ? 4096 : stack_size); // @todo(bpunsky): cmon son

    memory := make([]byte, length);
    
    copy(memory[0        ..len(code)], code);
    copy(memory[len(data)..len(code)], data);

    registers[gp] = u64(len(code));
    registers[sp] = u64(length);
    registers[fp] = u64(length);
    registers[hp] = u64(length);

    return Thread{memory=memory, registers=registers};
}

run_thread :: proc(using thread : ^Thread) {
    runcode = RUN;

    for runcode == RUN {
        step_thread(thread);
    }
}

debug_thread :: proc(using thread : ^Thread) {
    runcode = DEBUG;

    for runcode == DEBUG {
        instr := decode((^u64)(&memory[pc])^);

        opname := instr_to_string(instr);
        defer free(opname);

        when !DOS {
            fmt.printf("┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────┐\n");
            fmt.printf("| %s", opname);

            for in 0..(109-len(opname)) {
                fmt.print(" ");
            }

            fmt.printf(" |\n");

            step_thread(thread);

            fmt.printf("╞════╤════════╤════╤════════╤════╤════════╤════╤════════╤════╤════════╤════╤════════╤════╤════════╤════╤════════╡\n");
            fmt.printf("│ rz │% 8d│ gp │% 8d│ sp |% 8d│ hp │% 8d│ fp │% 8d│ ra │% 8d│ r0 |% 8d│ r1 │% 8d│\n", i64(registers[0]), i64(registers[1]), i64(registers[2]), i64(registers[3]), i64(registers[4]), i64(registers[5]), i64(registers[6]), i64(registers[7]));
            fmt.printf("├────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┤\n");
            fmt.printf("│ a0 │% 8d│ a1 │% 8d│ a2 |% 8d│ a3 │% 8d│ a4 │% 8d│ a5 │% 8d│ a6 |% 8d│ a7 │% 8d│\n", i64(registers[8]), i64(registers[9]), i64(registers[10]), i64(registers[11]), i64(registers[12]), i64(registers[13]), i64(registers[14]), i64(registers[15]));
            fmt.printf("├────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┤\n");
            fmt.printf("│ s0 │% 8d│ s1 │% 8d│ s2 |% 8d│ s3 │% 8d│ s4 │% 8d│ s5 │% 8d│ s6 |% 8d│ s7 │% 8d│\n", i64(registers[16]), i64(registers[17]), i64(registers[18]), i64(registers[19]), i64(registers[20]), i64(registers[21]), i64(registers[22]), i64(registers[23]));
            fmt.printf("├────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┤\n");
            fmt.printf("│ t0 │% 8d│ t1 │% 8d│ t2 |% 8d│ t3 │% 8d│ t4 │% 8d│ t5 │% 8d│ t6 |% 8d│ t7 │% 8d│\n", i64(registers[24]), i64(registers[25]), i64(registers[26]), i64(registers[27]), i64(registers[28]), i64(registers[29]), i64(registers[30]), i64(registers[31]));
            /*
            fmt.printf("├────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┤\n");
            fmt.printf("│ rz │% 8d│ ra │% 8d│ sp |% 8d│ gp │% 8d│ rz │% 8d│ ra │% 8d│ sp |% 8d│ gp │% 8d│\n", i64(registers[32]), i64(registers[33]), i64(registers[34]), i64(registers[35]), i64(registers[36]), i64(registers[37]), i64(registers[38]), i64(registers[39]));
            fmt.printf("├────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┤\n");
            fmt.printf("│ rz │% 8d│ ra │% 8d│ sp |% 8d│ gp │% 8d│ rz │% 8d│ ra │% 8d│ sp |% 8d│ gp │% 8d│\n", i64(registers[40]), i64(registers[41]), i64(registers[42]), i64(registers[43]), i64(registers[44]), i64(registers[45]), i64(registers[46]), i64(registers[47]));
            fmt.printf("├────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┤\n");
            fmt.printf("│ rz │% 8d│ ra │% 8d│ sp |% 8d│ gp │% 8d│ rz │% 8d│ ra │% 8d│ sp |% 8d│ gp │% 8d│\n", i64(registers[48]), i64(registers[49]), i64(registers[50]), i64(registers[51]), i64(registers[52]), i64(registers[53]), i64(registers[54]), i64(registers[55]));
            fmt.printf("├────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┼────┼────────┤\n");
            fmt.printf("│ rz │% 8d│ ra │% 8d│ sp |% 8d│ gp │% 8d│ rz │% 8d│ ra │% 8d│ sp |% 8d│ gp │% 8d│\n", i64(registers[56]), i64(registers[57]), i64(registers[58]), i64(registers[59]), i64(registers[60]), i64(registers[61]), i64(registers[62]), i64(registers[63]));
            */
            fmt.printf("└────┴────────┴────┴────────┴────┴────────┴────┴────────┴────┴────────┴────┴────────┴────┴────────┴────┴────────┘\n");
            fmt.printf("\n");
        }
        else {
            fmt.printf("\xDA\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xBF\n");
            fmt.printf("\xB3 %s", opname);

            for in 0..(109-len(opname)) {
                fmt.print(" ");
            }

            fmt.printf(" \xB3\n");

            step_thread(thread);

            fmt.printf("\xC6\xCD\xCD\xCD\xCD\xD1\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xD1\xCD\xCD\xCD\xCD\xD1\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xD1\xCD\xCD\xCD\xCD\xD1\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xD1\xCD\xCD\xCD\xCD\xD1\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xD1\xCD\xCD\xCD\xCD\xD1\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xD1\xCD\xCD\xCD\xCD\xD1\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xD1\xCD\xCD\xCD\xCD\xD1\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xD1\xCD\xCD\xCD\xCD\xD1\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xB5\n");
            fmt.printf("\xB3 rz \xB3% 8d\xB3 gp \xB3% 8d\xB3 sp \xB3% 8d\xB3 hp \xB3% 8d\xB3 fp \xB3% 8d\xB3 ra \xB3% 8d\xB3 r0 \xB3% 8d\xB3 r1 \xB3% 8d\xB3\n", i64(registers[0]), i64(registers[1]), i64(registers[2]), i64(registers[3]), i64(registers[4]), i64(registers[5]), i64(registers[6]), i64(registers[7]));
            fmt.printf("\xC3\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xB4\n");
            fmt.printf("\xB3 a0 \xB3% 8d\xB3 a1 \xB3% 8d\xB3 a2 \xB3% 8d\xB3 a3 \xB3% 8d\xB3 a4 \xB3% 8d\xB3 a5 \xB3% 8d\xB3 a6 \xB3% 8d\xB3 a7 \xB3% 8d\xB3\n", i64(registers[8]), i64(registers[9]), i64(registers[10]), i64(registers[11]), i64(registers[12]), i64(registers[13]), i64(registers[14]), i64(registers[15]));
            fmt.printf("\xC3\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xB4\n");
            fmt.printf("\xB3 s0 \xB3% 8d\xB3 s1 \xB3% 8d\xB3 s2 \xB3% 8d\xB3 s3 \xB3% 8d\xB3 s4 \xB3% 8d\xB3 s5 \xB3% 8d\xB3 s6 \xB3% 8d\xB3 s7 \xB3% 8d\xB3\n", i64(registers[16]), i64(registers[17]), i64(registers[18]), i64(registers[19]), i64(registers[20]), i64(registers[21]), i64(registers[22]), i64(registers[23]));
            fmt.printf("\xC3\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xB4\n");
            fmt.printf("\xB3 t0 \xB3% 8d\xB3 t1 \xB3% 8d\xB3 t2 \xB3% 8d\xB3 t3 \xB3% 8d\xB3 t4 \xB3% 8d\xB3 t5 \xB3% 8d\xB3 t6 \xB3% 8d\xB3 t7 \xB3% 8d\xB3\n", i64(registers[24]), i64(registers[25]), i64(registers[26]), i64(registers[27]), i64(registers[28]), i64(registers[29]), i64(registers[30]), i64(registers[31]));
            /*
            fmt.printf("\xC3\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xB4\n");
            fmt.printf("\xB3 rz \xB3% 8d\xB3 ra \xB3% 8d\xB3 sp \xB3% 8d\xB3 gp \xB3% 8d\xB3 rz \xB3% 8d\xB3 ra \xB3% 8d\xB3 sp \xB3% 8d\xB3 gp \xB3% 8d\xB3\n", i64(registers[32]), i64(registers[33]), i64(registers[34]), i64(registers[35]), i64(registers[36]), i64(registers[37]), i64(registers[38]), i64(registers[39]));
            fmt.printf("\xC3\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xB4\n");
            fmt.printf("\xB3 rz \xB3% 8d\xB3 ra \xB3% 8d\xB3 sp \xB3% 8d\xB3 gp \xB3% 8d\xB3 rz \xB3% 8d\xB3 ra \xB3% 8d\xB3 sp \xB3% 8d\xB3 gp \xB3% 8d\xB3\n", i64(registers[40]), i64(registers[41]), i64(registers[42]), i64(registers[43]), i64(registers[44]), i64(registers[45]), i64(registers[46]), i64(registers[47]));
            fmt.printf("\xC3\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xB4\n");
            fmt.printf("\xB3 rz \xB3% 8d\xB3 ra \xB3% 8d\xB3 sp \xB3% 8d\xB3 gp \xB3% 8d\xB3 rz \xB3% 8d\xB3 ra \xB3% 8d\xB3 sp \xB3% 8d\xB3 gp \xB3% 8d\xB3\n", i64(registers[48]), i64(registers[49]), i64(registers[50]), i64(registers[51]), i64(registers[52]), i64(registers[53]), i64(registers[54]), i64(registers[55]));
            fmt.printf("\xC3\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC5\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xB4\n");
            fmt.printf("\xB3 rz \xB3% 8d\xB3 ra \xB3% 8d\xB3 sp \xB3% 8d\xB3 gp \xB3% 8d\xB3 rz \xB3% 8d\xB3 ra \xB3% 8d\xB3 sp \xB3% 8d\xB3 gp \xB3% 8d\xB3\n", i64(registers[56]), i64(registers[57]), i64(registers[58]), i64(registers[59]), i64(registers[60]), i64(registers[61]), i64(registers[62]), i64(registers[63]));
            */
            fmt.printf("\xC0\xC4\xC4\xC4\xC4\xC1\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC1\xC4\xC4\xC4\xC4\xC1\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC1\xC4\xC4\xC4\xC4\xC1\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC1\xC4\xC4\xC4\xC4\xC1\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC1\xC4\xC4\xC4\xC4\xC1\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC1\xC4\xC4\xC4\xC4\xC1\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC1\xC4\xC4\xC4\xC4\xC1\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC1\xC4\xC4\xC4\xC4\xC1\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xD9\n");
            fmt.printf("\n");
        }
    }

    fmt.printf("runcode: %v\n", runcode);
}

step_thread :: proc(using thread : ^Thread) {
    using instr := decode((^u64)(&memory[pc])^);
    
    next_pc := pc + size_of(u64);

    null_target : u64 = ---;

    dst := rd == rz ? &null_target : &registers[rd];

    switch op {
    case QUIT:
        runcode = STOP;
    
    case BRK:
        // @todo: implement

    case IHI: (^u32)(dst)^ = u32(u64(im));
    case ILO: (^u32)(uintptr(dst) + size_of(u32))^ = u32(u64(im));

    case GOTO:
        dst^ = next_pc;
        next_pc = u64(i64(registers[rs1]) + im);

    case JUMP:
        dst^ = next_pc;
        next_pc = u64(i64(pc) + im);

    case JEQ:  if registers[rs1] == registers[rs2] do next_pc = u64(i64(pc) + i64(im));
    case JNE:  if registers[rs1] != registers[rs2] do next_pc = u64(i64(pc) + i64(im));
    case JLT:  if i64(registers[rs1]) <  i64(registers[rs2]) do next_pc = u64(i64(pc) + i64(im));
    case JGE:  if i64(registers[rs1]) >= i64(registers[rs2]) do next_pc = u64(i64(pc) + i64(im));
    case JLTU: if registers[rs1] <  registers[rs2] do next_pc = u64(i64(pc) + i64(im));
    case JGEU: if registers[rs1] >= registers[rs2] do next_pc = u64(i64(pc) + i64(im));

    case ADDI: registers[rd] = u64(i64(registers[rd]) + i64(im));

    case SV8:   (^u8)(&memory[(^i64)(&registers[rd])^ + im])^ =  u8(registers[rs1]);
    case SV16: (^u16)(&memory[(^i64)(&registers[rd])^ + im])^ = u16(registers[rs1]);
    case SV32: (^u32)(&memory[(^i64)(&registers[rd])^ + im])^ = u32(registers[rs1]);
    case SV64: (^u64)(&memory[(^i64)(&registers[rd])^ + im])^ = u64(registers[rs1]);

    case LD8:   (^u8)(dst)^ =  (^u8)(&memory[registers[rs1] + u64(im)])^;
    case LD16: (^u16)(dst)^ = (^u16)(&memory[registers[rs1] + u64(im)])^;
    case LD32: (^u32)(dst)^ = (^u32)(&memory[registers[rs1] + u64(im)])^;
    case LD64: (^u64)(dst)^ = (^u64)(&memory[registers[rs1] + u64(im)])^;

    case MUL: registers[rd] = u64(i64(registers[rs1]) *  i64(registers[rs2]));
    case DIV: registers[rd] = u64(i64(registers[rs1]) /  i64(registers[rs2]));
    case MOD: registers[rd] = u64(i64(registers[rs1]) %% i64(registers[rs2]));

    case ADD:  registers[rd] = registers[rs1] + registers[rs2];
    case SUB:  registers[rd] = registers[rs1] - registers[rs2];
    case MULU: registers[rd] = registers[rs1] * registers[rs2];
    case DIVU: registers[rd] = registers[rs1] / registers[rs2];
    case MODU: registers[rd] = registers[rs1] % registers[rs2];

    case ADDF: registers[rd] = u64(f64(registers[rs1]) + f64(registers[rs2]));
    case SUBF: registers[rd] = u64(f64(registers[rs1]) - f64(registers[rs2]));
    case MULF: registers[rd] = u64(f64(registers[rs1]) * f64(registers[rs2]));
    case DIVF: registers[rd] = u64(f64(registers[rs1]) / f64(registers[rs2]));
   
    case SHL: registers[rd] = registers[rs1] << registers[rs2];
    case SHR: registers[rd] = registers[rs1] >> registers[rs2];
    case SHA: registers[rd] = u64(i64(registers[rs1]) >> registers[rs2]);

    case SHLI: registers[rd] = registers[rs1] << u64(im);
    case SHRI: registers[rd] = registers[rs1] >> u64(im);
    case SHAI: registers[rd] = u64(i64(registers[rs1]) >> u64(im));

    case AND: registers[rd] = registers[rs1]  &  registers[rs2];
    case OR:  registers[rd] = registers[rs1]  |  registers[rs2];
    case XOR: registers[rd] = registers[rs1] ~~~ registers[rs2];

    case ANDI: registers[rd] = registers[rs1]  &  u64(im);
    case ORI:  registers[rd] = registers[rs1]  |  u64(im);
    case XORI: registers[rd] = registers[rs1] ~~~ u64(im);

    case FCALL: //(^i64)(&registers[a1])^ = procs[registers[rd]](registers[a2], registers[a3], registers[a4]);

    case: runcode = STOP;
    }

    pc = next_pc;
}
