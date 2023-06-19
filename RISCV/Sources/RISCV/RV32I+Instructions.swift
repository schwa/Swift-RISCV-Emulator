import Everything
import Foundation

public struct RV32IInstructionSet: InstructionSet {
    public let instructions = [
        // ### Immediates

        // Add Immediate
        Instruction(mnemonic: "ADDI", format: ImmFormat(), opcode: .imm, locator: .funct3(0b000)) { cpu, params in
            let rs1 = Int32(bitPattern: cpu.registers[params.rs1])
            let imm = signExtend(params.imm, bits: 12)
            cpu.registers[params.rd] = UInt32(bitPattern: imm &+ rs1)
            cpu.pc += params.instructionSize
        }.any(),

        // Set if less than immediate
        Instruction(mnemonic: "SLTI", format: ImmFormat(), opcode: .imm, locator: .funct3(0b010)) { cpu, params in
            let rs1 = cpu.registers[params.rs1]
            let imm = signExtend(params.imm, bits: 12)
            cpu.registers[params.rd] = rs1 < imm ? 1 : 0
            cpu.pc += params.instructionSize
        }.any(),

        // Set if less than unsigned immediate
        Instruction(mnemonic: "SLTIU", format: ImmFormat(), opcode: .imm, locator: .funct3(0b011)) { cpu, params in
            let rs1 = cpu.registers[params.rs1]
            let imm = UInt32(bitPattern: signExtend(params.imm, bits: 12))
            cpu.registers[params.rd] = rs1 < imm ? 1 : 0
            cpu.pc += params.instructionSize
        }.any(),

        // Logical and immediate
        Instruction(mnemonic: "ANDI", format: ImmFormat(), opcode: .imm, locator: .funct3(0b111)) { cpu, params in
            let rs1 = cpu.registers[params.rs1]
            let imm = signExtendU(params.imm, bits: 12)
            cpu.registers[params.rd] = rs1 & imm
            cpu.pc += params.instructionSize
        }.any(),

        // Logical or immediate
        Instruction(mnemonic: "ORI", format: ImmFormat(), opcode: .imm, locator: .funct3(0b110)) { cpu, params in
            let rs1 = cpu.registers[params.rs1]
            // let imm = signExtendU(params.imm, bits: 12)
            let imm = params.imm
            let value = rs1 | imm
            cpu.registers[params.rd] = rs1 | imm
            cpu.pc += params.instructionSize
        }.any(),

        // Logical xor immediate
        Instruction(mnemonic: "XORI", format: ImmFormat(), opcode: .imm, locator: .funct3(0b100)) { cpu, params in
            let rs1 = cpu.registers[params.rs1]
            let imm = signExtendU(params.imm, bits: 12)
            cpu.registers[params.rd] = rs1 ^ imm
            cpu.pc += params.instructionSize
        }.any(),

        // Load Upper Immediate
        Instruction(mnemonic: "LUI", format: UFormat(), opcode: .lui, locator: .none) { cpu, params in
            let rd = cpu.registers[params.rd]
            let imm = params.imm
            cpu.registers[params.rd] = imm
            cpu.pc += params.instructionSize
        }.any(),

        // Add upper immediate to pc
        Instruction(mnemonic: "AUIPC", format: UFormat(), opcode: .lui, locator: .none) { cpu, params in
            let rd = cpu.registers[params.rd]
            let imm = params.imm
            cpu.registers[params.rd] = UInt32(bitPattern: cpu.pc + Int32(bitPattern: imm << 12)) // TODO: Check the shift
            cpu.pc += params.instructionSize
        }.any(),
        // ### Jumps

        // Jump and link
        Instruction(mnemonic: "JAL", format: JALFormat(), opcode: .jal, locator: .none) { cpu, params in
            let offset = signExtend(params.imm, bits: 20) * 2
            cpu.registers[params.rd] = UInt32(bitPattern: cpu.pc + params.instructionSize)
            cpu.pc += offset
        }.any(),

        // Jump and link
        Instruction(mnemonic: "JALR", format: ImmFormat(), opcode: .jalr, locator: .funct3(0b000)) { cpu, params in
            let rs1 = Int32(bitPattern: cpu.registers[params.rs1])
            let imm = signExtend(params.imm, bits: 12)
            let address = (rs1 + imm) & 0xFFFE
            cpu.registers[params.rd] = UInt32(bitPattern: cpu.pc + params.instructionSize)
            cpu.pc = address
        }.any(),

        // ### Branches

        // Branch if equal
        Instruction(mnemonic: "BEQ", format: BranchFormat(), opcode: .branch, locator: .funct3(0b000)) { cpu, params in
            let rs1 = cpu.registers[params.rs1]
            let rs2 = cpu.registers[params.rs2]
            if rs1 == rs2 {
                let offset = signExtend(params.imm, bits: 12) * 2
                cpu.pc += offset
            }
            else {
                cpu.pc += params.instructionSize
            }
        }.any(),

        // Branch if not equal
        Instruction(mnemonic: "BNE", format: BranchFormat(), opcode: .branch, locator: .funct3(0b001)) { cpu, params in
            let rs1 = cpu.registers[params.rs1]
            let rs2 = cpu.registers[params.rs2]
            if rs1 != rs2 {
                let offset = signExtend(params.imm, bits: 12) * 2
                cpu.pc += offset
            }
            else {
                cpu.pc += params.instructionSize
            }
        }.any(),

        // Branch if less than
        Instruction(mnemonic: "BLT", format: BranchFormat(), opcode: .branch, locator: .funct3(0b100)) { cpu, params in
            let rs1 = Int32(bitPattern: cpu.registers[params.rs1])
            let rs2 = Int32(bitPattern: cpu.registers[params.rs2])
            if rs1 < rs2 {
                let offset = signExtend(params.imm, bits: 12) * 2
                cpu.pc += offset
            }
            else {
                cpu.pc += params.instructionSize
            }
        }.any(),

        // Branch if greater than or equal
        Instruction(mnemonic: "BGE", format: BranchFormat(), opcode: .branch, locator: .funct3(0b101)) { cpu, params in
            let rs1 = Int32(bitPattern: cpu.registers[params.rs1])
            let rs2 = Int32(bitPattern: cpu.registers[params.rs2])
            if rs1 >= rs2 {
                let offset = signExtend(params.imm, bits: 12) * 2
                cpu.pc += offset
            }
            else {
                cpu.pc += params.instructionSize
            }
        }.any(),

        // Branch if less than unsigned
        Instruction(mnemonic: "BLTU", format: BranchFormat(), opcode: .branch, locator: .funct3(0b110)) { cpu, params in
            let rs1 = cpu.registers[params.rs1]
            let rs2 = cpu.registers[params.rs2]
            if rs1 < rs2 {
                let offset = signExtend(params.imm, bits: 12) * 2
                cpu.pc += offset
            }
            else {
                cpu.pc += params.instructionSize
            }
        }.any(),

        // Branch if greater than or equal (unsigned)
        Instruction(mnemonic: "BGEU", format: BranchFormat(), opcode: .branch, locator: .funct3(0b111)) { cpu, params in
            let rs1 = cpu.registers[params.rs1]
            let rs2 = cpu.registers[params.rs2]
            if rs1 >= rs2 {
                let offset = signExtend(params.imm, bits: 12) * 2
                cpu.pc += offset
            }
            else {
                cpu.pc += params.instructionSize
            }
        }.any(),

        // ### Loads

        // Load word
        Instruction(mnemonic: "LW", format: ImmFormat(), opcode: .load, locator: .funct3(0b010)) { cpu, params in
            let rs1 = cpu.registers[params.rs1]
            let imm = signExtend(params.imm, bits: 12)
            let address = Int32(rs1) + imm
            let value = try cpu.peek(UInt32.self, address: address)
            cpu.registers[params.rd] = value
            cpu.pc += params.instructionSize
        }.any(),

        // Load byte unsigned
        Instruction(mnemonic: "LBU", format: ImmFormat(), opcode: .load, locator: .funct3(0b100)) { cpu, params in
            let rs1 = cpu.registers[params.rs1]
            let imm = signExtend(params.imm, bits: 12)
            let address = Int32(rs1) + imm
            let value = try cpu.peek(UInt8.self, address: address)
            cpu.registers[params.rd] = UInt32(value)
            cpu.pc += params.instructionSize
        }.any(),

        // Load byte signed
        Instruction(mnemonic: "LB", format: ImmFormat(), opcode: .load, locator: .funct3(0b000)) { cpu, params in
            let rs1 = cpu.registers[params.rs1]
            let imm = signExtend(params.imm, bits: 12)
            let address = Int32(rs1) + imm
            let value = try cpu.peek(UInt8.self, address: address)
            cpu.registers[params.rd] = signExtendU(UInt32(value), bits: 8)
            cpu.pc += params.instructionSize
        }.any(),

        // Load half word unsigned
        Instruction(mnemonic: "LHU", format: ImmFormat(), opcode: .load, locator: .funct3(0b101)) { cpu, params in
            let rs1 = cpu.registers[params.rs1]
            let imm = signExtend(params.imm, bits: 12)
            let address = Int32(rs1) + imm
            let value = try cpu.peek(UInt16.self, address: address)
            cpu.registers[params.rd] = UInt32(value)
            cpu.pc += params.instructionSize
        }.any(),

        // Load half word signed
        Instruction(mnemonic: "LH", format: ImmFormat(), opcode: .load, locator: .funct3(0b001)) { cpu, params in
            let rs1 = cpu.registers[params.rs1]
            let imm = signExtend(params.imm, bits: 12)
            let address = Int32(rs1) + imm
            let value = try cpu.peek(UInt16.self, address: address)
            cpu.registers[params.rd] = signExtendU(UInt32(value), bits: 16)
            cpu.pc += params.instructionSize
        }.any(),

        // ### Stores
        Instruction(mnemonic: "SW", format: SFormat(), opcode: .store, locator: .funct3(0b010)) { cpu, params in
            let rs1 = cpu.registers[params.rs1]
            let rs2 = cpu.registers[params.rs2]
            let imm = signExtend(params.imm, bits: 12)
            let address = Int32(rs1) + imm
            try cpu.poke(address: address, value: rs2)
            cpu.pc += params.instructionSize
        }.any(),

        // ### System
        Instruction(mnemonic: "ECALL", format: ImmFormat(), opcode: .system, locator: .funct3funct12(0b010, 0b0000_0000_0000)) { cpu, params in
            try cpu.systemCall()
            cpu.pc += params.instructionSize
        }.any(),

        Instruction(mnemonic: "EBREAK", format: ImmFormat(), opcode: .system, locator: .funct3funct12(0b010, 0b0000_0000_0001)) { cpu, params in
            try cpu.systemBreak()
            cpu.pc += params.instructionSize
        }.any(),
    ]

    public init() {
    }
}
