//
//  Panafall
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

#import "Panafall.h"
#import "Waterfall.h"

@interface Panafall () <RadioDelegate>

@property (weak, readwrite, nonatomic) Radio *radio;                         // The Radio which owns this panadaptor
@property (strong, readwrite, nonatomic) NSString *streamId;                 // Identifier of this panadapator (STRING)
@property (weak, readwrite, nonatomic) Waterfall <PanafallWaterfallData> *waterfall;     // The Waterfall linked to this panadaptor (if any)
@property (readwrite, nonatomic) BOOL wide;                                  // State of preselector for associated SCU (BOOL)
@property (readwrite, nonatomic) int capacity;                               // Capacity maximum indicator (INT)
@property (readwrite, nonatomic) int available;                              // Capacity available (INT)
@property (strong, readwrite, nonatomic) NSString *waterfallId;              // Waterfall linked to this panadaptor (NSString)
@property (readwrite, nonatomic) Float64 minBW;                              // Minimum bandwidth in MHz (Float)
@property (readwrite, nonatomic) Float64 maxBW;                              // Maximum bandwidth in MHz (Float)
@property (readwrite, nonatomic) long int daxIQRate;                         // DAX IQ Rate in bps (LONG INT)
@property (readwrite, nonatomic) BOOL nbUpdating;                            // NB recalculating threshold (BOOL)
@property (strong, readwrite, nonatomic) NSString *xvtrLabel;                // Label of selected XVTR profile (STRING)
@property (strong, readwrite, nonatomic) NSString *preLabel;                 // Label of preselector selected (STRING)
@property (strong, readwrite, nonatomic) NSArray *antList;                   // Array of NSString of antenna options available
@property (strong, readwrite, nonatomic) NSArray *preAmpList;                // Array of NSString of preamp gain options available
@property (readwrite, nonatomic) UInt32 lastFFTFrameIndex;                   // Index of the last FFT frame received
@property (readwrite, nonatomic) UInt32 droppedFrames;                       // Count of dropped FFT frames due to out of sequence

@property (strong, nonatomic) NSDictionary *panafallTokens;

// userSetSize is used to keep a record of the size the user of the model
// set.
@property (nonatomic) CGSize userSetSize;                                    // The size of the panadaptor set by the user


- (void) initPanafallTokens;

@end


enum panafallToken {
    panNullToken=0,
    xPixelsToken,
    yPixelsToken,
    centerToken,
    bandwidthToken,
    minDbmToken,
    maxDbmToken,
    fpsToken,
    averageToken,
    weightedAverageToken,
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
    waterfallToken,
    minBwToken,
    maxBwToken,
    xvtrToken,
    preToken,
    antListToken,
    nbPanToken,
    nbLevelPanToken,
    nbUpdatingToken,
    wnbToken,
    wnbLevelToken,
    wnbUpdatingToken,
};


static DDLogLevel ddLogLevel = DDLogLevelError;


@implementation Panafall



