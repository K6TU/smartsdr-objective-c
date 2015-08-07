//
//  Slice.m
//
//  Created by STU PHILLIPS on 8/5/13.
//  Copyright (c) 2013 STU PHILLIPS. All rights reserved.
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

#import "Radio.h"
#import "Slice.h"
#import "Meter.h"


@interface Slice() <RadioParser, RadioSliceMeter>
    
@property (nonatomic, strong, readwrite) NSNumber *thisSliceNumber;
@property (nonatomic, strong, readwrite) NSNumber *sliceInUse;
@property (readwrite, weak, nonatomic) Radio *radio;
@property (readwrite, strong, nonatomic) NSMutableDictionary *meters;
@property (readwrite, strong, nonatomic) dispatch_queue_t sliceRunQueue;
@property (strong, nonatomic) NSDictionary *statusSliceTokens;

- (void) initStatusSliceTokens;
- (long long int) freqStringToHertz: (NSString *) freq;
- (NSString *) formatFrequencyNumberAsCommandString:(NSNumber *) frequency;

@end


@implementation Slice


- (id) initWithRadio:(Radio *)radio sliceNumber: (NSInteger) sliceNum {
    self = [super init];
    
    if (self) {
        self.radio = radio;
        self.thisSliceNumber = [NSNumber numberWithInteger:sliceNum];
        // [[NSNotificationCenter defaultCenter] postNotificationName:@"SliceCreated" object:self];
        
        // Create a private run queue for us to run on
        NSString *qName = [NSString stringWithFormat:@"net.k6tu.sliceQueue-%i", (int)sliceNum];
        self.sliceRunQueue = dispatch_queue_create([qName UTF8String], NULL);
        
        
        // Initialize some state that will get overriden by status updates from the radio
        _sliceApfEnabled = [NSNumber numberWithBool:NO];
        _sliceAnfEnabled = [NSNumber numberWithBool:NO];
        _sliceNrEnabled = [NSNumber numberWithBool:NO];
        [self initStatusSliceTokens];
        
        self.meters = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (void) dealloc {
    // Free our private run queue
    self.sliceRunQueue = nil;
}

- (void) youAreBeingDeleted {
    // [[NSNotificationCenter defaultCenter] postNotificationName:@"SliceDeleted" object:self];
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

- (NSString *) formatFrequencyNumberAsString:(NSNumber *)frequency {
    return [self formatFrequencyNumberAsCommandString:frequency];
}


- (NSString *) formatFrequencyNumberAsCommandString:(NSNumber *) frequency {
    long long int fInHz = (long long int)[frequency longLongValue];
    NSString *fmtFreq = [NSString stringWithFormat:@"%i.%03i%03i",
                                  (int)(fInHz / 1000000), (int)(fInHz / 1000 % 1000), (int)(fInHz % 1000) ];
    return fmtFreq;
}


#pragma mark
#pragma mark RadioSliceMeter Protocol handlers

- (void) addMeter:(Meter *)meter {
    @synchronized(self.meters) {
        self.meters[meter.shortName] = meter;
    }
}

- (void) removeMeter:(Meter *)meter {
    @synchronized(self.meters) {
        [self.meters removeObjectForKey:meter.shortName];
    }
}


#pragma mark
#pragma Setters

// Private macro to improve readibility of setters

#define commandUpdateNotify(cmd, key, ivar, value) \
    /* Let observers know the change on the main queue */ \
    [self willChangeValueForKey:(key)]; \
    (ivar) = (value); \
    [self didChangeValueForKey:key]; \
    \
    __weak Slice *safeSelf = self; \
    dispatch_async(self.sliceRunQueue, ^(void) { \
        /* Send the command to the radio on our private queue */  \
        [safeSelf.radio commandToRadio:(cmd)]; \
         \
    });


-(void) setSliceFrequency:(NSString *)sliceFrequency {
    NSString *cmd = [NSString stringWithFormat: @"slice tune %i %@",
                     [self.thisSliceNumber intValue],
                     sliceFrequency];
    NSString *refSliceFrequency = sliceFrequency;
    
    commandUpdateNotify(cmd, @"sliceFrequency", _sliceFrequency, refSliceFrequency);
}


- (void)setSliceFrequency:(NSString *)sliceFrequency autopan:(BOOL)autopan {
    NSString *cmd = [NSString stringWithFormat: @"slice tune %i %@ autopan=%i",
                     [self.thisSliceNumber intValue],
                     sliceFrequency,
                     autopan];
    NSString *refSliceFrequency = sliceFrequency;

    commandUpdateNotify(cmd, @"sliceFrequency", _sliceFrequency, refSliceFrequency);
}

- (void) setSliceRxAnt:(NSString *)sliceRxAnt {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i rxant=%@",
                     [self.thisSliceNumber intValue],
                     sliceRxAnt];
    NSString *refSliceRxAnt = sliceRxAnt;

    commandUpdateNotify(cmd, @"salceRxAnt", _sliceRxAnt, refSliceRxAnt);
}


- (void) setSliceTxAnt:(NSString *)sliceTxAnt {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i txant=%@",
                     [self.thisSliceNumber intValue],
                     sliceTxAnt];
    NSString *refSliceTxAnt = sliceTxAnt;
    
    commandUpdateNotify(cmd, @"sliceTxAnt", _sliceTxAnt, refSliceTxAnt);
}


- (void) setSliceXitEnabled:(NSNumber *)sliceXitEnabled {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i xit_on=%i",
                     [self.thisSliceNumber intValue],
                     [sliceXitEnabled boolValue]];
    NSNumber *refSliceXitEnabled = sliceXitEnabled;
    
    commandUpdateNotify(cmd, @"sliceXitEnabled", _sliceXitEnabled, refSliceXitEnabled);
}


