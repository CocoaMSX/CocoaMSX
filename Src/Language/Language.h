/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Language/Language.h,v $
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
#ifndef LANGUAGE_H
#define LANGUAGE_H

typedef enum { 
    EMU_LANG_ENGLISH     = 0, 
    EMU_LANG_SWEDISH     = 1, 
    EMU_LANG_JAPANESE    = 2, 
    EMU_LANG_PORTUGUESE  = 3, 
    EMU_LANG_FRENCH      = 4, 
    EMU_LANG_DUTCH       = 5,
    EMU_LANG_SPANISH     = 6,
    EMU_LANG_ITALIAN     = 7,
    EMU_LANG_FINNISH     = 8,
    EMU_LANG_KOREAN      = 9,
    EMU_LANG_GERMAN      = 10,
    EMU_LANG_POLISH      = 11,
    EMU_LANG_CHINESESIMP = 12,
    EMU_LANG_CHINESETRAD = 13,
    EMU_LANG_RUSSIAN     = 14,
    EMU_LANG_CATALAN     = 15,
    EMU_LANG_COUNT       = 16,
    EMU_LANG_UNKNOWN     = -1 
} EmuLanguageType;

void langInit(void);

int langSetLanguage(EmuLanguageType languageType);
EmuLanguageType langGetLanguage(void);
EmuLanguageType langFromName(char* name, int translate);
const char* langToName(EmuLanguageType languageType, int translate);
EmuLanguageType langGetType(int i);


//----------------------
// Language lines
//----------------------

char* langLangCatalan(void);
char* langLangChineseSimplified(void);
char* langLangChineseTraditional(void);
char* langLangDutch(void);
char* langLangEnglish(void);
char* langLangFinnish(void);
char* langLangFrench(void);
char* langLangGerman(void);
char* langLangItalian(void);
char* langLangJapanese(void);
char* langLangKorean(void);
char* langLangPolish(void);
char* langLangPortuguese(void);
char* langLangRussian(void);
char* langLangSpanish(void);
char* langLangSwedish(void);


//----------------------
// Generic lines
//----------------------

char* langTextDevice(void);
char* langTextFilename(void);
char* langTextFile(void);
char* langTextNone(void);
char* langTextUnknown(void);


//----------------------
// Warning and Error lines
//----------------------

char* langWarningTitle(void);
char* langWarningDiscardChanges(void);
char* langWarningOverwriteFile(void);
char* langErrorTitle(void);
char* langErrorEnterFullscreen(void);
char* langErrorDirectXFailed(void);
char* langErrorNoRomInZip(void);
char* langErrorNoDskInZip(void);
char* langErrorNoCasInZip(void);
char* langErrorNoHelp(void);
char* langErrorStartEmu(void);
char* langErrorPortableReadonly(void);


//----------------------
// File related lines
//----------------------

char* langFileRom(void);
char* langFileAll(void);
char* langFileCpuState(void);
char* langFileVideoCapture(void);
char* langFileDisk(void);
char* langFileCas(void);
char* langFileAvi(void);


//----------------------
// Menu related lines
//----------------------

char* langMenuNoRecentFiles(void);
char* langMenuInsert(void);
char* langMenuEject(void);

char* langMenuCartGameReader(void);
char* langMenuCartIde(void);
char* langMenuCartBeerIde(void);
char* langMenuCartGIde(void);
char* langMenuCartSunriseIde(void);
char* langMenuCartScsi(void);
char* langMenuCartMegaSCSI(void);
char* langMenuCartWaveSCSI(void);
char* langMenuCartGoudaSCSI(void);
char* langMenuCartSCC(void);
char* langMenuCartJoyrexPsg(void);
char* langMenuCartSCCPlus(void);
char* langMenuCartFMPac(void);
char* langMenuCartPac(void);
char* langMenuCartHBI55(void);
char* langMenuCartInsertSpecial(void);
char* langMenuCartExternalRam(void);
char* langMenuCartMegaRam(void);
char* langMenuCartEseRam(void);
char* langMenuCartEseSCC(void);
char* langMenuCartMegaFlashRom(void);