- (void) initPanafallTokens {
    self.panafallTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [NSNumber numberWithInteger:xPixelsToken], @"x_pixels",
                           [NSNumber numberWithInteger:yPixelsToken], @"y_pixels",
                           [NSNumber numberWithInteger:centerToken], @"center",
                           [NSNumber numberWithInteger:bandwidthToken], @"bandwidth",
                           [NSNumber numberWithInteger:minDbmToken], @"min_dbm",
                           [NSNumber numberWithInteger:maxDbmToken], @"max_dbm",
                           [NSNumber numberWithInteger:fpsToken], @"fps",
                           [NSNumber numberWithInteger:averageToken], @"average",
                           [NSNumber numberWithInteger:weightedAverageToken], @"weighted_average",
                           [NSNumber numberWithInteger:rfGainToken], @"rfgain",
                           [NSNumber numberWithInteger:rxAntToken], @"rxant",
                           [NSNumber numberWithInteger:wideToken], @"wide",
                           [NSNumber numberWithInteger:loopaToken], @"loopa",
                           [NSNumber numberWithInteger:loopbToken], @"loopb",
                           [NSNumber numberWithInteger:nbPanToken], @"nb",
                           [NSNumber numberWithInteger:nbLevelPanToken], @"nb_level",
                           [NSNumber numberWithInteger:nbUpdatingToken], @"nb_updating",
                           [NSNumber numberWithInteger:bandToken], @"band",
                           [NSNumber numberWithInteger:daxIqToken], @"daxiq",
                           [NSNumber numberWithInteger:daxIqRateToken] , @"daxiq_rate",
                           [NSNumber numberWithInteger:capacityToken], @"capacity",
                           [NSNumber numberWithInteger:availableToken], @"available",
                           [NSNumber numberWithInteger:waterfallToken], @"waterfall",
                           [NSNumber numberWithInteger:minBwToken], @"min_bw",
                           [NSNumber numberWithInteger:maxBwToken], @"max_bw",
                           [NSNumber numberWithInteger:xvtrToken], @"xvtr",
                           [NSNumber numberWithInteger:preToken], @"pre",
                           [NSNumber numberWithInteger:antListToken], @"ant_list",
                           [NSNumber numberWithInteger:wnbToken], @"wnb",
                           [NSNumber numberWithInteger:wnbLevelToken], @"wnb_level",
                           [NSNumber numberWithInteger:wnbUpdatingToken], @"wnb_updating",
                           nil];
}

- (id) init {
    self = [super init];
    [self initPanafallTokens];
    _panDimensions = CGSizeMake(100, 100);
    return self;
}


- (void) dealloc {
    self.panafallTokens = nil;
}


#pragma mark 
#pragma mark RadioDisplay protoocol handlers

- (void) attachedRadio:(Radio *)radio streamId:(NSString *)streamId{
    self.radio = radio;
    self.streamId = streamId;
    
    if (!self.runQueue) {
        NSString *qName = [NSString stringWithFormat:@"net.k6tu.panafallQueue-%@", streamId];
        self.runQueue = dispatch_queue_create([qName UTF8String], NULL);
    }
    
    NSString *cmd = [NSString stringWithFormat:@"display pan rfgain_info %@", self.streamId];
    [self.radio commandToRadio:cmd notify:self];
}


- (void) willRemoveStreamProcessor {
    self.delegate = nil;
}


- (void) updateWaterfallRef:(Waterfall *)waterfall {
    self.waterfall = waterfall;
}


- (void) radioCommandResponse:(unsigned int)seqNum response:(NSString *)cmdResponse {
    // cmdResponse is the full response including the R<seqnum>|
    NSScanner *scan = [[NSScanner alloc] initWithString:[cmdResponse substringFromIndex:1]];
    [scan setCharactersToBeSkipped:nil];
    
    // Skip the sequence number and the following |
    [scan scanInteger:nil];
    [scan scanString:@"|" intoString:nil];
    
    // Now up is the response error code... grab it and skip the |
    NSString *errorNumAsString;
    [scan scanUpToString:@"|" intoString:&errorNumAsString];
    [scan scanString:@"|" intoString:nil];
    
    if ([errorNumAsString integerValue])
        // Anything other than 0 is an error and we return
        return;
    
    NSString *response;
    [scan scanUpToString:@"\n" intoString:&response];
    
    // The return info ia a list of appropriate preamp values separated by commas
    self.preAmpList = [response componentsSeparatedByString:@","];
}



#pragma mark
#pragma mark VitaManager Protocol handler

/* •	UInt32 start_bin_index
 •	UInt32 num_bins
 •	Uint32 bin_size
 •	UInt32 frame_index
 */

#define OFFSET_START_BIN    0
#define OFFSET_NUM_BINS     4
#define OFFSET_BIN_SIZE     8
#define OFFSET_FRAME_INDEX  12
#define OFFSET_BINS         16

