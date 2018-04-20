/*****************************************************************************
 **
 ** CocoaMSX: MSX Emulator for Mac OS X
 ** http://www.cocoamsx.com
 ** Copyright (C) 2012-2016 Akop Karapetyan
 **
 ** Sound engine based on SDL_audio:
 **
 **   SDL - Simple DirectMedia Layer
 **   Copyright (C) 1997-2012 Sam Lantinga (slouken@libsdl.org)
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
#import "CMCocoaSound.h"

#import "CMEmulatorController.h"

@interface CMCocoaSound ()

- (BOOL)initializeWithSampleRate:(UInt32)sampleRate
                        channels:(Int16)channels
                      bufferSize:(UInt32)aBufferSize
                           mixer:(Mixer*)aMixer
                  bitsPerChannel:(UInt16)bitsPerChannel;
- (BOOL)destroy;

- (void)mixSoundFromBuffer:(Int16*)mixBuffer
                     bytes:(UInt32)bytes;
- (void)renderSoundToStream:(AudioBufferList*)ioData;

@end

@implementation CMCocoaSound

static Int32 mixSound(void *dummy, Int16 *buffer, UInt32 count);
static OSStatus audioCallback(void *inRefCon,
                              AudioUnitRenderActionFlags *ioActionFlags,
                              const AudioTimeStamp *inTimeStamp,
                              UInt32 inBusNumber, UInt32 inNumberFrames,
                              AudioBufferList *ioData);

- (id)init
{
    if ((self = [super init]))
    {
        isPaused = NO;
        isReady = NO;
        
        buffer = NULL;
        __buffer = NULL;
    }
    
    return self;
}

- (void)dealloc
{
    [self destroy];
}

#pragma mark - Private Methods

- (BOOL)initializeWithSampleRate:(UInt32)sampleRate
                        channels:(Int16)channels
                      bufferSize:(UInt32)aBufferSize
                           mixer:(Mixer*)aMixer
                  bitsPerChannel:(UInt16)bitsPerChannel
{
    OSStatus result = noErr;
    AudioComponent comp;
    AudioComponentDescription desc;
    struct AURenderCallbackStruct callback;
    AudioStreamBasicDescription requestedDesc;
    
    // Setup a AudioStreamBasicDescription with the requested format
    requestedDesc.mFormatID = kAudioFormatLinearPCM;
    requestedDesc.mFormatFlags = kLinearPCMFormatFlagIsPacked;
    requestedDesc.mChannelsPerFrame = channels;
    requestedDesc.mSampleRate = sampleRate;
    
    requestedDesc.mBitsPerChannel = bitsPerChannel;
    requestedDesc.mFormatFlags |= kLinearPCMFormatFlagIsSignedInteger;
    
    requestedDesc.mFramesPerPacket = 1;
    requestedDesc.mBytesPerFrame = requestedDesc.mBitsPerChannel * requestedDesc.mChannelsPerFrame / 8;
    requestedDesc.mBytesPerPacket = requestedDesc.mBytesPerFrame * requestedDesc.mFramesPerPacket;
    
    // Locate the default output audio unit
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_DefaultOutput;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    
    comp = AudioComponentFindNext(NULL, &desc);
    if (!comp)
        return NO;
    
    // Open & initialize the default output audio unit
    result = AudioComponentInstanceNew(comp, &outputAudioUnit);
    if (result != noErr)
        return NO;
    
    result = AudioUnitInitialize(outputAudioUnit);
    if (result != noErr)
        return NO;
    
    // Set the input format of the audio unit
    result = AudioUnitSetProperty(outputAudioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input, 0, &requestedDesc,
                                  sizeof(requestedDesc));
    
    if (result != noErr)
        return NO;
    
    // Set the audio callback
    callback.inputProc = audioCallback;
    callback.inputProcRefCon = (__bridge void * _Nullable)(self);
    result = AudioUnitSetProperty(outputAudioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input, 0, &callback,
                                  sizeof(callback));
    
    if (result != noErr)
        return NO;
    
	UInt16 samples = channels;
    aBufferSize = aBufferSize * sampleRate / 1000 * sizeof(Int16) / 4;
    while (samples < aBufferSize) samples *= 2;
    
    __bufferSize = bitsPerChannel / 8;
	__bufferSize *= channels;
	__bufferSize *= samples;
    __bufferOffset = __bufferSize;
    __buffer = malloc(__bufferSize);
    
    // Finally, start processing of the audio unit
    result = AudioOutputUnitStart (outputAudioUnit);
    if (result != noErr)
        return NO;
    
    bufferSize = 1;
    while (bufferSize < 4 * __bufferSize) bufferSize *= 2;
    bufferMask = bufferSize - 1;
    buffer = (UInt8*)calloc(1, bufferSize);
    mixer = aMixer;
    bytesPerSample = bitsPerChannel / 8;
    
    mixerSetStereo(mixer, channels == 2);
    mixerSetWriteCallback(mixer, mixSound, (__bridge void *)(self), __bufferSize / bytesPerSample);
    
    isReady = YES;
    
    [self resume];
    
#ifdef DEBUG
    NSLog(@"CocoaSound: initialized");
#endif
    
    return YES;
}

- (BOOL)destroy
{
    if (!isReady)
        return YES;
    
    mixerSetWriteCallback(mixer, NULL, NULL, 0);
    
    BOOL success = YES;
    OSStatus result;
    struct AURenderCallbackStruct callback;
    
    result = AudioOutputUnitStop (outputAudioUnit);
    if (result != noErr)
        success = NO;
    
    callback.inputProc = 0;
    callback.inputProcRefCon = 0;
    result = AudioUnitSetProperty(outputAudioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input, 0, &callback,
                                  sizeof(callback));
    
    if (result != noErr)
        success = NO;
    
    result = AudioComponentInstanceDispose(outputAudioUnit);
    if (result != noErr)
        success = NO;
    
    if (__buffer)
    {
        free(__buffer);
        __buffer = NULL;
    }
    
    if (buffer)
    {
        free(buffer);
        buffer = NULL;
    }
    
    isReady = NO;
    
#ifdef DEBUG
    NSLog(@"CocoaSound: destroyed");
#endif
    
    return success;
}

- (void)renderSoundToStream:(AudioBufferList*)ioData
{
    UInt32 remaining, len;
    AudioBuffer *abuf;
    void *ptr;
    
    if (isPaused || !isReady)
    {
        for (int i = 0; i < ioData->mNumberBuffers; i++)
        {
            abuf = &ioData->mBuffers[i];
            memset(abuf->mData, 0, abuf->mDataByteSize);
        }
        
        return;
    }
    
    for (int i = 0; i < ioData->mNumberBuffers; i++)
    {
        abuf = &ioData->mBuffers[i];
        remaining = abuf->mDataByteSize;
        ptr = abuf->mData;
        
        while (remaining > 0)
        {
            if (__bufferOffset >= __bufferSize)
            {
                memset(__buffer, 0, __bufferSize);
                
                @synchronized(self)
                {
                    int length = __bufferSize;
                    UInt32 avail = (readPtr - writePtr) & bufferMask;
                    oldLen = length;
                    if ((UInt32)length > avail)
                    {
                        memset(__buffer + avail, 0, length - avail);
                        length = avail;
                    }
                    
                    memcpy(__buffer, buffer + readPtr, length);
                    readPtr = (readPtr + length) & bufferMask;
                }
                
                __bufferOffset = 0;
            }
            
            len = __bufferSize - __bufferOffset;
            if (len > remaining)
                len = remaining;
            
            memcpy(ptr, __buffer + __bufferOffset, len);
            ptr = (char *)ptr + len;
            remaining -= len;
            __bufferOffset += len;
        }
    }
}

- (void)mixSoundFromBuffer:(Int16*)mixBuffer
                     bytes:(UInt32)bytes
{
    UInt32 avail;
    
    if (!isReady)
        return;
    
    bytes *= bytesPerSample;
    
    if (skipCount > 0)
    {
        if (bytes <= skipCount)
        {
            skipCount -= bytes;
            return;
        }
        
        bytes -= skipCount;
        skipCount = 0;
    }
    
    @synchronized(self)
    {
        avail = (writePtr - readPtr) & bufferMask;
        if (bytes < avail && 0)
        {
            skipCount = bufferSize / 2;
        }
        else
        {
            if (writePtr + bytes > bufferSize)
            {
                UInt32 count1 = bufferSize - writePtr;
                UInt32 count2 = bytes - count1;
                
                memcpy(buffer + writePtr, mixBuffer, count1);
                memcpy(buffer, mixBuffer, count2);
                
                writePtr = count2;
            }
            else
            {
                memcpy(buffer + writePtr, mixBuffer, bytes);
                writePtr += bytes;
            }
        }
    }
}

#pragma mark - Public Methods

- (void)pause
{
    if (!isPaused)
        isPaused = YES;
}

- (void)resume
{
    if (isPaused)
        isPaused = NO;
}

#pragma mark - Miscellaneous Callbacks

extern CMEmulatorController *theEmulator;

static OSStatus audioCallback(void *inRefCon,
                              AudioUnitRenderActionFlags *ioActionFlags,
                              const AudioTimeStamp *inTimeStamp,
                              UInt32 inBusNumber, UInt32 inNumberFrames,
                              AudioBufferList *ioData)
{
    @autoreleasepool
    {
        CMCocoaSound *sound = (__bridge CMCocoaSound *) inRefCon;
        [sound renderSoundToStream:ioData];
    }
    
    return 0;
}

static Int32 mixSound(void *dummy, Int16 *buffer, UInt32 count)
{
    @autoreleasepool
    {
        CMCocoaSound *sound = (__bridge CMCocoaSound *) dummy;
        [sound mixSoundFromBuffer:buffer bytes:count];
    }
    
    return 0;
}

#pragma mark - BlueMSX Callbacks

void archSoundCreate(Mixer* mixer, UInt32 sampleRate, UInt32 bufferSize, Int16 channels)
{
    @autoreleasepool
    {
        [theEmulator.sound initializeWithSampleRate:sampleRate
                                           channels:channels
                                         bufferSize:bufferSize
                                              mixer:mixer
                                     bitsPerChannel:16];
    }
}

void archSoundDestroy()
{
    @autoreleasepool
    {
        [theEmulator.sound destroy];
    }
}

void archSoundResume()
{
    @autoreleasepool
    {
        [theEmulator.sound resume];
    }
}

void archSoundSuspend()
{
    @autoreleasepool
    {
        [theEmulator.sound pause];
    }
}

@end
