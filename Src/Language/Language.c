/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Language/Language.c,v $
**
** $Revision: 1.99 $
**
** $Date: 2009-04-04 20:57:19 $
**
** More info: http://www.bluemsx.com
**
** Copyright (C) 2003-2006 Daniel Vik
**
** This program is free software; you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation; either version 2 of the License, or
** (at your option) any later version.
** 
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program; if not, write to the Free Software
** Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
**
******************************************************************************
*/
#include "Language.h"
#include "LanguageStrings.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "LanguageEnglish.h"
//#include "LanguageSwedish.h"
//#include "LanguageSpannish.h"
//#include "LanguageJapanese.h"
//#include "LanguageKorean.h"
//#include "LanguagePortuguese.h"
//#include "LanguageFrench.h"
//#include "LanguageDutch.h"
//#include "LanguageItalian.h"
//#include "LanguageFinnish.h"
//#include "LanguageGerman.h"
//#include "LanguagePolish.h"
//#include "LanguageCatalan.h"
//#include "LanguageRussian.h"
//#include "LanguageChineseSimplified.h"
//#include "LanguageChineseTraditional.h"

static LanguageStrings langEnglish;
static LanguageStrings langSwedish;
static LanguageStrings langSpanish;
static LanguageStrings langJapanese;
static LanguageStrings langKorean;
static LanguageStrings langPortuguese;
static LanguageStrings langRussian;
static LanguageStrings langFrench;
static LanguageStrings langDutch;
static LanguageStrings langItalian;
static LanguageStrings langFinnish;
static LanguageStrings langGerman;
static LanguageStrings langPolish;
static LanguageStrings langCatalan;
static LanguageStrings langChineseSimplified;
static LanguageStrings langChineseTraditional;

static LanguageStrings* ls;
static EmuLanguageType  lType = EMU_LANG_UNKNOWN;

typedef struct {
    EmuLanguageType type;
    char            english[32];
    char*           (*translation)(void);
} LanguageInfo;

static LanguageInfo languageInfo[] = {
    { EMU_LANG_CATALAN,     "Catalan",             langLangCatalan },
    { EMU_LANG_CHINESESIMP, "Chinese Simplified",  langLangChineseSimplified },
    { EMU_LANG_CHINESETRAD, "Chinese Traditional", langLangChineseTraditional },
    { EMU_LANG_DUTCH,       "Dutch",               langLangDutch },
    { EMU_LANG_ENGLISH,     "English",             langLangEnglish },
    { EMU_LANG_FINNISH,     "Finnish",             langLangFinnish },
    { EMU_LANG_FRENCH,      "French",              langLangFrench },
    { EMU_LANG_GERMAN,      "German",              langLangGerman },
    { EMU_LANG_ITALIAN,     "Italian",             langLangItalian },
    { EMU_LANG_JAPANESE,    "Japanese",            langLangJapanese },
    { EMU_LANG_KOREAN,      "Korean",              langLangKorean },
    { EMU_LANG_POLISH,      "Polish",              langLangPolish },
    { EMU_LANG_PORTUGUESE,  "Portuguese",          langLangPortuguese },
    { EMU_LANG_RUSSIAN,     "Russian",             langLangRussian },
    { EMU_LANG_SPANISH,     "Spanish",             langLangSpanish },
    { EMU_LANG_SWEDISH,     "Swedish",             langLangSwedish },
    { EMU_LANG_UNKNOWN,     "",                    langTextUnknown }
};

EmuLanguageType langFromName(char* name, int translate) {
    int i;
    for (i = 0; languageInfo[i].type != EMU_LANG_UNKNOWN; i++) {
        if (translate) {
            if (0 == strcmp(name, languageInfo[i].translation())) {
                break;
            }
        }
        else {
            if (0 == strcmp(name, languageInfo[i].english)) {
                break;
            }
        }
    }
    return languageInfo[i].type;
}


const char* langToName(EmuLanguageType languageType, int translate) {
    int i;
    for (i = 0; languageInfo[i].type != EMU_LANG_UNKNOWN; i++) {
        if (languageInfo[i].type == languageType) {
            break;
        }
    }
    if (translate) {
        return languageInfo[i].translation();
    }
    return languageInfo[i].english;
}

EmuLanguageType langGetType(int i) {
    return languageInfo[i].type;
}

void langInit(void) {
    langInitEnglish(&langEnglish);

    langInitEnglish(&langSwedish);
//    langInitSwedish(&langSwedish);
    
    langInitEnglish(&langSpanish);
//    langInitSpanish(&langSpanish);
    
    langInitEnglish(&langJapanese);
//    langInitJapanese(&langJapanese);
    
    langInitEnglish(&langKorean);
//    langInitKorean(&langKorean);
    
    langInitEnglish(&langPortuguese);
//    langInitPortuguese(&langPortuguese);
    
    langInitEnglish(&langRussian);
//    langInitRussian(&langRussian);

    langInitEnglish(&langFrench);
//    langInitFrench(&langFrench);
    
    langInitEnglish(&langDutch);
//    langInitDutch(&langDutch);
    
    langInitEnglish(&langItalian);
//    langInitItalian(&langItalian);
    
    langInitEnglish(&langFinnish);
//    langInitFinnish(&langFinnish);
    
    langInitEnglish(&langGerman);
//    langInitGerman(&langGerman);

    langInitEnglish(&langPolish);
//    langInitPolish(&langPolish);

    langInitEnglish(&langCatalan);
//    langInitCatalan(&langCatalan);

    langInitEnglish(&langChineseSimplified);
//    langInitChineseSimplified(&langChineseSimplified);

    langInitEnglish(&langChineseTraditional);
//    langInitChineseTraditional(&langChineseTraditional);
    
    ls = &langEnglish;
}

EmuLanguageType langGetLanguage(void) {
    return lType;
}

int langSetLanguage(EmuLanguageType languageType) {
    switch (languageType) {
    case EMU_LANG_ENGLISH:
        ls = &langEnglish;
        break;
    case EMU_LANG_SWEDISH:
        ls = &langSwedish;
        break;
    case EMU_LANG_SPANISH:
        ls = &langSpanish;
        break;
    case EMU_LANG_JAPANESE:
        ls = &langJapanese;
        break;
    case EMU_LANG_KOREAN:
        ls = &langKorean;
        break;
    case EMU_LANG_PORTUGUESE:
        ls = &langPortuguese;
        break;
    case EMU_LANG_RUSSIAN:
        ls = &langRussian;
        break;
    case EMU_LANG_FRENCH:
        ls = &langFrench;
        break;
    case EMU_LANG_DUTCH:
        ls = &langDutch;
        break;
    case EMU_LANG_ITALIAN:
        ls = &langItalian;
        break;
    case EMU_LANG_FINNISH:
        ls = &langFinnish;
        break;
    case EMU_LANG_GERMAN:
        ls = &langGerman;
        break;

    case EMU_LANG_POLISH:
        ls = &langPolish;
        break;

    case EMU_LANG_CHINESESIMP:
        ls = &langChineseSimplified;
        break;

    case EMU_LANG_CHINESETRAD:
        ls = &langChineseTraditional;
        break;

    case EMU_LANG_CATALAN:
        ls = &langCatalan;
        break;

    default:
        return 0;
    }
    
    lType = languageType;

    return 1;
}


//----------------------
// Language lines
//----------------------

char* langLangCatalan(void) { return ls->langCatalan; }
char* langLangChineseSimplified(void) { return ls->langChineseSimplified; }
char* langLangChineseTraditional(void) { return ls->langChineseTraditional; }
char* langLangDutch(void) { return ls->langDutch; }
char* langLangEnglish(void) { return ls->langEnglish; }
char* langLangFinnish(void) { return ls->langFinnish; }
char* langLangFrench(void) { return ls->langFrench; }
char* langLangGerman(void) { return ls->langGerman; }
char* langLangItalian(void) { return ls->langItalian; }
char* langLangJapanese(void) { return ls->langJapanese; }
char* langLangKorean(void) { return ls->langKorean; }
char* langLangPolish(void) { return ls->langPolish; }
char* langLangPortuguese(void) { return ls->langPortuguese; }
char* langLangRussian(void) { return ls->langRussian; }
char* langLangSpanish(void) { return ls->langSpanish; }
char* langLangSwedish(void) { return ls->langSwedish; }