- (void) streamHandler:(VITA *)vitaPacket {
    // Before doing any significant work, check this frame is in sequence
    // or toss it
    UInt32 currentIndex = CFSwapInt32BigToHost(*(UInt32 *)(vitaPacket.payload + OFFSET_FRAME_INDEX));
    
    if (currentIndex < self.lastFFTFrameIndex) {
        self.droppedFrames++;
        return;
    }
    
    if (!self.delegate)
        // No handler
        return;
    
    // Allocate PanafallFFTFrame
    PanafallFFTFrame *frame = [[PanafallFFTFrame alloc]init];
    
    frame.buffer = vitaPacket.buffer;
    frame.startBinIndex = CFSwapInt32BigToHost(*(UInt32 *)(vitaPacket.payload + OFFSET_START_BIN));
    frame.numBins = CFSwapInt32BigToHost(*(UInt32 *)(vitaPacket.payload + OFFSET_NUM_BINS));
    frame.binSize = CFSwapInt32BigToHost(*(UInt32 *)(vitaPacket.payload + OFFSET_BIN_SIZE));
    frame.bins = vitaPacket.payload + OFFSET_BINS;
    
    // Swap the byte ordering of the payload
    
    ushort *bin = (ushort *) frame.bins;
    for (int i=0; i < frame.numBins; i++) {
        bin[i] = CFSwapInt16BigToHost(bin[i]);
    }
    
    // Pass the frame off to the delegate on the supplied run queue
    // Create weak reference to self before the block
    __weak Panafall *safeSelf = self;
    
    dispatch_async(self.runQueue, ^(void){
        @autoreleasepool {
            [safeSelf.delegate fftFrame:frame];
        }
    });
}

#pragma mark
#pragma mark Radio Parser Support


// Private Macro
//
// Macro to perform inline update on an ivar with KVO notification

