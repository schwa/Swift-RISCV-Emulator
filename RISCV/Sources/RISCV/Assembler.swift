import Everything
import Foundation

public struct Assembler {
    public let architecture = Architecture()
    public let instructionSet: InstructionSet

    public init(instructionSet: InstructionSet) {
        self.instructionSet = instructionSet
    }

    public func assemble(string: String) throws -> Program {
        let bytes = try assemble_(string: string).rebind(to: UInt8.self)
        let program = Program(source: string, bytes: bytes, ranges: [])
        return program
    }

    private func assemble_(string: String) throws -> [UInt32] {
        let lines = string.components(separatedBy: .newlines)
        return try lines.compactMap(assemble(line:))
    }

    private func assemble(line string: String) throws -> UInt32? {
        var string = string
        if let index = string.firstIndex(of: ";") {
            string = String(string[..<index])
        }
        string = string.trimmingCharacters(in: .whitespaces)
        guard !string.isEmpty else {
            return nil
        }
        let parts = string.split(separator: " ", omittingEmptySubsequences: true)
        let mnemonic = parts[0]
        guard let instruction = instructionSet.instructions.first(where: { $0.mnemonic == mnemonic }) else {
            fatalError()
        }
        let format = instruction.format
        var word = instruction.opcode.rawValue
        switch instruction.locator {
        case .none:
            break
        case .funct3(let funct3):
            word.bits[InstructionRanges.funct3] = funct3
        case .funct3funct7(let funct3, let funct7):
            word.bits[InstructionRanges.funct3] = funct3
            word.bits[InstructionRanges.funct7] = funct7
        case .funct3funct12(let funct3, let funct12):
            word.bits[InstructionRanges.funct3] = funct3
            word.bits[InstructionRanges.funct12] = funct12
        }
        word |= try format.assemble(parameters: ParameterReader_(architecture: architecture, parameters: parts.dropFirst().map(String.init)))
        return word
    }

    @available(*, unavailable)
    func scan(source: String) -> Program {
//        let scanner = Scanner(string: source)
        fatalError()
    }

    func register(for name: String) -> RegisterName? {
        let register = architecture.registers.first(where: { [$0.name, $0.alias].contains(name) })
        return register
    }
}

public protocol ParameterReader {
    var count: Int { get }
    func register(at index: Int) throws -> RegisterName
    func integer<T>(type: T.Type, at index: Int) throws -> T where T: UnsignedInteger
    func integer<T>(type: T.Type, at index: Int) throws -> T where T: SignedInteger
}

extension ParameterReader {
    var isEmpty: Bool {
        // swiftlint:disable:next empty_count
        count == 0
    }
}

// swiftlint:disable:next type_name
struct ParameterReader_: ParameterReader {
    let architecture: Architecture
    let parameters: [String]

    var count: Int {
        parameters.count
    }

    func register(at index: Int) throws -> RegisterName {
        let name = parameters[index]
        let register = architecture.registers.first(where: { [$0.name, $0.alias].contains(name) })
        return register!
    }

    func integer<T>(type: T.Type, at index: Int) throws -> T where T: UnsignedInteger {
        let parameter = parameters[index]
        return T(UInt(parameter)!)
    }

    func integer<T>(type: T.Type, at index: Int) throws -> T where T: SignedInteger {
        let parameter = parameters[index]
        return T(Int(parameter)!)
    }
}

public struct Program {
    public let source: String
    public let bytes: [UInt8]
    public let ranges: [Range<String.Index>]
}

extension Program: MemoryPageStorageProtocol {
    public func peek<T>(_ type: T.Type, address: Int32) throws -> T where T: UnsignedInteger {
        if address >= bytes.count {
            return 0
        }

        return try bytes.peek(type, address: address)
    }

    public mutating func poke<T>(address: Int32, value: T) throws where T: UnsignedInteger {
        throw RISCVError.generic("Read only page")
    }
}
