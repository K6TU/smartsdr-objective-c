//
//  Slice.m
//
//  Created by STU PHILLIPS on 8/5/13.
//  Copyright (c) 2013 STU PHILLIPS. All rights reserved.
//
// NOTE: THe license under which this software will be generally released
// is still under consideration.  For now, use of this software requires
// the specific approval of Stu Phillips, K6TU.

#import "Slice.h"

@interface Slice () {
    
}

- (NSInteger) freqStringToHertz: (NSString *) freq;
- (NSString *) formatFrequencyNumberAsCommandString:(NSNumber *) frequency;

@end
@implementation Slice


- (id) initWithRadio:(Radio *)radio sliceNumber: (NSInteger) sliceNum {
    self = [super init];
    
    if (self) {
        self.radio = radio;
        self.thisSliceNumber = [NSNumber numberWithInt:sliceNum];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SliceCreated" object:self];
    }
    
    return self;
}


- (void) youAreBeingDeleted {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SliceDeleted" object:self];
}


- (NSString *) formatSliceFrequency {
    NSInteger fInHz = [self freqStringToHertz:self.sliceFrequency];
    NSString *fmtFreq = [NSString stringWithFormat:@"%i.%03i.%03i",
                         fInHz / 1000000, fInHz / 1000 % 1000, fInHz % 1000 ];
    return fmtFreq;
    
}


- (NSString *) formatSliceFilterBandwidth {
    float filterLo = [self.sliceFilterLo floatValue];
    float filterHi = [self.sliceFilterHi floatValue];
    NSInteger filterBW = ((filterHi * 1000.00) - (filterLo * 1000.00)) * 1000.0 + 0.5;
    
    // Could be negative...
    filterBW = (filterBW < 0) ? -1 * filterBW : filterBW;
    
    // Do we display in KHz or Hz...
    BOOL kHzDisplay = filterBW >= 1000 ? YES: NO;
    NSString *fmtFreq;
    
    if (kHzDisplay) {
        fmtFreq = [NSString stringWithFormat:@"%i.%i KHz", filterBW / 1000, (filterBW / 100) % 10];
    } else {
        fmtFreq = [NSString stringWithFormat:@"%i Hz", filterBW];
    }

    return fmtFreq;
}


- (NSNumber *) formatSliceFrequencyAsNumber {
    return [NSNumber numberWithInt:[self freqStringToHertz:self.sliceFrequency]];
}


- (NSString *) formatFrequencyNumberAsCommandString:(NSNumber *) frequency {
    NSInteger fInHz = [frequency integerValue];
    NSString *fmtFreq = [NSString stringWithFormat:@"%i.%03i%03i",
                         fInHz / 1000000, fInHz / 1000 % 1000, fInHz % 1000 ];
    return fmtFreq;
}

#pragma mark
#pragma mark Slice Commands

- (void) cmdSetTx:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i tx=%@",
                     [self.thisSliceNumber integerValue],
                     state];
    [self.radio commandToRadio:cmd];
    self.sliceTxEnabled = state;
}

- (void) cmdTuneSlice:(NSNumber *)frequency {
    NSString *cmdF = [self formatFrequencyNumberAsCommandString:frequency];
    
    NSString *cmd = [NSString stringWithFormat: @"slice tune %i %@",
                     [self.thisSliceNumber integerValue],
                     cmdF];
    [self.radio commandToRadio: cmd];
    self.sliceFrequency = cmdF;    
}

- (void) cmdSetMode:(NSString *)mode {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i mode=%@",
                     [self.thisSliceNumber integerValue],
                     mode];
    [self.radio commandToRadio:cmd];
    self.sliceMode = mode;
}

- (void) cmdSetRxAnt:(NSString *)antenna {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i rxant=%@",
                     [self.thisSliceNumber integerValue],
                     antenna];
    [self.radio commandToRadio:cmd];
    self.sliceRxAnt = antenna;
}


- (void) cmdSetTxAnt:(NSString *)antenna {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i txant=%@",
                     [self.thisSliceNumber integerValue],
                     antenna];
    [self.radio commandToRadio:cmd];
    self.sliceTxAnt = antenna;
}