//----------------------
// Generic lines
//----------------------

char* langTextDevice(void) { return ls->textDevice; }
char* langTextFilename(void) { return ls->textFilename; }
char* langTextFile(void) { return ls->textFile; }
char* langTextNone(void) { return ls->textNone; }
char* langTextUnknown(void) { return ls->textUnknown; }


//----------------------
// Warning and Error lines
//----------------------

char* langWarningTitle(void) { return ls->warningTitle; }
char* langWarningDiscardChanges(void)  {return ls->warningDiscardChanges; }
char* langWarningOverwriteFile(void) { return ls->warningOverwriteFile; }
char* langErrorTitle(void) { return ls->errorTitle; }
char* langErrorEnterFullscreen(void) { return ls->errorEnterFullscreen; }
char* langErrorDirectXFailed(void) { return ls->errorDirectXFailed; }
char* langErrorNoRomInZip(void) { return ls->errorNoRomInZip; }
char* langErrorNoDskInZip(void) { return ls->errorNoDskInZip; }
char* langErrorNoCasInZip(void) { return ls->errorNoCasInZip; }
char* langErrorNoHelp(void) { return ls->errorNoHelp; }
char* langErrorStartEmu(void) { return ls->errorStartEmu; }
char* langErrorPortableReadonly(void)  {return ls->errorPortableReadonly; }


//----------------------
// File related lines
//----------------------

char* langFileRom(void) { return ls->fileRom; }
char* langFileAll(void) { return ls->fileAll; }
char* langFileCpuState(void) { return ls->fileCpuState; }
char* langFileVideoCapture(void) { return ls->fileVideoCapture; }
char* langFileDisk(void) { return ls->fileDisk; }
char* langFileCas(void) { return ls->fileCas; }
char* langFileAvi(void) { return ls->fileAvi; }


//----------------------
// Menu related lines
//----------------------

char* langMenuNoRecentFiles(void) { return ls->menuNoRecentFiles; }
char* langMenuInsert(void) { return ls->menuInsert; }
char* langMenuEject(void) { return ls->menuEject; }

char* langMenuCartGameReader(void) { return ls->menuCartGameReader; }
char* langMenuCartIde(void) { return ls->menuCartIde; }
char* langMenuCartBeerIde(void) { return ls->menuCartBeerIde; }
char* langMenuCartGIde(void) { return ls->menuCartGIde; }
char* langMenuCartSunriseIde(void) { return ls->menuCartSunriseIde; }
char* langMenuCartScsi(void) { return ls->menuCartScsi; }
char* langMenuCartMegaSCSI(void) { return ls->menuCartMegaSCSI; }
char* langMenuCartWaveSCSI(void) { return ls->menuCartWaveSCSI; }
char* langMenuCartGoudaSCSI(void) { return ls->menuCartGoudaSCSI; }
char* langMenuCartSCC(void) { return ls->menuCartSCC; }
char* langMenuCartJoyrexPsg(void) { return ls->menuJoyrexPsg; }
char* langMenuCartSCCPlus(void) { return ls->menuCartSCCPlus; }
char* langMenuCartFMPac(void)  { return ls->menuCartFMPac; }
char* langMenuCartPac(void)  { return ls->menuCartPac; }
char* langMenuCartHBI55(void) { return ls->menuCartHBI55; }
char* langMenuCartInsertSpecial(void) { return ls->menuCartInsertSpecial; }
char* langMenuCartMegaRam(void) { return ls->menuCartMegaRam; }
char* langMenuCartExternalRam(void) { return ls->menuCartExternalRam; }
char* langMenuCartEseRam(void) { return ls->menuCartEseRam; }
char* langMenuCartEseSCC(void) { return ls->menuCartEseSCC; }
char* langMenuCartMegaFlashRom(void) { return ls->menuCartMegaFlashRom; }

char* langMenuDiskInsertNew(void) { return ls->menuDiskInsertNew; }
char* langMenuDiskDirInsertCdrom(void) { return ls->menuDiskInsertCdrom; }
char* langMenuDiskDirInsert(void) { return ls->menuDiskDirInsert; }
char* langMenuDiskAutoStart(void) { return ls->menuDiskAutoStart; }
char* langMenuCartAutoReset(void) { return ls->menuCartAutoReset; }

char* langMenuCasRewindAfterInsert(void) { return ls->menuCasRewindAfterInsert; }
char* langMenuCasUseReadOnly(void) { return ls->menuCasUseReadOnly; }
char* langMenuCasSaveAs(void) { return ls->lmenuCasSaveAs; }
char* langMenuCasSetPosition(void) { return ls->menuCasSetPosition; }
char* langMenuCasRewind(void) { return ls->menuCasRewind; }

char* langMenuVideoLoad(void) { return ls->menuVideoLoad; }
char* langMenuVideoPlay(void) { return ls->menuVideoPlay; }
char* langMenuVideoRecord(void) { return ls->menuVideoRecord; }
char* langMenuVideoRecording(void) { return ls->menuVideoRecording; }
char* langMenuVideoRecAppend(void) { return ls->menuVideoRecAppend; }
char* langMenuVideoStop(void) { return ls->menuVideoStop; }
char* langMenuVideoRender(void) { return ls->menuVideoRender; }

char* langMenuPrnFormfeed(void) { return ls->menuPrnFormfeed; }

char* langMenuZoomNormal(void) { return ls->menuZoomNormal; }
char* langMenuZoomDouble(void) { return ls->menuZoomDouble; }
char* langMenuZoomFullscreen(void) { return ls->menuZoomFullscreen; }

char* langMenuPropsEmulation(void) { return ls->menuPropsEmulation; }
char* langMenuPropsVideo(void) { return ls->menuPropsVideo; }
char* langMenuPropsSound(void) { return ls->menuPropsSound; }
char* langMenuPropsControls(void) { return ls->menuPropsControls; }
char* langMenuPropsEffects(void) { return ls->menuPropsEffects; }
char* langMenuPropsSettings(void) { return ls->menuPropsSettings; }
char* langMenuPropsFile(void) { return ls->menuPropsFile; }
char* langMenuPropsDisk(void) { return ls->menuPropsDisk; }
char* langMenuPropsLanguage(void) { return ls->menuPropsLanguage; }
char* langMenuPropsPorts(void) { return ls->menuPropsPorts; }

char* langMenuVideoSource(void)        { return ls->menuVideoSource; }
char* langMenuVideoSourceDefault(void) { return ls->menuVideoSourceDefault; }
char* langMenuVideoChipAutodetect(void) { return ls->menuVideoChipAutodetect; }
char* langMenuVideoInSource(void) { return ls->menuVideoInSource; }
char* langMenuVideoInBitmap(void) { return ls->menuVideoInBitmap; }
    
char* langMenuEthInterface(void) { return ls->menuEthInterface; }

char* langMenuHelpHelp(void) { return ls->menuHelpHelp; }
char* langMenuHelpAbout(void) { return ls->menuHelpAbout; }

char* langMenuFileCart(void) { return ls->menuFileCart; }
char* langMenuFileDisk(void) { return ls->menuFileDisk; }
char* langMenuFileCas(void) { return ls->menuFileCas; }
char* langMenuFilePrn(void) { return ls->menuFilePrn; }
char* langMenuFileLoadState(void) { return ls->menuFileLoadState; }
char* langMenuFileSaveState(void) { return ls->menuFileSaveState; }
char* langMenuFileQLoadState(void) { return ls->menuFileQLoadState; }
char* langMenuFileQSaveState(void) { return ls->menuFileQSaveState; }
char* langMenuFileCaptureAudio(void) { return ls->menuFileCaptureAudio; }
char* langMenuFileCaptureVideo(void) { return ls->menuFileCaptureVideo; }
char* langMenuFileScreenShot(void) { return ls->menuFileScreenShot; }
char* langMenuFileExit(void) { return ls->menuFileExit; }
char* langMenuFileHarddisk(void) { return ls->menuFileHarddisk; }
char* langMenuFileHarddiskNoPresent(void) { return ls->menuFileHarddiskNoPesent; }
char* langMenuFileHarddiskRemoveAll(void) { return ls->menuFileHarddiskRemoveAll; }