char* langMenuDiskDirInsert(void);
char* langMenuDiskDirInsertCdrom(void);
char* langMenuDiskInsertNew(void);
char* langMenuDiskAutoStart(void);
char* langMenuCartAutoReset(void);

char* langMenuCasRewindAfterInsert(void);
char* langMenuCasUseReadOnly(void);
char* langMenuCasSaveAs(void);
char* langMenuCasSetPosition(void);
char* langMenuCasRewind(void);

char* langMenuVideoLoad(void);
char* langMenuVideoPlay(void);
char* langMenuVideoRecord(void);
char* langMenuVideoRecording(void);
char* langMenuVideoRecAppend(void);
char* langMenuVideoStop(void);
char* langMenuVideoRender(void);

char* langMenuPrnFormfeed(void);

char* langMenuZoomNormal(void);
char* langMenuZoomDouble(void);
char* langMenuZoomFullscreen(void);

char* langMenuPropsEmulation(void);
char* langMenuPropsVideo(void);
char* langMenuPropsSound(void);
char* langMenuPropsControls(void);
char* langMenuPropsSettings(void);
char* langMenuPropsFile(void);
char* langMenuPropsDisk(void);
char* langMenuPropsLanguage(void);
char* langMenuPropsPorts(void);
char* langMenuPropsEffects(void);

char* langMenuVideoSource(void);
char* langMenuVideoSourceDefault(void);
char* langMenuVideoChipAutodetect(void);
char* langMenuVideoInSource(void);
char* langMenuVideoInBitmap(void);

char* langMenuEthInterface(void);

char* langMenuHelpHelp(void);
char* langMenuHelpAbout(void);

char* langMenuFileCart(void);
char* langMenuFileDisk(void);
char* langMenuFileCas(void);
char* langMenuFilePrn(void);
char* langMenuFileLoadState(void);
char* langMenuFileSaveState(void);
char* langMenuFileQLoadState(void);
char* langMenuFileQSaveState(void);
char* langMenuFileCaptureAudio(void);
char* langMenuFileCaptureVideo(void);
char* langMenuFileScreenShot(void);
char* langMenuFileExit(void);
char* langMenuFileHarddisk(void);
char* langMenuFileHarddiskNoPresent(void);
char* langMenuFileHarddiskRemoveAll(void);

char* langMenuRunRun(void);
char* langMenuRunPause(void);
char* langMenuRunStop(void);
char* langMenuRunSoftReset(void);
char* langMenuRunHardReset(void);
char* langMenuRunCleanReset(void);

char* langMenuToolsMachine(void);
char* langMenuToolsShortcuts(void);
char* langMenuToolsCtrlEditor(void);
char* langMenuToolsMixer(void);
char* langMenuToolsLoadMemory(void);
char* langMenuToolsDebugger(void);
char* langMenuToolsTrainer(void);
char* langMenuToolsTraceLogger(void);

char* langMenuFile(void);
char* langMenuRun(void);
char* langMenuWindow(void);
char* langMenuOptions(void);
char* langMenuTools(void);
char* langMenuHelp(void);


//----------------------
// Dialog related lines
//----------------------

char* langDlgOK(void);
char* langDlgOpen(void);
char* langDlgCancel(void);
char* langDlgSave(void);
char* langDlgSaveAs(void);
char* langDlgRun(void);
char* langDlgClose(void);

char* langDlgLoadRom(void);
char* langDlgLoadDsk(void);
char* langDlgLoadCas(void);
char* langDlgLoadRomDskCas(void);
char* langDlgLoadRomDesc(void);
char* langDlgLoadDskDesc(void);
char* langDlgLoadCasDesc(void);
char* langDlgLoadRomDskCasDesc(void);
char* langDlgLoadState(void);
char* langDlgLoadVideoCapture(void);
char* langDlgSaveState(void);
char* langDlgSaveCassette(void);
char* langDlgSaveVideoClipAs(void);
char* langDlgAmountCompleted(void);
char* langDlgInsertRom1(void);
char* langDlgInsertRom2(void);
char* langDlgInsertDiskA(void);
char* langDlgInsertDiskB(void);
char* langDlgInsertHarddisk(void);
char* langDlgInsertCas(void);
char* langDlgRomType(void);
char* langDlgDiskSize(void);

