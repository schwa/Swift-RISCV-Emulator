import Combine
import Everything
import Foundation

// func run(processor: Processor = SimpleProcessor(), program: String, limit: Int = .max, setup: ((Processor) -> Void)? = nil) throws {
//    let assembler = Assembler(instructionSet: RV32IInstructionSet())
//    let words = try assembler.assemble_(string: program)
//    let program = words.rebind(to: UInt8.self)
//
//    processor.memory.pages = [program]
//
//    setup?(processor)
//    let start = CFAbsoluteTimeGetCurrent()
//
//    var someError: Error?
//    var count = 0
//    while true {
//        do {
//            try processor.step()
//            count += 1
//            if count >= limit {
//                break
//            }
//        }
//        catch {
//            someError = error
//            break
//        }
//    }
//
//    let end = CFAbsoluteTimeGetCurrent()
//    print(end - start)
//    print(someError as Any)
//
//    processor.dump()
//
//    print(Double(count) / (end - start), "per second")
//
// }

// MARK: -

// func count() {
//
//    try! run(processor: SimpleProcessor(), program: """
//    ADDI x1 x1 1
//    BEQ x1 x2 4
//    JAL x0 -4
//    """) { processor in
//        processor.registers[.x2] = 10
//    }
// }

public func helloWorld(processor: Processor = SimpleProcessor(logging: true)) throws -> Processor {
    let pageSize = processor.memory.pageSize

    let codeAddress = pageSize * 1
    let globalsAddress = pageSize * 2
//    assert(pageSize <= 1024)

    let program = """
    LUI x1 \(globalsAddress)     ; load address of "hello world" into x1 upper
    ADDI x1 x1 \(globalsAddress) ; load address of "hello world" into x1 lower
                                 ; start of loop
    LBU x2 x1 0                  ; load byte at address x1
    BEQ x2 x0 8                  ; exit loop if x2 is nil byte
    ECALL                        ; system call
    ADDI x1 x1 1                 ; increment x1
    JAL x0 -8                    ; jump to start of loop
    JAL x0 -14                   ; jump to start
    ;JALR x0 x0 0                ; Force an illegal instruction to bail
    """

    let assembler = Assembler(instructionSet: RV32IInstructionSet())

    let codePage = try assembler.assemble(string: program)
    let globalsPage = Array("hello world\0".utf8)

    processor.memory.insert(pageStorage: ZeroPageStorage())
    processor.memory.insert(pageStorage: codePage)
    processor.memory.insert(pageStorage: globalsPage)
    processor.memory.insert(pageStorage: GuardPageStorage())

    processor.pc = codeAddress
    return processor
}

public func helloWorld1() throws {
    let processor = try helloWorld()
    processor.systemCall = {
        let x2 = UInt8(processor.registers.x2)
        print("\(UnicodeScalar(x2)), (\(x2.hexString))")
    }

    do {
        try processor.run()
    }
    catch {
        error.log()
    }

    processor.dump()
}

// func helloWorld2() {
//    let program = """
//        .global s "Hello World\0"
//        # store absolute address of string into x1
//        ADDI x1 x0 $s
//        LUI x1 string
//        loop:
//            # load byte at x1 into x2
//            LB x2 x1 0
//            # print character at x2
//            ECALL
//            # jump to loop if x2 is not zero
//            BNE x2 x0 loop
//
//        # jump to address 0
//        JALR x0 x0 0
//    """
//
//
// }
