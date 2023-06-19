import Foundation

public struct Architecture {
    let xlen: UInt32 = 32

    let registers: [RegisterName]

    init() {
        registers = (0 ..< xlen).map { RegisterName(rawValue: $0) }
    }
}

public struct RegisterName: RawRepresentable {
    public let rawValue: UInt32
    public let alias: String = ""

    public var index: UInt32 {
        rawValue
    }

    public var name: String {
        "x\(rawValue)"
    }

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: UInt32) throws {
        self.rawValue = rawValue
    }

    public static let x0 = RegisterName(rawValue: 0)
    public static let x1 = RegisterName(rawValue: 1)
    public static let x2 = RegisterName(rawValue: 2)
}

extension RegisterName: CustomStringConvertible {
    public var description: String {
        "x\(rawValue)"
    }
}

public struct Register: Identifiable {
    public var id: String {
        name.name
    }

    public let name: RegisterName
    let zero: Bool

    var _rawValue: UInt32 = 0

    // TODO: Replace with PropertyDelegate
    public var rawValue: UInt32 {
        get {
            !zero ? _rawValue : 0
        }
        set {
            _rawValue = !zero ? newValue : 0
        }
    }
}

public class RegisterBank {
    public var registers: [Register]

    public init(architecture: Architecture) {
        registers = architecture.registers.map { Register(name: $0, zero: false) }
    }

    public subscript(register: RegisterName) -> UInt32 {
        get {
            registers[Int(register.rawValue)].rawValue
        }
        set {
            let index = Int(register.rawValue)
            guard index != 0 else {
                return
            }
            registers[index].rawValue = newValue
        }
    }
}

public extension RegisterBank {
    var x2: UInt32 {
        self[.x2]
    }
}

extension RegisterBank: CustomStringConvertible {
    public var description: String {
        registers.map {
            ($0.rawValue & 0x8000_0000 != 0) ? $0.rawValue.hexString : String($0.rawValue)
        }
        .joined(separator: " ")
    }
}
