import Everything
import Foundation

public struct ImmFormat: InstructionFormat {
    public struct Parameters: InstructionParameters {
        let rd: RegisterName
        let rs1: RegisterName
        let imm: UInt32
    }

    public func decodeParameters(word: UInt32) throws -> Parameters {
        Parameters(
            rd: RegisterName(rawValue: word.bits[InstructionRanges.rd]),
            rs1: RegisterName(rawValue: word.bits[InstructionRanges.rs1]),
            imm: word.bits[InstructionRanges.imm]
        )
    }

    public func assemble(parameters: ParameterReader) throws -> UInt32 {
        var word: UInt32 = 0
        // TODO: Hack
        if parameters.isEmpty {
            return 0
        }

        word.bits[InstructionRanges.rd] = try parameters.register(at: 0).index
        word.bits[InstructionRanges.rs1] = try parameters.register(at: 1).index
        word.bits[InstructionRanges.imm] = UInt32(bitPattern: try parameters.integer(type: Int32.self, at: 2))
        return word
    }
}

extension ImmFormat.Parameters: CustomStringConvertible {
    public var description: String {
        "I(rd: \(rd), rs1: \(rs1), imm: \(signExtend(imm, bits: 12)))"
    }
}

// MARK: -

public struct BranchFormat: InstructionFormat {
    public struct Parameters: InstructionParameters {
        let rs1: RegisterName
        let rs2: RegisterName
        let imm: UInt32
    }

    public func decodeParameters(word: UInt32) throws -> Parameters {
        let rs1 = word.bits[InstructionRanges.rs1]
        let rs2 = word.bits[InstructionRanges.rs2]
        var imm: UInt32 = 0
        imm.bits[1 ... 4] = word.bits[8 ... 11]
        imm.bits[5 ... 10] = word.bits[25 ... 30]
        imm.bits[11 ... 11] = word.bits[7 ... 7]
        imm.bits[12 ... 31] = word.bits[12 ... 12] // THis all seems whack
        return Parameters(
            rs1: RegisterName(rawValue: rs1),
            rs2: RegisterName(rawValue: rs2),
            imm: imm
        )
    }

    public func assemble(parameters: ParameterReader) throws -> UInt32 {
        let rs1 = try parameters.register(at: 0)
        let rs2 = try parameters.register(at: 1)
        let imm = try parameters.integer(type: UInt32.self, at: 2)

        var word: UInt32 = 0
        word.bits[InstructionRanges.rs1] = rs1.index
        word.bits[InstructionRanges.rs2] = rs2.index
        word.bits[8 ... 11] = imm.bits[1 ... 4]
        word.bits[25 ... 30] = imm.bits[5 ... 10]
        word.bits[7 ... 7] = imm.bits[11 ... 11]
        word.bits[12 ... 12] = imm.bits[12 ... 31]
        return word
    }
}

extension BranchFormat.Parameters: CustomStringConvertible {
    public var description: String {
        "B(rs1: \(rs1), rs2: \(rs2), imm: \(signExtend(imm, bits: 12)))"
    }
}

// MARK: -

public struct JALFormat: InstructionFormat {
    public struct Parameters: InstructionParameters {
        let rd: RegisterName
        let imm: UInt32
    }

    public func decodeParameters(word: UInt32) throws -> Parameters {
        let rd = word.bits[InstructionRanges.rd]
        var imm: UInt32 = 0
        imm.bits[12 ... 19] = word.bits[12 ... 19]
        imm.bits[11 ... 11] = word.bits[20 ... 20]
        imm.bits[1 ... 10] = word.bits[21 ... 30]
        imm.bits[20 ... 20] = word.bits[31 ... 31]
        return Parameters(
            rd: RegisterName(rawValue: rd),
            imm: imm
        )
    }

    public func assemble(parameters: ParameterReader) throws -> UInt32 {
        let rd = try parameters.register(at: 0)
        let imm = UInt32(bitPattern: try parameters.integer(type: Int32.self, at: 1))

        var word: UInt32 = 0
        word.bits[InstructionRanges.rd] = rd.index
        word.bits[12 ... 19] = imm.bits[12 ... 19]
        word.bits[20 ... 20] = imm.bits[11 ... 11]
        word.bits[21 ... 30] = imm.bits[1 ... 10]
        word.bits[31 ... 31] = imm.bits[20 ... 20]
        return word
    }
}

extension JALFormat.Parameters: CustomStringConvertible {
    public var description: String {
        "J(rd: \(rd), imm: \(signExtend(imm, bits: 20)))"
    }
}

public struct SFormat: InstructionFormat {
    public struct Parameters: InstructionParameters {
        let rs1: RegisterName
        let rs2: RegisterName
        let imm: UInt32
    }

    public func decodeParameters(word: UInt32) throws -> Parameters {
        let rs1 = word.bits[InstructionRanges.rs1]
        let rs2 = word.bits[InstructionRanges.rs2]
        var imm: UInt32 = 0
        imm.bits[5 ... 11] = word.bits[25 ... 31]
        imm.bits[0 ... 4] = word.bits[7 ... 11]
        return Parameters(
            rs1: RegisterName(rawValue: rs1),
            rs2: RegisterName(rawValue: rs2),
            imm: imm
        )
    }

    public func assemble(parameters: ParameterReader) throws -> UInt32 {
        let rs1 = try parameters.register(at: 0)
        let rs2 = try parameters.register(at: 1)
        let imm = try parameters.integer(type: UInt32.self, at: 2)

        var word: UInt32 = 0
        word.bits[InstructionRanges.rs1] = rs1.index
        word.bits[InstructionRanges.rs2] = rs2.index
        word.bits[25 ... 31] = imm.bits[5 ... 11]
        word.bits[7 ... 11] = imm.bits[0 ... 4]
        return word
    }
}

// MARK: -

public struct UFormat: InstructionFormat {
    public struct Parameters: InstructionParameters {
        let rd: RegisterName
        let imm: UInt32
    }

    public func decodeParameters(word: UInt32) throws -> Parameters {
        let rd = word.bits[InstructionRanges.rd]
        var imm: UInt32 = 0
        imm.bits[12 ... 31] = word.bits[12 ... 31]
        return Parameters(
            rd: RegisterName(rawValue: rd),
            imm: imm
        )
    }

    public func assemble(parameters: ParameterReader) throws -> UInt32 {
        let rd = try parameters.register(at: 0)
        let imm = try parameters.integer(type: UInt32.self, at: 1)

        var word: UInt32 = 0
        word.bits[InstructionRanges.rd] = rd.index
        word.bits[12 ... 31] = imm.bits[12 ... 31]
        return word
    }
}
