/*****************************************************************************
** $Source: /cygdrive/d/Private/_SVNROOT/bluemsx/blueMSX/Src/Emulator/Actions.h,v $
**
** $Revision: 1.34 $
**
** $Date: 2007-03-24 05:20:32 $
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
#ifndef ACTIONS_H
#define ACTIONS_H

#include "Properties.h"
#include "VideoRender.h"
#include "AudioMixer.h"

void actionInit(Video* video, Properties* properties, Mixer* mixer);
void actionSetAudioCaptureSetDirectory(char* dir, char* prefix);
void actionSetVideoCaptureSetDirectory(char* dir, char* prefix);
void actionSetQuickSaveSetDirectory(char* dir, char* prefix);

void actionCartInsert(int cartNo);
void actionCartRemove(int cartNo);
void actionDiskInsert(int diskNo);
void actionDiskInsertDir(int diskNo);
void actionDiskInsertNew(int diskNo);
void actionDiskRemove(int diskNo);

void actionHarddiskInsert(int diskNo);
void actionHarddiskInsertCdrom(int diskNo);
void actionHarddiskInsertNew(int diskNo);
void actionHarddiskInsertDir(int diskNo);
void actionHarddiskRemove(int diskNo);
void actionHarddiskRemoveAll(void);

void actionQuit(void);
void actionLoadState(void);
void actionSaveState(void);
void actionQuickLoadState(void);
void actionQuickSaveState(void);
void actionCartInsert1(void);
void actionCartInsert2(void);
void actionEmuTogglePause(void);
void actionEmuStep(void);
void actionEmuStepBack(void);
void actionEmuStop(void);
void actionDiskInsertA(void);
void actionDiskInsertB(void);
void actionDiskDirInsertA(void);
void actionDiskDirInsertB(void);
void actionMaxSpeedSet(void);
void actionMaxSpeedRelease(void);
void actionStartPlayReverse(void);
void actionStopPlayReverse(void);
void actionDiskQuickChange(void);
void actionWindowSizeSmall(void);
void actionWindowSizeNormal(void);
void actionWindowSizeMinimized(void);
void actionWindowSizeFullscreen(void);
void actionEmuSpeedNormal(void);
void actionEmuSpeedDecrease(void);
void actionEmuSpeedIncrease(void);
void actionCasInsert(void);
void actionCasRewind(void);
void actionCasSetPosition(void);
void actionEmuResetSoft(void);
void actionEmuResetHard(void);
void actionEmuResetClean(void);
void actionScreenCapture(void);
void actionScreenCaptureUnfilteredSmall(void);
void actionScreenCaptureUnfilteredLarge(void);
void actionNextTheme(void);
void actionCasRemove(void);
void actionDiskRemoveA(void);
void actionDiskRemoveB(void);
void actionCartRemove1(void);
void actionCartRemove2(void);
void actionCasSave(void);
void actionPropShowEmulation(void);
void actionPropShowVideo(void);
void actionPropShowAudio(void);
void actionPropShowSettings(void);
void actionPropShowDisk(void);
void actionPropShowApearance(void);
void actionPropShowPorts(void);
void actionPropShowEffects(void);
void actionOptionsShowLanguage(void);
void actionToolsShowMachineEditor(void);
void actionToolsShowShorcutEditor(void);
void actionToolsShowKeyboardEditor(void);
void actionToolsShowMixer(void);
void actionToolsShowDebugger(void);
void actionToolsShowTrainer(void);
void actionHelpShowHelp(void);
void actionHelpShowAbout(void);
void actionMaximizeWindow(void);
void actionMinimizeWindow(void);
void actionCloseWindow(void);
void actionVolumeIncrease(void);
void actionVolumeDecrease(void);

void actionMenuSpecialCart1(int x, int y);
void actionMenuSpecialCart2(int x, int y);
void actionMenuReset(int x, int y);
void actionMenuRun(int x, int y);
void actionMenuFile(int x, int y);
void actionMenuCart1(int x, int y);
void actionMenuCart2(int x, int y);
void actionMenuHarddisk(int x, int y);
void actionMenuDiskA(int x, int y);
void actionMenuDiskB(int x, int y);
void actionMenuCassette(int x, int y);
void actionMenuPrinter(int x, int y);
void actionMenuJoyPort1(int x, int y);
void actionMenuJoyPort2(int x, int y);
void actionMenuZoom(int x, int y);
void actionMenuOptions(int x, int y);
void actionMenuHelp(int x, int y);
void actionMenuTools(int x, int y);

void actionToggleCartAutoReset(void);
void actionToggleDiskAutoReset(void);
void actionToggleCasAutoRewind(void);
void actionToggleSpriteEnable(void);
void actionToggleFdcTiming(void);
void actionToggleNoSpriteLimits(void);
void actionToggleMsxKeyboardQuirk(void);
void actionToggleMsxAudioSwitch(void);
void actionToggleFrontSwitch(void);
void actionTogglePauseSwitch(void);
void actionToggleWaveCapture(void);
void actionToggleMouseCapture(void);
void actionVideoCaptureLoad(void);
void actionVideoCapturePlay(void);
void actionVideoCaptureRec(void);
void actionVideoCaptureStop(void);
void actionVideoCaptureSave(void);
void actionMaxSpeedToggle(void);
void actionFullscreenToggle(void);
void actionCasToggleReadonly(void);
void actionVolumeToggleStereo(void);

void actionToggleHorizontalStretch(void);
void actionToggleVerticalStretch(void);
void actionToggleScanlinesEnable(void);
void actionToggleDeinterlaceEnable(void);
void actionToggleBlendFrameEnable(void);
void actionToggleRfModulatorEnable(void);

void actionMuteToggleMaster(void);
void actionMuteTogglePsg(void);
void actionMuteTogglePcm(void);
void actionMuteToggleIo(void);
void actionMuteToggleScc(void);
void actionMuteToggleKeyboard(void);
void actionMuteToggleMsxMusic(void);
void actionMuteToggleMsxAudio(void);
void actionMuteToggleMoonsound(void);
void actionMuteToggleYamahaSfg(void);
void actionMuteToggleMidi(void);

void actionPrinterForceFormFeed(void);

void actionSetCartAutoReset(int value);
void actionSetDiskAutoResetA(int value);
void actionSetCasAutoRewind(int value);
void actionSetSpriteEnable(int value);
void actionSetMsxAudioSwitch(int value);
void actionSetFdcTiming(int value);
void actionSetNoSpriteLimits(int value);
void actionSetFrontSwitch(int value);
void actionSetPauseSwitch(int value);
void actionSetWaveCapture(int value);
void actionSetMouseCapture(int value);
void actionSetFullscreen(int value);
void actionSetCasReadonly(int value);
void actionSetVolumeMute(int value);
void actionSetVolumeStereo(int value);

void actionVideoSetGamma(int value);
void actionVideoSetBrightness(int value);
void actionVideoSetContrast(int value);
void actionVideoSetSaturation(int value);
void actionVideoSetScanlines(int value);
void actionVideoSetRfModulation(int value);
void actionVideoSetColorMode(int value);
void actionVideoSetFilter(int value);
void actionVideoEnableMon1(int value);
void actionVideoEnableMon2(int value);
void actionVideoEnableMon3(int value);

void actionVolumeSetMaster(int value);
void actionVolumeSetPsg(int value);
void actionVolumeSetPcm(int value);
void actionVolumeSetIo(int value);
void actionVolumeSetIo(int value);
void actionVolumeSetScc(int value);
void actionVolumeSetKeyboard(int value);
void actionVolumeSetMsxMusic(int value);
void actionVolumeSetMsxAudio(int value);
void actionVolumeSetMoonsound(int value);
void actionVolumeSetYamahaSfg(int value);
void actionVolumeSetMidi(int value);
void actionPanSetPsg(int value);
void actionPanSetPcm(int value);
void actionPanSetIo(int value);
void actionPanSetScc(int value);
void actionPanSetKeyboard(int value);
void actionPanSetMsxMusic(int value);
void actionPanSetMsxAudio(int value);
void actionPanSetMoonsound(int value);
void actionPanSetYamahaSfg(int value);
void actionPanSetMidi(int value);

void actionRenshaSetLevel(int value);
void actionEmuSpeedSet(int value);

void actionKeyPress(int keyCode, int pressed);

#endif

