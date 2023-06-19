import Everything
import Foundation

public enum Opcode: UInt32 {
    case imm = 0b0010011
    case lui = 0b0110111
    case auipc = 0b0010111
    case op = 0b0110011
    case jal = 0b1101111
    case jalr = 0b1100111
    case branch = 0b1100011
    case load = 0b0000011
    case store = 0b0100011
    case system = 0b1110011
}

// swiftlint:enable operator_usage_whitespace

public enum RISCVError: Error {
    case generic(String)
    case illegalInstruction(UInt32)
}

// TODO: Rename to ranges? Put inside RV32I
public enum InstructionRanges {
    static let opcode = 0 ... 6
    static let rd = 7 ... 11
    static let funct3 = 12 ... 14
    static let funct7 = 25 ... 31
    static let funct12 = 20 ... 31
    static let rs1 = 15 ... 19
    static let rs2 = 20 ... 24
    static let imm = 20 ... 31 // TODO: This is only correct for "I" type
}

public enum Locator {
    case none
    case funct3(UInt32)
    case funct3funct7(UInt32, UInt32)
    case funct3funct12(UInt32, UInt32)
}

// MARK: -

public protocol InstructionSet {
    var instructions: [AnyInstruction] { get }
}

public struct AnyDecodedInstruction {
    let instruction: AnyInstruction
    let parameters: AnyInstruction.Parameters

    func execute(processor: Processor) throws {
        try instruction.execute(processor: processor, parameters: parameters)
    }
}

extension AnyDecodedInstruction: CustomStringConvertible {
    public var description: String {
        "\(instruction.mnemonic) \(parameters)"
    }
}

public extension InstructionSet {
    func decode(word: UInt32) throws -> AnyDecodedInstruction {
        let instruction = try instructions.first { instruction in
            try match(word: word, instruction: instruction)
        }
        let parameters = try instruction!.format.decodeParameters(word: word)
        if instruction == nil {
            throw RISCVError.generic("Could not decode word \(word)")
        }
        return AnyDecodedInstruction(instruction: instruction!, parameters: parameters)
    }

    func match(word: UInt32, instruction: AnyInstruction) throws -> Bool {
        guard word != 0 else {
            throw RISCVError.illegalInstruction(word)
        }

        guard let opcode = Opcode(rawValue: word.bits[InstructionRanges.opcode]) else {
            throw RISCVError.generic("Not an opcode: \(word.bits[InstructionRanges.opcode]))")
        }
        guard instruction.opcode == opcode else {
            return false
        }
        switch instruction.locator {
        case .none:
            break
        case .funct3(let funct3):
            guard word.bits[InstructionRanges.funct3] == funct3 else {
                return false
            }
        case .funct3funct7(let funct3, let funct7):
            guard word.bits[InstructionRanges.funct3] == funct3 else {
                return false
            }
            guard word.bits[InstructionRanges.funct7] == funct7 else {
                return false
            }
        case .funct3funct12(let funct3, let funct12):
            guard word.bits[InstructionRanges.funct3] == funct3 else {
                return false
            }
            guard word.bits[InstructionRanges.funct12] == funct12 else {
                return false
            }
        }
        return true
    }
}

// MARK: -

public protocol InstructionParameters {
}

public extension InstructionParameters {
    var instructionSize: Int32 {
        4
    }
}

public struct AnyInstructionParameters: InstructionParameters {
    let other: Any

    let _description: () -> String

    init<T>(_ other: T) where T: InstructionParameters {
        self.other = other
        _description = { String(describing: other) }
    }
}

extension AnyInstructionParameters: CustomStringConvertible {
    public var description: String {
        _description()
    }
}

public extension InstructionParameters {
    func any() -> AnyInstructionParameters {
        AnyInstructionParameters(self)
    }
}

// MARK: -

public protocol InstructionFormat {
    associatedtype Parameters: InstructionParameters

    func decodeParameters(word: UInt32) throws -> Parameters

    func assemble(parameters: ParameterReader) throws -> UInt32
}

// MARK: -

public struct AnyInstructionFormat: InstructionFormat {
    public typealias Parameters = AnyInstructionParameters

    let _decode: (UInt32) throws -> Parameters
    let _assemble: (ParameterReader) throws -> UInt32

    init<T>(_ other: T) where T: InstructionFormat {
        _decode = { word in
            try other.decodeParameters(word: word).any()
        }
        _assemble = { parameters in
            try other.assemble(parameters: parameters)
        }
    }

    public func decodeParameters(word: UInt32) throws -> Parameters {
        try _decode(word)
    }

    public func assemble(parameters: ParameterReader) throws -> UInt32 {
        try _assemble(parameters)
    }
}

// MARK: -

public protocol InstructionProtocol {
    associatedtype Format: InstructionFormat
    typealias Parameters = Format.Parameters

    var mnemonic: String { get }
    var format: Format { get }
    var opcode: Opcode { get }
    var locator: Locator { get }

    func execute(processor: Processor, parameters: Parameters) throws
}

public struct Instruction<Format>: InstructionProtocol where Format: InstructionFormat {
    public typealias Parameters = Format.Parameters

    public let mnemonic: String
    public let format: Format
    public let opcode: Opcode
    public let locator: Locator
    public let closure: (Processor, Parameters) throws -> Void

    public func execute(processor: Processor, parameters: Parameters) throws {
        try closure(processor, parameters)
    }
}

public struct AnyInstruction: InstructionProtocol {
    public typealias Format = AnyInstructionFormat

    public let mnemonic: String
    public let format: Format
    public let opcode: Opcode
    public let locator: Locator
    private let _execute: (Processor, Parameters) throws -> Void

    init<T>(_ other: T) where T: InstructionProtocol {
        mnemonic = other.mnemonic
        format = AnyInstructionFormat(other.format)
        opcode = other.opcode
        locator = other.locator
        _execute = { processor, parameters in
            // swiftlint:disable:next force_cast
            let parameters = parameters.other as! T.Parameters
            try other.execute(processor: processor, parameters: parameters)
        }
    }

    public func execute(processor: Processor, parameters: Parameters) throws {
        try _execute(processor, parameters)
    }
}

public extension InstructionProtocol {
    func any() -> AnyInstruction {
        AnyInstruction(self)
    }
}
