/*****************************************************************************
** disasmtrace.h - lightweight, opt-in execution/memory tracer.
**
** Purpose: aid disassembly-driven reverse-engineering of MSX ROMs by writing a
** log of executed addresses and memory writes, each tagged with the ROM segment
** currently paged in, so the log lines up 1:1 with a segment disassembly.
**
** The execution trace and the memory-write watch are mapper-independent and
** work for any cartridge.  Segment tagging is accurate for mappers that report
** their bank state via disasmTraceBank(); the Konami4 mapper does so today, and
** other mappers can add the same one-line call.  Without a report, the segment
** falls back to each page's initial mapping.
**
** Compiled in ONLY when the project is built with -DDISASMTRACE, and even then
** it does nothing until the DISASM_TRACE environment variable is set, so normal
** builds and runs are completely unaffected.
**
** Runtime configuration (environment variables, read once, lazily):
**   DISASM_TRACE   master switch: set to 1 to enable tracing.
**   DISASM_LOG     output file path (default "/tmp/disasmtrace.log").
**   DISASM_EXEC    comma-separated CPU-address ranges whose executed opcodes are
**                  logged, e.g. "6000-7fff" or "4000-bfff,c000-c0ff". Empty=off.
**   DISASM_WATCH   comma-separated target-address ranges for memory writes,
**                  e.g. "c000-c7ff,d000-d00f". Logs writer PC + addr + value.
**   DISASM_DEDUP   "1" (default) collapses runs of the same executed PC.
**
** Log format (all addresses hex):
**   X ss:pppp            executed opcode at segment ss, CPU addr pppp
**   W ss:pppp aaaa=vv    code at ss:pppp wrote value vv to address aaaa
**   B page=n seg=ss      mapper paged segment ss into page n (0..3)
******************************************************************************/
#ifndef DISASMTRACE_H
#define DISASMTRACE_H

#include "MsxTypes.h"

#ifdef DISASMTRACE

/* Record that ROM segment `seg` is now mapped into mapper bank `page` (0..3,
   where 0=0x4000, 1=0x6000, 2=0x8000, 3=0xA000). */
void disasmTraceBank(int page, int seg);

/* Hook at instruction fetch: `pc` is the CPU address of the opcode. */
void disasmTraceExec(UInt16 pc);

/* Hook at memory write: `pc` is the writer's CPU address. */
void disasmTraceWrite(UInt16 pc, UInt16 addr, UInt8 value);

#else /* !DISASMTRACE : compile to nothing */

#define disasmTraceBank(page, seg)        ((void)0)
#define disasmTraceExec(pc)               ((void)0)
#define disasmTraceWrite(pc, addr, value) ((void)0)

#endif /* DISASMTRACE */

#endif /* DISASMTRACE_H */