- (void) cmdSetMute:(NSNumber *)state {
    NSInteger gain;
    
    if ([state boolValue]) {
        gain = 0;
    } else {
        gain = [self.sliceAudioLevel integerValue];
    }

    NSString *cmd = [NSString stringWithFormat:@"audio client 0 slice %i gain %i",
                     [self.thisSliceNumber integerValue],
                     gain];
    
    [self.radio commandToRadio:cmd];
    self.sliceMuteEnabled = state;
}


- (void) cmdSetAfLevel:(NSNumber *)level {
    if (![self.sliceMuteEnabled boolValue]) {
        NSString *cmd = [NSString stringWithFormat:@"audio client 0 slice %i gain %i",
                         [self.thisSliceNumber integerValue],
                         [level integerValue]];
        
        [self.radio commandToRadio:cmd];
    }
    self.sliceAudioLevel = level;
}

- (void) cmdSetAfPan:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"audio client 0 slice %i pan %f",
                     [self.thisSliceNumber integerValue],
                     [level floatValue] / 100.0];
    
    [self.radio commandToRadio:cmd];
    self.slicePanControl = level;
}

- (void) cmdSetAgcMode:(NSString *)mode {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i agc_mode=%@",
                     [self.thisSliceNumber integerValue],
                     [mode lowercaseString]];
    [self.radio commandToRadio:cmd];
    self.sliceAgcMode = mode;
}

- (void) cmdSetAgcLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i agc_threshold=%i",
                     [self.thisSliceNumber integerValue],
                     [level integerValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceAgcThreshold = level;
}

- (void) cmdSetDspNb:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i nb=%i",
                     [self.thisSliceNumber integerValue],
                     [state integerValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceNbEnabled = state;
}

- (void) cmdSetDspNr:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i nr=%i",
                     [self.thisSliceNumber integerValue],
                     [state integerValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceNrEnabled = state;
}

- (void) cmdSetDspAnf:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i anf=%i",
                     [self.thisSliceNumber integerValue],
                     [state integerValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceAnfEnabled = state;
}

- (void) cmdSetDspNbLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i nb_level=%i",
                     [self.thisSliceNumber integerValue],
                     [level integerValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceNbLevel = level;
}

- (void) cmdSetDspNrLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i nr_level=%i",
                     [self.thisSliceNumber integerValue],
                     [level integerValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceNrLevel = level;
}

- (void) cmdSetDspAnfLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i anf_level=%i",
                     [self.thisSliceNumber integerValue],
                     [level integerValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceAnfLevel = level;
}

- (void) cmdSetFilter:(NSNumber *)filterLo filterHi:(NSNumber *)filterHi {
    NSString *cmd = [NSString stringWithFormat:@"filt %i %f %f",
                     [self.thisSliceNumber integerValue],
                     [filterLo floatValue] * 1000000.00,
                     [filterHi floatValue] * 1000000.00];
    
    // Ignore zero filter widths
    if ([filterHi floatValue] == [filterLo floatValue])
        return;
    
    [self.radio commandToRadio:cmd];
    self.sliceFilterLo = filterLo;
    self.sliceFilterHi = filterHi;
}


#pragma mark
#pragma mark Utility Functions (Internal)

- (NSInteger) freqStringToHertz:(NSString *)freq {
    NSInteger cAfterDP;
    
    // We need to get this into Hz...
    // ..
    // Count chararacters after the decimal point so we can scale frequency as needed
    // Check to make sure we have a DP..
    if ([freq rangeOfString:@"."].location == NSNotFound) {
        // No DP found - must be an integer number of MHZ
        cAfterDP = 0;
    } else
        cAfterDP = [freq length] - ([freq rangeOfString:@"."].location + 1);
    
    NSString *freqMinusDP = [freq stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSInteger fInHz = [freqMinusDP integerValue];
    
    // We need 6 characters after the DP so we scale by 10 ** (6 - cAfterDP)
    
    for (int i=(6 - cAfterDP); i>0; i--) {
        fInHz *= 10;
    }
    return fInHz;
}

@end
