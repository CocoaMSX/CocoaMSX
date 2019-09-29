//
//  CH376s.c
//  CocoaMSX
//
//  Created by Mario Smit on 08/09/2019.
//  Copyright © 2019 Akop Karapetyan. All rights reserved.
//

#include "CH376s.h"
#include "IoPort.h"
#include "Board.h"
#include "SaveState.h"
#include "DebugDeviceManager.h"
#include "Language.h"
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

struct DEVINFO     //   ; Contains information about a specific device
{
    UInt8    DeviceType;                  /* 00H */
    UInt8    RemovableMedia;              /* 01H */
    UInt8    Versions;                    /* 02H */
    UInt8    DataFormatAndEtc;            /* 03H */
    UInt8    AdditionalLength;            /* 04H */
    UInt8    Reserved1;                   /* 05H */
    UInt8    Reserved2;                   /* 06H */
    UInt8    MiscFlag;                    /* 07H */
    UInt8    VendorIdStr[8];              /* 08H */
    UInt8    ProductIdStr[16];            /* 10H */
    UInt8    ProductRevStr[4];            /* 20H */
} devinfo;

struct CH376S_STATE
{
    UInt8 prev_command;
    UInt8 command;
    UInt8 data;
    UInt8 interrupt;
    FILE* fp;
    UInt32 sector_number;
    UInt8 nrsectors;
    int nrbytesread;
    int file_operation_result;
    unsigned char InBuffer[64];
    unsigned char OutBuffer[65];
    unsigned char* pInBuffer;
    unsigned char* pOutBuffer;
} state;



static UInt8 ch376sReadCommand(struct CH376S_STATE* state, UInt16 ioPort)
{
    if (state->interrupt)
        return 0x00;
    state->interrupt = 0;
    return 0x80;
}
/*
 ; CH376 commands
 CH_CMD_RESET_ALL: equ 05h
 CH_CMD_CHECK_EXIST: equ 06h
 CH_CMD_SET_RETRY: equ 0Bh
 CH_CMD_DELAY_100US: equ 0Fh
 CH_CMD_SET_USB_ADDR: equ 13h
 CH_CMD_SET_USB_MODE: equ 15h
 CH_CMD_TEST_CONNECT: equ 16h
 CH_CMD_ABORT_NAK: equ 17h
 CH_CMD_GET_STATUS: equ 22h
 CH_CMD_RD_USB_DATA0: equ 27h
 CH_CMD_WR_HOST_DATA: equ 2Ch
 CH_CMD_SET_FILE_NAME: equ 2Fh
 CH_CMD_DISK_CONNECT: equ 30h
 CH_CMD_DISK_MOUNT: equ 31h
 CH_CMD_OPEN_FILE: equ 32h
 CH_CMD_FILE_ENUM_GO: equ 33h
 CH_CMD_FILE_CLOSE: equ 36h
 CH_CMD_SET_ADDRESS: equ 45h
 CH_CMD_GET_DESCR: equ 46h
 CH_CMD_SET_CONFIG: equ 49h
 CH_CMD_SEC_LOCATE: equ 4Ah
 CH_CMD_SEC_READ: equ 4Bh
 CH_CMD_ISSUE_TKN_X: equ 4Eh
 CH_CMD_DISK_READ: equ 54h
 CH_CMD_DISK_RD_GO: equ 55h
*/
#define CH_CMD_CHECK_EXIST 0x06
#define CH_CMD_RESET_ALL 0x05
#define CH_CMD_DELAY_100US 0x0f
#define CH_CMD_SET_USB_MODE 0x15
#define CH_CMD_SEC_LOCATE 0x4a
#define CH_CMD_SEC_READ 0x4b
#define CH_CMD_SET_RETRY 0x0b
#define CH_CMD_DISK_CONNECT 0x30
#define CH_CMD_GET_STATUS 0x22
#define CH_CMD_DISK_MOUNT 0x31
#define CH_CMD_RD_USB_DATA0 0x27
#define CH_CMD_SET_FILE_NAME 0x2F
#define CH_CMD_OPEN_FILE 0x32
#define CH_CMD_FILE_CLOSE 0x36
#define CH_CMD_DISK_READ 0x54
#define CH_CMD_DISK_RD_GO 0x55

// return codes
#define CH_ST_RET_SUCCESS 0x51
#define CH_ST_RET_ABORT 0x5F
#define CH_USB_INT_SUCCESS 0x14
#define CH_USB_ERR_MISS_FILE 0x42
#define CH_USB_INT_DISK_READ 0x1d