char* langDlgTapeTitle(void);
char* langDlgTapeFrameText(void);
char* langDlgTapeCurrentPos(void);
char* langDlgTapeSetPosText(void);
char* langDlgTapeCustom(void);
char* langDlgTabPosition(void);
char* langDlgTabType(void);
char* langDlgTabFilename(void);
char* langDlgTapeTotalTime(void);
char* langDlgZipReset(void);

char* langDlgAboutTitle(void);

char* langDlgLangLangText(void);
char* langDlgLangTitle(void);

char* langDlgAboutAbout(void);
char* langDlgAboutVersion(void);
char* langDlgAboutBuildNumber(void);
char* langDlgAboutBuildDate(void);
char* langDlgAboutCreat(void);
char* langDlgAboutDevel(void);
char* langDlgAboutThanks(void);
char* langDlgAboutLisence(void);

char* langDlgSavePreview(void);
char* langDlgSaveDate(void);

char* langDlgRenderVideoCapture(void);


//----------------------
// Properties related lines
//----------------------

char* langPropTitle(void);
char* langPropEmulation(void);
char* langPropD3D(void);
char* langPropVideo(void);
char* langPropSound(void);
char* langPropControls(void);
char* langPropPerformance(void);
char* langPropEffects(void);
char* langPropSettings(void);
char* langPropFile(void);
char* langPropDisk(void);
char* langPropPorts(void);

char* langPropEmuGeneralGB(void);
char* langPropEmuFamilyText(void);
char* langPropEmuMemoryGB(void);
char* langPropEmuRamSizeText(void);
char* langPropEmuVramSizeText(void);
char* langPropEmuSpeedGB(void);
char* langPropEmuSpeedText(void);
char* langPropEmuFrontSwitchGB(void);
char* langPropEmuFrontSwitch(void);
char* langPropEmuFdcTiming(void);
char* langPropEmuReversePlay(void);
char* langPropEmuNoSpriteLimits(void);
char* langPropEnableMsxKeyboardQuirk(void);
char* langPropEmuPauseSwitch(void);
char* langPropEmuAudioSwitch(void);
char* langPropVideoFreqText(void);
char* langPropVideoFreqAuto(void);
char* langPropSndOversampleText(void);
char* langPropSndYkInGB(void);
char* langPropSndMidiInGB(void);
char* langPropSndMidiOutGB(void);
char* langPropSndMidiChannel(void);
char* langPropSndMidiAll(void);

char* langPropMonMonGB(void);
char* langPropMonTypeText(void);
char* langPropMonEmuText(void);
char* langPropVideoTypeText(void);
char* langPropWindowSizeText(void);
char* langPropMonHorizStretch(void);
char* langPropMonVertStretch(void);
char* langPropMonDeInterlace(void);
char* langPropMonBlendFrames(void);
char* langPropMonBrightness(void);
char* langPropMonContrast(void);
char* langPropMonSaturation(void);
char* langPropMonGamma(void);
char* langPropMonScanlines(void);
char* langPropMonColorGhosting(void);
char* langPropMonEffectsGB(void);

char* langPropPerfVideoDrvGB(void);
char* langPropPerfVideoDispDrvText(void);
char* langPropPerfFrameSkipText(void);
char* langPropPerfAudioDrvGB(void);
char* langPropPerfAudioDrvText(void);
char* langPropPerfAudioBufSzText(void);
char* langPropPerfEmuGB(void);
char* langPropPerfSyncModeText(void);
char* langPropFullscreenResText(void);

char* langPropSndChipEmuGB(void);
char* langPropSndMsxMusic(void);
char* langPropSndMsxAudio(void);
char* langPropSndMoonsound(void);
char* langPropSndMt32ToGm(void);

char* langPropPortsLptGB(void);
char* langPropPortsComGB(void);
char* langPropPortsLptText(void);
char* langPropPortsCom1Text(void);
char* langPropPortsNone(void);
char* langPropPortsSimplCovox(void);
char* langPropPortsFile(void);
char* langPropPortsComFile(void);
char* langPropPortsOpenLogFile(void);
char* langPropPortsEmulateMsxPrn(void);