- (void) setSliceXitOffset:(NSNumber *)sliceXitOffset {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i xit_freq=%i",
                     [self.thisSliceNumber intValue],
                     [sliceXitOffset intValue]];
    NSNumber *refSliceXitOffset = sliceXitOffset;

    commandUpdateNotify(cmd, @"sliceXitOffset", _sliceXitOffset, refSliceXitOffset);
}


- (void) setSliceRitEnabled:(NSNumber *)sliceRitEnabled {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i rit_on=%i",
                     [self.thisSliceNumber intValue],
                     [sliceRitEnabled boolValue]];
    NSNumber *refSliceRitEnabled = sliceRitEnabled;

    commandUpdateNotify(cmd, @"sliceRitEnabled", _sliceRitEnabled, refSliceRitEnabled);
}


- (void) setSliceRitOffset:(NSNumber *)sliceRitOffset {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i rit_freq=%i",
                     [self.thisSliceNumber intValue],
                     [sliceRitOffset intValue]];
    NSNumber *refSliceRitOffset = sliceRitOffset;
    
    commandUpdateNotify(cmd, @"sliceRitOffset", _sliceRitOffset, refSliceRitOffset);
}


- (void) setSliceMode:(NSString *)sliceMode {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i mode=%@",
                     [self.thisSliceNumber intValue],
                     sliceMode];
    NSString *refSliceMode = sliceMode;
    
    commandUpdateNotify(cmd, @"sliceMode", _sliceMode, refSliceMode);
}


- (void)setSliceFilterLo:(NSNumber *)sliceFilterLo {
    NSString *cmd = [NSString stringWithFormat:@"filt %i %i %i",
                     [self.thisSliceNumber intValue],
                     [sliceFilterLo intValue],
                     [self.sliceFilterHi intValue]];
    NSNumber *refSliceFilterLo = sliceFilterLo;
    
    commandUpdateNotify(cmd, @"sliceFilterLo", _sliceFilterLo, refSliceFilterLo);
}


- (void)setSliceFilterHi:(NSNumber *)sliceFilterHi {
    NSString *cmd = [NSString stringWithFormat:@"filt %i %i %i",
                     [self.thisSliceNumber intValue],
                     [self.sliceFilterLo intValue],
                     [sliceFilterHi intValue]];
    NSNumber *refSliceFilterHi = sliceFilterHi;
    
    commandUpdateNotify(cmd, @"sliceFilterHi", _sliceFilterHi, refSliceFilterHi);
}


- (void) setSliceNbEnabled:(NSNumber *)sliceNbEnabled {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i nb=%i",
                     [self.thisSliceNumber intValue],
                     [sliceNbEnabled boolValue]];
    NSNumber *refSliceNbEnabled = sliceNbEnabled;
    
    commandUpdateNotify(cmd, @"sliceNbEnabled", _sliceNbEnabled, refSliceNbEnabled);
}


- (void) setSliceNbLevel:(NSNumber *)sliceNbLevel {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i nb_level=%i",
                     [self.thisSliceNumber intValue],
                     [sliceNbLevel intValue]];
    NSNumber *refSliceNbLevel = sliceNbLevel;
    
    commandUpdateNotify(cmd, @"sliceNbLevel", _sliceNbLevel, refSliceNbLevel);
}


- (void) setSliceNrEnabled:(NSNumber *)sliceNrEnabled {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i nr=%i",
                     [self.thisSliceNumber intValue],
                     [sliceNrEnabled intValue]];
    NSNumber *refSliceNrEnabled = sliceNrEnabled;
    
    commandUpdateNotify(cmd, @"sliceNrEnabled", _sliceNrEnabled, refSliceNrEnabled);
}


- (void)setSliceNrLevel:(NSNumber *)sliceNrLevel {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i nr_level=%i",
                     [self.thisSliceNumber intValue],
                     [sliceNrLevel intValue]];
    NSNumber *refSliceNrLevel = sliceNrLevel;
    
    commandUpdateNotify(cmd, @"sliceNrLevel", _sliceNrLevel, refSliceNrLevel);
    
}


- (void) setSliceAnfEnabled:(NSNumber *)sliceAnfEnabled {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i anf=%i",
                     [self.thisSliceNumber intValue],
                     [sliceAnfEnabled intValue]];
    NSNumber *refSliceAnfEnabled = sliceAnfEnabled;
    commandUpdateNotify(cmd, @"sliceAnfEnabled", _sliceAnfEnabled, refSliceAnfEnabled);
}


