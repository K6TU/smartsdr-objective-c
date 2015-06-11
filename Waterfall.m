//
//  Waterfall.m
//  VITA Engine
//
//  Created by STU PHILLIPS on 2/4/15.
//  Copyright (c) 2015 STU PHILLIPS. All rights reserved.
//
// LICENSE TERMS:
// Stu Phillips, K6TU is the author and copyright of this software.
// Copyright is assigned to Ridgelift, VC LLC.
//
// All rights are reserved.  Third parties may use this software under
// the following terms:
//
// Educational, Non-commercial and Open Source use:
// ------------------------------------------------
// Any individual(s) or educational institutions may use this software at
// no charge subject to the following conditions:
// - K6TU Copyright is clearly acknowledged in the software
//
// If the software is developed other than for personal use and is distributed
// in any form;
// - Software incoporating the K6TU code is provided free of charge to end users
// - Source code of the package/software including the K6TU code must be Open Source
// - Source code of the package/software including the k6TU code must be publicly
//   available on the Internet via github or similar repository system
//
// Commercial Use
// --------------
// The incorporation of the K6TU software in a proprietary product regardless of
// whether the product is sold for a fee, bundled with another product at no cost
// or in any use by a for-profit organization is expressly prohibited without a
// specific license agreement from Stu Phillips, K6TU and Ridgelift VC, LLC.
//
// Violation of these Copyright terms will be protected by US & International law.
//

#import "Waterfall.h"
#import "Radio.h"


@interface Waterfall () <RadioParser>
@property (weak, readwrite, nonatomic) Radio *radio;                         // The Radio which owns this panadaptor
@property (weak, readwrite, nonatomic) Panafall *panafall;                   // Panafall associated with this waterfall
@property (readwrite, nonatomic) int xPixels;                                // Size of waterfall width in pixels
@property (strong, readwrite, nonatomic) NSString *streamId;                 // Identifier of this waterfall (STRING)
@property (readwrite, nonatomic) BOOL wide;                                  // State of preselector for associated SCU (BOOL)
@property (readwrite, nonatomic) int capacity;                               // Capacity maximum indicator (INT)
@property (readwrite, nonatomic) int available;                              // Capacity available (INT)
@property (strong, readwrite, nonatomic) NSString *panadaptorId;             // Panadaptor linked to this waterfall (if any)
@property (readwrite, nonatomic) UInt32 timecode;                            // Time code of last tile received
@property (readwrite, nonatomic) UInt32 droppedTiles;                        // Count of tile dropped because received after current timecode

@property (strong, nonatomic) NSDictionary *waterfallTokens;

@end


enum waterfallToken {
    waterfallNullToken=0,
    xPixelsToken,
    centerToken,
    bandwidthToken,
    lineDurationToken,
    rfGainToken,
    rxAntToken,
    wideToken,
    loopaToken,
    loopbToken,
    bandToken,
    daxIqToken,
    daxIqRateToken,
    capacityToken,
    availableToken,
    panadaptorToken,
    colorGainToken,
    autoBlackToken,
    blackLevelToken,
    gradientIndexToken,
    xvtrToken,
};



@implementation Waterfall

- (void) initWaterfallTokens {
    self.waterfallTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [NSNumber numberWithInteger:xPixelsToken], @"x_pixels",
                            [NSNumber numberWithInteger:centerToken], @"center",
                            [NSNumber numberWithInteger:bandwidthToken], @"bandwidth",
                            [NSNumber numberWithInteger:lineDurationToken], @"line_duration",
                            [NSNumber numberWithInteger:rfGainToken], @"rfgain",
                            [NSNumber numberWithInteger:rxAntToken], @"rxant",
                            [NSNumber numberWithInteger:wideToken], @"wide",
                            [NSNumber numberWithInteger:loopaToken], @"loopa",
                            [NSNumber numberWithInteger:loopbToken], @"loopb",
                            [NSNumber numberWithInteger:bandToken], @"band",
                            [NSNumber numberWithInteger:daxIqToken], @"daxiq",
                            [NSNumber numberWithInteger:daxIqRateToken] , @"daxiq_rate",
                            [NSNumber numberWithInteger:capacityToken], @"capacity",
                            [NSNumber numberWithInteger:availableToken], @"available",
                            [NSNumber numberWithInteger:panadaptorToken], @"panadaptor",
                            [NSNumber numberWithInteger:colorGainToken], @"color_gain",
                            [NSNumber numberWithInteger:autoBlackToken], @"auto_black",
                            [NSNumber numberWithInteger:blackLevelToken], @"black_level",
                            [NSNumber numberWithInteger:xvtrToken], @"xvtr",
                            nil];
}

