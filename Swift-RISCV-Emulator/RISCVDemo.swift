import Everything
import RISCV
import SwiftSimulation
import SwiftUI

extension ObservableProcessor: SimulationProtocol {
}

public struct RISCVDemo: View {
    @StateObject
    // swiftlint:disable:next force_cast
    var simulator = Simulator(simulation: try! helloWorld(processor: ObservableProcessor()) as! ObservableProcessor, start: true)

    public init() {
    }

    public var body: some View {
        RISCVProcessorView()
            .environment(\.wordFormatter, IntegerStringFormatter(radix: 16, prefix: .standard, leadingZeros: true, groupCount: 8, groupSeparator: " ", uppercase: true))
            .environmentObject(simulator.simulation)
    }
}

struct RISCVProcessorView: View {
    @EnvironmentObject
    var processor: ObservableProcessor

    @State
    var links: [AddressGeometryPreferenceKey.Element: CGPoint] = [:]

    static let coordinateSpace = "coordinate-space"

    var body: some View {
        let bank = processor.registers
        let registers = bank.registers

        let colors = addressColors(processor: processor as Processor)

        return HStack {
            VStack {
                RegisterView(name: "PC", value: UInt32(self.processor.pc))
                    .saveToAddressGeometry(kind: .register, register: self.processor.pc)
                    .fixedSize()
                RegistersView(registers: registers)
//                Button("Step") {
//                    try! self.processor.step(delta: 0)
//                }
            }
            MemoryView(memory: processor.memory)
        }
        .coordinateSpace(name: RISCVProcessorView.coordinateSpace)
        .background(LinksView(links: links))
        .environment(\.coloredAddresses, colors)
        .onPreferenceChange(AddressGeometryPreferenceKey.self) { elements in
            self.links = elements
        }
    }
}

struct LinksView: View {
    let links: [AddressGeometryPreferenceKey.Element: CGPoint]

    @Environment(\.coloredAddresses)
    var coloredAddresses: [Int32: Color]

    var body: some View {
        var lines: [(CGPoint, CGPoint, Color)] = []
        let registers = Dictionary(uniqueKeysWithValues: links.filter { $0.key.kind == .register }.map { key, value in (key.address, value) })
        for (address, position) in links.filter({ $0.key.kind == .address }) {
            guard let registerPosition = registers[address.address] else {
                continue
            }
            let color = (coloredAddresses[address.address] ?? Color.black)
            lines.append((position, registerPosition, color))
        }
        return LinesView(lines: lines).opacity(0.4)
    }
}

struct LinesView: View {
    let lines: [(CGPoint, CGPoint, Color)]

    var body: some View {
        ZStack {
            ForEach(self.lines.indices, id: \.self, content: self.line)
        }
    }

    func line(for index: Int) -> some View {
        let (start, end, color) = lines[index]
        return Path { path in
            path.addSCurve(from: start, to: end)
        }.stroke(color, lineWidth: 4)
    }
}

struct RegistersView: View {
    let registers: [Register]

    var body: some View {
        VStack {
            ForEach(self.registers, id: \.id) { register in
                self.registerView(register: register)
            }
        }
    }

    func registerView(register: Register) -> some View {
        RegisterView(register: register)
            .saveToAddressGeometry(kind: .register, register: Int32(register.rawValue))
            .fixedSize()
    }
}

struct RegisterView: View {
    let name: String
    let value: UInt32

    @Environment(\.coloredAddresses)
    var coloredAddresses: [Int32: Color]

    var body: some View {
        let title = Text(name)
        return HStack {
            title
            AddressView(address: Int32(value))
        }
    }
}

extension RegisterView {
    init(register: Register) {
        name = register.name.name
        value = register.rawValue
    }
}

struct MemoryView: View {
    let memory: Memory

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(memory.pages.indices, id: \.self) { (index: Int) -> MemoryPageMultiplexerView in
                let page = self.memory.pages[index]
                return MemoryPageMultiplexerView(page: page)
            }
        }
    }
}

struct MemoryPageMultiplexerView: View {
    let page: MemoryPageRecord