char* langMenuRunRun(void) { return ls->menuRunRun; }
char* langMenuRunPause(void) { return ls->menuRunPause; }
char* langMenuRunStop(void) { return ls->menuRunStop; }
char* langMenuRunSoftReset(void) { return ls->menuRunSoftReset; }
char* langMenuRunHardReset(void) { return ls->menuRunHardReset; }
char* langMenuRunCleanReset(void) { return ls->menuRunCleanReset; }

char* langMenuToolsMachine(void) { return ls->menuToolsMachine; }
char* langMenuToolsShortcuts(void) { return ls->menuToolsShortcuts; }
char* langMenuToolsCtrlEditor(void) { return ls->menuToolsCtrlEditor; }
char* langMenuToolsMixer(void) { return ls->menuToolsMixer; }
char* langMenuToolsLoadMemory(void) { return ls->menuToolsLoadMemory; }
char* langMenuToolsDebugger(void) { return ls->menuToolsDebugger; }
char* langMenuToolsTrainer(void) { return ls->menuToolsTrainer; }
char* langMenuToolsTraceLogger(void) { return ls->menuToolsTraceLogger; }

char* langMenuFile(void) { return ls->menuFile; }
char* langMenuRun(void) { return ls->menuRun; }
char* langMenuWindow(void) { return ls->menuWindow; }
char* langMenuOptions(void) { return ls->menuOptions; }
char* langMenuTools(void) { return ls->menuTools; }
char* langMenuHelp(void) { return ls->menuHelp; }


//----------------------
// Dialog related lines
//----------------------

char* langDlgOK(void) { return ls->dlgOK; }
char* langDlgOpen(void) { return ls->dlgOpen; }
char* langDlgCancel(void) { return ls->dlgCancel; }
char* langDlgSave(void) { return ls->dlgSave; }
char* langDlgSaveAs(void) { return ls->dlgSaveAs; }
char* langDlgRun(void) { return ls->dlgRun; }
char* langDlgClose(void) { return ls->dlgClose; }

char* langDlgLoadRom(void) { return ls->dlgLoadRom; }
char* langDlgLoadDsk(void) { return ls->dlgLoadDsk; }
char* langDlgLoadCas(void) { return ls->dlgLoadCas; }
char* langDlgLoadRomDskCas(void) { return ls->dlgLoadRomDskCas; }
char* langDlgLoadRomDesc(void) { return ls->dlgLoadRomDesc; }
char* langDlgLoadDskDesc(void) { return ls->dlgLoadDskDesc; }
char* langDlgLoadCasDesc(void) { return ls->dlgLoadCasDesc; }
char* langDlgLoadRomDskCasDesc(void) { return ls->dlgLoadRomDskCasDesc; }
char* langDlgLoadState(void) { return ls->dlgLoadState; }
char* langDlgLoadVideoCapture(void) { return ls->dlgLoadVideoCapture; }
char* langDlgSaveState(void) { return ls->dlgSaveState; }
char* langDlgSaveCassette(void) { return ls->dlgSaveCassette; }
char* langDlgSaveVideoClipAs(void) { return ls->dlgSaveVideoClipAs; }
char* langDlgAmountCompleted(void) { return ls->dlgAmountCompleted; }
char* langDlgInsertRom1(void) { return ls->dlgInsertRom1; }
char* langDlgInsertRom2(void) { return ls->dlgInsertRom2; }
char* langDlgInsertDiskA(void) { return ls->dlgInsertDiskA; }
char* langDlgInsertDiskB(void) { return ls->dlgInsertDiskB; }
char* langDlgInsertHarddisk(void) { return ls->dlgInsertHarddisk; }
char* langDlgInsertCas(void) { return ls->dlgInsertCas; }
char* langDlgRomType(void) { return ls->dlgRomType; }
char* langDlgDiskSize(void) { return ls->dlgDiskSize; }

char* langDlgTapeTitle(void) { return ls->dlgTapeTitle; }
char* langDlgTapeFrameText(void) { return ls->dlgTapeFrameText; }
char* langDlgTapeCurrentPos(void) { return ls->dlgTapeCurrentPos; }
char* langDlgTapeTotalTime(void) { return ls->dlgTapeTotalTime; }
char* langDlgTapeSetPosText(void) { return ls->dlgTapeSetPosText; }
char* langDlgTapeCustom(void) { return ls->dlgTapeCustom; }
char* langDlgTabPosition(void) { return ls->dlgTabPosition; }
char* langDlgTabType(void) { return ls->dlgTabType; }
char* langDlgTabFilename(void) { return ls->dlgTabFilename; }
char* langDlgZipReset(void) { return ls->dlgZipReset; }

char* langDlgAboutTitle(void) { return ls->dlgAboutTitle; }

char* langDlgLangLangText(void) { return ls->dlgLangLangText; }
char* langDlgLangTitle(void) { return ls->dlgLangLangTitle; }

char* langDlgAboutAbout(void) { return ls->dlgAboutAbout; }
char* langDlgAboutVersion(void) { return ls->dlgAboutVersion; }
char* langDlgAboutBuildNumber(void) { return ls->dlgAboutBuildNumber; }
char* langDlgAboutBuildDate(void) { return ls->dlgAboutBuildDate; }
char* langDlgAboutCreat(void) { return ls->dlgAboutCreat; }
char* langDlgAboutDevel(void) { return ls->dlgAboutDevel; }
char* langDlgAboutThanks(void) { return ls->dlgAboutThanks; }
char* langDlgAboutLisence(void) { return ls->dlgAboutLisence; }


//----------------------
// Properties related lines
//----------------------

char* langPropTitle(void) { return ls->propTitle; }
char* langPropEmulation(void) { return ls->propEmulation; }
char* langPropD3D(void) { return ls->propD3D; }
char* langPropVideo(void) { return ls->propVideo; }
char* langPropSound(void) { return ls->propSound; }
char* langPropControls(void) { return ls->propControls; }
char* langPropPerformance(void) { return ls->propPerformance; }
char* langPropEffects(void) { return ls->propEffects; }
char* langPropSettings(void) { return ls->propSettings; }
char* langPropFile(void)  { return ls->propFile; }
char* langPropDisk(void)  { return ls->propDisk; }
char* langPropPorts(void) { return ls->propPorts; }

char* langPropEmuGeneralGB(void) { return ls->propEmuGeneralGB; }
char* langPropEmuFamilyText(void) { return ls->propEmuFamilyText; }
char* langPropEmuMemoryGB(void) { return ls->propEmuMemoryGB; }
char* langPropEmuRamSizeText(void) { return ls->propEmuRamSizeText; }
char* langPropEmuVramSizeText(void) { return ls->propEmuVramSizeText; }
char* langPropEmuSpeedGB(void) { return ls->propEmuSpeedGB; }
char* langPropEmuSpeedText(void) { return ls->propEmuSpeedText; }
char* langPropEmuFrontSwitchGB(void) { return ls->propEmuFrontSwitchGB; }
char* langPropEmuFrontSwitch(void) { return ls->propEmuFrontSwitch; }
char* langPropEmuFdcTiming(void) { return ls->propEmuFdcTiming; }
char* langPropEmuReversePlay(void) { return ls->propEmuReversePlay; }
char* langPropEmuNoSpriteLimits(void) { return ls->propEmuNoSpriteLimits; }
char* langPropEnableMsxKeyboardQuirk(void) { return ls->propEnableMsxKeyboardQuirk; }
char* langPropEmuPauseSwitch(void) { return ls->propEmuPauseSwitch; }
char* langPropEmuAudioSwitch(void) { return ls->propEmuAudioSwitch; }
char* langPropVideoFreqText(void) { return ls->propVideoFreqText; }
char* langPropVideoFreqAuto(void) { return ls->propVideoFreqAuto; }
char* langPropSndOversampleText(void) { return ls->propSndOversampleText; }
char* langPropSndYkInGB(void) { return ls->propSndYkInGB; }
char* langPropSndMidiInGB(void) { return ls->propSndMidiInGB; }
char* langPropSndMidiOutGB(void) { return ls->propSndMidiOutGB; }
char* langPropSndMidiChannel(void) { return ls->propSndMidiChannel; }
char* langPropSndMidiAll(void) { return ls->propSndMidiAll; }