- (id) init {
    self = [super init];
    [self initWaterfallTokens];
    self.xPixels = 100;
    return self;
}


- (void) dealloc {
    self.waterfallTokens = nil;
}


#pragma mark
#pragma mark PanafallWaterfallData protocol handler



// Private Macro
//
// Macro to perform inline update on an ivar with KVO notification

#define updateWithNotify(key,ivar,value)  \
    {    \
        __weak Waterfall *safeSelf = self; \
        dispatch_async(dispatch_get_main_queue(), ^(void) { \
        [safeSelf willChangeValueForKey:(key)]; \
        (ivar) = (value); \
        [safeSelf didChangeValueForKey:(key)]; \
        }); \
    }

- (void)updateXPixelSize:(int)x {
    updateWithNotify(@"xPixels", _xPixels, x);
}



#pragma mark
#pragma mark RadioDisplay protoocol handlers

- (void) attachedRadio:(Radio *)radio streamId:(NSString *)streamId{
    self.radio = radio;
    self.streamId = streamId;
    
    if (!self.runQueue) {
        NSString *qName = [NSString stringWithFormat:@"net.k6tu.waterfallQueue-%@", streamId];
        self.runQueue = dispatch_queue_create([qName UTF8String], NULL);
    }
}

- (void) willRemoveStreamProcessor {
    
}


- (void) updatePanafallRef:(Panafall *)pan {
    self.panafall = pan;
}

#pragma mark
#pragma mark VitaManager Protocol handler

#define OFFSET_FIRST_PIXEL_FREQ         0
#define OFFSET_BIN_BANDWIDTH            8
#define OFFSET_LINE_DURATION            16
#define OFFSET_WIDTH                    20
#define OFFSET_HEIGHT                   22
#define OFFSET_TIMECODE                 24
#define OFFSET_AUTOBLACK_LEVEL          28
#define OFFSET_TILE                     32


- (void) streamHandler:(VITA *)vitaPacket {
    // Before doing any real work, make sure we want this tile... if its out of sequence,
    // drop it
    UInt32 thisTimeCode = CFSwapInt32BigToHost(*(UInt32 *)(vitaPacket.payload + OFFSET_TIMECODE));
    
    if (thisTimeCode < self.timecode) {
        // Arrived too late - pitch it
        self.droppedTiles++;
        return;
    }

    self.timecode = thisTimeCode;
    
    if (!self.delegate)
        // No handler
        return;
    
    WaterfallTile *tile = [[WaterfallTile alloc]init];
    tile.buffer = vitaPacket.buffer;
    tile.firstPixelFreq = (Float64)CFSwapInt64BigToHost(*(uint64_t *)(vitaPacket.payload + OFFSET_FIRST_PIXEL_FREQ)) / 1.048576E12;
    tile.binBandwidth = (Float64)CFSwapInt64BigToHost(*(uint64_t *)(vitaPacket.payload + OFFSET_BIN_BANDWIDTH)) / 1.048576E12;
    tile.lineDuration = CFSwapInt32BigToHost(*(UInt32 *)(vitaPacket.payload + OFFSET_LINE_DURATION));
    tile.width = CFSwapInt16BigToHost(*(UInt16 *)(vitaPacket.payload + OFFSET_WIDTH));
    tile.height = CFSwapInt16BigToHost(*(UInt16 *)(vitaPacket.payload + OFFSET_HEIGHT));
    tile.timecode = thisTimeCode;
    tile.autoBlackLevel = CFSwapInt32BigToHost(*(UInt32 *)(vitaPacket.payload + OFFSET_AUTOBLACK_LEVEL));
    tile.tile = vitaPacket.payload + OFFSET_TILE;
    
    // Swap the payload byte ordering
    UInt16 *bins = (UInt16 *)tile.tile;
    for (int i=0; i < (tile.width * tile.height); i++)
        bins[i] = CFSwapInt16BigToHost(bins[i]);
    
    // Create weak reference to self before the block
    __weak Waterfall *safeSelf = self;
    
    dispatch_async(self.runQueue, ^(void) {
        @autoreleasepool {
            [safeSelf.delegate waterfallTile:tile];
        }
    });
}


