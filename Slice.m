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

- (long long int) freqStringToHertz: (NSString *) freq;
- (NSString *) formatFrequencyNumberAsCommandString:(NSNumber *) frequency;

@end
@implementation Slice


- (id) initWithRadio:(Radio *)radio sliceNumber: (NSInteger) sliceNum {
    self = [super init];
    
    if (self) {
        self.radio = radio;
        self.thisSliceNumber = [NSNumber numberWithInteger:sliceNum];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SliceCreated" object:self];
    }
    
    return self;
}


- (void) youAreBeingDeleted {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SliceDeleted" object:self];
}


- (NSString *) formatSliceFrequency {
    long long int fInHz = (long long int)[self freqStringToHertz:self.sliceFrequency];
    NSString *fmtFreq = [NSString stringWithFormat:@"%i.%03i.%03i",
                         (int)(fInHz / 1000000), (int)(fInHz / 1000 % 1000), (int)(fInHz % 1000) ];
    return fmtFreq;
    
}


- (NSString *) formatSliceFilterBandwidth {
    int filterLo = (int)[self.sliceFilterLo integerValue];
    int filterHi = (int)[self.sliceFilterHi integerValue];
    int filterBW = filterHi - filterLo;
    
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
    return [NSNumber numberWithLongLong:[self freqStringToHertz:self.sliceFrequency]];
}


- (NSString *) formatFrequencyNumberAsCommandString:(NSNumber *) frequency {
    long long int fInHz = (long long int)[frequency longLongValue];
    NSString *fmtFreq = [NSString stringWithFormat:@"%i.%03i%03i",
                                  (int)(fInHz / 1000000), (int)(fInHz / 1000 % 1000), (int)(fInHz % 1000) ];
    return fmtFreq;
}

#pragma mark
#pragma mark Slice Commands

- (void) cmdSetTx:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i tx=%@",
                     [self.thisSliceNumber intValue],
                     state];
    [self.radio commandToRadio:cmd];
    self.sliceTxEnabled = state;
}

- (void) cmdTuneSlice:(NSNumber *)frequency {
    NSString *cmdF = [self formatFrequencyNumberAsCommandString:frequency];
    
    NSString *cmd = [NSString stringWithFormat: @"slice tune %i %@",
                     [self.thisSliceNumber intValue],
                     cmdF];
    [self.radio commandToRadio: cmd];
    self.sliceFrequency = cmdF;    
}

- (void) cmdSetMode:(NSString *)mode {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i mode=%@",
                     [self.thisSliceNumber intValue],
                     mode];
    [self.radio commandToRadio:cmd];
    self.sliceMode = mode;
}

- (void) cmdSetRxAnt:(NSString *)antenna {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i rxant=%@",
                     [self.thisSliceNumber intValue],
                     antenna];
    [self.radio commandToRadio:cmd];
    self.sliceRxAnt = antenna;
}


- (void) cmdSetTxAnt:(NSString *)antenna {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i txant=%@",
                     [self.thisSliceNumber intValue],
                     antenna];
    [self.radio commandToRadio:cmd];
    self.sliceTxAnt = antenna;
}

- (void) cmdSetMute:(NSNumber *)state {
    int gain;
    NSString *cmd;
    
    // Version dependent command differences between V1.0.0.0 and V1.1.0.0
    if ([self.radio.apiVersion isEqualToString:@"V1.0.0.0"]) {
        if ([state boolValue]) {
            gain = 0;
        } else {
            gain = [self.sliceAudioLevel intValue];
        }
        
        cmd = [NSString stringWithFormat:@"audio client 0 slice %i gain %i",
               [self.thisSliceNumber intValue],
               gain];
    } else {
        cmd = [NSString stringWithFormat:@"audio client 0 slice %i mute %i",
               [self.thisSliceNumber intValue],
               [state intValue]];
    }
    
    [self.radio commandToRadio:cmd];
    self.sliceMuteEnabled = state;
}