- (void) setSliceAnfLevel:(NSNumber *)sliceAnfLevel {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i anf_level=%i",
                     [self.thisSliceNumber intValue],
                     [sliceAnfLevel intValue]];
    NSNumber *refSliceAnfLevel = sliceAnfLevel;
    commandUpdateNotify(cmd, @"sliceAnfLevel", _sliceAnfLevel, refSliceAnfLevel);
}


-(void) setSliceApfEnabled:(NSNumber *)sliceApfEnabled {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i apf=%i",
                     [self.thisSliceNumber intValue],
                     [sliceApfEnabled intValue]];
    NSNumber *refSliceApfEnabled = sliceApfEnabled;
    
    commandUpdateNotify(cmd, @"sliceApfEnabled", _sliceApfEnabled, refSliceApfEnabled);
}


- (void) setSliceApfLevel:(NSNumber *)sliceApfLevel {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i apf=%i apf_level=%i",
                     [self.thisSliceNumber intValue], [self.sliceApfEnabled boolValue],
                     [sliceApfLevel intValue]];
    NSNumber *refSliceApfLevel = sliceApfLevel;
    commandUpdateNotify(cmd, @"sliceApfLevel", _sliceApfLevel, refSliceApfLevel);
}


- (void) setSliceAgcMode:(NSString *)sliceAgcMode {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i agc_mode=%@",
                     [self.thisSliceNumber intValue],
                     [sliceAgcMode lowercaseString]];
    NSString *refSliceAgcMode = sliceAgcMode;
    
    commandUpdateNotify(cmd, @"sliceAgcMode", _sliceAgcMode, refSliceAgcMode);
}


- (void) setSliceAgcThreshold:(NSNumber *)sliceAgcThreshold {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i agc_threshold=%i",
                     [self.thisSliceNumber intValue],
                     [sliceAgcThreshold intValue]];
    NSNumber *refSliceAgcThreshold = sliceAgcThreshold;
    
    commandUpdateNotify(cmd, @"sliceAgcThreshold", _sliceAgcThreshold, refSliceAgcThreshold);
}


- (void) setSliceTxEnabled:(NSNumber *)sliceTxEnabled  {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i tx=%@",
                     [self.thisSliceNumber intValue],
                     sliceTxEnabled];
    NSNumber *refSliceTxEnabled = sliceTxEnabled;
    
    commandUpdateNotify(cmd, @"sliceTxEnabled", _sliceTxEnabled, refSliceTxEnabled);
}


- (void) setSliceLocked:(NSNumber *)sliceLocked {
    NSString * cmd;
    
    if ([sliceLocked boolValue])
        cmd = [NSString stringWithFormat:@"slice lock %i", [self.thisSliceNumber intValue]];
    else
        cmd = [NSString stringWithFormat:@"slice unlock %i", [self.thisSliceNumber intValue]];
    
    NSNumber *refSliceLocked = sliceLocked;
    
    commandUpdateNotify(cmd, @"sliceLocked", _sliceLocked, refSliceLocked);
}


- (void) setSliceActive:(NSNumber *)sliceActive {
    if ([self.sliceActive boolValue] == [sliceActive boolValue])
        return;
    
    NSString *cmd = [NSString stringWithFormat:@"slice set %i active=%i",
                     [self.thisSliceNumber intValue],
                     [sliceActive intValue]];
    NSNumber *refSliceActive = sliceActive;
    
    commandUpdateNotify(cmd, @"sliceActive", _sliceActive, refSliceActive);
}


- (void) setSliceDax:(NSNumber *)sliceDax {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i dax=%i",
                     [self.thisSliceNumber intValue],
                     [sliceDax intValue]];
    NSNumber *refSliceDax = sliceDax;
    
    commandUpdateNotify(cmd, @"sliceDax", _sliceDax, refSliceDax);
    
}


- (void) setSliceMuteEnabled:(NSNumber *)sliceMuteEnabled {
    NSString *cmd = [NSString stringWithFormat:@"audio client 0 slice %i mute %i",
                     [self.thisSliceNumber intValue],
                     [sliceMuteEnabled intValue]];
    NSNumber *refSliceMuteEnabled = sliceMuteEnabled;

    commandUpdateNotify(cmd, @"sliceMuteEnabled", _sliceMuteEnabled, refSliceMuteEnabled);
}


- (void) setSliceAudioLevel:(NSNumber *)sliceAudioLevel {
    NSString *cmd = [NSString stringWithFormat:@"audio client 0 slice %i gain %i",
                     [self.thisSliceNumber intValue],
                     [sliceAudioLevel intValue]];
    NSNumber *refSliceAudioLevel = sliceAudioLevel;
    
    commandUpdateNotify(cmd, @"sliceAudioLevel", _sliceAudioLevel, refSliceAudioLevel);
    
}


- (void) setSlicePanControl:(NSNumber *)slicePanControl {
    NSString *cmd = [NSString stringWithFormat:@"audio client 0 slice %i pan %i",
                     [self.thisSliceNumber intValue],
                     [slicePanControl intValue]];
    NSNumber *refSlicePanControl = slicePanControl;
    
    commandUpdateNotify(cmd, @"slicePanControl", _slicePanControl, refSlicePanControl);
}


