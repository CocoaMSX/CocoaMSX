/*****************************************************************************
** disasmtrace.c - see disasmtrace.h.  Opt-in (-DDISASMTRACE) execution/memory
** tracer that tags events with the currently-paged ROM segment.
******************************************************************************/
#include "disasmtrace.h"

#ifdef DISASMTRACE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define DT_MAX_RANGES 16

typedef struct { UInt16 lo, hi; } DtRange;

static int      dt_ready   = 0;   /* config parsed yet?          */
static int      dt_on      = 0;   /* master enable (DISASM_TRACE)*/
static int      dt_dedup   = 1;
static FILE*    dt_log     = NULL;

static DtRange  dt_exec[DT_MAX_RANGES];  static int dt_execN  = 0;
static DtRange  dt_watch[DT_MAX_RANGES]; static int dt_watchN = 0;

/* segment currently in each mapper bank: [0]=0x4000 [1]=0x6000 [2]=0x8000
   [3]=0xA000.  Defaults to the linear 0,1,2,3 mapping until a mapper reports. */
static int      dt_bank[4] = { 0, 1, 2, 3 };

static UInt16   dt_lastPc  = 0xffff;
static int      dt_lastValid = 0;

/* Parse "lo-hi,lo-hi,..." (hex) into `out`; returns the count. */
static int dtParseRanges(const char* s, DtRange* out, int max)
{
    int n = 0;
    if (s == NULL) return 0;
    while (*s && n < max) {
        unsigned lo = 0, hi = 0;
        if (sscanf(s, "%x-%x", &lo, &hi) == 2) {
            out[n].lo = (UInt16)lo; out[n].hi = (UInt16)hi; n++;
        } else if (sscanf(s, "%x", &lo) == 1) {
            out[n].lo = out[n].hi = (UInt16)lo; n++;
        }
        while (*s && *s != ',') s++;
        if (*s == ',') s++;
    }
    return n;
}

static int dtInRanges(UInt16 a, const DtRange* r, int n)
{
    int i;
    for (i = 0; i < n; i++) {
        if (a >= r[i].lo && a <= r[i].hi) return 1;
    }
    return 0;
}

static void dtInit(void)
{
    const char* env;
    dt_ready = 1;

    env = getenv("DISASM_TRACE");
    if (env == NULL || env[0] == '0' || env[0] == '\0') { dt_on = 0; return; }
    dt_on = 1;

    env = getenv("DISASM_DEDUP");
    dt_dedup = (env == NULL || env[0] != '0');

    dt_execN  = dtParseRanges(getenv("DISASM_EXEC"),  dt_exec,  DT_MAX_RANGES);
    dt_watchN = dtParseRanges(getenv("DISASM_WATCH"), dt_watch, DT_MAX_RANGES);

    env = getenv("DISASM_LOG");
    dt_log = fopen(env && env[0] ? env : "/tmp/disasmtrace.log", "w");
    if (dt_log == NULL) { dt_on = 0; return; }
    setvbuf(dt_log, NULL, _IOLBF, 0);   /* line-buffered: readable live */

    fprintf(dt_log, "# disasmtrace: exec ranges=%d watch ranges=%d dedup=%d\n",
            dt_execN, dt_watchN, dt_dedup);
}

/* Segment mapped at CPU address `pc`; -1 for RAM/BIOS (outside 0x4000-0xBFFF). */
static int dtSegOf(UInt16 pc)
{
    if (pc < 0x4000 || pc >= 0xc000) return -1;
    return dt_bank[(pc - 0x4000) >> 13];
}

void disasmTraceBank(int page, int seg)
{
    if (!dt_ready) dtInit();
    if (page >= 0 && page < 4) dt_bank[page] = seg;
    if (!dt_on) return;
    fprintf(dt_log, "B page=%d seg=%02x\n", page, seg & 0xff);
}

void disasmTraceExec(UInt16 pc)
{
    int seg;
    if (!dt_ready) dtInit();
    if (!dt_on || dt_execN == 0) return;
    if (!dtInRanges(pc, dt_exec, dt_execN)) return;
    if (dt_dedup && dt_lastValid && pc == dt_lastPc) return;
    dt_lastPc = pc; dt_lastValid = 1;

    seg = dtSegOf(pc);
    if (seg < 0) fprintf(dt_log, "X --:%04x\n", pc);
    else         fprintf(dt_log, "X %02x:%04x\n", seg & 0xff, pc);
}

void disasmTraceWrite(UInt16 pc, UInt16 addr, UInt8 value)
{
    int seg;
    if (!dt_ready) dtInit();
    if (!dt_on || dt_watchN == 0) return;
    if (!dtInRanges(addr, dt_watch, dt_watchN)) return;

    seg = dtSegOf(pc);
    if (seg < 0) fprintf(dt_log, "W --:%04x %04x=%02x\n", pc, addr, value);
    else         fprintf(dt_log, "W %02x:%04x %04x=%02x\n", seg & 0xff, pc, addr, value);
}

#endif /* DISASMTRACE */