char* langPropSetFileHistoryGB(void);
char* langPropSetFileHistorySize(void);
char* langPropSetFileHistoryClear(void);
char* langPropWindowsEnvGB(void);
char* langPropScreenSaver(void);
char* langPropFileTypes(void);
char* langPropDisableWinKeys(void);
char* langPropPriorityBoost(void);
char* langPropScreenshotPng(void);
char* langPropEjectMediaOnExit(void);
char* langPropClearFileHistory(void);
char* langPropOpenRomGB(void);
char* langPropDefaultRomType(void);
char* langPropGuessRomType(void);

char* langPropSettDefSlotGB(void);
char* langPropSettDefSlots(void);
char* langPropSettDefSlot(void);
char* langPropSettDefDrives(void);
char* langPropSettDefDrive(void);

char* langPropThemeGB(void);
char* langPropTheme(void);

char* langPropCdromGB(void);
char* langPropCdromMethod(void);
char* langPropCdromMethodNone(void);
char* langPropCdromMethodIoctl(void);
char* langPropCdromMethodAspi(void);
char* langPropCdromDrive(void);

char* langPropD3DParametersGB(void);
char* langPropD3DAspectRatioText(void);
char* langPropD3DLinearFilteringText(void);
char* langPropD3DForceHighResText(void);
char* langPropD3DExtendBorderColorText(void);

char* langpropD3DCroppingGB(void);
char* langpropD3DCroppingTypeText(void);
char* langpropD3DCroppingLeftText(void);
char* langpropD3DCroppingRightText(void);
char* langpropD3DCroppingTopText(void);
char* langpropD3DCroppingBottomText(void);

//----------------------
// Dropdown related lines
//----------------------

char* langEnumVideoMonColor(void);
char* langEnumVideoMonGrey(void);
char* langEnumVideoMonGreen(void);
char* langEnumVideoMonAmber(void);

char* langEnumVideoTypePAL(void);
char* langEnumVideoTypeNTSC(void);

char* langEnumVideoEmuNone(void);
char* langEnumVideoEmuYc(void);
char* langEnumVideoEmuMonitor(void);
char* langEnumVideoEmuYcBlur(void);
char* langEnumVideoEmuComp(void);
char* langEnumVideoEmuCompBlur(void);
char* langEnumVideoEmuScale2x(void);
char* langEnumVideoEmuHq2x(void);
char* langEnumVideoEmuStreched(void);

char* langEnumVideoSize1x(void);
char* langEnumVideoSize2x(void);
char* langEnumVideoSizeFullscreen(void);

char* langEnumVideoDrvDirectDrawHW(void);
char* langEnumVideoDrvDirectDraw(void);
char* langEnumVideoDrvGDI(void);
char* langEnumVideoDrvD3D(void);

char* langEnumVideoFrameskip0(void);
char* langEnumVideoFrameskip1(void);
char* langEnumVideoFrameskip2(void);
char* langEnumVideoFrameskip3(void);
char* langEnumVideoFrameskip4(void);
char* langEnumVideoFrameskip5(void);

char* langEnumD3DARAuto(void);
char* langEnumD3DARStretch(void);
char* langEnumD3DARPAL(void);
char* langEnumD3DARNTSC(void);
char* langEnumD3DAR11(void);

char* langEnumD3DCropNone(void);
char* langEnumD3DCropMSX1(void);
char* langEnumD3DCropMSX1Plus8(void);
char* langEnumD3DCropMSX2(void);
char* langEnumD3DCropMSX2Plus8(void);
char* langEnumD3DCropCustom(void);

char* langEnumSoundDrvNone(void);
char* langEnumSoundDrvWMM(void);
char* langEnumSoundDrvDirectX(void);

char* langEnumEmuSync1ms(void);
char* langEnumEmuSyncAuto(void);
char* langEnumEmuSyncNone(void);
char* langEnumEmuSyncVblank(void);
char* langEnumEmuAsyncVblank(void);