#pragma mark
#pragma mark Radio Parser Support



- (void) statusParser:(NSScanner *)scan selfStatus:(BOOL)selfStatus {
    NSString *all;
    NSArray *fields;
    [scan scanString:@" " intoString:nil];
    [scan scanUpToString:@"\n" intoString:&all];
    
    fields = [all componentsSeparatedByString:@" "];
    
    for (NSString *f in fields) {
        NSArray *kv = [f componentsSeparatedByString:@"="];
        NSString *k = kv[0];
        NSString *v = kv[1];
        
        NSInteger tokenVal = [self.waterfallTokens[k] integerValue];
        
        switch (tokenVal) {
            case lineDurationToken:
                updateWithNotify(@"lineDuration", _lineDuration, (int)[v integerValue]);
                break;
               
            case panadaptorToken:
                updateWithNotify(@"panadaptorId", _panadaptorId, ([NSString stringWithFormat:@"0x%@", v]));
                break;
                
            case colorGainToken:
                updateWithNotify(@"colorGain", _colorGain, (int)[v integerValue]);
                break;
                
            case autoBlackToken:
                updateWithNotify(@"autoBlack", _autoBlack, [v boolValue]);
                break;

            case blackLevelToken:
                updateWithNotify(@"blackLevel", _blackLevel, (int)[v integerValue]);
                break;

            case gradientIndexToken:
                updateWithNotify(@"gradientIndex", _gradientIndex, (int)[v integerValue]);
                break;
                
            case xPixelsToken:
            case centerToken:
            case bandwidthToken:
            case rfGainToken:
            case rxAntToken:
            case wideToken:
            case loopaToken:
            case loopbToken:
            case bandToken:
            case daxIqToken:
            case daxIqRateToken:
            case capacityToken:
            case xvtrToken:
                // All of these properties are held on the corresponding Panafall object
                break;
        }
    }
}



#pragma mark
#pragma mark Setters with Commands

// Private macro to improve readibility of setters

#define commandUpdateNotify(cmd, key, ivar, value) \
    /* Let observers know the change on the main queue */ \
    [self willChangeValueForKey:(key)]; \
    (ivar) = (value); \
    [self didChangeValueForKey:(key)]; \
    \
    __weak Waterfall *safeSelf = self; \
    @synchronized(self) { \
        dispatch_async(self.runQueue, ^(void) { \
            /* Send the command to the radio on our private queue */ \
            [safeSelf.radio commandToRadio:(cmd)]; \
        }); \
    }


- (void) setLineDuration:(int)lineDuration {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ line_duration=%i",
                     self.streamId, lineDuration];
    
    commandUpdateNotify(cmd, @"lineDuration", _lineDuration, lineDuration);
}


- (void) setAutoBlack:(BOOL)autoBlack {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ auto_black=%i",
                     self.streamId, autoBlack];
    
    commandUpdateNotify(cmd, @"autoBlack", _autoBlack, autoBlack);
}


- (void) setColorGain:(int)colorGain {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ color_gain=%i",
                     self.streamId, colorGain];
    
    commandUpdateNotify(cmd, @"colorGain", _colorGain, colorGain);
}


- (void) setBlackLevel:(int)blackLevel {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ black_level=%i",
                     self.streamId, blackLevel];
    
    commandUpdateNotify(cmd, @"blackLevel", _blackLevel, blackLevel);
}


- (void) setGradientIndex:(int)gradientIndex {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ gradient_index=%i",
                     self.streamId, gradientIndex];
    
    commandUpdateNotify(cmd, @"gradientIndex", _gradientIndex, gradientIndex);
}

- (void) setRunQueue:(dispatch_queue_t)runQueue {
    @synchronized(self) {
        _runQueue = runQueue;
    }
}

- (void) setDelegate:(id)delegate {
    @synchronized(self) {
        _delegate = delegate;
    }
}


@end