static void ch376sWriteCommand(struct CH376S_STATE* state, UInt16 ioPort, UInt8 value)
{
    state->prev_command = state->command;
    state->command = value;
    
    unsigned char* command;
    switch (state->command)
    {
        case CH_CMD_DISK_RD_GO:
            command = "CH_CMD_DISK_RD_GO";
            state->interrupt = 1;
            break;
        case CH_CMD_DISK_READ:
            command = "CH_CMD_DISK_READ";
            state->pInBuffer = state->InBuffer;
            state->interrupt = 1;
            break;
        case CH_CMD_CHECK_EXIST:
            command = "CH_CMD_CHECK_EXIST";
            break;
        case CH_CMD_FILE_CLOSE:
            command = "CH_CMD_FILE_CLOSE";
            if (state->fp!=NULL)
                fclose (state->fp);
            state->fp = NULL;
            break;
        case CH_CMD_OPEN_FILE:
            command = "CH_CMD_OPEN_FILE";
            state->interrupt = 1;
            printf ("Opening: %s\n",state->InBuffer);
            if (state->fp!=NULL)
                fclose (state->fp);
            state->fp = fopen (state->InBuffer,"r");
            break;
        case CH_CMD_SET_FILE_NAME:
            command = "CH_CMD_SET_FILE_NAME";
            state->pInBuffer = state->InBuffer;
            break;
        case CH_CMD_RD_USB_DATA0:
            command = "CH_CMD_RD_USB_DATA0";
            state->pOutBuffer = state->OutBuffer;
            break;
        case CH_CMD_DISK_MOUNT:
            command = "CH_CMD_DISK_MOUNT";
            break;
        case CH_CMD_SET_RETRY:
            command = "CH_CMD_SET_RETRY";
            break;
        case CH_CMD_DISK_CONNECT:
            command = "CH_CMD_DISK_CONNECT";
            state->interrupt = 1;
            memset (state->OutBuffer,0,sizeof (state->OutBuffer));
            state->OutBuffer[0] = sizeof (struct DEVINFO);
            strcpy (devinfo.VendorIdStr,"Neximus");
            strcpy (devinfo.ProductIdStr,"NexDrive");
            strcpy (devinfo.ProductRevStr,"0");
            memcpy (state->OutBuffer+1,&devinfo,sizeof (struct DEVINFO));
            state->pOutBuffer = state->OutBuffer;
            break;
        case CH_CMD_GET_STATUS:
            command = "--CH_CMD_GET_STATUS";
            break;
        case CH_CMD_RESET_ALL:
            command = "CH_CMD_RESET_ALL";
            break;
        case CH_CMD_DELAY_100US:
            return;
        case CH_CMD_SET_USB_MODE:
            command = "CH_CMD_SET_USB_MODE";
            break;
        case CH_CMD_SEC_LOCATE:
            command = "CH_CMD_SEC_LOCATE";
            state->pInBuffer = state->InBuffer;
            state->interrupt = 1;
            break;
        case CH_CMD_SEC_READ:
            command = "CH_CMD_SEC_READ";
            state->sector_number = *(state->InBuffer);
            state->pInBuffer = state->InBuffer; // receiving nr of sectors requested
            state->interrupt = 1;
            break;
        default:
            command = "UNKNOWN";
            state->data = value;
    }
    //printf ("CH376s command: %s [%02x]\n",command,value);
}

