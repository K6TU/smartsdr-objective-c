//
//  Panafall
//  VITA Engine
//
//  Created by STU PHILLIPS on 2/4/15.
//  Copyright (c) 2015 STU PHILLIPS. All rights reserved.
//

#import "Panafall.h"
#import "Waterfall.h"

@interface Panafall ()

@property (weak, readwrite, nonatomic) Radio *radio;                         // The Radio which owns this panadaptor
@property (strong, readwrite, nonatomic) NSString *streamId;                 // Identifier of this panadapator (STRING)
@property (weak, readwrite, nonatomic) Waterfall <PanafallWaterfallData> *waterfall;     // The Waterfall linked to this panadaptor (if any)
@property (readwrite, nonatomic) BOOL wide;                                  // State of preselector for associated SCU (BOOL)
@property (strong, readwrite, nonatomic) NSString *band;                     // Band encompassed by this pan (STRING)
@property (readwrite, nonatomic) int capacity;                               // Capacity maximum indicator (INT)
@property (readwrite, nonatomic) int available;                              // Capacity available (INT)
@property (strong, readwrite, nonatomic) NSString *waterfallId;              // Waterfall linked to this panadaptor (NSString)
@property (readwrite, nonatomic) Float64 minBW;                              // Minimum bandwidth in MHz (Float)
@property (readwrite, nonatomic) Float64 maxBW;                              // Maximum bandwidth in MHz (Float)
@property (readwrite, nonatomic) long int daxIQRate;                         // DAX IQ Rate in bps (LONG INT)
@property (strong, readwrite, nonatomic) NSString *xvtrLabel;                // Label of selected XVTR profile (STRING)
@property (strong, readwrite, nonatomic) NSString *preLabel;                 // Label of preselector selected (STRING)
@property (strong, readwrite, nonatomic) NSArray *antList;                   // Array of NSString of antenna options available
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
};


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
        NSString *qName = [NSString stringWithFormat:@"com.k6tu.panafallQueue-%@", streamId];
        self.runQueue = dispatch_queue_create([qName UTF8String], NULL);
    }
}


- (void) willRemoveDisplay {
    
}


- (void) updateWaterfallRef:(Waterfall *)waterfall {
    self.waterfall = waterfall;
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
    
    // Allocate PanafallFFTFrame
    PanafallFFTFrame *frame = [[PanafallFFTFrame alloc]init];
    
    frame.buffer = vitaPacket.buffer;
    frame.startBinIndex = CFSwapInt32BigToHost(*(UInt32 *)(vitaPacket.payload + OFFSET_START_BIN));
    frame.numBins = CFSwapInt32BigToHost(*(UInt32 *)(vitaPacket.payload + OFFSET_NUM_BINS));
    frame.binSize = CFSwapInt32BigToHost(*(UInt32 *)(vitaPacket.payload + OFFSET_BIN_SIZE));
    frame.bins = vitaPacket.payload + OFFSET_START_BIN;
    
    // No longer any requirement to byte swap the payload - the radio now sends these in little endian
    // byte order
    //
    // Pass the frame off to the delegate on the supplied run queue
    
    dispatch_async(self.runQueue, ^(void){
        [self.delegate fftFrame:frame];
    });
}

#pragma mark
#pragma mark Radio Parser Support


// Private Macro
//
// Macro to perform inline update on an ivar with KVO notification

#define updateWithNotify(key,ivar,value)  \
    {    dispatch_sync(dispatch_get_main_queue(), ^(void) { \
            [self willChangeValueForKey:(key)]; \
            (ivar) = (value); \
            [self didChangeValueForKey:(key)]; \
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
                
                // See whether this is reflecting a change the user made
                if (self.userSetSize.width == [v floatValue]) {
                    dim.width = [v floatValue];
                    updateWithNotify(@"panDimensions", _panDimensions, dim);
                    [self.waterfall updateXPixelSize:(int)[v integerValue]];
                }

                break;
                
            case yPixelsToken:
                dim = self.panDimensions;
                
                // See whether this is reflecting a change the user made
                if (self.userSetSize.height == [v floatValue]) {
                    dim.height = [v floatValue];
                    updateWithNotify(@"panDimensions", _panDimensions, dim);
                }
                
                break;
                
            case centerToken:
                updateWithNotify(@"center", _center, [v floatValue]);
                break;
                
            case bandwidthToken:
                updateWithNotify(@"bandwidth", _bandwidth, [v floatValue]);
                break;
                
            case minDbmToken:
                updateWithNotify(@"minDbm", _minDbm, [v floatValue]);
                break;
                
            case maxDbmToken:
                updateWithNotify(@"maxDbm", _maxDbm, [v floatValue]);
                break;
                
            case fpsToken:
                updateWithNotify(@"fps", _fps, (int)[v integerValue]);
                break;
                
            case averageToken:
                updateWithNotify(@"average", _average, (int)[v integerValue]);
                break;
                
            case weightedAverageToken:
                updateWithNotify(@"weightedAverage", _weightedAverage, [v integerValue] ? YES : NO);
                break;
                
            case rfGainToken:
                updateWithNotify(@"rfGain", _rfGain, (int)[v integerValue]);
                break;
                
            case rxAntToken:
                updateWithNotify(@"rxAnt", _rxAnt, v);
                break;
                
            case wideToken:
                updateWithNotify(@"wide", _wide, [v integerValue] ? YES : NO);
                break;
                
            case loopaToken:
                updateWithNotify(@"loopa", _loopA, [v integerValue] ? YES : NO);
                break;
                
            case loopbToken:
                updateWithNotify(@"loopb", _loopB, [v integerValue] ? YES : NO);
                break;
                
            case bandToken:
                updateWithNotify(@"band", _band, v);
                break;
                
            case daxIqToken:
                updateWithNotify(@"daxiq", _daxIQ, [v integerValue] ? YES : NO);
                break;
                
            case daxIqRateToken:
                updateWithNotify(@"daxIQRate", _daxIQRate, [v integerValue]);
                break;
                
            case capacityToken:
                updateWithNotify(@"capacity", _capacity, (int)[v integerValue]);
                break;
                
            case availableToken:
                updateWithNotify(@"available", _available, (int)[v integerValue]);
                break;
                
            case waterfallToken:
                updateWithNotify(@"waterfallId", _waterfallId, ([NSString stringWithFormat:@"0x%@", v]));
                break;
                
            case minBwToken:
                updateWithNotify(@"minBW", _minBW, [v floatValue]);
                break;
                
            case maxBwToken:
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
    @synchronized(self) {\
        dispatch_async(self.runQueue, ^(void) { \
            /* Send the command to the radio on our private queue */ \
            [self.radio commandToRadio:(cmd)]; \
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
    NSString *cmd = [NSString stringWithFormat:@"display panafall set %@ center=%f",
                     self.streamId, center];
    
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