- (void) setSlicePlaybackEnabled:(NSNumber *)slicePlaybackEnabled {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i play=%i",
                     [self.thisSliceNumber intValue],
                     [slicePlaybackEnabled intValue]];
    NSNumber *refSlicePlaybackEnabled = slicePlaybackEnabled;
    
    commandUpdateNotify(cmd, @"slicePlaybackEnabled", _slicePlaybackEnabled, refSlicePlaybackEnabled);
}


- (void) setSliceRecordEnabled:(NSNumber *)sliceRecordEnabled {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i record=%i",
                     [self.thisSliceNumber intValue],
                     [sliceRecordEnabled intValue]];
    NSNumber *refSliceRecordEnabled = sliceRecordEnabled;
    
    commandUpdateNotify(cmd, @"sliceRecordEnabled", _sliceRecordEnabled, refSliceRecordEnabled);
}


- (void) setSliceDiversityEnabled:(NSNumber *)sliceDiversityEnabled {
    
}


- (void) setSquelchEnabled:(NSNumber *)squelchEnabled {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i squelch=%i",
                     [self.thisSliceNumber intValue],
                     [squelchEnabled intValue]];
    NSNumber *refSquelchEnabled = squelchEnabled;
    
    commandUpdateNotify(cmd, @"squelchEnabled", _squelchEnabled, refSquelchEnabled);
}


- (void) setSquelchLevel:(NSNumber *)squelchLevel {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i squelch_level=%i",
                     [self.thisSliceNumber intValue],
                     [squelchLevel intValue]];
    NSNumber *refSquelchLevel = squelchLevel;
    
    commandUpdateNotify(cmd, @"squelchLevel", _squelchLevel, refSquelchLevel);
}


- (void) setFmToneMode:(NSString *)fmToneMode {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i fm_tone_mode=%@",
                     [self.thisSliceNumber intValue],
                     fmToneMode];
    NSString *refFmToneMode = fmToneMode;
    
    commandUpdateNotify(cmd, @"fmToneMode", _fmToneMode, refFmToneMode);
}


- (void) setFmToneFreq:(NSNumber *)fmToneFreq {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i fm_tone_value=%.1f",
                     [self.thisSliceNumber intValue],
                     [fmToneFreq floatValue ]];
    NSNumber *refFmToneFreq = fmToneFreq;
    
    commandUpdateNotify(cmd, @"fmToneFreq", _fmToneFreq, refFmToneFreq);
}


- (void) setFmRepeaterOffset:(NSNumber *)fmRepeaterOffset {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i fm_repeater_offset_freq=%.3f",
                     [self.thisSliceNumber intValue],
                     [fmRepeaterOffset floatValue]];
    NSNumber *refFmRepeaterOffset = fmRepeaterOffset;
    
    commandUpdateNotify(cmd, @"fmRepeaterOffset", _fmRepeaterOffset, refFmRepeaterOffset);
}


- (void) setTxOffsetFreq:(NSNumber *)txOffsetFreq {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i tx_offset_freq=%f",
                     [self.thisSliceNumber intValue],
                     [txOffsetFreq floatValue]];
    NSNumber *refTxOffsetFreq = txOffsetFreq;
    
    commandUpdateNotify(cmd, @"txOffsetFreq", _txOffsetFreq, refTxOffsetFreq);
}


- (void) setRepeaterOffsetDir:(NSString *)repeaterOffsetDir {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i repeater_offset_dir=%@",
                     [self.thisSliceNumber intValue],
                     repeaterOffsetDir];
    NSString *refRepeaterOffsetDir = repeaterOffsetDir;
    
    commandUpdateNotify(cmd, @"repeaterOffsetDir", _repeaterOffsetDir, refRepeaterOffsetDir);
}


- (void) setFmToneBurstEnabled:(NSNumber *)fmToneBurstEnabled {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i fm_tone_burst=%i",
                     [self.thisSliceNumber intValue], [fmToneBurstEnabled boolValue]];
    NSNumber *refFmToneBurstEnabled = fmToneBurstEnabled;
    
    commandUpdateNotify(cmd, @"fmToneBurstEnabled", _fmToneBurstEnabled, refFmToneBurstEnabled);
}


- (void) setFmDeviation:(NSNumber *)fmDeviation {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i fm_deviation=%i",
                     [self.thisSliceNumber intValue], [fmDeviation intValue]];
    NSNumber *refFmDeviation = fmDeviation;
    
    commandUpdateNotify(cmd, @"fmDeviation", _fmDeviation, refFmDeviation);
}


- (void) setFmPreDeEmphasis:(NSNumber *)fmPreDeEmphasis {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i dfm_pre_de_emphasis=%i",
                     [self.thisSliceNumber intValue], [fmPreDeEmphasis boolValue]];
    NSNumber *refFmPreDeEmphasis = fmPreDeEmphasis;
    
    commandUpdateNotify(cmd, @"fmPreDeEmphasis", _fmPreDeEmphasis, refFmPreDeEmphasis);
}


- (void) setPostDemodLo:(NSNumber *)postDemodLo {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i post_demod_low=%i",
                     [self.thisSliceNumber intValue], [postDemodLo intValue]];
    NSNumber *refPostDemodLo = postDemodLo;
    
    commandUpdateNotify(cmd, @"postDemodLo", _postDemodLo, refPostDemodLo);
}