char* langEnumControlsJoyNone(void);
char* langEnumControlsJoyTetrisDongle(void);
char* langEnumControlsJoyMagicKeyDongle(void);
char* langEnumControlsJoyMouse(void);
char* langEnumControlsJoy2Button(void);
char* langEnumControlsJoyGunStick(void);
char* langEnumControlsJoyAsciiLaser(void);
char* langEnumControlsJoyArkanoidPad(void);
char* langEnumControlsJoyColeco(void);
    
char* langEnumDiskMsx35Dbl9Sect(void);
char* langEnumDiskMsx35Dbl8Sect(void);
char* langEnumDiskMsx35Sgl9Sect(void);
char* langEnumDiskMsx35Sgl8Sect(void);
char* langEnumDiskSvi525Dbl(void);
char* langEnumDiskSvi525Sgl(void);
char* langEnumDiskSf3Sgl(void);

//----------------------
// Configuration related lines
//----------------------

char* langConfTitle(void);
char* langConfConfigText(void);
char* langConfSlotLayout(void);
char* langConfMemory(void);
char* langConfChipEmulation(void);
char* langConfChipExtras(void);

char* langConfOpenRom(void);
char* langConfSaveTitle(void);
char* langConfSaveAsTitle(void);
char* langConfSaveText(void);
char* langConfSaveAsMachineName(void);
char* langConfDiscardTitle(void);
char* langConfExitSaveTitle(void);
char* langConfExitSaveText(void);

char* langConfSlotLayoutGB(void);
char* langConfSlotExtSlotGB(void);
char* langConfBoardGB(void);
char* langConfBoardText(void);
char* langConfSlotPrimary(void);
char* langConfSlotExpanded(void);

char* langConfCartridge(void);
char* langConfSlot(void);
char* langConfSubslot(void);

char* langConfMemAdd(void);
char* langConfMemEdit(void);
char* langConfMemRemove(void);
char* langConfMemSlot(void);
char* langConfMemAddress(void);
char* langConfMemType(void);
char* langConfMemRomImage(void);

char* langConfChipVideoGB(void);
char* langConfChipVideoChip(void);
char* langConfChipVideoRam(void);
char* langConfChipSoundGB(void);
char* langConfChipPsgStereoText(void);

char* langConfCmosGB(void);
char* langConfCmosEnableText(void);
char* langConfCmosBatteryText(void);

char* langConfChipCpuFreqGB(void);
char* langConfChipZ80FreqText(void);
char* langConfChipR800FreqText(void);
char* langConfChipFdcGB(void);
char* langConfChipFdcNumDrivesText(void);

char* langConfEditMemTitle(void);
char* langConfEditMemGB(void);
char* langConfEditMemType(void);
char* langConfEditMemFile(void);
char* langConfEditMemAddress(void);
char* langConfEditMemSize(void);
char* langConfEditMemSlot(void);


//----------------------
// Shortcut lines
//----------------------

char* langShortcutKey(void);
char* langShortcutDescription(void);