#define updateWithNotify(key,ivar,value)  \
    {   \
        __weak Panafall *safeSelf = self; \
        dispatch_async(dispatch_get_main_queue(), ^(void) { \
            [safeSelf willChangeValueForKey:(key)]; \
            (ivar) = (value); \
            [safeSelf didChangeValueForKey:(key)]; \
        }); \
    }


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
        
        NSInteger tokenVal = [self.panafallTokens[k] integerValue];
        CGSize dim;
        
        switch (tokenVal) {
            case xPixelsToken:
                dim = self.panDimensions;
                dim.width = [v floatValue];
                // updateWithNotify(@"panDimensions", _panDimensions, dim);
                // [self.waterfall updateXPixelSize:(int)[v integerValue]];
                break;
                
            case yPixelsToken:
                dim = self.panDimensions;
                dim.height = [v floatValue];
                // updateWithNotify(@"panDimensions", _panDimensions, dim);
                break;
                
            case centerToken:
                if (_center != [v floatValue])
                    updateWithNotify(@"center", _center, [v floatValue]);
                break;
                
            case bandwidthToken:
                if (_bandwidth != [v floatValue])
                    updateWithNotify(@"bandwidth", _bandwidth, [v floatValue]);
                break;
                
            case minDbmToken:
                if (_minDbm != [v floatValue])
                    updateWithNotify(@"minDbm", _minDbm, [v floatValue]);
                break;
                
            case maxDbmToken:
                if (_maxDbm != [v floatValue])
                    updateWithNotify(@"maxDbm", _maxDbm, [v floatValue]);
                break;
                
            case fpsToken:
                if (_fps != [v integerValue])
                    updateWithNotify(@"fps", _fps, (int)[v integerValue]);
                break;
                
            case averageToken:
                if (_average != [v integerValue])
                    updateWithNotify(@"average", _average, (int)[v integerValue]);
                break;
                
            case weightedAverageToken:
                if (_weightedAverage != [v boolValue])
                    updateWithNotify(@"weightedAverage", _weightedAverage, [v integerValue] ? YES : NO);
                break;
                
            case rfGainToken:
                if (_rfGain != [v integerValue])
                    updateWithNotify(@"rfGain", _rfGain, (int)[v integerValue]);
                break;
                
            case rxAntToken:
                updateWithNotify(@"rxAnt", _rxAnt, v);
                break;
                
            case wideToken:
                if (_wide != [v boolValue])
                    updateWithNotify(@"wide", _wide, [v integerValue] ? YES : NO);
                break;
                
            case loopaToken:
                if (_loopA != [v boolValue])
                    updateWithNotify(@"loopa", _loopA, [v integerValue] ? YES : NO);
                break;
                
            case loopbToken:
                if (_loopB != [v boolValue])
                    updateWithNotify(@"loopb", _loopB, [v integerValue] ? YES : NO);
                break;
                
            case nbPanToken:
                if (_nb != [v boolValue])
                    updateWithNotify(@"nb", _nb, [v integerValue] ? YES : NO);
                break;

            case nbLevelPanToken:
                if (_nbLevel != [v integerValue])
                    updateWithNotify(@"nbLevel", _nbLevel, (int)[v integerValue]);
                break;
                
            case nbUpdatingToken:
                if (_nbUpdating != [v boolValue])
                    updateWithNotify(@"nbUpdating", _nbUpdating, [v boolValue]);
                break;
                
            case wnbToken:
                if (_wnb != [v boolValue])
                    updateWithNotify(@"wnb", _wnb, [v integerValue] ? YES : NO);
                break;
                
            case wnbLevelToken:
                if (_wnbLevel != [v integerValue])
                    updateWithNotify(@"wnbLevel", _wnbLevel, (int)[v integerValue]);
                break;
                
            case wnbUpdatingToken:
                if (_wnbUpdating != [v boolValue])
                    updateWithNotify(@"wnbUpdating", _wnbUpdating, [v boolValue]);
                break;
                
            case bandToken:
                updateWithNotify(@"band", _band, v);
                break;
                
            case daxIqToken:
                if (_daxIQ != [v boolValue])
                    updateWithNotify(@"daxiq", _daxIQ, [v integerValue] ? YES : NO);
                break;
                
            case daxIqRateToken:
                if (_daxIQRate != [v integerValue])
                    updateWithNotify(@"daxIQRate", _daxIQRate, [v integerValue]);
                break;
                
            case capacityToken:
                if (_capacity != [v integerValue])
                    updateWithNotify(@"capacity", _capacity, (int)[v integerValue]);
                break;
                
            case availableToken:
                if (_available != [v integerValue])
                    updateWithNotify(@"available", _available, (int)[v integerValue]);
                break;
                
            case waterfallToken:
                // Important to update the waterfallId value here - so that when its corresponding
                // waterfall is created for this pan, we will know the two belong together
                // and the notification for the panafall creation can be triggered.
                _waterfallId = [NSString stringWithFormat:@"0x%@", v];
                updateWithNotify(@"waterfallId", _waterfallId, ([NSString stringWithFormat:@"0x%@", v]));
                break;
                
            case minBwToken:
                if (_minBW != [v floatValue])
                    updateWithNotify(@"minBW", _minBW, [v floatValue]);
                break;
                
            case maxBwToken:
                if (_maxBW != [v floatValue])
                    updateWithNotify(@"maxBW", _maxBW, [v floatValue]);
                break;
                
            case xvtrToken:
                updateWithNotify(@"xvtrLabel", _xvtrLabel, v);
                break;
                
            case preToken:
                updateWithNotify(@"preLabel", _preLabel, v);
                break;
                
            case antListToken:
                updateWithNotify(@"antList", _antList, ([v componentsSeparatedByString:@","]));
                break;
                
            default:
                // Ignore
                DDLogError(@"Panafall statusParser: Unknown key %@", k);
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
    __weak Panafall *safeSelf = self; \
    @synchronized(self) {\
        dispatch_async(self.runQueue, ^(void) { \
            /* Send the command to the radio on our private queue */ \
            [safeSelf.radio commandToRadio:(cmd)]; \
        }); \
    }


- (void) setPanDimensions:(CGSize)panDimensions {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ xpixels=%i ypixels=%i",
                     self.streamId, (int) panDimensions.width, (int)panDimensions.height];
    
    // Save the size set by the user
    self.userSetSize = panDimensions;
    
    CGSize lCopyPanDimensions = panDimensions;
    commandUpdateNotify(cmd, @"panDimensions", _panDimensions, lCopyPanDimensions);
}