- (void) setPostDemodHi:(NSNumber *)postDemodHi {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i post_demod_high=%i",
                     [self.thisSliceNumber intValue], [postDemodHi intValue]];
    NSNumber *refPostDemodHi = postDemodHi;
    
    commandUpdateNotify(cmd, @"postDemodHi", _postDemodHi, refPostDemodHi);
}


- (void) setPostDemodBypassEnabled:(NSNumber *)postDemodBypassEnabled {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i post_demod_bypass=%i",
                     [self.thisSliceNumber intValue], [postDemodBypassEnabled intValue]];
    NSNumber *refPostDemodBypassEnabled = postDemodBypassEnabled;
    
    commandUpdateNotify(cmd, @"postDemodBypassEnabled", _postDemodBypassEnabled, refPostDemodBypassEnabled);
}


- (void) setRttyMark:(NSNumber *)rttyMark {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i rtty_mark=%i",
                     [self.thisSliceNumber intValue], [rttyMark intValue]];
    NSNumber *refRttyMark = rttyMark;
    
    commandUpdateNotify(cmd, @"rttyMark", _rttyMark, refRttyMark);
}


- (void) setRttyShift:(NSNumber *)rttyShift {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i rtty_shift=%i",
                     [self.thisSliceNumber intValue], [rttyShift intValue]];
    NSNumber *refRttyShift = rttyShift;
    
    commandUpdateNotify(cmd, @"rttyShift", _rttyShift, refRttyShift);
}


- (void) setDiglOffset:(NSNumber *)diglOffset {
    NSString *cmd = [NSString stringWithFormat:@"slice set %i digl_offset=%i",
                     [self.thisSliceNumber intValue], [diglOffset intValue]];
    NSNumber *refDiglOffset = diglOffset;
    
    commandUpdateNotify(cmd, @"diglOffset", _diglOffset, refDiglOffset);
}


- (void) setDighOffset:(NSNumber *)diguOffset {
        NSString *cmd = [NSString stringWithFormat:@"slice set %i digu_offset=%i",
                         [self.thisSliceNumber intValue], [diguOffset intValue]];
        NSNumber *refDiguOffset = diguOffset;
        
        commandUpdateNotify(cmd, @"diguOffset", _diguOffset, refDiguOffset);
}

#pragma mark
#pragma mark Slice Parser

enum enumStatusSliceTokens {
    enumStatusSliceTokenNone = 0,
    rfFrequencyToken,
    modeToken,
    rxAntToken,
    txAntToken,
    filterLoToken,
    filterHiToken,
    nrToken,
    nrLevelToken,
    nbToken,
    nbLevelToken,
    anfToken,
    anfLevelToken,
    apfToken,
    apfLevelToken,
    agcModeToken,
    agcThresholdToken,
    agcOffLevelToken,
    txToken,
    activeToken,
    ownerToken,
    ghostToken,
    wideToken,
    inUseToken,
    panToken,
    loopaToken,
    loopbToken,
    qskToken,
    audioPanToken,
    audioGainToken,
    audioMuteToken,
    xitOnToken,
    ritOnToken,
    xitFreqToken,
    ritFreqToken,
    daxToken,
    daxClientsToken,
    daxTxToken,
    lockToken,
    stepToken,
    stepListToken,
    recordToken,
    playToken,
    recordTimeToken,
    diversityToken,
    diversityParentToken,
    diversityChildToken,
    diversityIndexToken,
    antListToken,
    squelchToken,
    squelchLevelToken,
    modeListToken,
    fmToneModeToken,
    fmToneValueToken,
    fmRepeaterOffsetToken,
    txOffsetFreqToken,
    repeaterOffsetDirToken,
    fmToneBurstToken,
    fmDeviationToken,
    dfmPreDeEmphasisToken,
    postDemodLowToken,
    postDemodHighToken,
    rttyMarkToken,
    rttyShiftToken,
    diglOffsetToken,
    diguOffsetToken,
    postDemodBypassEnabledToken,
};