char* langShortcutSaveConfig(void);
char* langShortcutOverwriteConfig(void);
char* langShortcutExitConfig(void);
char* langShortcutDiscardConfig(void);
char* langShortcutSaveConfigAs(void);
char* langShortcutConfigName(void);
char* langShortcutNewProfile(void);
char* langShortcutConfigTitle(void);
char* langShortcutAssign(void);
char* langShortcutPressText(void);
char* langShortcutScheme(void);
char* langShortcutCartInsert1(void);
char* langShortcutCartRemove1(void);
char* langShortcutCartInsert2(void);
char* langShortcutCartRemove2(void);
char* langShortcutCartSpecialMenu1(void);
char* langShortcutCartSpecialMenu2(void);
char* langShortcutCartAutoReset(void);
char* langShortcutDiskInsertA(void);
char* langShortcutDiskDirInsertA(void);
char* langShortcutDiskRemoveA(void);
char* langShortcutDiskChangeA(void);
char* langShortcutDiskAutoResetA(void);
char* langShortcutDiskInsertB(void);
char* langShortcutDiskDirInsertB(void);
char* langShortcutDiskRemoveB(void);
char* langShortcutCasInsert(void);
char* langShortcutCasEject(void);
char* langShortcutCasAutorewind(void);
char* langShortcutCasReadOnly(void);
char* langShortcutCasSetPosition(void);
char* langShortcutCasRewind(void);
char* langShortcutCasSave(void);
char* langShortcutPrnFormFeed(void);
char* langShortcutCpuStateLoad(void);
char* langShortcutCpuStateSave(void);
char* langShortcutCpuStateQload(void);
char* langShortcutCpuStateQsave(void);
char* langShortcutAudioCapture(void);
char* langShortcutScreenshotOrig(void);
char* langShortcutScreenshotSmall(void);
char* langShortcutScreenshotLarge(void);
char* langShortcutQuit(void);
char* langShortcutRunPause(void);
char* langShortcutStop(void);
char* langShortcutResetHard(void);
char* langShortcutResetSoft(void);
char* langShortcutResetClean(void);
char* langShortcutSizeSmall(void);
char* langShortcutSizeNormal(void);
char* langShortcutSizeMinimized(void);
char* langShortcutSizeFullscreen(void);
char* langShortcutToggleFullscren(void);
char* langShortcutVolumeIncrease(void);
char* langShortcutVolumeDecrease(void);
char* langShortcutVolumeMute(void);
char* langShortcutVolumeStereo(void);
char* langShortcutSwitchMsxAudio(void);
char* langShortcutSwitchFront(void);
char* langShortcutSwitchPause(void);
char* langShortcutToggleMouseLock(void);
char* langShortcutEmuSpeedMax(void);
char* langShortcutEmuPlayReverse(void);
char* langShortcutEmuSpeedMaxToggle(void);
char* langShortcutEmuSpeedNormal(void);
char* langShortcutEmuSpeedInc(void);
char* langShortcutEmuSpeedDec(void);
char* langShortcutThemeSwitch(void);
char* langShortcutShowEmuProp(void);
char* langShortcutShowVideoProp(void);
char* langShortcutShowAudioProp(void);
char* langShortcutShowCtrlProp(void);
char* langShortcutShowEffectsProp(void);
char* langShortcutShowSettProp(void);
char* langShortcutShowPorts(void);
char* langShortcutShowLanguage(void);
char* langShortcutShowMachines(void);
char* langShortcutShowShortcuts(void);
char* langShortcutShowKeyboard(void);
char* langShortcutShowMixer(void);
char* langShortcutShowDebugger(void);
char* langShortcutShowTrainer(void);
char* langShortcutShowHelp(void);
char* langShortcutShowAbout(void);
char* langShortcutShowFiles(void);
char* langShortcutToggleSpriteEnable(void);
char* langShortcutToggleFdcTiming(void);
char* langShortcutToggleNoSpriteLimits(void);
char* langShortcutEnableMsxKeyboardQuirk(void);
char* langShortcutToggleCpuTrace(void);
char* langShortcutVideoLoad(void);
char* langShortcutVideoPlay(void);
char* langShortcutVideoRecord(void);
char* langShortcutVideoStop(void);
char* langShortcutVideoRender(void);


//----------------------
// Keyboard config lines
//----------------------

char* langKeyconfigSelectedKey(void);
char* langKeyconfigMappedTo(void);
char* langKeyconfigMappingScheme(void);


//----------------------
// Rom type lines
//----------------------