char* langPropMonMonGB(void) { return ls->propMonMonGB; }
char* langPropMonTypeText(void) { return ls->propMonTypeText; }
char* langPropMonEmuText(void) { return ls->propMonEmuText; }
char* langPropVideoTypeText(void) { return ls->propVideoTypeText; }
char* langPropWindowSizeText(void) { return ls->propWindowSizeText; }
char* langPropMonHorizStretch(void) { return ls->propMonHorizStretch; }
char* langPropMonVertStretch(void) { return ls->propMonVertStretch; }
char* langPropMonDeInterlace(void) { return ls->propMonDeInterlace; }
char* langPropMonBlendFrames(void) { return ls->propBlendFrames; }
char* langPropMonBrightness(void) { return ls->propMonBrightness; }
char* langPropMonContrast(void) { return ls->propMonContrast; }
char* langPropMonSaturation(void) { return ls->propMonSaturation; }
char* langPropMonGamma(void) { return ls->propMonGamma; }
char* langPropMonScanlines(void) { return ls->propMonScanlines; }
char* langPropMonColorGhosting(void) { return ls->propMonColorGhosting; }
char* langPropMonEffectsGB(void) { return ls->propMonEffectsGB; }

char* langPropPerfVideoDrvGB(void) { return ls->propPerfVideoDrvGB; }
char* langPropPerfVideoDispDrvText(void) { return ls->propPerfVideoDispDrvText; }
char* langPropPerfFrameSkipText(void) { return ls->propPerfFrameSkipText; }
char* langPropPerfAudioDrvGB(void) { return ls->propPerfAudioDrvGB; }
char* langPropPerfAudioDrvText(void) { return ls->propPerfAudioDrvText; }
char* langPropPerfAudioBufSzText(void) { return ls->propPerfAudioBufSzText; }
char* langPropPerfEmuGB(void) { return ls->propPerfEmuGB; }
char* langPropPerfSyncModeText(void) { return ls->propPerfSyncModeText; }
char* langPropFullscreenResText(void) { return ls->propFullscreenResText; }

char* langPropSndChipEmuGB(void) { return ls->propSndChipEmuGB; }
char* langPropSndMsxMusic(void) { return ls->propSndMsxMusic; }
char* langPropSndMsxAudio(void) { return ls->propSndMsxAudio; }
char* langPropSndMoonsound(void) { return ls->propSndMoonsound; }
char* langPropSndMt32ToGm(void) { return ls->propSndMt32ToGm; }

char* langPropPortsLptGB(void) { return ls->propPortsLptGB; }
char* langPropPortsComGB(void) { return ls->propPortsComGB; }
char* langPropPortsLptText(void) { return ls->propPortsLptText; }
char* langPropPortsCom1Text(void) { return ls->propPortsCom1Text; }
char* langPropPortsNone(void) { return ls->propPortsNone; }
char* langPropPortsSimplCovox(void) { return ls->propPortsSimplCovox; }
char* langPropPortsFile(void) { return ls->propPortsFile; }
char* langPropPortsComFile(void)  { return ls->propPortsComFile; }
char* langPropPortsOpenLogFile(void) { return ls->propPortsOpenLogFile; }
char* langPropPortsEmulateMsxPrn(void) { return ls->propPortsEmulateMsxPrn; }

char* langPropSetFileHistoryGB(void) { return ls->propSetFileHistoryGB; }
char* langPropSetFileHistorySize(void) { return ls->propSetFileHistorySize; }
char* langPropSetFileHistoryClear(void) { return ls->propSetFileHistoryClear; }
char* langPropFileTypes(void) { return ls->propFileTypes; }
char* langPropWindowsEnvGB(void) { return ls->propWindowsEnvGB; }
char* langPropScreenSaver(void) { return ls->propSetScreenSaver; }
char* langPropDisableWinKeys(void) { return ls->propDisableWinKeys; }
char* langPropPriorityBoost(void) { return ls->propPriorityBoost; }
char* langPropScreenshotPng(void) { return ls->propScreenshotPng; }
char* langPropEjectMediaOnExit(void) { return ls->propEjectMediaOnExit; }
char* langPropClearFileHistory(void) { return ls->propClearHistory; }
char* langPropOpenRomGB(void) { return ls->propOpenRomGB; }
char* langPropDefaultRomType(void) { return ls->propDefaultRomType; }
char* langPropGuessRomType(void) { return ls->propGuessRomType; }

char* langPropSettDefSlotGB(void) { return ls->propSettDefSlotGB; }
char* langPropSettDefSlots(void) { return ls->propSettDefSlots; }
char* langPropSettDefSlot(void) { return ls->propSettDefSlot; }
char* langPropSettDefDrives(void) { return ls->propSettDefDrives; }
char* langPropSettDefDrive(void) { return ls->propSettDefDrive; }

char* langPropThemeGB(void) { return ls->propThemeGB; }
char* langPropTheme(void) { return ls->propTheme; }

char* langPropCdromGB(void) { return ls->propCdromGB; }
char* langPropCdromMethod(void) { return ls->propCdromMethod; }
char* langPropCdromMethodNone(void) { return ls->propCdromMethodNone; }
char* langPropCdromMethodIoctl(void) { return ls->propCdromMethodIoctl; }
char* langPropCdromMethodAspi(void) { return ls->propCdromMethodAspi; }
char* langPropCdromDrive(void) { return ls->propCdromDrive; }

//----------------------
// Dropdown related lines
//----------------------

char* langEnumVideoMonColor(void) { return ls->enumVideoMonColor; }
char* langEnumVideoMonGrey(void) { return ls->enumVideoMonGrey; }
char* langEnumVideoMonGreen(void) { return ls->enumVideoMonGreen; }
char* langEnumVideoMonAmber(void) { return ls->enumVideoMonAmber; }

char* langEnumVideoTypePAL(void) { return ls->enumVideoTypePAL; }
char* langEnumVideoTypeNTSC(void) { return ls->enumVideoTypeNTSC; }

char* langEnumVideoEmuNone(void) { return ls->enumVideoEmuNone; }
char* langEnumVideoEmuYc(void) { return ls->enumVideoEmuYc; }
char* langEnumVideoEmuMonitor(void) { return ls->enumVideoEmuMonitor; }
char* langEnumVideoEmuYcBlur(void) { return ls->enumVideoEmuYcBlur; }
char* langEnumVideoEmuComp(void) { return ls->enumVideoEmuComp; }
char* langEnumVideoEmuCompBlur(void) { return ls->enumVideoEmuCompBlur; }
char* langEnumVideoEmuScale2x(void) { return ls->enumVideoEmuScale2x; }
char* langEnumVideoEmuHq2x(void) { return ls->enumVideoEmuHq2x; }

char* langEnumVideoSize1x(void) { return ls->enumVideoSize1x; }
char* langEnumVideoSize2x(void) { return ls->enumVideoSize2x; }
char* langEnumVideoSizeFullscreen(void) { return ls->enumVideoSizeFullscreen; }

char* langEnumVideoDrvDirectDrawHW(void) { return ls->enumVideoDrvDirectDrawHW; }
char* langEnumVideoDrvDirectDraw(void) { return ls->enumVideoDrvDirectDraw; }
char* langEnumVideoDrvGDI(void) { return ls->enumVideoDrvGDI; }
char* langEnumVideoDrvD3D(void) { return ls->enumVideoDrvD3D; }

char* langEnumVideoFrameskip0(void) { return ls->enumVideoFrameskip0; }
char* langEnumVideoFrameskip1(void) { return ls->enumVideoFrameskip1; }
char* langEnumVideoFrameskip2(void) { return ls->enumVideoFrameskip2; }
char* langEnumVideoFrameskip3(void) { return ls->enumVideoFrameskip3; }
char* langEnumVideoFrameskip4(void) { return ls->enumVideoFrameskip4; }
char* langEnumVideoFrameskip5(void) { return ls->enumVideoFrameskip5; }

char* langEnumD3DARAuto(void) { return ls->enumD3DARAuto; }
char* langEnumD3DARStretch(void) { return ls->enumD3DARStretch; }
char* langEnumD3DARPAL(void) { return ls->enumD3DARPAL; }
char* langEnumD3DARNTSC(void) { return ls->enumD3DARNTSC; }
char* langEnumD3DAR11(void) { return ls->enumD3DAR11; }