- (void) cmdSetLock:(NSNumber *)state {
    NSString * cmd;
    
    if ([state boolValue])
        cmd = [NSString stringWithFormat:@"slice lock %i", [self.thisSliceNumber intValue]];
    else
        cmd = [NSString stringWithFormat:@"slice unlock %i", [self.thisSliceNumber intValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceLocked = state;
}


- (void) cmdSetAfLevel:(NSNumber *)level {
    NSString *cmd;
    
    // Version dependent command differences between V1.0.0.0 and V1.1.0.0
    if ([self.radio.apiVersion isEqualToString:@"V1.0.0.0.0"]) {
        // Version 1.0.0.0 didn't support the ability to mute a slice other than by
        // reducing its audio gain to zero - hence the check on whether we command
        // the radio below if muted
        
        if (![self.sliceMuteEnabled boolValue]) {
            cmd = [NSString stringWithFormat:@"audio client 0 slice %i gain %i",
                   [self.thisSliceNumber intValue],
                   [level intValue]];
            
            [self.radio commandToRadio:cmd];
        }
    } else {
        // V1.1.0.0 support per slice muting so no check needed on whether the slice
        // is muted or not.  Just go ahead and set the value.
        
        cmd = [NSString stringWithFormat:@"audio client 0 slice %i gain %i",
               [self.thisSliceNumber intValue],
               [level intValue]];
        
        [self.radio commandToRadio:cmd];
    }
    
    self.sliceAudioLevel = level;
}

- (void) cmdSetAfPan:(NSNumber *)level {
    NSString *cmd;
    
    // Version dependent command format between V1.0.0.0 and V1.1.0.0
    if ([self.radio.apiVersion isEqualToString:@"V1.0.0.0"])
        cmd = [NSString stringWithFormat:@"audio client 0 slice %i pan %f",
               [self.thisSliceNumber intValue],
               [level floatValue] / 100.0];
    else
        cmd = [NSString stringWithFormat:@"audio client 0 slice %i pan %i",
               [self.thisSliceNumber intValue],
               [level intValue]];
    
    [self.radio commandToRadio:cmd];
    self.slicePanControl = level;
}

- (void) cmdSetAgcMode:(NSString *)mode {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i agc_mode=%@",
                     [self.thisSliceNumber intValue],
                     [mode lowercaseString]];
    [self.radio commandToRadio:cmd];
    self.sliceAgcMode = mode;
}

- (void) cmdSetAgcLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i agc_threshold=%i",
                     [self.thisSliceNumber intValue],
                     [level intValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceAgcThreshold = level;
}

- (void) cmdSetDspNb:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i nb=%i",
                     [self.thisSliceNumber intValue],
                     [state intValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceNbEnabled = state;
}

- (void) cmdSetDspNr:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i nr=%i",
                     [self.thisSliceNumber intValue],
                     [state intValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceNrEnabled = state;
}

- (void) cmdSetDspAnf:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i anf=%i",
                     [self.thisSliceNumber intValue],
                     [state intValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceAnfEnabled = state;
}

- (void) cmdSetDspApf:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i apf=%i",
                     [self.thisSliceNumber intValue],
                     [state intValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceApfEnabled = state;
}

- (void) cmdSetDspNbLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i nb_level=%i",
                     [self.thisSliceNumber intValue],
                     [level intValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceNbLevel = level;
}

- (void) cmdSetDspNrLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i nr_level=%i",
                     [self.thisSliceNumber intValue],
                     [level intValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceNrLevel = level;
}

- (void) cmdSetDspAnfLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i anf_level=%i",
                     [self.thisSliceNumber intValue],
                     [level intValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceAnfLevel = level;
}

- (void) cmdSetDspApfLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i apf=%i apf_level=%i",
                     [self.thisSliceNumber intValue], [self.sliceApfEnabled boolValue],
                     [level intValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceApfLevel = level;
}

- (void) cmdSetXitEnable:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i xit_on=%i",
                     [self.thisSliceNumber intValue],
                     [state boolValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceXitEnabled = state;
}

- (void) cmdSetRitEnable:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i rit_on=%i",
                     [self.thisSliceNumber intValue],
                     [state boolValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceRitEnabled = state;
}

- (void) cmdSetXitOffset:(NSNumber *)offset {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i xit_freq=%i",
                     [self.thisSliceNumber intValue],
                     [offset intValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceXitOffset = offset;
}

- (void) cmdSetRitOffset:(NSNumber *)offset {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i rit_freq=%i",
                     [self.thisSliceNumber intValue],
                     [offset intValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceRitOffset = offset;
}

- (void) cmdSetDaxEnable:(NSNumber *)channel {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i dax=%i",
                     [self.thisSliceNumber intValue],
                     [channel intValue]];
    
    [self.radio commandToRadio:cmd];
    self.sliceDax = channel;
}

- (void) cmdSetFilter:(NSNumber *)filterLo filterHi:(NSNumber *)filterHi {
    NSString *cmd = [NSString stringWithFormat:@"filt %i %i %i",
                     [self.thisSliceNumber intValue],
                     [filterLo intValue],
                     [filterHi intValue]];
    
    // Ignore zero filter widths
    if ([filterHi floatValue] == [filterLo floatValue])
        return;
    
    [self.radio commandToRadio:cmd];
    self.sliceFilterLo = filterLo;
    self.sliceFilterHi = filterHi;
}

- (void) cmdSetSliceActive:(NSNumber *)state {
    if ([self.sliceActive boolValue] == [state boolValue])
        return;
    
    NSString *cmd = [NSString stringWithFormat:@"slice set %i active=%i",
                     [self.thisSliceNumber intValue],
                     [state intValue]];
    [self.radio commandToRadio:cmd];
    
    self.sliceActive = state;
}


- (void) cmdSetQRPlayback:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i play=%i",
                     [self.thisSliceNumber intValue],
                     [state intValue]];
    [self.radio commandToRadio:cmd];
    
    self.slicePlaybackEnabled = state;
}


- (void) cmdSetQRRecord:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i record=%i",
                     [self.thisSliceNumber intValue],
                     [state intValue]];
    [self.radio commandToRadio:cmd];
    
    self.sliceRecordEnabled = state;
}


#pragma mark
#pragma mark Utility Functions (Internal)

- (long long int) freqStringToHertz:(NSString *)freq {
    int cAfterDP;
    
    // We need to get this into Hz...
    // ..
    // Count chararacters after the decimal point so we can scale frequency as needed
    // Check to make sure we have a DP..
    if ([freq rangeOfString:@"."].location == NSNotFound) {
        // No DP found - must be an integer number of MHZ
        cAfterDP = 0;
    } else
        cAfterDP = (int)[freq length] - (int)([freq rangeOfString:@"."].location + 1);
    
    NSString *freqMinusDP = [freq stringByReplacingOccurrencesOfString:@"." withString:@""];
    long long int fInHz = [freqMinusDP longLongValue];
    
    // We need 6 characters after the DP so we scale by 10 ** (6 - cAfterDP)
    
    for (int i=(6 - cAfterDP); i>0; i--) {
        fInHz *= 10;
    }
    return fInHz;
}

@end