-(void) setCenter:(Float32)center {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ center=%f autocenter=%i",
                     self.streamId, center, self.autoCenter];
    
    commandUpdateNotify(cmd, @"center", _center, center);
}


-(void) setBandwidth:(Float32)bandwidth {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ bandwidth=%f autocenter=%i",
                     self.streamId, bandwidth, self.autoCenter];
    
    self.autoCenter = NO;
    commandUpdateNotify(cmd, @"bandwidth", _bandwidth, bandwidth);
}


- (void) setMinDbm:(Float32)minDbm {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ min_dbm=%f",
                     self.streamId, minDbm];
    
    commandUpdateNotify(cmd, @"minDbm", _minDbm, minDbm);
}


- (void) setMaxDbm:(Float32)maxDbm {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ max_dbm=%f",
                     self.streamId, maxDbm];
    
    commandUpdateNotify(cmd, @"maxDbm", _maxDbm, maxDbm);
}


- (void) setFps:(int)fps {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ fps=%i",
                     self.streamId, fps];

    commandUpdateNotify(cmd, @"fps", _fps, fps);
}


- (void)setAverage:(int)average {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ average=%i",
                     self.streamId, average];
    
    commandUpdateNotify(cmd, @"average", _average, average);
}


- (void) setWeightedAverage:(BOOL)weightedAverage {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ weighted_average=%i",
                     self.streamId, weightedAverage];
    
    commandUpdateNotify(cmd, @"weightedAverage", _weightedAverage, weightedAverage);
}


- (void) setLoopA:(BOOL)loopA {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ loopa=%i",
                     self.streamId, loopA];
    
    commandUpdateNotify(cmd, @"loopa", _loopA, loopA);
}


- (void) setLoopB:(BOOL)loopB {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ loopb=%i",
                     self.streamId, loopB];
    
    commandUpdateNotify(cmd, @"loopb", _loopB, loopB);
}


- (void) setRfGain:(int)rfGain {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ rfgain=%f",
                     self.streamId, (float)rfGain];
    
    commandUpdateNotify(cmd, @"rfGain", _rfGain, rfGain);
}


- (void)setRxAnt:(NSString *)rxAnt {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ rxant=%@",
                     self.streamId, rxAnt];
    
    commandUpdateNotify(cmd, @"rxAnt", _rxAnt, rxAnt);
}


- (void) setBand:(NSString *)band {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ band=%@",
                     self.streamId, band];
    
    commandUpdateNotify(cmd, @"band", _band, band);
}


- (void) setNb:(BOOL)nb {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ nb=%i",
                     self.streamId, nb];
    commandUpdateNotify(cmd, @"nb", _nb, nb);
}


- (void) setNbLevel:(int)nbLevel {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ nb_level=%i",
                     self.streamId, nbLevel];
    commandUpdateNotify(cmd, @"nbLevel", _nbLevel, nbLevel);
}


- (void) setWnb:(BOOL)wnb {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ wnb=%i",
                     self.streamId, wnb];
    commandUpdateNotify(cmd, @"wnb", _wnb, wnb);
}


- (void) setWnbLevel:(int)wnbLevel {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ wnb_level=%i",
                     self.streamId, wnbLevel];
    commandUpdateNotify(cmd, @"wnbLevel", _wnbLevel, wnbLevel);
}


- (void) setDaxIQ:(int)daxIQ {
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ daxiq=%i",
                     self.streamId, daxIQ];
    
    commandUpdateNotify(cmd, @"daxIQ", _daxIQ, daxIQ);
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