char* langEnumD3DCropNone(void) { return ls->enumD3DCropNone; }
char* langEnumD3DCropMSX1(void) { return ls->enumD3DCropMSX1; }
char* langEnumD3DCropMSX1Plus8(void) { return ls->enumD3DCropMSX1Plus8; }
char* langEnumD3DCropMSX2(void) { return ls->enumD3DCropMSX2; }
char* langEnumD3DCropMSX2Plus8(void) { return ls->enumD3DCropMSX2Plus8; }
char* langEnumD3DCropCustom(void) { return ls->enumD3DCropCustom; }

char* langPropD3DParametersGB(void) { return ls->propD3DParametersGB; }
char* langPropD3DAspectRatioText(void) { return ls->propD3DAspectRatioText; }
char* langPropD3DLinearFilteringText(void) { return ls->propD3DLinearFilteringText; }
char* langPropD3DForceHighResText(void) { return ls->propD3DForceHighResText; }
char* langPropD3DExtendBorderColorText(void) { return ls->propD3DExtendBorderColorText; }

char* langpropD3DCroppingGB(void) { return ls->propD3DCroppingGB; }
char* langpropD3DCroppingTypeText(void) { return ls->propD3DCroppingTypeText; }
char* langpropD3DCroppingLeftText(void) { return ls->propD3DCroppingLeftText; }
char* langpropD3DCroppingRightText(void) { return ls->propD3DCroppingRightText; }
char* langpropD3DCroppingTopText(void) { return ls->propD3DCroppingTopText; }
char* langpropD3DCroppingBottomText(void) { return ls->propD3DCroppingBottomText; }

char* langEnumSoundDrvNone(void) { return ls->enumSoundDrvNone; }
char* langEnumSoundDrvWMM(void) { return ls->enumSoundDrvWMM; }
char* langEnumSoundDrvDirectX(void) { return ls->enumSoundDrvDirectX; }

char* langEnumEmuSync1ms(void) { return ls->enumEmuSync1ms; }
char* langEnumEmuSyncAuto(void) { return ls->enumEmuSyncAuto; }
char* langEnumEmuSyncNone(void) { return ls->enumEmuSyncNone; }
char* langEnumEmuSyncVblank(void) { return ls->enumEmuSyncVblank; }
char* langEnumEmuAsyncVblank(void) { return ls->enumEmuAsyncVblank; }

char* langEnumControlsJoyNone(void) { return ls->enumControlsJoyNone; }
char* langEnumControlsJoyMouse(void) { return ls->enumControlsJoyMouse; }
char* langEnumControlsJoyTetrisDongle(void) { return ls->enumControlsJoyTetris2Dongle; }
char* langEnumControlsJoyMagicKeyDongle(void) { return ls->enumControlsJoyTMagicKeyDongle; }
char* langEnumControlsJoy2Button(void) { return ls->enumControlsJoy2Button; }
char* langEnumControlsJoyGunStick(void) { return ls->enumControlsJoyGunstick; }
char* langEnumControlsJoyAsciiLaser(void) { return ls->enumControlsJoyAsciiLaser; }
char* langEnumControlsJoyArkanoidPad(void) { return ls->enumControlsArkanoidPad; }
char* langEnumControlsJoyColeco(void) { return ls->enumControlsJoyColeco; }
    
char* langEnumDiskMsx35Dbl9Sect(void) { return ls->enumDiskMsx35Dbl9Sect; }
char* langEnumDiskMsx35Dbl8Sect(void) { return ls->enumDiskMsx35Dbl8Sect; }
char* langEnumDiskMsx35Sgl9Sect(void) { return ls->enumDiskMsx35Sgl9Sect; }
char* langEnumDiskMsx35Sgl8Sect(void) { return ls->enumDiskMsx35Sgl8Sect; }
char* langEnumDiskSvi525Dbl(void) { return ls->enumDiskSvi525Dbl; }
char* langEnumDiskSvi525Sgl(void) { return ls->enumDiskSvi525Sgl; }
char* langEnumDiskSf3Sgl(void) { return ls->enumDiskSf3Sgl; }


//----------------------
// Configuration related lines
//----------------------

char* langDlgSavePreview(void) { return ls->dlgSavePreview; }
char* langDlgSaveDate(void) { return ls->dlgSaveDate; }

char* langDlgRenderVideoCapture(void) { return ls->dlgRenderVideoCapture; }

char* langConfTitle(void) { return ls->confTitle; }
char* langConfConfigText(void) { return ls->confConfigText; }
char* langConfSlotLayout(void) { return ls->confSlotLayout; }
char* langConfMemory(void) { return ls->confMemory; }
char* langConfChipEmulation(void) { return ls->confChipEmulation; }
char* langConfChipExtras(void) { return ls->confChipExtras; }

char* langConfOpenRom(void) { return ls->confOpenRom; }
char* langConfSaveTitle(void) { return ls->confSaveTitle; }
char* langConfSaveText(void) { return ls->confSaveText; }
char* langConfSaveAsTitle(void) { return ls->confSaveAsTitle; }
char* langConfSaveAsMachineName(void) { return ls->confSaveAsMachineName; }
char* langConfDiscardTitle(void) { return ls->confDiscardTitle; }
char* langConfExitSaveTitle(void) { return ls->confExitSaveTitle; }
char* langConfExitSaveText(void) { return ls->confExitSaveText; }

char* langConfSlotLayoutGB(void) { return ls->confSlotLayoutGB; }
char* langConfSlotExtSlotGB(void) { return ls->confSlotExtSlotGB; }
char* langConfBoardGB(void) { return ls->confBoardGB; }
char* langConfBoardText(void) { return ls->confBoardText; }
char* langConfSlotPrimary(void) { return ls->confSlotPrimary; }
char* langConfSlotExpanded(void) { return ls->confSlotExpanded; }

char* langConfCartridge(void) { return ls->confSlotCart; }
char* langConfSlot(void) { return ls->confSlot; }
char* langConfSubslot(void) { return ls->confSubslot; }

char* langConfMemAdd(void) { return ls->confMemAdd; }
char* langConfMemEdit(void) { return ls->confMemEdit; }
char* langConfMemRemove(void) { return ls->confMemRemove; }
char* langConfMemSlot(void) { return ls->confMemSlot; }
char* langConfMemAddress(void) { return ls->confMemAddresss; }
char* langConfMemType(void) { return ls->confMemType; }
char* langConfMemRomImage(void) { return ls->confMemRomImage; }

char* langConfChipVideoGB(void) { return ls->confChipVideoGB; }
char* langConfChipVideoChip(void) { return ls->confChipVideoChip; }
char* langConfChipVideoRam(void) { return ls->confChipVideoRam; }
char* langConfChipSoundGB(void) { return ls->confChipSoundGB; }
char* langConfChipPsgStereoText(void) { return ls->confChipPsgStereoText; }

char* langConfCmosGB(void) { return ls->confCmosGB; }
char* langConfCmosEnableText(void) { return ls->confCmosEnable; }
char* langConfCmosBatteryText(void) { return ls->confCmosBattery; }

char* langConfChipCpuFreqGB(void) { return ls->confCpuFreqGB; }
char* langConfChipZ80FreqText(void) { return ls->confZ80FreqText; }
char* langConfChipR800FreqText(void) { return ls->confR800FreqText; }
char* langConfChipFdcGB(void) { return ls->confFdcGB; }
char* langConfChipFdcNumDrivesText(void) { return ls->confCFdcNumDrivesText; }

char* langConfEditMemTitle(void) { return ls->confEditMemTitle; }
char* langConfEditMemGB(void) { return ls->confEditMemGB; }
char* langConfEditMemType(void) { return ls->confEditMemType; }
char* langConfEditMemFile(void) { return ls->confEditMemFile; }
char* langConfEditMemAddress(void) { return ls->confEditMemAddress; }
char* langConfEditMemSize(void) { return ls->confEditMemSize; }
char* langConfEditMemSlot(void) { return ls->confEditMemSlot; }


//----------------------
// Shortcut lines
//----------------------

char* langShortcutKey(void) { return ls->shortcutKey; }
char* langShortcutDescription(void) { return ls->shortcutDescription; }

