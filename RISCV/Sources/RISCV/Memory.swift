import Foundation

public class Memory {
    public let pageSize: Int32
    public private(set) var pages: [MemoryPageRecord]

    public init(pageSize: Int32) {
        self.pageSize = pageSize
        pages = []
    }

    public func peek<T>(_ type: T.Type, address: Int32) throws -> T where T: UnsignedInteger {
        let pageIndex = Int(address / pageSize)
        return try pages[pageIndex].peek(type, address: address)
    }

    public func poke<T>(address: Int32, value: T) throws where T: UnsignedInteger {
        let pageIndex = Int(address / pageSize)
        try pages[pageIndex].poke(address: address, value: value)
    }

    public func insert(pageStorage: MemoryPageStorageProtocol) {
        let start = pages.last?.range.endIndex ?? 0
        let range = start ..< (start + pageSize)

        let record = MemoryPageRecord(range: range, options: [], storage: pageStorage)
        pages.append(record)
    }
}

extension Memory: CustomStringConvertible {
    public var description: String {
        "\(type(of: self))(pageSize: \(pageSize), pages: \(pages))"
    }
}

// MARK: -

public struct MemoryPageRecord {
    public struct Options: OptionSet {
        public let rawValue: UInt32

        static let readable = Options(rawValue: 1 << 0)
        static let writable = Options(rawValue: 1 << 1)

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
    }

    public let range: Range<Int32>
    public let options: Options
    public private(set) var storage: MemoryPageStorageProtocol

    public init(range: Range<Int32>, options: Options, storage: MemoryPageStorageProtocol) {
        self.range = range
        self.options = options
        self.storage = storage
    }

    public func peek<T>(_ type: T.Type, address: Int32) throws -> T where T: UnsignedInteger {
        guard range.contains(address) else {
            throw RISCVError.generic("Peek out of bounds \(address)")
        }

        let pageRelativeAddress = address - range.lowerBound
        return try storage.peek(type, address: pageRelativeAddress)
    }

    public mutating func poke<T>(address: Int32, value: T) throws where T: UnsignedInteger {
        guard range.contains(address) else {
            throw RISCVError.generic("Peek out of bounds \(address)")
        }
        let pageRelativeAddress = address - range.lowerBound
        try storage.poke(address: pageRelativeAddress, value: value)
    }

    public func contains(address: Int32) -> Bool {
//        let pageRelativeAddress = address - range.lowerBound
//        return range.contains(pageRelativeAddress)
        range.contains(address)
    }
}

extension MemoryPageRecord: CustomStringConvertible {
    public var description: String {
        "\(type(of: self))(range: \(range), options: \(options), storage: \(storage))"
    }
}

// MARK: -

public protocol MemoryPageStorageProtocol {
    func peek<T>(_ type: T.Type, address: Int32) throws -> T where T: UnsignedInteger
    mutating func poke<T>(address: Int32, value: T) throws where T: UnsignedInteger
}

// MARK: -

public struct GuardPageStorage: MemoryPageStorageProtocol {
    // swiftlint:disable:next unavailable_function
    public func peek<T>(_ type: T.Type, address: Int32) throws -> T where T: UnsignedInteger {
        fatalError("Attempt to read from guard page")
    }

    // swiftlint:disable:next unavailable_function
    public mutating func poke<T>(address: Int32, value: T) throws where T: UnsignedInteger {
        fatalError("Attempt to write to guard page")
    }

    public init() {
    }
}

extension GuardPageStorage: CustomStringConvertible {
    public var description: String {
        "\(type(of: self))()"
    }
}

public struct ZeroPageStorage: MemoryPageStorageProtocol {
    public func peek<T>(_ type: T.Type, address: Int32) throws -> T where T: UnsignedInteger {
        0
    }

    public mutating func poke<T>(address: Int32, value: T) throws where T: UnsignedInteger {
    }

    public init() {
    }
}

extension ZeroPageStorage: CustomStringConvertible {
    public var description: String {
        "\(type(of: self))()"
    }
}

extension Array: MemoryPageStorageProtocol where Element == UInt8 {
    public func peek<T>(_ type: T.Type, address: Int32) throws -> T where T: UnsignedInteger {
        guard address >= 0 && address <= (count - MemoryLayout<T>.size) else {
            return 0
        }
        return withUnsafeBytes { buffer in
            let pointer = buffer.baseAddress!.advanced(by: Int(address)).assumingMemoryBound(to: T.self)
            return pointer.pointee
        }
    }

    public mutating func poke<T>(address: Int32, value: T) throws where T: UnsignedInteger {
        guard address >= 0 && address <= (count - MemoryLayout<T>.size) else {
            throw RISCVError.generic("Poke out of bounds")
        }
        return withUnsafeMutableBytes { buffer in
            let pointer = buffer.baseAddress!.advanced(by: Int(address)).assumingMemoryBound(to: T.self)
            pointer.pointee = value
        }
    }
}