- (void) initStatusSliceTokens {
    self.statusSliceTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [NSNumber numberWithInt:rfFrequencyToken], @"RF_frequency",
                              [NSNumber numberWithInt:modeToken], @"mode",
                              [NSNumber numberWithInt:rxAntToken], @"rxant",
                              [NSNumber numberWithInt:txAntToken], @"txant",
                              [NSNumber numberWithInt:filterLoToken], @"filter_lo",
                              [NSNumber numberWithInt:filterHiToken], @"filter_hi",
                              [NSNumber numberWithInt:nrToken], @"nr",
                              [NSNumber numberWithInt:nrLevelToken], @"nr_level",
                              [NSNumber numberWithInt:nbToken], @"nb",
                              [NSNumber numberWithInt:nbLevelToken], @"nb_level",
                              [NSNumber numberWithInt:anfToken], @"anf",
                              [NSNumber numberWithInt:anfLevelToken], @"anf_level",
                              [NSNumber numberWithInt:apfToken], @"apf",
                              [NSNumber numberWithInt:apfLevelToken], @"apf_level",
                              [NSNumber numberWithInt:agcModeToken], @"agc_mode",
                              [NSNumber numberWithInt:agcThresholdToken], @"agc_threshold",
                              [NSNumber numberWithInt:agcOffLevelToken], @"agc_off_level",
                              [NSNumber numberWithInt:txToken], @"tx",
                              [NSNumber numberWithInt:activeToken], @"active",
                              [NSNumber numberWithInt:ownerToken], @"owner",
                              [NSNumber numberWithInt:ghostToken], @"ghost",
                              [NSNumber numberWithInt:wideToken], @"wide",
                              [NSNumber numberWithInt:inUseToken], @"in_use",
                              [NSNumber numberWithInt:panToken], @"pan",
                              [NSNumber numberWithInt:loopaToken], @"loopa",
                              [NSNumber numberWithInt:loopbToken], @"loopb",
                              [NSNumber numberWithInt:qskToken], @"qsk",
                              [NSNumber numberWithInt:audioGainToken], @"audio_gain",
                              [NSNumber numberWithInt:audioPanToken], @"audio_pan",
                              [NSNumber numberWithInt:audioMuteToken], @"audio_mute",
                              [NSNumber numberWithInt:xitOnToken], @"xit_on",
                              [NSNumber numberWithInt:ritOnToken], @"rit_on",
                              [NSNumber numberWithInt:xitFreqToken], @"xit_freq",
                              [NSNumber numberWithInt:ritFreqToken], @"rit_freq",
                              [NSNumber numberWithInt:daxToken], @"dax",
                              [NSNumber numberWithInt:daxClientsToken], @"dax_clients",
                              [NSNumber numberWithInt:daxTxToken], @"dax_tx",
                              [NSNumber numberWithInt:lockToken], @"lock",
                              [NSNumber numberWithInt:stepToken], @"step",
                              [NSNumber numberWithInt:stepListToken], @"step_list",
                              [NSNumber numberWithInt:recordToken], @"record",
                              [NSNumber numberWithInt:playToken], @"play",
                              [NSNumber numberWithInt:recordTimeToken], @"record_time",
                              [NSNumber numberWithInt:diversityToken], @"diversity",
                              [NSNumber numberWithInt:diversityParentToken], @"diversity_parent",
                              [NSNumber numberWithInt:diversityChildToken], @"diversity_child",
                              [NSNumber numberWithInt:diversityIndexToken], @"diversity_index",
                              [NSNumber numberWithInt:antListToken], @"ant_list",
                              [NSNumber numberWithInt:squelchToken], @"squelch",
                              [NSNumber numberWithInt:squelchLevelToken], @"squelch_level",
                              [NSNumber numberWithInt:modeListToken], @"mode_list",
                              [NSNumber numberWithInt:fmToneModeToken], @"fm_tone_mode",
                              [NSNumber numberWithInt:fmToneValueToken], @"fm_tone_value",
                              [NSNumber numberWithInt:fmRepeaterOffsetToken], @"fm_repeater_offset_freq",
                              [NSNumber numberWithInt:txOffsetFreqToken], @"tx_offset_freq",
                              [NSNumber numberWithInt:repeaterOffsetDirToken], @"repeater_offset_dir",
                              [NSNumber numberWithInt:fmToneBurstToken], @"fm_tone_burst",
                              [NSNumber numberWithInt:fmDeviationToken], @"fm_deviation",
                              [NSNumber numberWithInt:dfmPreDeEmphasisToken], @"dfm_pre_de_emphasis",
                              [NSNumber numberWithInt:postDemodLowToken], @"post_demod_low",
                              [NSNumber numberWithInt:postDemodHighToken], @"post_demod_high",
                              [NSNumber numberWithInt:postDemodBypassEnabledToken], @"post_demod_bypass",
                              [NSNumber numberWithInt:rttyMarkToken], @"rtty_mark",
                              [NSNumber numberWithInt:rttyShiftToken], @"rtty_shift",
                              [NSNumber numberWithInt:diglOffsetToken], @"digl_offset",
                              [NSNumber numberWithInt:diguOffsetToken], @"digu_offset",
                              nil];
}


// Private Macro
//
// Macro to perform inline update on an ivar with KVO notification

#define updateWithNotify(key,ivar,value)  \
{    \
     __weak Slice *safeSelf = self; \
     dispatch_async(dispatch_get_main_queue(), ^(void) { \
        [safeSelf willChangeValueForKey:(key)]; \
        (ivar) = (value); \
        [safeSelf didChangeValueForKey:(key)]; \
    }); \
}