char* langShortcutSaveConfig(void) { return ls->shortcutSaveConfig; }
char* langShortcutOverwriteConfig(void) { return ls->shortcutOverwriteConfig; }
char* langShortcutExitConfig(void) { return ls->shortcutExitConfig; }
char* langShortcutDiscardConfig(void) { return ls->shortcutDiscardConfig; }
char* langShortcutSaveConfigAs(void) { return ls->shortcutSaveConfigAs; }
char* langShortcutConfigName(void) { return ls->shortcutConfigName; }
char* langShortcutNewProfile(void) { return ls->shortcutNewProfile; }
char* langShortcutConfigTitle(void) { return ls->shortcutConfigTitle; }
char* langShortcutAssign(void) { return ls->shortcutAssign; }
char* langShortcutPressText(void) { return ls->shortcutPressText; }
char* langShortcutScheme(void) { return ls->shortcutScheme; }
char* langShortcutCartInsert1(void) { return ls->shortcutCartInsert1; }
char* langShortcutCartRemove1(void) { return ls->shortcutCartRemove1; }
char* langShortcutCartInsert2(void) { return ls->shortcutCartInsert2; }
char* langShortcutCartRemove2(void) { return ls->shortcutCartRemove2; }
char* langShortcutCartSpecialMenu1(void) { return ls->shortcutSpecialMenu1; }
char* langShortcutCartSpecialMenu2(void) { return ls->shortcutSpecialMenu2; }
char* langShortcutCartAutoReset(void) { return ls->shortcutCartAutoReset; }
char* langShortcutDiskInsertA(void) { return ls->shortcutDiskInsertA; }
char* langShortcutDiskDirInsertA(void) { return ls->shortcutDiskDirInsertA; }
char* langShortcutDiskRemoveA(void) { return ls->shortcutDiskRemoveA; }
char* langShortcutDiskChangeA(void) { return ls->shortcutDiskChangeA; }
char* langShortcutDiskAutoResetA(void) { return ls->shortcutDiskAutoResetA; }
char* langShortcutDiskInsertB(void) { return ls->shortcutDiskInsertB; }
char* langShortcutDiskDirInsertB(void) { return ls->shortcutDiskDirInsertB; }
char* langShortcutDiskRemoveB(void) { return ls->shortcutDiskRemoveB; }
char* langShortcutCasInsert(void) { return ls->shortcutCasInsert; }
char* langShortcutCasEject(void) { return ls->shortcutCasEject; }
char* langShortcutCasAutorewind(void) { return ls->shortcutCasAutorewind; }
char* langShortcutCasReadOnly(void) { return ls->shortcutCasReadOnly; }
char* langShortcutCasSetPosition(void) { return ls->shortcutCasSetPosition; }
char* langShortcutCasRewind(void) { return ls->shortcutCasRewind; }
char* langShortcutCasSave(void) { return ls->shortcutCasSave; }
char* langShortcutPrnFormFeed(void) { return ls->shortcutPrnFormFeed; }
char* langShortcutCpuStateLoad(void) { return ls->shortcutCpuStateLoad; }
char* langShortcutCpuStateSave(void) { return ls->shortcutCpuStateSave; }
char* langShortcutCpuStateQload(void) { return ls->shortcutCpuStateQload; }
char* langShortcutCpuStateQsave(void) { return ls->shortcutCpuStateQsave; }
char* langShortcutAudioCapture(void) { return ls->shortcutAudioCapture; }
char* langShortcutScreenshotOrig(void) { return ls->shortcutScreenshotOrig; }
char* langShortcutScreenshotSmall(void) { return ls->shortcutScreenshotSmall; }
char* langShortcutScreenshotLarge(void) { return ls->shortcutScreenshotLarge; }
char* langShortcutQuit(void) { return ls->shortcutQuit; }
char* langShortcutRunPause(void) { return ls->shortcutRunPause; }
char* langShortcutStop(void) { return ls->shortcutStop; }
char* langShortcutResetHard(void) { return ls->shortcutResetHard; }
char* langShortcutResetSoft(void) { return ls->shortcutResetSoft; }
char* langShortcutResetClean(void) { return ls->shortcutResetClean; }
char* langShortcutSizeSmall(void) { return ls->shortcutSizeSmall; }
char* langShortcutSizeNormal(void) { return ls->shortcutSizeNormal; }
char* langShortcutSizeFullscreen(void) { return ls->shortcutSizeFullscreen; }
char* langShortcutSizeMinimized(void) { return ls->shortcutSizeMinimized; }
char* langShortcutToggleFullscren(void) { return ls->shortcutToggleFullscren; }
char* langShortcutVolumeIncrease(void) { return ls->shortcutVolumeIncrease; }
char* langShortcutVolumeDecrease(void) { return ls->shortcutVolumeDecrease; }
char* langShortcutVolumeMute(void) { return ls->shortcutVolumeMute; }
char* langShortcutVolumeStereo(void) { return ls->shortcutVolumeStereo; }
char* langShortcutSwitchMsxAudio(void) { return ls->shortcutSwitchMsxAudio; }
char* langShortcutSwitchFront(void) { return ls->shortcutSwitchFront; }
char* langShortcutSwitchPause(void) { return ls->shortcutSwitchPause; }
char* langShortcutToggleMouseLock(void) { return ls->shortcutToggleMouseLock; }
char* langShortcutEmuSpeedMax(void) { return ls->shortcutEmuSpeedMax; }
char* langShortcutEmuPlayReverse(void) { return ls->shortcutEmuPlayReverse; }
char* langShortcutEmuSpeedMaxToggle(void) { return ls->shortcutEmuSpeedToggle; }
char* langShortcutEmuSpeedNormal(void) { return ls->shortcutEmuSpeedNormal; }
char* langShortcutEmuSpeedInc(void) { return ls->shortcutEmuSpeedInc; }
char* langShortcutEmuSpeedDec(void) { return ls->shortcutEmuSpeedDec; }
char* langShortcutThemeSwitch(void) { return ls->shortcutThemeSwitch; }
char* langShortcutShowEmuProp(void) { return ls->shortcutShowEmuProp; }
char* langShortcutShowVideoProp(void) { return ls->shortcutShowVideoProp; }
char* langShortcutShowAudioProp(void) { return ls->shortcutShowAudioProp; }
char* langShortcutShowCtrlProp(void) { return ls->shortcutShowCtrlProp; }
char* langShortcutShowEffectsProp(void) { return ls->shortcutShowEffectsProp; }
char* langShortcutShowSettProp(void) { return ls->shortcutShowSettProp; }
char* langShortcutShowPorts(void) { return ls->shortcutShowPorts; }
char* langShortcutShowLanguage(void) { return ls->shortcutShowLanguage; }
char* langShortcutShowMachines(void) { return ls->shortcutShowMachines; }
char* langShortcutShowShortcuts(void) { return ls->shortcutShowShortcuts; }
char* langShortcutShowKeyboard(void) { return ls->shortcutShowKeyboard; }
char* langShortcutShowMixer(void) { return ls->shortcutShowMixer; }
char* langShortcutShowDebugger(void) { return ls->shortcutShowDebugger; }
char* langShortcutShowTrainer(void) { return ls->shortcutShowTrainer; }
char* langShortcutShowHelp(void) { return ls->shortcutShowHelp; }
char* langShortcutShowAbout(void) { return ls->shortcutShowAbout; }
char* langShortcutShowFiles(void) { return ls->shortcutShowFiles; }
char* langShortcutToggleSpriteEnable(void) { return ls->shortcutToggleSpriteEnable; }
char* langShortcutToggleFdcTiming(void) { return ls->shortcutToggleFdcTiming; }
char* langShortcutToggleNoSpriteLimits(void) { return ls->shortcutToggleNoSpriteLimits; }
char* langShortcutEnableMsxKeyboardQuirk(void) { return ls->shortcutEnableMsxKeyboardQuirk; }
char* langShortcutToggleCpuTrace(void) { return ls->shortcutToggleCpuTrace; }
char* langShortcutVideoLoad(void) { return ls->shortcutVideoLoad; }
char* langShortcutVideoPlay(void) { return ls->shortcutVideoPlay; }
char* langShortcutVideoRecord(void) { return ls->shortcutVideoRecord; }
char* langShortcutVideoStop(void) { return ls->shortcutVideoStop; }
char* langShortcutVideoRender(void) { return ls->shortcutVideoRender; }


//----------------------
// Keyboard config lines
//----------------------