int8_t fileread (struct CH376S_STATE* state)
{
    //printf ("CH376s reading file: %d of %d bytes\n",512-state->nrbytesread,state->nrsectors*512);
    if (state->nrbytesread==0)
        return 0;
    memset (state->OutBuffer,0,sizeof (state->OutBuffer));
    state->OutBuffer[0] = fread(state->OutBuffer+1, 1, sizeof (state->OutBuffer)-1, state->fp);
    state->nrbytesread -= state->OutBuffer[0];
    return state->OutBuffer[0];
}
static UInt8 ch376sReadData(struct CH376S_STATE* state, UInt16 ioPort)
{
    UInt8 value;
    switch (state->command)
    {
        case CH_CMD_DELAY_100US:
            value = 1;
            break;
        case CH_CMD_SET_USB_MODE:
            value = CH_ST_RET_SUCCESS;
            break;
        case CH_CMD_GET_STATUS:
            switch (state->prev_command)
            {
                case CH_CMD_DISK_CONNECT:
                    value = CH_USB_INT_SUCCESS;
                    break;
                case CH_CMD_DISK_MOUNT:
                    value = CH_USB_INT_SUCCESS;
                    state->command = CH_CMD_DISK_MOUNT;
                    break;
                case CH_CMD_OPEN_FILE:
                    if (state->fp!=NULL)
                        value = CH_USB_INT_SUCCESS;
                    else
                        value = CH_USB_ERR_MISS_FILE;
                    break;
                case CH_CMD_SEC_LOCATE:
                    if (state->fp!=NULL) {
                        value = CH_USB_INT_SUCCESS;
                        state->command = CH_CMD_SEC_LOCATE;
                    }
                    else
                        value = CH_USB_ERR_MISS_FILE;
                    break;
                case CH_CMD_SEC_READ:
                    state->nrsectors = *(state->InBuffer);
                    printf ("CH376s read sector: %d to: %d\n",state->sector_number,state->sector_number+state->nrsectors);
                    if (state->fp)
                        state->file_operation_result = fseek (state->fp,state->sector_number*512,SEEK_SET);
                    else
                        state->file_operation_result = 1; //error
                    memset (state->OutBuffer,0,sizeof (state->OutBuffer));
                    state->OutBuffer[0] = 8;
                    UInt32* pNrSecs = state->OutBuffer+1;
                    UInt32* pLBA = state->OutBuffer+5;
                    *pNrSecs = state->nrsectors;
                    *pLBA = 0;
                    state->pOutBuffer = state->OutBuffer;
                    
                    if (state->file_operation_result==0)
                        value = CH_USB_INT_SUCCESS;
                    else
                        value = CH_ST_RET_ABORT;
                    state->command = CH_CMD_SEC_READ;
                    break;
                case CH_CMD_DISK_READ:
                    state->sector_number = *(state->InBuffer);
                    state->nrsectors = *(state->InBuffer+4);
                    state->nrbytesread = state->nrsectors*512;
                    state->pOutBuffer = state->OutBuffer;
                    if (fileread (state)>0)
                        value = CH_USB_INT_DISK_READ;
                    else
                        value = CH_USB_INT_SUCCESS;
                    state->command = CH_CMD_DISK_READ;
                    break;
                case CH_CMD_DISK_RD_GO:
                    state->pOutBuffer = state->OutBuffer;
                    if (fileread (state)>0)
                        value = CH_USB_INT_DISK_READ;
                    else
                        value = CH_USB_INT_SUCCESS;
                    state->command = CH_CMD_DISK_RD_GO;
                    break;
                default:
                    value = CH_ST_RET_ABORT;
                    break;
            }
            break;
        case CH_CMD_RD_USB_DATA0:
            switch (state->prev_command)
            {
                case CH_CMD_DISK_MOUNT:
                    value = *state->pOutBuffer++;
                    break;
                case CH_CMD_SEC_READ:
                    value = *state->pOutBuffer++;
                    break;
                case CH_CMD_DISK_READ:
                    value = *state->pOutBuffer++;
                    break;
                case CH_CMD_DISK_RD_GO:
                    value = *state->pOutBuffer++;
                    break;
                default:
                    break;
            }
            break;
        default:
            value = state->data;
    }
    state->data = 0;
    //printf ("CH376s read: %02x\n",value);
    return value;
}
static void ch376sWriteData(struct CH376S_STATE* state, UInt16 ioPort, UInt8 value)
{
    //printf ("CH376s write: %02x\n",value);
    switch (state->command)
    {
        case CH_CMD_CHECK_EXIST:
            state->data = value ^ 255;
            break;
        case CH_CMD_SET_FILE_NAME:
            *state->pInBuffer++ = value;
            break;
        case CH_CMD_SEC_READ:
            *state->pInBuffer++ = value;
            break;
        case CH_CMD_SEC_LOCATE:
            *state->pInBuffer++ = value;
            break;
        case CH_CMD_DISK_READ:
            *state->pInBuffer++ = value;
            break;
        default:
            state->data = value;
    }
}

void ch376sCreate ()
{
    state.fp = NULL;
    
    ioPortRegister(0x11, ch376sReadCommand, ch376sWriteCommand,  (void*) &state);
    ioPortRegister(0x10, ch376sReadData, ch376sWriteData,  (void*) &state);
}
void ch376sDestroy ()
{
    ioPortUnregister(0x11);
    ioPortUnregister(0x10);
}