char* langRomTypeStandard(void);
char* langRomTypeMsxdos2(void);
char* langRomTypeKonamiScc(void);
char* langRomTypeManbow2(void);
char* langRomTypeMegaFlashRomScc(void);
char* langRomTypeKonami(void);
char* langRomTypeAscii8(void);
char* langRomTypeAscii16(void);
char* langRomTypeGameMaster2(void);
char* langRomTypeAscii8Sram(void);
char* langRomTypeAscii16Sram(void);
char* langRomTypeRtype(void);
char* langRomTypeCrossblaim(void);
char* langRomTypeHarryFox(void);
char* langRomTypeMajutsushi(void);
char* langRomTypeZenima80(void);
char* langRomTypeZenima90(void);
char* langRomTypeZenima126(void);
char* langRomTypeScc(void);
char* langRomTypeSccPlus(void);
char* langRomTypeSnatcher(void);
char* langRomTypeSdSnatcher(void);
char* langRomTypeSccMirrored(void);
char* langRomTypeSccExtended(void);
char* langRomTypeFmpac(void);
char* langRomTypeFmpak(void);
char* langRomTypeKonamiGeneric(void);
char* langRomTypeSuperPierrot(void);
char* langRomTypeMirrored(void);
char* langRomTypeNormal(void);
char* langRomTypeDiskPatch(void);
char* langRomTypeCasPatch(void);
char* langRomTypeTc8566afFdc(void);
char* langRomTypeTc8566afTrFdc(void);
char* langRomTypeMicrosolFdc(void);
char* langRomTypeNationalFdc(void);
char* langRomTypePhilipsFdc(void);
char* langRomTypeSvi707Fdc(void);
char* langRomTypeSvi738Fdc(void);
char* langRomTypeMappedRam(void);
char* langRomTypeMirroredRam1k(void);
char* langRomTypeMirroredRam2k(void);
char* langRomTypeNormalRam(void);
char* langRomTypeKanji(void);
char* langRomTypeHolyQuran(void);
char* langRomTypeMatsushitaSram(void);
char* langRomTypeMasushitaSramInv(void);
char* langRomTypePanasonic8(void);
char* langRomTypePanasonicWx16(void);
char* langRomTypePanasonic16(void);
char* langRomTypePanasonic32(void);
char* langRomTypePanasonicModem(void);
char* langRomTypeDram(void);
char* langRomTypeBunsetsu(void);
char* langRomTypeJisyo(void);
char* langRomTypeKanji12(void);
char* langRomTypeNationalSram(void);
char* langRomTypeS1985(void);
char* langRomTypeS1990(void);
char* langRomTypeTurborPause(void);
char* langRomTypeF4deviceNormal(void);
char* langRomTypeF4deviceInvert(void);
char* langRomTypeMsxMidi(void);
char* langRomTypeMsxMidiExternal(void);
char* langRomTypeTurborTimer(void);
char* langRomTypeKoei(void);
char* langRomTypeBasic(void);
char* langRomTypeHalnote(void);
char* langRomTypeLodeRunner(void);
char* langRomTypeNormal4000(void);
char* langRomTypeNormalC000(void);
char* langRomTypeKonamiSynth(void);
char* langRomTypeKonamiKbdMast(void);
char* langRomTypeKonamiWordPro(void);
char* langRomTypePac(void);
char* langRomTypeMegaRam(void);
char* langRomTypeMegaRam128(void);
char* langRomTypeMegaRam256(void);
char* langRomTypeMegaRam512(void);
char* langRomTypeMegaRam768(void);
char* langRomTypeMegaRam2mb(void);
char* langRomTypeExtRam(void);
char* langRomTypeExtRam16(void);
char* langRomTypeExtRam32(void);
char* langRomTypeExtRam48(void);
char* langRomTypeExtRam64(void);
char* langRomTypeExtRam512(void);
char* langRomTypeExtRam1mb(void);
char* langRomTypeExtRam2mb(void);
char* langRomTypeExtRam4mb(void);
char* langRomTypeMsxMusic(void);
char* langRomTypeMsxAudio(void);
char* langRomTypeY8950(void);
char* langRomTypeMoonsound(void);
char* langRomTypeSvi328Cart(void);
char* langRomTypeSvi328Fdc(void);
char* langRomTypeSvi328Prn(void);
char* langRomTypeSvi328Uart(void);
char* langRomTypeSvi328col80(void);
char* langRomTypeSvi328RsIde(void);
char* langRomTypeSvi727col80(void);
char* langRomTypeColecoCart(void);
char* langRomTypeSg1000Cart(void);
char* langRomTypeSc3000Cart(void);
char* langRomTypeTheCastle(void);
char* langRomTypeSegaBasic(void);
char* langRomTypeSonyHbi55(void);
char* langRomTypeMsxPrinter(void);
char* langRomTypeTurborPcm(void);
char* langRomTypeGameReader(void);
char* langRomTypeSunriseIde(void);
char* langRomTypeBeerIde(void);
char* langRomTypeGide(void);
char* langRomTypeVmx80(void);
char* langRomTypeNms8280Digitiz(void);
char* langRomTypeHbiV1Digitiz(void);
char* langRomTypePlayBall(void);
char* langRomTypeFmdas(void);
char* langRomTypeSfg01(void);
char* langRomTypeSfg05(void);
char* langRomTypeObsonet(void);
char* langRomTypeDumas(void);
char* langRomTypeNoWind(void);
char* langRomTypeMegaSCSI(void);
char* langRomTypeMegaSCSI128(void);
char* langRomTypeMegaSCSI256(void);
char* langRomTypeMegaSCSI512(void);
char* langRomTypeMegaSCSI1mb(void);
char* langRomTypeEseRam(void);
char* langRomTypeEseRam128(void);
char* langRomTypeEseRam256(void);
char* langRomTypeEseRam512(void);
char* langRomTypeEseRam1mb(void);
char* langRomTypeWaveSCSI(void);
char* langRomTypeWaveSCSI128(void);
char* langRomTypeWaveSCSI256(void);
char* langRomTypeWaveSCSI512(void);
char* langRomTypeWaveSCSI1mb(void);
char* langRomTypeEseSCC(void);
char* langRomTypeEseSCC128(void);
char* langRomTypeEseSCC256(void);
char* langRomTypeEseSCC512(void);
char* langRomTypeGoudaSCSI(void);