char* langKeyconfigSelectedKey(void) { return ls->keyconfigSelectedKey; }
char* langKeyconfigMappedTo(void) { return ls->keyconfigMappedTo; }
char* langKeyconfigMappingScheme(void) { return ls->keyconfigMappingScheme; }


//----------------------
// Rom type lines
//----------------------

char* langRomTypeStandard(void) { return ls->romTypeStandard; }
char* langRomTypeMsxdos2(void) { return "MSXDOS 2"; }
char* langRomTypeKonamiScc(void) { return "Konami SCC"; }
char* langRomTypeManbow2(void) { return "Manbow 2"; }
char* langRomTypeMegaFlashRomScc(void) { return "Mega Flash Rom SCC"; }
char* langRomTypeKonami(void) { return "Konami"; }
char* langRomTypeAscii8(void) { return "ASCII 8"; }
char* langRomTypeAscii16(void) { return "ASCII 16"; }
char* langRomTypeGameMaster2(void) { return "Game Master 2 (SRAM)"; }
char* langRomTypeAscii8Sram(void) { return "ASCII 8 (SRAM)"; }
char* langRomTypeAscii16Sram(void) { return "ASCII 16 (SRAM)"; }
char* langRomTypeRtype(void) { return "R-Type"; }
char* langRomTypeCrossblaim(void) { return "Cross Blaim"; }
char* langRomTypeHarryFox(void) { return "Harry Fox"; }
char* langRomTypeMajutsushi(void) { return "Konami Majutsushi"; }
char* langRomTypeZenima80(void) { return ls->romTypeZenima80; }
char* langRomTypeZenima90(void) { return ls->romTypeZenima90; }
char* langRomTypeZenima126(void) { return ls->romTypeZenima126; }
char* langRomTypeScc(void) { return "SCC"; }
char* langRomTypeSccPlus(void) { return "SCC-I"; }
char* langRomTypeSnatcher(void) { return "The Snatcher"; }
char* langRomTypeSdSnatcher(void) { return "SD Snatcher"; }
char* langRomTypeSccMirrored(void) { return ls->romTypeSccMirrored; }
char* langRomTypeSccExtended(void) { return ls->romTypeSccExtended; }
char* langRomTypeFmpac(void) { return "FMPAC (SRAM)"; }
char* langRomTypeFmpak(void) { return "FMPAK"; }
char* langRomTypeKonamiGeneric(void) { return ls->romTypeKonamiGeneric; }
char* langRomTypeSuperPierrot(void) { return "Super Pierrot"; }
char* langRomTypeMirrored(void) { return ls->romTypeMirrored; }
char* langRomTypeNormal(void) { return ls->romTypeNormal; }
char* langRomTypeDiskPatch(void) { return ls->romTypeDiskPatch; }
char* langRomTypeCasPatch(void) { return ls->romTypeCasPatch; }
char* langRomTypeTc8566afFdc(void) { return ls->romTypeTc8566afFdc; }
char* langRomTypeTc8566afTrFdc(void) { return ls->romTypeTc8566afTrFdc; }
char* langRomTypeMicrosolFdc(void) { return ls->romTypeMicrosolFdc; }
char* langRomTypeNationalFdc(void) { return ls->romTypeNationalFdc; }
char* langRomTypePhilipsFdc(void) { return ls->romTypePhilipsFdc; }
char* langRomTypeSvi707Fdc(void) { return ls->romTypeSvi707Fdc; }
char* langRomTypeSvi738Fdc(void) { return ls->romTypeSvi738Fdc; }
char* langRomTypeMappedRam(void) { return ls->romTypeMappedRam; }
char* langRomTypeMirroredRam1k(void) { return ls->romTypeMirroredRam1k; }
char* langRomTypeMirroredRam2k(void) { return ls->romTypeMirroredRam2k; }
char* langRomTypeNormalRam(void) { return ls->romTypeNormalRam; }
char* langRomTypeKanji(void) { return "Kanji"; }
char* langRomTypeHolyQuran(void) { return "Holy Quran"; }
char* langRomTypeMatsushitaSram(void) { return "Matsushita SRAM"; }
char* langRomTypeMasushitaSramInv(void) { return "Matsushita SRAM - Turbo 5.37MHz"; }
char* langRomTypePanasonic8(void)  { return "Panasonic FM 8kB SRAM"; }
char* langRomTypePanasonicWx16(void) { return "Panasonic WX 16kB SRAM"; }
char* langRomTypePanasonic16(void) { return "Panasonic 16kB SRAM"; }
char* langRomTypePanasonic32(void) { return "Panasonic 32kB SRAM"; }
char* langRomTypePanasonicModem(void) { return "Panasonic Modem"; }
char* langRomTypeDram(void) { return "Panasonic DRAM"; }
char* langRomTypeBunsetsu(void) { return "Bunsetsu"; }
char* langRomTypeJisyo(void) { return "Jisyo"; }
char* langRomTypeKanji12(void) { return "Kanji12"; }
char* langRomTypeNationalSram(void) { return "National (SRAM)"; }
char* langRomTypeS1985(void) { return "S1985"; }
char* langRomTypeS1990(void) { return "S1990"; }
char* langRomTypeTurborPause(void) { return ls->romTypeTurborPause; }
char* langRomTypeF4deviceNormal(void) { return ls->romTypeF4deviceNormal; }
char* langRomTypeF4deviceInvert(void) { return ls->romTypeF4deviceInvert; }
char* langRomTypeMsxMidi(void) { return "MSX-MIDI"; }
char* langRomTypeMsxMidiExternal(void) { return "MSX-MIDI external"; }
char* langRomTypeTurborTimer(void) { return ls->romTypeTurborTimer; }
char* langRomTypeKoei(void) { return "Koei (SRAM)"; }
char* langRomTypeBasic(void) { return "Basic ROM"; }
char* langRomTypeHalnote(void) { return "Halnote"; }
char* langRomTypeLodeRunner(void) { return "Lode Runner"; }
char* langRomTypeNormal4000(void) { return ls->romTypeNormal4000; }
char* langRomTypeNormalC000(void) { return ls->romTypeNormalC000; }
char* langRomTypeKonamiSynth(void) { return "Konami Synthesizer"; }
char* langRomTypeKonamiKbdMast(void) { return "Konami Keyboard Master"; }
char* langRomTypeKonamiWordPro(void) { return "Konami Word Pro"; }
char* langRomTypePac(void) { return "PAC (SRAM)"; }
char* langRomTypeMegaRam(void) { return "MegaRAM"; }
char* langRomTypeMegaRam128(void) { return "128kB MegaRAM"; }
char* langRomTypeMegaRam256(void) { return "256kB MegaRAM"; }
char* langRomTypeMegaRam512(void) { return "512kB MegaRAM"; }
char* langRomTypeMegaRam768(void) { return "768kB MegaRAM"; }
char* langRomTypeMegaRam2mb(void) { return "2MB MegaRAM"; }
char* langRomTypeExtRam(void) { return ls->romTypeExtRam; }
char* langRomTypeExtRam16(void) { return ls->romTypeExtRam16; }
char* langRomTypeExtRam32(void) { return ls->romTypeExtRam32; }
char* langRomTypeExtRam48(void) { return ls->romTypeExtRam48; }
char* langRomTypeExtRam64(void) { return ls->romTypeExtRam64; }
char* langRomTypeExtRam512(void) { return ls->romTypeExtRam512; }
char* langRomTypeExtRam1mb(void) { return ls->romTypeExtRam1mb; }
char* langRomTypeExtRam2mb(void) { return ls->romTypeExtRam2mb; }
char* langRomTypeExtRam4mb(void) { return ls->romTypeExtRam4mb; }
char* langRomTypeMsxMusic(void) { return "MSX Music"; }
char* langRomTypeMsxAudio(void) { return "MSX Audio"; }
char* langRomTypeY8950(void) { return "Y8950"; }
char* langRomTypeMoonsound(void) { return "Moonsound"; }
char* langRomTypeSvi328Cart(void) { return ls->romTypeSvi328Cart; }
char* langRomTypeSvi328Fdc(void) { return ls->romTypeSvi328Fdc; }
char* langRomTypeSvi328Prn(void) { return ls->romTypeSvi328Prn; }
char* langRomTypeSvi328Uart(void) { return ls->romTypeSvi328Uart; }
char* langRomTypeSvi328col80(void) { return ls->romTypeSvi328col80; }
char* langRomTypeSvi328RsIde(void) { return ls->romTypeSvi328RsIde; }
char* langRomTypeSvi727col80(void) { return ls->romTypeSvi727col80; }
char* langRomTypeColecoCart(void) { return ls->romTypeColecoCart; }
char* langRomTypeSg1000Cart(void) { return ls->romTypeSg1000Cart; }
char* langRomTypeSc3000Cart(void) { return ls->romTypeSc3000Cart; }
char* langRomTypeTheCastle(void) { return "SG-1000 The Castle"; }
char* langRomTypeSonyHbi55(void) { return "Sony HBI-55"; }
char* langRomTypeMsxPrinter(void) { return ls->romTypeMsxPrinter; }
char* langRomTypeTurborPcm(void) { return ls->romTypeTurborPcm; }
char* langRomTypeGameReader(void) { return "GameReader"; }
char* langRomTypeSunriseIde(void) { return "Sunrise IDE"; }
char* langRomTypeBeerIde(void) { return "Beer IDE"; }
char* langRomTypeGide(void) { return "GIDE"; }
char* langRomTypeVmx80(void) { return "Microsol VMX-80"; }
char* langRomTypeNms8280Digitiz(void) { return ls->romTypeNms8280Digitiz; }
char* langRomTypeHbiV1Digitiz(void) { return ls->romTypeHbiV1Digitiz; }
char* langRomTypePlayBall(void) { return "Sony Playball"; }
char* langRomTypeFmdas(void) { return "F&M Direct Assembler System"; }
char* langRomTypeSfg01(void) { return "Yamaha SFG-01"; }
char* langRomTypeSfg05(void) { return "Yamaha SFG-05"; }
char* langRomTypeObsonet(void) { return "Obsonet"; }
char* langRomTypeDumas(void) { return "Dumas"; }
char* langRomTypeNoWind(void) { return "NoWind USB"; }
char* langRomTypeSegaBasic(void) { return "Sega Basic"; }
char* langRomTypeMegaSCSI(void) { return "MEGA-SCSI"; }
char* langRomTypeMegaSCSI128(void) { return "128kb MEGA-SCSI"; }
char* langRomTypeMegaSCSI256(void) { return "256kb MEGA-SCSI"; }
char* langRomTypeMegaSCSI512(void) { return "512kb MEGA-SCSI"; }
char* langRomTypeMegaSCSI1mb(void) { return "1MB MEGA-SCSI"; }
char* langRomTypeEseRam(void) { return "Ese-RAM"; }
char* langRomTypeEseRam128(void) { return "128kb Ese-RAM"; }
char* langRomTypeEseRam256(void) { return "256kb Ese-RAM"; }
char* langRomTypeEseRam512(void) { return "512kb Ese-RAM"; }
char* langRomTypeEseRam1mb(void) { return "1MB Ese-RAM"; }
char* langRomTypeWaveSCSI(void) { return "WAVE-SCSI"; }
char* langRomTypeWaveSCSI128(void) { return "128kb WAVE-SCSI"; }
char* langRomTypeWaveSCSI256(void) { return "256kb WAVE-SCSI"; }
char* langRomTypeWaveSCSI512(void) { return "512kb WAVE-SCSI"; }
char* langRomTypeWaveSCSI1mb(void) { return "1MB WAVE-SCSI"; }
char* langRomTypeEseSCC(void) { return "Ese-SCC"; }
char* langRomTypeEseSCC128(void) { return "128kb Ese-SCC"; }
char* langRomTypeEseSCC256(void) { return "256kb Ese-SCC"; }
char* langRomTypeEseSCC512(void) { return "512kb Ese-SCC"; }
char* langRomTypeGoudaSCSI(void) { return "Gouda SCSI"; }

