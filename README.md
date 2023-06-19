# Swift-RISCV-Emulator

## What the heck is this?

It's a Swift RISCV Emulator!

![Alt text](<Documentation/Screenshot 2023-06-19 at 16.30.15.png>)
[Demo](<Documentation/Screen Recording 2023-06-19 at 16.30.09.mov>)

## Does it work?

"Sure"

## No really, does it work?

"Suure"

## How much of RISC-V does it emulate?

RV32I: 32-bit Integer Instructions. So not very much. And maybe not all of RV32I - I forgot (this code is kinda old)

## Is it "correct"?

Buggered if I know. I haven't tried comparing it to a real emulator. Let's go with no.

## Is it "fast"?

It's not what you would call fast. The SwiftUI gui slows it down quite a bit and running headless speeds it up considerably. But it's not fast regardless. I wrote the code to be instructional.

## What's it doing?

The sample project prints(*) "hello world" to the ECALL system call instruction. (* And by print, I mean not actually printing because ECALL isn't hooked up).

```asm
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
```

## Why?

Because I found RISCV interesting, and I wanted to play with it.

## Why are you releasing this?

Because it's kinda fun and it is rather old code I couldn't release it before because of employer restrictions. And someone might find it vaguely interesting/entertaining.

## Is there an assembler?

There is but it's not great. But it assemblies the hello world program. What more do you want?

## Are you going to do more with it?

Probably not. Hey, look! A squirrel!

## What license is this?

BSD 3-Clause License as god intended.

## Where can I find out more about RISCV?

Really?