- (void) statusParser:(NSScanner *)scan selfStatus:(BOOL)selfStatus {
    NSString *token;
    NSInteger intVal;
    NSString *stringVal;
    
    float floatVal;
    BOOL play;
    
    while (![scan isAtEnd]) {
        // Grab the token between current scanner position and the '=' separator
        // and then eat the '='
        [scan scanUpToString:@"=" intoString:&token];
        [scan scanString:@"=" intoString:nil];
        
        // Look up in our dictionary
        int thisToken = [self.statusSliceTokens[token] intValue];
        
        switch (thisToken) {
            case rfFrequencyToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                updateWithNotify(@"sliceFrequency", _sliceFrequency, stringVal);
                break;
                
            case modeToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                updateWithNotify(@"sliceMode",_sliceMode,stringVal);
                break;
                
            case rxAntToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                updateWithNotify(@"sliceRxAnt",_sliceRxAnt,stringVal);
                break;
                
            case txAntToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                updateWithNotify(@"sliceTxAnt",_sliceTxAnt,stringVal);
                break;
                
            case filterLoToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceFilterLo",_sliceFilterLo,[NSNumber numberWithInteger:intVal]);
                break;
                
            case filterHiToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceFilterHi",_sliceFilterHi,[NSNumber numberWithInteger:intVal]);
                break;
                
            case nrToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceNrEnabled",_sliceNrEnabled,[NSNumber numberWithInteger:intVal]);
                break;
                
            case nrLevelToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceNrLevel",_sliceNrLevel,[NSNumber numberWithInteger:intVal]);
                break;
                
            case nbToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceNbEnabled",_sliceNbEnabled,[NSNumber numberWithInteger:intVal]);
                break;
                
            case nbLevelToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceNbLevel",_sliceNbLevel,[NSNumber numberWithInteger:intVal]);
                break;
                
            case anfToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceAnfEnabled",_sliceAnfEnabled,[NSNumber numberWithInteger:intVal]);
                break;
                
            case anfLevelToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceAnfLevel",_sliceAnfLevel,[NSNumber numberWithInteger:intVal]);
                break;
                
            case apfToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceApfEnabled",_sliceApfEnabled,[NSNumber numberWithInteger:intVal]);
                break;
                
            case apfLevelToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceApfLevel",_sliceApfLevel,[NSNumber numberWithInteger:intVal]);
                break;
                
            case agcModeToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                updateWithNotify(@"sliceAgcMode",_sliceAgcMode,stringVal);
                break;
                
            case agcThresholdToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceAgcThreshold",_sliceAgcThreshold,[NSNumber numberWithInteger:intVal]);
                break;
                
            case agcOffLevelToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceAgcOffLevel",_sliceAgcOffLevel,[NSNumber numberWithInteger:intVal]);
                break;
                
            case txToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceTxEnabled",_sliceTxEnabled,[NSNumber numberWithBool:intVal]);
                break;
                
            case activeToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceActive",_sliceActive,[NSNumber numberWithBool:intVal]);
                break;
                
            case ghostToken:
                [scan scanInteger:&intVal];
                // _sliceGhost = [NSNumber numberWithInteger:intVal];
                break;
                
            case ownerToken:
                // [scan scanInteger:&intVal];
                // thisSlice.sliceOwner = [NSNumber numberWithInteger:intVal];
                break;
                
            case wideToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceWide",_sliceWide,[NSNumber numberWithBool:intVal]);
                break;
                
            case inUseToken:
                [scan scanInteger:&intVal];
                
                if (!intVal) {
                    // If in_use=0, this slice has been deleted and we need to make it go away
                    // in an orderly fashion - BEFORE we update the property OR make it go away!
                    [self youAreBeingDeleted];
                    
                    // By the time this returns, the slice be deletable - post the transition to
                    // not in use
                    updateWithNotify(@"sliceInUse",_sliceInUse,[NSNumber numberWithBool:NO]);
                } else {
                    updateWithNotify(@"sliceInUse",_sliceInUse,[NSNumber numberWithBool:YES]);
                }
                break;
                
            case panToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                updateWithNotify(@"panForSlice",_panForSlice,stringVal);
                break;
                
            case loopaToken:
                [scan scanInteger:&intVal];
                                 updateWithNotify(@"loopAEnabled",_loopAEnabled,[NSNumber numberWithBool:intVal]);
                break;
                
            case loopbToken:
                [scan scanInteger:&intVal];
                                 updateWithNotify(@"loopBEnabled",_loopBEnabled,[NSNumber numberWithBool:intVal]);
                break;
                
            case qskToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"qskEnabled",_qskEnabled,[NSNumber numberWithBool:intVal]);
                break;
                
            case audioGainToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceAudioLevel",_sliceAudioLevel,[NSNumber numberWithInteger:intVal]);
                break;
                
            case audioPanToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"slicePanControl",_slicePanControl,[NSNumber numberWithInteger:intVal]);
                break;
                
            case audioMuteToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceMuteEnabled",_sliceMuteEnabled,[NSNumber numberWithBool:intVal]);
                break;
                
            case xitOnToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceXitEnabled",_sliceXitEnabled,[NSNumber numberWithBool:intVal]);
                break;
                
            case ritOnToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceRitEnabled",_sliceRitEnabled,[NSNumber numberWithBool:intVal]);
                break;
                
            case xitFreqToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceXitOffset",_sliceXitOffset,[NSNumber numberWithInteger:intVal]);
                break;
                
            case ritFreqToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceRitOffset",_sliceRitOffset,[NSNumber numberWithInteger:intVal]);
                break;
                
            case daxToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceDax",_sliceDax,[NSNumber numberWithInteger:intVal]);
                break;
                
            case daxClientsToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceDaxClients",_sliceDaxClients,[NSNumber numberWithInteger:intVal]);
                break;
                
            case daxTxToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceDaxTxEnabled",_sliceDaxTxEnabled,[NSNumber numberWithBool:intVal]);
                break;
                
            case lockToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceLocked",_sliceLocked,[NSNumber numberWithBool:intVal]);
                break;
                
            case stepToken:
                [scan scanInteger:&intVal];
                break;
                
            case stepListToken:
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]
                                     intoString:&stringVal];
                updateWithNotify(@"stepList", _stepList, [[NSMutableArray alloc]initWithArray:[stringVal componentsSeparatedByString:@","]]);
                break;
                
            case recordToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceRecordEnabled",_sliceRecordEnabled,[NSNumber numberWithBool:intVal]);
                break;
                
            case playToken:
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]
                                     intoString:&stringVal];
                
                // Depending on whether the command was sent with "enabled" or "1", the reply will be
                // similarly encoded...  SSDR sends enabled - we sent 1...
                // Argh!
                play = [stringVal isEqualToString:@"enabled"] || [stringVal isEqualToString:@"1"];
                
                updateWithNotify(@"slicePlaybackEnabled",_slicePlaybackEnabled,[NSNumber numberWithBool:play]);
                break;
                
            case recordTimeToken:
                [scan scanFloat:&floatVal];
                updateWithNotify(@"sliceQRlength",_sliceQRlength,[NSNumber numberWithFloat:floatVal]);
                break;
                
            case diversityToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceDiversityEnabled",_sliceDiversityEnabled,[NSNumber numberWithBool:intVal]);
                break;
                
            case diversityParentToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceDiversityParent",_sliceDiversityParent,[NSNumber numberWithInteger:intVal]);
                break;
                
            case diversityChildToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliveDiversityChild",_sliceDiversityChild,[NSNumber numberWithInteger:intVal]);
                break;
                
            case diversityIndexToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sliceDoversityIndex",_sliceDiversityIndex,[NSNumber numberWithInteger:intVal]);
                break;
                
            case antListToken:
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]
                                     intoString:&stringVal];
                updateWithNotify(@"antList",_antList,[[NSMutableArray alloc] initWithArray:[stringVal componentsSeparatedByString:@","]]);
                break;
                
            case squelchToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"squelchEnabled",_squelchEnabled,[NSNumber numberWithBool:intVal]);
                break;
                
            case squelchLevelToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"squelchLevel",_squelchLevel,[NSNumber numberWithInteger:intVal]);
                break;
                
            case modeListToken:
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]
                                     intoString:&stringVal];
                updateWithNotify(@"modeList",_modeList,[[NSMutableArray alloc] initWithArray:[stringVal componentsSeparatedByString:@","]]);
                break;
                
            case fmToneModeToken:
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]
                                     intoString:&stringVal];
                updateWithNotify(@"fmToneMode",_fmToneMode,stringVal);
                break;
                
            case fmToneValueToken:
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]
                                     intoString:&stringVal];
                updateWithNotify(@"fmToneFreq",_fmToneFreq,[NSNumber numberWithFloat:[stringVal floatValue]]);
                break;
                
            case fmRepeaterOffsetToken:
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]
                                     intoString:&stringVal];
                updateWithNotify(@"fmRepeaterOffset",_fmRepeaterOffset,[NSNumber numberWithFloat:[stringVal floatValue]]);
                break;
                
            case txOffsetFreqToken:
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]
                                     intoString:&stringVal];
                updateWithNotify(@"txOffsetFreq",_txOffsetFreq,[NSNumber numberWithFloat:[stringVal floatValue]]);
                break;
                
            case repeaterOffsetDirToken:
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]
                                     intoString:&stringVal];
                updateWithNotify(@"repeaterOffsetDir",_repeaterOffsetDir,stringVal);
                break;
                
            case fmToneBurstToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"fmtToneBurstEnabled", _fmToneBurstEnabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case fmDeviationToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"fmDeviation", _fmDeviation, [NSNumber numberWithInteger:intVal]);
                break;
                
            case dfmPreDeEmphasisToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"fmPreDeEmphasis", _fmPreDeEmphasis, [NSNumber numberWithBool:intVal]);
                break;
                
            case postDemodLowToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"postDemodLo", _postDemodLo, [NSNumber numberWithInteger:intVal]);
                break;
                
            case postDemodHighToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"postDemodHi", _postDemodHi, [NSNumber numberWithInteger:intVal]);
                break;
                
            case postDemodBypassEnabledToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"postDemodBypassEnabled", _postDemodBypassEnabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case rttyMarkToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"rttyMark", _rttyMark, [NSNumber numberWithInteger:intVal]);
                break;
                
            case rttyShiftToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"rttyShift", _rttyShift, [NSNumber numberWithInteger:intVal]);
                break;
                
            case diglOffsetToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"diglOffset", _diglOffset, [NSNumber numberWithInteger:intVal]);
                break;
                
            case diguOffsetToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"diguOffset", _diguOffset, [NSNumber numberWithInteger:intVal]);
                break;
            
            default:
                // Unknown token and therefore an unknown argument type
                // Eat until the next space or \n
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]
                                     intoString:nil];
                NSLog(@"Unexpected token in Slice statusParser - %@", token);
                break;
        }
        
        // Scanner is either at a space or at the end - eat either
        [scan scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"] intoString:nil];
    }
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