//----------------------
// Debug type lines
//----------------------

char* langDbgMemVisible(void);
char* langDbgMemRamNormal(void);
char* langDbgMemRamMapped(void);
char* langDbgMemVram(void);
char* langDbgMemYmf278(void);
char* langDbgMemAy8950(void);
char* langDbgMemScc(void);

char* langDbgCallstack(void);

char* langDbgRegs(void);
char* langDbgRegsCpu(void);
char* langDbgRegsYmf262(void);
char* langDbgRegsYmf278(void);
char* langDbgRegsAy8950(void);
char* langDbgRegsYm2413(void);

char* langDbgDevRamMapper(void);
char* langDbgDevRam(void);
char* langDbgDevIdeBeer(void);
char* langDbgDevIdeGide(void);
char* langDbgDevIdeSviRs(void);
char* langDbgDevScsiGouda(void);
char* langDbgDevF4Device(void);
char* langDbgDevFmpac(void);
char* langDbgDevFmpak(void);
char* langDbgDevKanji(void);
char* langDbgDevKanji12(void);
char* langDbgDevKonamiKbd(void);
char* langDbgDevKorean80(void);
char* langDbgDevKorean90(void);
char* langDbgDevKorean128(void);
char* langDbgDevMegaRam(void);
char* langDbgDevFdcMicrosol(void);
char* langDbgDevMoonsound(void);
char* langDbgDevMsxAudio(void);
char* langDbgDevMsxAudioMidi(void);
char* langDbgDevMsxMusic(void);
char* langDbgDevPrinter(void);
char* langDbgDevRs232(void);
char* langDbgDevS1990(void);
char* langDbgDevSfg05(void);
char* langDbgDevHbi55(void);
char* langDbgDevSviFdc(void);
char* langDbgDevSviPrn(void);
char* langDbgDevSvi80Col(void);
char* langDbgDevPcm(void);
char* langDbgDevMatsushita(void);
char* langDbgDevS1985(void);
char* langDbgDevCrtc6845(void);
char* langDbgDevTms9929A(void);
char* langDbgDevTms99x8A(void);
char* langDbgDevV9938(void);
char* langDbgDevV9958(void);
char* langDbgDevZ80(void);
char* langDbgDevMsxMidi(void);
char* langDbgDevPpi(void);
char* langDbgDevRtc(void);
char* langDbgDevTrPause(void);
char* langDbgDevAy8910(void);
char* langDbgDevScc(void);


//----------------------
// Debug type lines
// Note: Can only be translated to european languages
//----------------------
char* langAboutScrollThanksTo(void);
char* langAboutScrollAndYou(void);

#endif

