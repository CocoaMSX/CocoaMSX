#ifndef __FMOPL_H_
#define __FMOPL_H_

#include "MsxTypes.h"

/* for MSX-AUDIO specifics */
#define MSX_AUDIO

/* --- system optimize --- */
/* select bit size of output : 8 or 16 */
#define OPL_OUTPUT_BIT 16

/* compiler dependence */
#ifndef OSD_CPU_H
#define OSD_CPU_H
typedef unsigned char	UINT8;   /* unsigned  8bit */
typedef unsigned short	UINT16;  /* unsigned 16bit */
typedef unsigned int	UINT32;  /* unsigned 32bit */
typedef signed char		INT8;    /* signed  8bit   */
typedef signed short	INT16;   /* signed 16bit   */
typedef signed int		INT32;   /* signed 32bit   */
#endif

#if (OPL_OUTPUT_BIT==16)
typedef INT16 OPLSAMPLE;
#endif
#if (OPL_OUTPUT_BIT==8)
typedef unsigned char  OPLSAMPLE;
#endif

#include "Ymdeltat.h"

/* !!!!! here is private section , do not access there member direct !!!!! */

#define OPL_TYPE_WAVESEL   0x01  /* waveform select    */
#define OPL_TYPE_ADPCM     0x02  /* DELTA-T ADPCM unit */
#define OPL_TYPE_KEYBOARD  0x04  /* keyboard interface */
#define OPL_TYPE_IO        0x08  /* I/O port */

/* ---------- OPL one of slot  ---------- */
typedef struct fm_opl_slot {
	INT32 TL;		/* total level     :TL << 8            */
	INT32 TLL;		/* adjusted now TL                     */
	UINT8  KSR;		/* key scale rate  :(shift down bit)   */
	INT32 AR;		/* attack rate     :&AR_TABLE[AR<<2]   */
	INT32 DR;		/* decay rate      :&DR_TALBE[DR<<2]   */
	INT32 SL;		/* sustin level    :SL_TALBE[SL]       */
	INT32 RR;		/* release rate    :&DR_TABLE[RR<<2]   */
	UINT8 ksl;		/* keyscale level  :(shift down bits)  */
	UINT8 ksr;		/* key scale rate  :kcode>>KSR         */
	UINT32 mul;		/* multiple        :ML_TABLE[ML]       */
	UINT32 Cnt;		/* frequency count :                   */
	UINT32 Incr;	/* frequency step  :                   */
	/* envelope generator state */
	UINT8 eg_typ;	/* envelope type flag                  */
	UINT8 evm;		/* envelope phase                      */
	INT32 evc;		/* envelope counter                    */
	INT32 eve;		/* envelope counter end point          */
	INT32 evs;		/* envelope counter step               */
	INT32 evsa;	/* envelope step for AR :AR[ksr]       */
	INT32 evsd;	/* envelope step for DR :DR[ksr]       */
	INT32 evsr;	/* envelope step for RR :RR[ksr]       */
	/* LFO */
	UINT8 ams;		/* ams flag                            */
	UINT8 vib;		/* vibrate flag                        */
	/* wave selector */
	INT32 wavetableidx;
}OPL_SLOT;

/* ---------- OPL one of channel  ---------- */
typedef struct fm_opl_channel {
	OPL_SLOT SLOT[2];
	UINT8 CON;			/* connection type                     */
	UINT8 FB;			/* feed back       :(shift down bit)   */
	INT32 op1_out[2];	/* slot1 output for selfeedback        */
	/* phase generator state */
	UINT32  block_fnum;	/* block+fnum      :                   */
	UINT8 kcode;		/* key code        : KeyScaleCode      */
	UINT32  fc;			/* Freq. Increment base                */
	UINT32  ksl_base;	/* KeyScaleLevel Base step             */
	UINT8 keyon;		/* key on/off flag                     */
} OPL_CH;

/* OPL state */
typedef struct fm_opl_f {
    void* ref; /* Pointer to user data */
	/* Delta-T ADPCM unit (Y8950) */
	YM_DELTAT *deltat;			/* DELTA-T ADPCM       */
	/* FM channel slots */
	OPL_CH *P_CH;		/* pointer of CH       */
    
	int clock;			/* master clock  (Hz)                */
	int rate;			/* sampling rate (Hz)                */
    int baseRate;       /* sampling rate (Hz)                */
	DoubleT freqbase;	/* frequency base                    */
	DoubleT TimerBase;	/* Timer base time (==sampling time) */

    UINT8 type;			/* chip type                        */
	UINT8 address;		/* address register                  */
	UINT8 status;		/* status flag                       */
	UINT8 statusmask;	/* status mask                       */
	UINT32 mode;		/* Reg.08 : CSM , notesel,etc.       */
	int	max_ch;			/* maximum channel     */
	/* Rythm sention */
	UINT8 rythm;		/* Rythm mode , key flag */
	/* Keyboard / I/O interface unit (Y8950) */
	UINT8 portDirection;
	UINT8 portLatch;
	/* time tables */
	INT32 AR_TABLE[75];	/* atttack rate tables */
	INT32 DR_TABLE[75];	/* decay rate tables   */
	UINT32 FN_TABLE[1024];  /* fnumber -> increment counter */
	/* LFO */
	int ams_table_idx;
	int vib_table_idx;
	INT32 amsCnt;
	INT32 amsIncr;
	INT32 vibCnt;
	INT32 vibIncr;
	/* wave selector enable flag */
	UINT8 wavesel;
    
    //DAC stuff
    int dacSampleVolume;
    int dacOldSampleVolume;
    int dacSampleVolumeSum;
    int dacCtrlVolume;
    int dacDaVolume;
    int dacEnabled;

    UINT8 regs[256];
    int reg6;
    int reg15;
    int reg16;
    int reg17;

} FM_OPL;

/* ---------- Generic interface section ---------- */
#define OPL_TYPE_YM3526 (0)
#define OPL_TYPE_YM3812 (OPL_TYPE_WAVESEL)
#define OPL_TYPE_Y8950  (OPL_TYPE_ADPCM|OPL_TYPE_KEYBOARD|OPL_TYPE_IO)

FM_OPL *OPLCreate(int type, int clock, int rate, int sampleram, void* ref);
void OPLDestroy(FM_OPL *OPL);

void OPLSetOversampling(FM_OPL *OPL, int oversampling);
void OPLResetChip(FM_OPL *OPL);
int OPLWrite(FM_OPL *OPL,int a,int v);
void OPLWriteReg(FM_OPL *OPL, int r, int v);
unsigned char OPLRead(FM_OPL *OPL,int a);
unsigned char OPLPeek(FM_OPL *OPL,int a);
int OPLTimerOver(FM_OPL *OPL,int c);

int Y8950UpdateOne(FM_OPL *OPL);

void Y8950LoadState(FM_OPL *OPL);
void Y8950SaveState(FM_OPL *OPL);

#endif