//----------------------
// Debug type lines
//----------------------

char* langDbgMemVisible(void) { return ls->dbgMemVisible; }
char* langDbgMemRamNormal(void) { return ls->dbgMemRamNormal; }
char* langDbgMemRamMapped(void) { return ls->dbgMemRamMapped; }
char* langDbgMemVram(void) { return "VRAM"; }
char* langDbgMemYmf278(void) { return ls->dbgMemYmf278; }
char* langDbgMemAy8950(void) { return ls->dbgMemAy8950; }
char* langDbgMemScc(void) { return ls->dbgMemScc; }
char* langDbgCallstack(void) { return ls->dbgCallstack; }
char* langDbgRegs(void) { return ls->dbgRegs; }
char* langDbgRegsCpu(void) { return ls->dbgRegsCpu; }
char* langDbgRegsYmf262(void) { return ls->dbgRegsYmf262; }
char* langDbgRegsYmf278(void) { return ls->dbgRegsYmf278; }
char* langDbgRegsAy8950(void) { return ls->dbgRegsAy8950; }
char* langDbgRegsYm2413(void) { return ls->dbgRegsYm2413; }
char* langDbgDevRamMapper(void) { return ls->dbgDevRamMapper; }
char* langDbgDevRam(void) { return ls->dbgDevRam; }
char* langDbgDevIdeBeer(void) { return "Beer IDE"; }
char* langDbgDevIdeGide(void) { return "GIDE"; }
char* langDbgDevIdeSviRs(void) { return "SVI-328 RS IDE"; }
char* langDbgDevScsiGouda(void) { return "Gouda SCSI"; }
char* langDbgDevF4Device(void) { return ls->dbgDevF4Device; }
char* langDbgDevFmpac(void) { return "FMPAC"; }
char* langDbgDevFmpak(void) { return "FMPAK"; }
char* langDbgDevKanji(void) { return "Kanji"; }
char* langDbgDevKanji12(void) { return "Kanji 12"; }
char* langDbgDevKonamiKbd(void) { return "Konami Keyboard Master"; }
char* langDbgDevKorean80(void) { return ls->dbgDevKorean80; }
char* langDbgDevKorean90(void) { return ls->dbgDevKorean90; }
char* langDbgDevKorean128(void) { return ls->dbgDevKorean128; }
char* langDbgDevMegaRam(void) { return "Mega RAM"; }
char* langDbgDevFdcMicrosol(void) { return ls->dbgDevFdcMicrosol; }
char* langDbgDevMoonsound(void) { return "Moonsound"; }
char* langDbgDevMsxAudio(void) { return "MSX Audio"; }
char* langDbgDevMsxAudioMidi(void) { return "MSX Audio MIDI"; }
char* langDbgDevMsxMusic(void) { return "MSX Music"; }
char* langDbgDevPrinter(void) { return ls->dbgDevPrinter; }
char* langDbgDevRs232(void) { return "RS232"; }
char* langDbgDevS1990(void) { return "S1990"; }
char* langDbgDevSfg05(void) { return "Yamaha SFG-05"; }
char* langDbgDevHbi55(void) { return "Sony HBI-55"; }
char* langDbgDevSviFdc(void) { return ls->dbgDevSviFdc; }
char* langDbgDevSviPrn(void) { return ls->dbgDevSviPrn; }
char* langDbgDevSvi80Col(void) { return ls->dbgDevSvi80Col; }
char* langDbgDevPcm(void) { return "PCM"; }
char* langDbgDevMatsushita(void) { return "Matsushita"; }
char* langDbgDevS1985(void) { return "S1985"; }
char* langDbgDevCrtc6845(void) { return "CRTC6845"; }
char* langDbgDevTms9929A(void) { return "TMS9929A"; }
char* langDbgDevTms99x8A(void) { return "TMS99x8A"; }
char* langDbgDevV9938(void) { return "V9938"; }
char* langDbgDevV9958(void) { return "V9958"; }
char* langDbgDevZ80(void) { return "Z80"; }
char* langDbgDevMsxMidi(void) { return "MSX MIDI"; }
char* langDbgDevPpi(void) { return "PPI"; }
char* langDbgDevRtc(void) { return ls->dbgDevRtc; }
char* langDbgDevTrPause(void) { return ls->dbgDevTrPause; }
char* langDbgDevAy8910(void) { return "AY8910 PSG"; }
char* langDbgDevScc(void) { return "SCC"; }


//----------------------
// Debug type lines
// Note: Can only be translated to european languages
//----------------------
char* langAboutScrollThanksTo(void) { return ls->aboutScrollThanksTo; }
char* langAboutScrollAndYou(void) { return ls->aboutScrollAndYou; }
