import Everything
import Foundation

public protocol Processor: AnyObject {
    var architecture: Architecture { get }
    var registers: RegisterBank { get set }
    var pc: Int32 { get set }
    var memory: Memory { get set }
    var instructionSet: InstructionSet { get }

    func step(delta: TimeInterval) throws

    var systemCall: () throws -> Void { get set }
    var systemBreak: () throws -> Void { get set }
}

public extension Processor {
    func dump() {
        print("pc: \(pc), registers: \(registers)")
    }

    func peek<T>(_ type: T.Type, address: Int32) throws -> T where T: UnsignedInteger {
        try memory.peek(type, address: address)
    }

    func poke<T>(address: Int32, value: T) throws where T: UnsignedInteger {
        try memory.poke(address: address, value: value)
    }
}

public class SimpleProcessor: Processor {
    public let architecture = Architecture()
    public var registers: RegisterBank
    public var pc: Int32 = 0
    public var memory = Memory(pageSize: 100)

    public let instructionSet: InstructionSet = RV32IInstructionSet()

    var count = 0

    var logging: Bool

    public required init(logging: Bool = true) {
        self.logging = logging
        registers = RegisterBank(architecture: architecture)
    }

    public func step(delta: TimeInterval) throws {
        let decodedInstruction = try fetch()
        try execute(decodedInstruction: decodedInstruction)
    }

    func fetch() throws -> AnyDecodedInstruction {
        let word = try peek(UInt32.self, address: pc)
        return try instructionSet.decode(word: word)
    }

    func execute(decodedInstruction: AnyDecodedInstruction) throws {
        if logging {
            print("\(count) / \(decodedInstruction) / \(registers)")
        }
        try decodedInstruction.execute(processor: self)
        count += 1
    }

    public var systemCall: () throws -> Void = {
    }

    public var systemBreak: () throws -> Void = {
    }
}

// class InstructionCachingProcessor: Processor {
//    let architecture = Architecture()
//    var registers = RegisterBank()
//    var pc: Int32 = 0
//    var memory: MemoryProtocol = Memory(pages: [])
//
//    let instructionSet: InstructionSet = RV32IInstructionSet()
//
//    required init() {
//    }
//
//    var instructionCache: [AnyDecodedInstruction?] = Array(repeating: nil, count: 64)
//
//    func step() throws {
//        var decodedInstruction = instructionCache[Int(pc / 2)]
//        if decodedInstruction == nil {
//            print("CACHE MISS")
//            let word = try peek(UInt32.self, address: pc)
//            decodedInstruction = try instructionSet.decode(word: word)
//            instructionCache[Int(pc / 2)] = decodedInstruction!
//        }
//        try decodedInstruction!.execute(processor: self)
//    }
//
//    var systemCall: () throws -> Void = {
//
//    }
//
//    var systemBreak: () throws -> Void = {
//
//    }
// }

public class ObservableProcessor: Processor, ObservableObject {
    public let architecture = Architecture()

    @Published
    public var registers: RegisterBank

    @Published
    public var pc: Int32 = 0

    @Published
    public var memory = Memory(pageSize: 100)

    public let instructionSet: InstructionSet = RV32IInstructionSet()

    public required init() {
        registers = RegisterBank(architecture: architecture)
    }

    public func step(delta: TimeInterval) throws {
        let word = try peek(UInt32.self, address: pc)
        let decodedInstruction = try instructionSet.decode(word: word)
        try decodedInstruction.execute(processor: self)
    }

    public var systemCall: () throws -> Void = {
    }

    public var systemBreak: () throws -> Void = {
    }
}

public extension Processor {
    func run() throws {
        while true {
            try step(delta: 0)
        }
    }
}