    var body: some View {
        HStack(alignment: .top) {
            AddressView(address: page.range.startIndex)
            switch page.storage {
            case _ as GuardPageStorage:
                Text("Guard page")
            case _ as ZeroPageStorage:
                Text("Zero page")
            default:
                RawMemoryPageView(page: page)
            }
        }
    }
}

struct RawMemoryPageView: View {
    var page: MemoryPageRecord

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 16)) {
            ForEach(page.range, id: \.self) { address in
                AddressPeekView(page: page, address: address)
                    .saveToAddressGeometry(kind: .address, register: address)
                    .fixedSize()
            }
        }
    }

    func byteView(address: Int32) -> some View {
        AddressPeekView(page: page, address: address)
            .saveToAddressGeometry(kind: .address, register: address)
            .fixedSize()
    }
}

struct AddressView: View {
    let address: Int32

    @Environment(\.coloredAddresses)
    var coloredAddresses: [Int32: Color]

    @Environment(\.wordFormatter)
    var formatter: IntegerStringFormatter?

    var body: some View {
        let formattedAddress = formatter.map { $0.format(address) } ?? String(address)
        let backgroundColor = coloredAddresses[address] ?? Color.clear
        let foregroundColor = coloredAddresses[address] == nil ? Color.black : Color.white
        return Text(formattedAddress)
            .font(.body.monospaced())
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .fixedSize()
    }
}

struct AddressPeekView: View {
    let page: MemoryPageRecord
    let address: Int32

    @Environment(\.coloredAddresses)
    var coloredAddresses: [Int32: Color]

    var body: some View {
        let value: UInt8
        if page.contains(address: address) {
            value = try! page.peek(UInt8.self, address: address)
        }
        else {
            value = 255
        }

        let formattedValue = value.format(radix: 16, prefix: .none, leadingZeros: true, uppercase: true)

        let backgroundColor = coloredAddresses[address] ?? Color.clear
        let foregroundColor = coloredAddresses[address] == nil ? Color.black : Color.white

        return Text(formattedValue)
            .font(.body.monospaced())
            .fixedSize()
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
    }
}

// MARK: -

struct AddressGeometryPreferenceKey: PreferenceKey {
    struct Element: Equatable, Hashable {
        enum Kind {
            case register
            case address
        }

        let kind: Kind
        let address: Int32
    }

    typealias Value = [Element: CGPoint]

    static var defaultValue: Value = [:]

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    func saveToAddressGeometry(kind: AddressGeometryPreferenceKey.Element.Kind, register: Int32) -> some View {
        overlay {
            GeometryReader { proxy in
                preference(key: AddressGeometryPreferenceKey.self, value: [
                    .init(kind: kind, address: register): proxy.frame(in: .named(RISCVProcessorView.coordinateSpace)).midXMidY,
                ])
            }
        }
    }
}

// MARK: -

struct ColoredAddressesEnvironmentKey: EnvironmentKey {
    static let defaultValue: [Int32: Color] = [:]
}

extension EnvironmentValues {
    var coloredAddresses: [Int32: Color] {
        get {
            return self[ColoredAddressesEnvironmentKey.self]
        }
        set {
            self[ColoredAddressesEnvironmentKey.self] = newValue
        }
    }
}

// MARK: -

struct WordFormatterEnvironmentKey: EnvironmentKey {
    static let defaultValue: IntegerStringFormatter? = nil
}

extension EnvironmentValues {
    var wordFormatter: IntegerStringFormatter? {
        get {
            return self[WordFormatterEnvironmentKey.self]
        }
        set {
            self[WordFormatterEnvironmentKey.self] = newValue
        }
    }
}

// MARK: -

func addressColors(processor: Processor) -> [Int32: Color] {
    var palette: [Color] = [
        .red,
        .green,
        .blue,
        .purple,
    ].reversed()

    var colors: [Int32: Color] = [:]
    colors[processor.pc] = palette.popLast()

    for register in processor.registers.registers {
        let value = Int32(register.rawValue)

        if colors[value] == nil {
            colors[value] = palette.popLast()
        }
    }
    return colors
}
