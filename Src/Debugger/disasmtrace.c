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

/* --- snapshot state (independent of the master trace switch) --------------- */
int             disasmTraceSnapPending = 0;
static FILE*    dt_snapFile = NULL;
static int      dt_snapInit = 0;
static int      dt_snapSeq  = 0;
static UInt16   dt_snapLo   = 0xc000;
static UInt16   dt_snapHi   = 0xdfff;

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

/* Lazily open the snapshot file and parse its RAM window. Independent of the
   DISASM_TRACE master switch so snapshots work even with tracing off. */
static void dtSnapSetup(void)
{
    const char* env;
    unsigned lo, hi;
    dt_snapInit = 1;

    env = getenv("DISASM_SNAP_RANGE");
    if (env != NULL && sscanf(env, "%x-%x", &lo, &hi) == 2 && hi >= lo) {
        dt_snapLo = (UInt16)lo;
        dt_snapHi = (UInt16)hi;
    }
    env = getenv("DISASM_SNAP");
    dt_snapFile = fopen(env && env[0] ? env : "/tmp/disasmsnap.bin", "wb");
}

void disasmTraceRequestSnapshot(void)
{
    disasmTraceSnapPending = 1;
}

/* --- auto-snapshot (F8): periodic capture, one every dt_autoDiv frames ------ */
static int dt_autoSnap = 0;
static int dt_autoDiv  = 1;
static int dt_autoCnt  = 0;

void disasmTraceToggleAutoSnap(void)
{
    dt_autoSnap = !dt_autoSnap;
    if (dt_autoSnap) {
        const char* env = getenv("DISASM_SNAP_EVERY");
        int n = env ? atoi(env) : 0;
        dt_autoDiv = n > 0 ? n : 1;
        dt_autoCnt = 0;
    }
    fprintf(stderr, "[disasmtrace] auto-snapshot %s (every %d frame(s))\n",
            dt_autoSnap ? "ON" : "OFF", dt_autoDiv);
}

int disasmTraceAutoSnapActive(void)
{
    return dt_autoSnap;
}

void disasmTraceAutoSnapTick(void)
{
    if (!dt_autoSnap) return;
    if (++dt_autoCnt >= dt_autoDiv) {
        dt_autoCnt = 0;
        disasmTraceSnapPending = 1;   /* taken at the next opcode fetch */
    }
}

void disasmTraceDoSnapshot(void* ref, DisasmReadFn rd)
{
    UInt32 addr;
    UInt16 len;

    disasmTraceSnapPending = 0;
    if (!dt_snapInit) dtSnapSetup();
    if (dt_snapFile == NULL || rd == NULL) return;

    len = (UInt16)(dt_snapHi - dt_snapLo + 1);

    /* record header: 'S', seq(u32 LE), base(u16 LE), len(u16 LE) */
    fputc('S', dt_snapFile);
    fputc( dt_snapSeq        & 0xff, dt_snapFile);
    fputc((dt_snapSeq >> 8)  & 0xff, dt_snapFile);
    fputc((dt_snapSeq >> 16) & 0xff, dt_snapFile);
    fputc((dt_snapSeq >> 24) & 0xff, dt_snapFile);
    fputc( dt_snapLo & 0xff, dt_snapFile);
    fputc((dt_snapLo >> 8) & 0xff, dt_snapFile);
    fputc( len & 0xff, dt_snapFile);
    fputc((len >> 8) & 0xff, dt_snapFile);

    for (addr = dt_snapLo; addr <= dt_snapHi; addr++)
        fputc(rd(ref, (UInt16)addr), dt_snapFile);

    fflush(dt_snapFile);
    if (dt_log)
        fprintf(dt_log, "# snapshot %d: %04x-%04x (%u bytes)\n",
                dt_snapSeq, dt_snapLo, dt_snapHi, (unsigned)len);
    fprintf(stderr, "[disasmtrace] snapshot %d captured (%04x-%04x)\n",
            dt_snapSeq, dt_snapLo, dt_snapHi);
    dt_snapSeq++;
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
