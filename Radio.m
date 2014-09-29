//
//  Radio.m
//
//  Created by STU PHILLIPS on 8/3/13.
//  Copyright (c) 2013 STU PHILLIPS. All rights reserved.
//
// NOTE: THe license under which this software will be generally released
// is still under consideration.  For now, use of this software requires
// the specific approval of Stu Phillips, K6TU.

#import "Radio.h"
#import "Slice.h"
#import "Equalizer.h"
#import "FilterSpec.h"



@interface Radio () {
    GCDAsyncSocket *socket;
    UInt16 seqNum;
    BOOL verbose;
    enum radioConnectionState connectionState;
}

@property (strong, nonatomic) NSObject<RadioDelegate> *delegate;

@property (strong, nonatomic) NSDictionary *statusTokens;
@property (strong, nonatomic) NSDictionary *statusInterlockTokens;
@property (strong, nonatomic) NSDictionary *statusInterlockStateTokens;
@property (strong, nonatomic) NSDictionary *statusInterlockReasonTokens;
@property (strong, nonatomic) NSDictionary *statusRadioTokens;
@property (strong, nonatomic) NSDictionary *statusAtuTokens;
@property (strong, nonatomic) NSDictionary *statusAtuStatusTokens;
@property (strong, nonatomic) NSDictionary *statusTransmitTokens;
@property (strong, nonatomic) NSDictionary *statusSliceTokens;
@property (strong, nonatomic) NSDictionary *statusEqTokens;
@property (strong, nonatomic) NSMutableDictionary *notifyList;

- (void) initStatusTokens;
- (void) initStatusInterlockTokens;
- (void) initStatusInterlockStateTokens;
- (void) initStatusInterlockReasonTokens;
- (void) initStatusRadioTokens;
- (void) initStatusAtuTokens;
- (void) initStatusAtuStatusTokens;
- (void) initStatusTransmitTokens;
- (void) initStatusSliceTokens;
- (void) initStatusEqTokens;

- (void) parseRadioStream: (NSString *) payload;
- (void) parseHandleType: (NSString *) payload;
- (void) parseStatusType: (NSString *) payload;
- (void) parseMessageType: (NSString *) payload;
- (void) parseVersionType: (NSString *) payload;
- (void) parseResponseType: (NSString *) payload;

- (void) parseInterlockToken: (NSScanner *) scan;
- (void) parseRadioToken: (NSScanner *) scan;
- (void) parseAtuToken: (NSScanner *) scan;
- (void) parseTransmitToken: (NSScanner *) scan selfStatus:(BOOL) selfStatus;
- (void) parseSliceToken: (NSScanner *) scan;
- (void) parseMixerToken: (NSScanner *) scan;
- (void) parseDisplayToken: (NSScanner *) scan;
- (void) parseMeterToken: (NSScanner *) scan;
- (void) parseEqToken: (NSScanner *) scan selfStatus: (BOOL) selfStatus;

@end


// Private enumerations...

enum enumStatusTokens {
    enumStatusTokensNone = 0,
    interlockToken,
    radioToken,
    atuToken,
    transmitToken,
    sliceToken,
    mixerToken,
    displayToken,
    meterToken,
    eqToken,
    gpsToken,
};

enum enumStatusInterlockTokens {
    enumStatusInterlockTokensNone = 0,
    timeoutToken,
    acc_txreq_enableToken,
    rca_txreq_enableToken,
    acc_txreq_polarityToken,
    rca_txreq_polarityToken,
    ptt_delayToken,
    tx1_delayToken,
    tx2_delayToken,
    tx3_delayToken,
    acc_tx_delayToken,
    tx_delayToken,
    stateToken,
    sourceToken,
    reasonToken,
    tx1EnabledToken,
    tx2EnabledToken,
    tx3EnabledToken,
    accTxEnabledToken,
};

enum enumStatusInterlockReasonTokens {
    enumStatusInterlockReasonTokensNone = 0,
    rcaTxReqReasonToken,
    accTxReqReasonToken,
    badModeReasonToken,
    tuneTooFarReasonToken,
    outOfBandReasonToken,
    paRangeReasonToken,
};

enum enumStatusInterlockStateTokens {
    enumStatusInternlockStateTokensNone = 0,
    receiveToken,
    readyToken,
    notReadyToken,
    pttRequestedToken,
    transmittingToken,
    txFaultToken,
    interlockTimeoutToken,
    stuckInputToken,
};


enum enumStatusAtuTokens {
    enumStatusAtuTokensNone = 0,
    atuStatusToken,
    atuEnabledToken,
};

enum enumStatusRadioTokens {
    enumStatusRadioTokensNone = 0,
    slicesToken,
    panadaptersToken,
    lineoutGainToken,
    lineoutMuteToken,
    headphoneGainToken,
    headphoneMuteToken,
    remoteOnToken,
    pllDoneToken,
    freqErrorToken,
    calFreqToken,
    tnfEnabledToken,
    snapTuneEnabledToken,
};


enum enumStatusAtuStatusTokens {
    enumStatusAtuStatusTokensNone = 0,
    tuneNotStartedToken,
    tuneInProgressToken,
    tuneBypassToken,
    tuneSuccessfulToken,
    tuneOkToken,
    tuneFailBypassToken,
    tuneFailToken,
    tuneAbortedToken,
    tuneManualBypassToken,
};

enum enumStatusTransmitTokens {
    enumStatusTransmitTokensNone = 0,
    freqToken,
    loTxFilterToken,
    hiTxFilterToken,
    rfPowerToken,
    amCarrierLevelToken,
    micLevelToken,
    micSelectionToken,
    micBoostToken,
    micBiasToken,
    companderToken,
    companderLevelToken,
    speechProcToken,
    speechProcLevelToken,
    noiseGateLevelToken,
    pitchToken,
    speedToken,
    iambicToken,
    iambicModeToken,
    swapPaddlesToken,
    breakInToken,
    breakInDelayToken,
    monitorToken,
    monitorGainToken,
    metInRxToken,
    voxToken,
    voxLevelToken,
    voxDelayToken,
    voxVisibleToken,
    monGainToken,
    tuneToken,
    voxEnableToken,
    micAccToken,
    tunePowerToken,
    hwAlcEnabledToken,
    daxTxEnabledToken,
    inhibitToken,
    showTxInWaterFallToken,
    sidetoneToken,
    sidetoneGainToken,
    sidetonePanToken,
    phMonitorToken,
    monitorPHGainToken,
    monitorPHPanToken,
    cwlEnabledToken,
    rawIQEnabledToken,
};

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
};

enum enumStatusMixerTokens {
    enumStatusMixerTokensNone = 0,
    
};

enum enumStatusEqTokens {
    enumStatusEqTokensNone = 0,
    eqRxToken,
    eqTxToken,
    eqModeToken,
    eqBand0Token,
    eqBand1Token,
    eqBand2Token,
    eqBand3Token,
    eqBand4Token,
    eqBand5Token,
    eqBand6Token,
    eqBand7Token,
};



@implementation Radio

NSNumber *txPowerLevel;

- (void) initStatusTokens {
    self.statusTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSNumber numberWithInt:interlockToken],  @"interlock",
                         [NSNumber numberWithInt:radioToken], @"radio",
                         [NSNumber numberWithInt:atuToken], @"atu",
                         [NSNumber numberWithInt:transmitToken], @"transmit",
                         [NSNumber numberWithInt:sliceToken], @"slice",
                         [NSNumber numberWithInt:mixerToken], @"mixer",
                         [NSNumber numberWithInt:displayToken], @"display",
                         [NSNumber numberWithInt:meterToken], @"meter",
                         [NSNumber numberWithInt:eqToken], @"eq",
                         [NSNumber numberWithInt:gpsToken], @"gps",
                         nil];
}


- (void) initStatusInterlockTokens {
    self.statusInterlockTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  [NSNumber numberWithInt:timeoutToken], @"timeout",
                                  [NSNumber numberWithInt:acc_txreq_enableToken], @"acc_txreq_enable",
                                  [NSNumber numberWithInt:rca_txreq_enableToken], @"rca_txreq_enable",
                                  [NSNumber numberWithInt:acc_txreq_polarityToken], @"acc_txreq_polarity",
                                  [NSNumber numberWithInt:rca_txreq_polarityToken], @"rca_txreq_polarity",
                                  [NSNumber numberWithInt:ptt_delayToken], @"ptt_delay",
                                  [NSNumber numberWithInt:tx1_delayToken], @"tx1_delay",
                                  [NSNumber numberWithInt:tx2_delayToken], @"tx2_delay",
                                  [NSNumber numberWithInt:tx3_delayToken], @"tx3_delay",
                                  [NSNumber numberWithInt:acc_tx_delayToken], @"acc_tx_delay",
                                  [NSNumber numberWithInt:tx_delayToken], @"tx_delay",
                                  [NSNumber numberWithInt:stateToken], @"state",
                                  [NSNumber numberWithInt:reasonToken], @"reason",
                                  [NSNumber numberWithInt:sourceToken], @"source",
                                  [NSNumber numberWithInt:tx1EnabledToken], @"tx1_enabled",
                                  [NSNumber numberWithInt:tx2EnabledToken], @"tx2_enabled",
                                  [NSNumber numberWithInt:tx3EnabledToken], @"tx3_enabled",
                                  [NSNumber numberWithInt:accTxEnabledToken], @"acc_tx_enabled",
                                  nil];
}


- (void) initStatusInterlockStateTokens {
    self.statusInterlockStateTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                                       [NSNumber numberWithInt:receiveToken], @"RECEIVE",
                                       [NSNumber numberWithInt:readyToken], @"READY",
                                       [NSNumber numberWithInt:notReadyToken], @"NOT_READY",
                                       [NSNumber numberWithInt:pttRequestedToken], @"PTT_REQUESTED",
                                       [NSNumber numberWithInt:transmittingToken], @"TRANSMITTING",
                                       [NSNumber numberWithInt:txFaultToken], @"TX_FAULT",
                                       [NSNumber numberWithInt:interlockTimeoutToken], @"TIMEOUT",
                                       [NSNumber numberWithInt:stuckInputToken], @"STUCK_INPUT",
                                       nil];
}


- (void) initStatusInterlockReasonTokens {
    self.statusInterlockReasonTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                                       [NSNumber numberWithInt:rcaTxReqReasonToken], @"RCA_TXREQ",
                                       [NSNumber numberWithInt:accTxReqReasonToken], @"ACC_RXREQ",
                                       [NSNumber numberWithInt:badModeReasonToken], @"BAD_MODE",
                                       [NSNumber numberWithInt:tuneTooFarReasonToken], @"TUNED_TOO_FAR",
                                       [NSNumber numberWithInt:outOfBandReasonToken], @"OUT_OF_BAND",
                                       [NSNumber numberWithInt:paRangeReasonToken], @"PA_RANGE",
                                       nil];
}



- (void) initStatusRadioTokens {
    self.statusRadioTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [NSNumber numberWithInt:slicesToken],  @"slices",
                              [NSNumber numberWithInt:panadaptersToken], @"panadapters",
                              [NSNumber numberWithInt:lineoutGainToken], @"lineout_gain",
                              [NSNumber numberWithInt:lineoutMuteToken], @"lineout_mute",
                              [NSNumber numberWithInt:headphoneGainToken], @"headphone_gain",
                              [NSNumber numberWithInt:headphoneMuteToken], @"headphone_mute",
                              [NSNumber numberWithInt:remoteOnToken], @"remote_on_enabled",
                              [NSNumber numberWithInt:pllDoneToken], @"pll_done",
                              [NSNumber numberWithInt:freqErrorToken], @"freq_error_ppb",
                              [NSNumber numberWithInt:calFreqToken], @"cal_freq",
                              [NSNumber numberWithInt:tnfEnabledToken], @"tnf_enabled",
                              [NSNumber numberWithInt:snapTuneEnabledToken], @"snap_tune_enabled",
                              nil];
}


- (void) initStatusAtuTokens {
    self.statusAtuTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [NSNumber numberWithInt:atuStatusToken],  @"status",
                              [NSNumber numberWithInt:atuEnabledToken], @"atu_enabled",
                              nil];
}


- (void) initStatusAtuStatusTokens {
    self.statusAtuStatusTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  [NSNumber numberWithInt:tuneNotStartedToken], @"TUNE_NOT_STARTED",
                                  [NSNumber numberWithInt:tuneInProgressToken], @"TUNE_IN_PROGRESS",
                                  [NSNumber numberWithInt:tuneBypassToken], @"TUNE_BYPASS",
                                  [NSNumber numberWithInt:tuneSuccessfulToken], @"TUNE_SUCCESSFUL",
                                  [NSNumber numberWithInt:tuneOkToken], @"TUNE_OK",
                                  [NSNumber numberWithInt:tuneFailBypassToken], @"TUNE_FAIL_BYPASS",
                                  [NSNumber numberWithInt:tuneFailToken], @"TUNE_FAIL",
                                  [NSNumber numberWithInt:tuneAbortedToken], @"TUNE_ABORTED",
                                  [NSNumber numberWithInt:tuneManualBypassToken], @"TUNE_MANUAL_BYPASS",
                                  nil];
}

- (void) initStatusTransmitTokens {
    self.statusTransmitTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 [NSNumber numberWithInt:rfPowerToken], @"rfpower",
                                 [NSNumber numberWithInt:freqToken], @"freq",
                                 [NSNumber numberWithInt:loTxFilterToken], @"lo",
                                 [NSNumber numberWithInt:hiTxFilterToken], @"hi",
                                 [NSNumber numberWithInt:amCarrierLevelToken], @"am_carrier_level",
                                 [NSNumber numberWithInt:amCarrierLevelToken], @"am_carrler_level",
                                 [NSNumber numberWithInt:micLevelToken], @"mic_level",
                                 [NSNumber numberWithInt:micSelectionToken], @"mic_selection",
                                 [NSNumber numberWithInt:micBoostToken], @"mic_boost",
                                 [NSNumber numberWithInt:micBiasToken], @"mic_bias",
                                 [NSNumber numberWithInt:micAccToken], @"mic_acc",
                                 [NSNumber numberWithInt:companderToken], @"compander",
                                 [NSNumber numberWithInt:companderLevelToken], @"compander_level",
                                 [NSNumber numberWithInteger:speechProcToken], @"speech_processor_enable",
                                 [NSNumber numberWithInteger:speechProcLevelToken], @"speech_processor_level",
                                 [NSNumber numberWithInt:noiseGateLevelToken], @"noise_gate_level",
                                 [NSNumber numberWithInt:pitchToken], @"pitch",
                                 [NSNumber numberWithInt:speedToken], @"speed",
                                 [NSNumber numberWithInt:iambicToken], @"iambic",
                                 [NSNumber numberWithInt:iambicModeToken], @"iambic_mode",
                                 [NSNumber numberWithInt:swapPaddlesToken], @"swap_paddles",
                                 [NSNumber numberWithInt:breakInToken], @"break_in",
                                 [NSNumber numberWithInt:breakInDelayToken], @"break_in_delay",
                                 [NSNumber numberWithInt:monitorToken], @"monitor",
                                 [NSNumber numberWithInt:monitorGainToken], @"mon_gain",
                                 [NSNumber numberWithInt:metInRxToken], @"met_in_rx",
                                 [NSNumber numberWithInt:voxToken], @"vox",
                                 [NSNumber numberWithInt:voxEnableToken], @"vox_enable",
                                 [NSNumber numberWithInt:voxLevelToken], @"vox_level",
                                 [NSNumber numberWithInt:voxDelayToken], @"vox_delay",
                                 [NSNumber numberWithInt:voxVisibleToken], @"vox_visible",
                                 [NSNumber numberWithInt:monGainToken], @"mon_gain",
                                 [NSNumber numberWithInt:tuneToken], @"tune",
                                 [NSNumber numberWithInt:tunePowerToken], @"tunepower",
                                 [NSNumber numberWithInt:hwAlcEnabledToken], @"hwalc_enabled",
                                 [NSNumber numberWithInt:daxTxEnabledToken], @"dax",
                                 [NSNumber numberWithInt:inhibitToken], @"inhibit",
                                 [NSNumber numberWithInt:showTxInWaterFallToken], @"show_tx_in_waterfall",
                                 [NSNumber numberWithInt:sidetoneToken], @"sidetone",
                                 [NSNumber numberWithInt:sidetoneGainToken], @"mon_gain_cw",
                                 [NSNumber numberWithInt:sidetonePanToken], @"mon_pan_cw",
                                 [NSNumber numberWithInt:phMonitorToken], @"sb_monitor",
                                 [NSNumber numberWithInt:monitorPHGainToken], @"mon_gain_sb",
                                 [NSNumber numberWithInt:monitorPHPanToken] , @"mon_pan_sb",
                                 [NSNumber numberWithInt:cwlEnabledToken], @"cwl_enabled",
                                 [NSNumber numberWithInt:rawIQEnabledToken], @"raw_iq_enable",
                                 nil];
}


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
                              nil];
}


- (void) initStatusEqTokens {
    self.statusEqTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [NSNumber numberWithInt:eqRxToken], @"rx",
                           [NSNumber numberWithInt:eqTxToken], @"tx",
                           [NSNumber numberWithInt:eqModeToken], @"mode",
                           [NSNumber numberWithInt:eqBand0Token], @"63Hz",
                           [NSNumber numberWithInt:eqBand1Token], @"125Hz",
                           [NSNumber numberWithInt:eqBand2Token], @"250Hz",
                           [NSNumber numberWithInt:eqBand3Token], @"500Hz",
                           [NSNumber numberWithInt:eqBand4Token], @"1000Hz",
                           [NSNumber numberWithInt:eqBand5Token], @"2000Hz",
                           [NSNumber numberWithInt:eqBand6Token], @"4000Hz",
                           [NSNumber numberWithInt:eqBand7Token], @"8000Hz",
                           nil];
}

- (void) initFilterSpecs {
    // Create our static data - there must be a better way... surely?
    
    self.filters = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                    [NSMutableArray arrayWithObjects:
                     [[FilterSpec alloc] initWithLabel:@"10 Hz"   mode:@"CW" txFilterLo: 0 txFilterHi: 0 filterLo:-5 filterHi:5],
                     [[FilterSpec alloc] initWithLabel:@"24 Hz"   mode:@"CW" txFilterLo: 0 txFilterHi: 0 filterLo:-12 filterHi:12],
                     [[FilterSpec alloc] initWithLabel:@"50 Hz"   mode:@"CW" txFilterLo: 0 txFilterHi: 0 filterLo:-25 filterHi:25],
                     [[FilterSpec alloc] initWithLabel:@"100 Hz"  mode:@"CW" txFilterLo: 0 txFilterHi: 0 filterLo:-50 filterHi:50],
                     [[FilterSpec alloc] initWithLabel:@"250 Hz"  mode:@"CW" txFilterLo: 0 txFilterHi: 0 filterLo:-125 filterHi:125],
                     [[FilterSpec alloc] initWithLabel:@"500 Hz"  mode:@"CW" txFilterLo: 0 txFilterHi: 0 filterLo:-250 filterHi:250],
                     [[FilterSpec alloc] initWithLabel:@"1 KHz"   mode:@"CW" txFilterLo: 0 txFilterHi: 0 filterLo:-500 filterHi:500],
                     nil], @"CW",
                    [NSMutableArray arrayWithObjects:
                     [[FilterSpec alloc] initWithLabel:@"1 KHz"   mode:@"USB" txFilterLo: 100 txFilterHi: 2800 filterLo:100 filterHi:1100],
                     [[FilterSpec alloc] initWithLabel:@"1.5 KHz" mode:@"USB" txFilterLo: 100 txFilterHi: 2800 filterLo:100 filterHi:1600],
                     [[FilterSpec alloc] initWithLabel:@"1.8 KHz" mode:@"USB" txFilterLo: 100 txFilterHi: 2800 filterLo:100 filterHi:1900],
                     [[FilterSpec alloc] initWithLabel:@"2 KHz"   mode:@"USB" txFilterLo: 100 txFilterHi: 2800 filterLo:100 filterHi:2100],
                     [[FilterSpec alloc] initWithLabel:@"2.2 KHz" mode:@"USB" txFilterLo: 100 txFilterHi: 2800 filterLo:100 filterHi:2300],
                     [[FilterSpec alloc] initWithLabel:@"2.4 KHz" mode:@"USB" txFilterLo: 100 txFilterHi: 2800 filterLo:100 filterHi:2500],
                     [[FilterSpec alloc] initWithLabel:@"2.7 KHz" mode:@"USB" txFilterLo: 100 txFilterHi: 2800 filterLo:100 filterHi:2800],
                     [[FilterSpec alloc] initWithLabel:@"2.9 KHz" mode:@"USB" txFilterLo: 100 txFilterHi: 2800 filterLo:100 filterHi:3000],
                     nil], @"USB",
                    [NSMutableArray arrayWithObjects:
                     [[FilterSpec alloc] initWithLabel:@"1 KHz"   mode:@"LSB" txFilterLo: 100 txFilterHi: 2800 filterLo:-1100 filterHi:-100],
                     [[FilterSpec alloc] initWithLabel:@"1.5 KHz" mode:@"LSB" txFilterLo: 100 txFilterHi: 2800 filterLo:-1600 filterHi:-100],
                     [[FilterSpec alloc] initWithLabel:@"1.8 KHz" mode:@"LSB" txFilterLo: 100 txFilterHi: 2800 filterLo:-1900 filterHi:-100],
                     [[FilterSpec alloc] initWithLabel:@"2 KHz"   mode:@"LSB" txFilterLo: 100 txFilterHi: 2800 filterLo:-2100 filterHi:-100],
                     [[FilterSpec alloc] initWithLabel:@"2.2 KHz" mode:@"LSB" txFilterLo: 100 txFilterHi: 2800 filterLo:-2300 filterHi:-100],
                     [[FilterSpec alloc] initWithLabel:@"2.4 KHz" mode:@"LSB" txFilterLo: 100 txFilterHi: 2800 filterLo:-2500 filterHi:-100],
                     [[FilterSpec alloc] initWithLabel:@"2.7 KHz" mode:@"LSB" txFilterLo: 100 txFilterHi: 2800 filterLo:-2800 filterHi:-100],
                     [[FilterSpec alloc] initWithLabel:@"2.9 KHz" mode:@"LSB" txFilterLo: 100 txFilterHi: 2800 filterLo:-3000 filterHi:-100],
                     nil], @"LSB",
                    [NSMutableArray arrayWithObjects:
                     [[FilterSpec alloc] initWithLabel:@"1 KHz"   mode:@"DIGU" txFilterLo: 100 txFilterHi: 2800 filterLo:100 filterHi:1100],
                     [[FilterSpec alloc] initWithLabel:@"1.5 KHz" mode:@"DIGU" txFilterLo: 100 txFilterHi: 2800 filterLo:100 filterHi:1600],
                     [[FilterSpec alloc] initWithLabel:@"1.8 KHz" mode:@"DIGU" txFilterLo: 100 txFilterHi: 2800 filterLo:100 filterHi:1900],
                     [[FilterSpec alloc] initWithLabel:@"2 KHz"   mode:@"DIGU" txFilterLo: 100 txFilterHi: 2800 filterLo:100 filterHi:2100],
                     [[FilterSpec alloc] initWithLabel:@"2.2 KHz" mode:@"DIGU" txFilterLo: 100 txFilterHi: 2800 filterLo:100 filterHi:2300],
                     [[FilterSpec alloc] initWithLabel:@"2.4 KHz" mode:@"DIGU" txFilterLo: 100 txFilterHi: 2800 filterLo:100 filterHi:2500],
                     [[FilterSpec alloc] initWithLabel:@"2.7 KHz" mode:@"DIGU" txFilterLo: 100 txFilterHi: 2800 filterLo:100 filterHi:2800],
                     [[FilterSpec alloc] initWithLabel:@"2.8 KHz" mode:@"DIGU" txFilterLo: 100 txFilterHi: 2800 filterLo:100 filterHi:3000],
                     nil], @"DIGU",
                    [NSMutableArray arrayWithObjects:
                     [[FilterSpec alloc] initWithLabel:@"270 Hz"  mode:@"DIGL" txFilterLo: 100 txFilterHi: 2800 filterLo:-2345 filterHi:-2075],
                     [[FilterSpec alloc] initWithLabel:@"300 Hz"  mode:@"DIGL" txFilterLo: 100 txFilterHi: 2800 filterLo:-2360 filterHi:-2060],
                     [[FilterSpec alloc] initWithLabel:@"500 Hz"  mode:@"DIGL" txFilterLo: 100 txFilterHi: 2800 filterLo:-2460 filterHi:-1960],
                     [[FilterSpec alloc] initWithLabel:@"1 KHz"   mode:@"DIGL" txFilterLo: 100 txFilterHi: 2800 filterLo:-2710 filterHi:-1710],
                     [[FilterSpec alloc] initWithLabel:@"1.2 KHz" mode:@"DIGL" txFilterLo: 100 txFilterHi: 2800 filterLo:-2810 filterHi:-1610],
                     nil], @"DIGL",
                    [NSMutableArray arrayWithObjects:
                     [[FilterSpec alloc] initWithLabel:@"5 KHz"  mode:@"AM" txFilterLo: 1 txFilterHi: 2500 filterLo:-2500 filterHi:2500],
                     [[FilterSpec alloc] initWithLabel:@"6 KHz"  mode:@"AM" txFilterLo: 1 txFilterHi: 3000 filterLo:-3000 filterHi:3000],
                     [[FilterSpec alloc] initWithLabel:@"8 KHz"  mode:@"AM" txFilterLo: 1 txFilterHi: 4000 filterLo:-4000 filterHi:4000],
                     [[FilterSpec alloc] initWithLabel:@"10 KHz" mode:@"AM" txFilterLo: 1 txFilterHi: 5000 filterLo:-5000 filterHi:5000],
                     [[FilterSpec alloc] initWithLabel:@"12 KHz" mode:@"AM" txFilterLo: 1 txFilterHi: 6000 filterLo:-6000 filterHi:6000],
                     [[FilterSpec alloc] initWithLabel:@"14 KHz" mode:@"AM" txFilterLo: 1 txFilterHi: 7000 filterLo:-7000 filterHi:7000],
                     [[FilterSpec alloc] initWithLabel:@"16 KHz" mode:@"AM" txFilterLo: 1 txFilterHi: 8000 filterLo:-8000 filterHi:8000],
                     [[FilterSpec alloc] initWithLabel:@"20 KHz" mode:@"AM" txFilterLo: 1 txFilterHi: 10000 filterLo:-10000 filterHi:10000],
                     nil], @"AM",
                    [NSMutableArray arrayWithObjects:
                     [[FilterSpec alloc] initWithLabel:@"5 KHz"  mode:@"SAM" txFilterLo: 1 txFilterHi: 2500 filterLo:-2500 filterHi:2500],
                     [[FilterSpec alloc] initWithLabel:@"6 KHz"  mode:@"SAM" txFilterLo: 1 txFilterHi: 3000 filterLo:-3000 filterHi:3000],
                     [[FilterSpec alloc] initWithLabel:@"8 KHz"  mode:@"SAM" txFilterLo: 1 txFilterHi: 4000 filterLo:-4000 filterHi:4000],
                     [[FilterSpec alloc] initWithLabel:@"10 KHz" mode:@"SAM" txFilterLo: 1 txFilterHi: 5000 filterLo:-5000 filterHi:5000],
                     [[FilterSpec alloc] initWithLabel:@"12 KHz" mode:@"SAM" txFilterLo: 1 txFilterHi: 6000 filterLo:-6000 filterHi:6000],
                     [[FilterSpec alloc] initWithLabel:@"14 KHz" mode:@"SAM" txFilterLo: 1 txFilterHi: 7000 filterLo:-7000 filterHi:7000],
                     [[FilterSpec alloc] initWithLabel:@"16 KHz" mode:@"SAM" txFilterLo: 1 txFilterHi: 8000 filterLo:-8000 filterHi:8000],
                     [[FilterSpec alloc] initWithLabel:@"20 KHz" mode:@"SAM" txFilterLo: 1 txFilterHi: 10000 filterLo:-10000 filterHi:10000],
                     nil], @"SAM",
                    nil];
}


- (id) initWithRadioInstanceAndDelegate:(RadioInstance *)thisRadio delegate: (NSObject<RadioDelegate> *) theDelegate {
    self = [super init];
    
    if (self) {
        self.radioInstance = thisRadio;
        socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [socket setIPv4PreferredOverIPv6:YES];
        [socket setIPv6Enabled:NO];
        
        NSError *error = nil;
        
        if (![socket connectToHost:self.radioInstance.ipAddress
                            onPort:[self.radioInstance.port unsignedIntegerValue]
                       withTimeout:5.0
                             error:&error]) {
            NSLog(@"Error connecting to %@ - %@", self.radioInstance.ipAddress, error);
            return nil;
        }

        // Initialize our static data - there HAS to be a better way...
        [self initStatusTokens];
        [self initStatusInterlockTokens];
        [self initStatusInterlockStateTokens];
        [self initStatusInterlockReasonTokens];
        [self initStatusRadioTokens];
        [self initStatusAtuTokens];
        [self initStatusAtuStatusTokens];
        [self initStatusTransmitTokens];
        [self initStatusSliceTokens];
        [self initStatusEqTokens];
        [self initFilterSpecs];
        
        // Set TX ports - same for 6300, 6500 and 6700
        self.txAntennaPorts = [[NSMutableArray alloc] initWithObjects:@"ANT1", @"ANT2", @"XVTR", nil];
        
        // Rx ports are model dependent
        if ([self.radioInstance.model isEqualToString:@"FLEX-6700"])
            self.rxAntennaPorts = [[NSMutableArray alloc] initWithObjects:@"ANT1", @"ANT2", @"RX_A", @"RX_B", @"XVTR", nil];
        else if ([self.radioInstance.model isEqualToString:@"FLEX-6300"]) {
            self.rxAntennaPorts = [[NSMutableArray alloc] initWithObjects:@"ANT1", @"ANT2", @"XVTR", nil];
        } else // FLEX-6500
            self.rxAntennaPorts = [[NSMutableArray alloc] initWithObjects:@"ANT1", @"ANT2", @"RX_A", @"XVTR", nil];
        
        self.slices = [[NSMutableArray alloc] init];
        for (int i=0; i < MAX_SLICES_PER_RADIO; i++) {
            [self.slices insertObject:[NSNull null] atIndex:i];
        }
        
        self.equalizers = [[NSMutableArray alloc] initWithCapacity:2];
        self.equalizers[0] = [[NSNull alloc] init];
        self.equalizers[1] = [[NSNull alloc] init];
        
        connectionState = connecting;
        self.delegate = theDelegate;
        
        // Set up list for notification of command results
        self.notifyList = [[NSMutableDictionary alloc]init];
        
        // Set any initial non zero state requirements
        self.tunePowerLevel = [NSNumber numberWithInt:10];
        self.syncActiveSlice = [NSNumber numberWithBool:YES];
    }
    return self;
}


- (void) close {
    // Release all the slices...
    for (int s=0; s < [self.slices count]; s++) {
        if ([(self.slices[s]) isKindOfClass:[Slice class]])
            [self.slices[s] youAreBeingDeleted];
            [self.slices removeObjectAtIndex:s];
    }
    
    // Close the socket
    [socket disconnectAfterWriting];
    [socket setDelegate:nil];
}


- (void) dealloc {
    NSLog(@"Radio dealloc completed");
}


#pragma mark radioConnectionState

- (enum radioConnectionState) radioConnectionState {
    return connectionState;
}



// Conversation Handlers

#pragma mark
#pragma mark Radio Conversation Handlers


// Sends the initialize requests to the radio and posts our first read

- (void) initializeRadio {
    // Post initial commands
    [self commandToRadio:@"client program K6TUControl"];
    [self commandToRadio:@"sub tx all"];
    [self commandToRadio:@"sub atu all"];
    [self commandToRadio:@"sub slice all"];
    [self commandToRadio:@"eq rx info"];
    [self commandToRadio:@"eq tx info"];
    [self commandToRadio:@"info" notify:self];
    
    [socket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:0];
}



- (void) commandToRadio: (NSString *) cmd {
    seqNum++;
    NSString *cmdline = [[NSString alloc] initWithFormat:@"c%@%u|%@\n", verbose ? @"d" : @"", (unsigned int)seqNum, cmd ];
    
#ifdef DEBUG
    NSLog(@"Data sent - %@", cmdline);
#endif
    [socket writeData: [cmdline dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:(long)seqNum];
}


- (int) commandToRadio:(NSString *) cmd notify: (id<RadioDelegate>) notifyMe {
    seqNum++;
    NSString *cmdline = [[NSString alloc] initWithFormat:@"c%@%u|%@\n", verbose ? @"d" : @"", (unsigned int)seqNum, cmd ];
    
    self.notifyList[[NSString stringWithFormat:@"%i", seqNum]] = notifyMe;
    
#ifdef DEBUG
    NSLog(@"Data sent - %@", cmdline);
#endif
    [socket writeData: [cmdline dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:(long)seqNum];
    return seqNum;
}



// Parse the data stream from the radio

- (void) parseRadioStream: (NSString *) payload {
    char msgType = [payload characterAtIndex:0];
    
    switch (msgType) {
        case 'H':   // Handle type
            [self parseHandleType: payload];
            break;
            
        case 'S':   // Status type
            [self parseStatusType: payload];
            break;
            
        case 'M':   // Message Type
            [self parseMessageType: payload];
            break;
            
        case 'V':   // Version Type
            [self parseVersionType: payload];
            break;
            
        case 'R':   // Response Type
            [self parseResponseType: payload];
            break;
            
        default:    // Huh?
            NSLog(@"Unexpected message type from radio - %@", payload);
            break;
    }
}



- (void) parseStatusType:(NSString *)payload {
    NSScanner *scan = [[NSScanner alloc] initWithString:[payload substringFromIndex:1]];
    [scan setCharactersToBeSkipped:nil];
    BOOL selfStatus = NO;
    
    // First up is the handle... grap it and skip the |
    NSString *statusForHandle;
    [scan scanUpToString:@"|" intoString:&statusForHandle];
    [scan scanString:@"|" intoString:nil];
     
    if ([self.apiHandle isEqualToString:statusForHandle]) {
        selfStatus = YES;
    }
    
    // Next up is the source of the status message within the radio... a token
    // ending in a space...
    NSString *sourceToken;
    
    [scan scanUpToString:@" " intoString:&sourceToken];
    [scan scanString:@" " intoString:nil];
    
    int thisToken = [self.statusTokens[sourceToken] intValue];
    
    switch (thisToken) {
        case interlockToken:
            [self parseInterlockToken: scan];
            break;
            
        case radioToken:
            [self parseRadioToken: scan];
            break;
            
        case atuToken:
            [self parseAtuToken: scan];
            break;
            
        case transmitToken:
            [self parseTransmitToken: scan selfStatus:selfStatus];
            break;
            
        case sliceToken:
            [self parseSliceToken: scan];
            break;
            
        case mixerToken:
            [self parseMixerToken: scan];
            break;
            
        case displayToken:
            [self parseDisplayToken: scan];
            break;
            
        case meterToken:
            [self parseMeterToken: scan];
            break;
            
        case eqToken:
            [self parseEqToken: scan selfStatus:selfStatus];
            break;
            
        case gpsToken:
            [self parseGpsToken: scan];
            break;
            
        default:
            NSLog(@"Unexpected token in parseStatusType - %@", sourceToken);
            break;
    }
    return;
}



- (void) parseHandleType:(NSString *)payload {
    self.apiHandle = [payload substringFromIndex:1];
}



- (void) parseMessageType:(NSString *)payload {
    // Should check and see whether the message is an error or a fatal
    // error and then appropriately notify the user...
    
    // For now, ignore it...
}



- (void) parseVersionType:(NSString *)payload {
    // Should check to see whether the radio understand our version of
    // the api commands...  leave this for later.
    // For now, save the version string
    self.apiVersion = payload;
}



- (void) parseResponseType:(NSString *)payload {
    // See if someone is waiting for this response...
    NSScanner *scan = [[NSScanner alloc] initWithString:[payload substringFromIndex:1]];
    [scan setCharactersToBeSkipped:nil];
    
    // First up is the sequence number... grab it and skip the |
    NSString *seqNumAsString;
    [scan scanUpToString:@"|" intoString:&seqNumAsString];
    [scan scanString:@"|" intoString:nil];
    id<RadioDelegate> notifyIt = self.notifyList[seqNumAsString];
    
    if (notifyIt) {
        // Someone waiting for the response...
        NSString *responseString;
        [scan scanUpToString:@"\n" intoString:&responseString];
        
        if ([notifyIt respondsToSelector:@selector(radioCommandResponse:response:)])
            [notifyIt radioCommandResponse:[seqNumAsString intValue] response:responseString];
        
        // Remove the object for the notification list
        [self.notifyList removeObjectForKey:seqNumAsString];
    }
}


- (void) parseInterlockToken: (NSScanner *) scan{
    NSString *token;
    NSInteger intVal;
    NSString *stringVal;
    
    
    while (![scan isAtEnd]) {
        // Grab the token between current scanner position and the '=' separator
        // and then eat the '='
        [scan scanUpToString:@"=" intoString:&token];
        [scan scanString:@"=" intoString:nil];
        
        // Look up in our dictionary
        int thisToken = [self.statusInterlockTokens[token] intValue];
        
        
        switch (thisToken) {
            case timeoutToken:
                [scan scanInteger:&intVal];
                self.interlockTimeoutValue = [NSNumber numberWithInteger:intVal];
                break;
                
            case acc_txreq_enableToken:
                [scan scanInteger:&intVal];
                self.accTxReqEnable = [NSNumber numberWithInteger:intVal];
                break;
                
            case rca_txreq_enableToken:
                [scan scanInteger:&intVal];
                self.rcaTxReqEnable = [NSNumber numberWithInteger:intVal];
                break;
                
            case acc_txreq_polarityToken:
                [scan scanInteger:&intVal];
                self.accTxReqPolarity = [NSNumber numberWithInteger:intVal];
                break;
                
            case rca_txreq_polarityToken:
                [scan scanInteger:&intVal];
                self.rcaTxReqPolarity = [NSNumber numberWithInteger:intVal];
                break;
                
            case ptt_delayToken:
                [scan scanInteger:&intVal];
                self.pttDelay = [NSNumber numberWithInteger:intVal];
                break;
                
            case tx1_delayToken:
                [scan scanInteger:&intVal];
                self.tx1Delay = [NSNumber numberWithInteger:intVal];
                break;
                
            case tx2_delayToken:
                [scan scanInteger:&intVal];
                self.tx2Delay = [NSNumber numberWithInteger:intVal];
                break;
                
            case tx3_delayToken:
                [scan scanInteger:&intVal];
                self.tx3Delay = [NSNumber numberWithInteger:intVal];
                break;
                
            case acc_tx_delayToken:
                [scan scanInteger:&intVal];
                self.accTxDelay = [NSNumber numberWithInteger:intVal];
                break;
                
            case tx_delayToken:
                [scan scanInteger:&intVal];
                self.txDelay = [NSNumber numberWithInteger:intVal];
                break;
                
            case stateToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                self.interlockState = [self.statusInterlockStateTokens objectForKey: stringVal];
                break;
                
            case sourceToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                self.pttSource = stringVal;
                break;
                
            case reasonToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                self.interlockReason = stringVal;
                break;
                
            case tx1EnabledToken:
                [scan scanInteger:&intVal];
                self.tx1Enabled = [NSNumber numberWithBool:intVal];
                break;
                
            case tx2EnabledToken:
                [scan scanInteger:&intVal];
                self.tx2Enabled = [NSNumber numberWithBool:intVal];
                break;
                
            case tx3EnabledToken:
                [scan scanInteger:&intVal];
                self.tx3Enabled = [NSNumber numberWithBool:intVal];
                break;
                
            case accTxEnabledToken:
                [scan scanInteger:&intVal];
                self.accTxEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            default:
                // Unknown token and therefore an unknown argument type
                // Eat until the next space or \n
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]
                                     intoString:nil];
                NSLog(@"Unexpected token in parseInterlockToken - %@", token);
                break;
        }
    
        // Scanner is either at a space or at the end - eat either
        [scan scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"] intoString:nil];    }
}



- (void) parseRadioToken: (NSScanner *) scan {
    NSString *token;
    NSInteger intVal;
    float floatVal;
    
    while (![scan isAtEnd]) {
        // Grab the token between current scanner position and the '=' separator
        // and then eat the '='
        [scan scanUpToString:@"=" intoString:&token];
        [scan scanString:@"=" intoString:nil];
        
        // Look up in our dictionary
        int thisToken = [self.statusRadioTokens[token] intValue];
        
        switch (thisToken) {
            case slicesToken:
                [scan scanInteger:&intVal];
                self.availableSlices = [NSNumber numberWithInteger:intVal];
                break;
                
            case panadaptersToken:
                [scan scanInteger:&intVal];
                self.availablePanadapters = [NSNumber numberWithInteger:intVal];
                break;
                
            case lineoutGainToken:
                [scan scanInteger:&intVal];
                self.masterSpeakerAfGain = [NSNumber numberWithInteger:intVal];
                break;
                
            case lineoutMuteToken:
                [scan scanInteger:&intVal];
                self.masterSpeakerMute = [NSNumber numberWithBool:intVal];
                break;
                
            case headphoneGainToken:
                [scan scanInteger:&intVal];
                self.masterHeadsetAfGain = [NSNumber numberWithInteger:intVal];
                break;
                
            case headphoneMuteToken:
                [scan scanInteger:&intVal];
                self.masterHeadsetMute = [NSNumber numberWithBool:intVal];
                break;
                
            case remoteOnToken:
                [scan scanInteger:&intVal];
                self.remoteOnEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case pllDoneToken:
                [scan scanInteger:&intVal];
                break;
                
            case freqErrorToken:
                [scan scanInteger:&intVal];
                break;
                
            case calFreqToken:
                [scan scanFloat:&floatVal];
                break;
                
            case tnfEnabledToken:
                [scan scanInteger:&intVal];
                break;
                
            case snapTuneEnabledToken:
                [scan scanInteger:&intVal];
                break;

            default:
                // Unknown token and therefore an unknown argument type
                // Eat until the next space or \n
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]
                                     intoString:nil];
                NSLog(@"Unexpected token in parseRadioToken - %@", token);
                break;
        }
        // Scanner is either at a space or at the end - eat either
        [scan scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"] intoString:nil];
    }
};


- (void) parseAtuToken: (NSScanner *) scan {
    NSString *token;
    NSString *stringVal;
    NSInteger intVal;
    
    
    while (![scan isAtEnd]) {
        // Grab the token between current scanner position and the '=' separator
        // and then eat the '='
        [scan scanUpToString:@"=" intoString:&token];
        [scan scanString:@"=" intoString:nil];
        
        // Look up in our dictionary
        int thisToken = [self.statusAtuTokens[token] intValue];
        
        switch (thisToken) {
            case atuStatusToken:
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"] intoString:&stringVal];
                self.atuStatus = [self.statusAtuStatusTokens objectForKey: stringVal];
                break;
                
            case atuEnabledToken:
                [scan scanInteger:&intVal];
                self.atuEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            default:
                // Unknown token and therefore an unknown argument type
                // Eat until the next space or \n
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]
                                     intoString:nil];
                NSLog(@"Unexpected token in parseAtuToken - %@", token);
                break;
        }
        // Scanner is either at a space or at the end - eat either
        [scan scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"] intoString:nil];    }
};


- (void) parseTransmitToken: (NSScanner *) scan selfStatus:(BOOL)selfStatus {
    NSString *token;
    NSInteger intVal;
    NSString *stringVal;
    
    
    while (![scan isAtEnd]) {
        // Grab the token between current scanner position and the '=' separator
        // and then eat the '='
        [scan scanUpToString:@"=" intoString:&token];
        [scan scanString:@"=" intoString:nil];
        
        // Look up in our dictionary
        int thisToken = [self.statusTransmitTokens[token] intValue];
        
        switch (thisToken) {
            case freqToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                self.transmitFrequency = stringVal;
                break;

            case loTxFilterToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                self.transmitFilterLo = stringVal;
                break;
                
            case hiTxFilterToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                self.transmitFilterHi = stringVal;
                break;
                
            case rfPowerToken:
                // Ignore the update if we are in tune state
                if ([self.tuneEnabled boolValue]) {
                    // pitch the value
                    
                    [scan scanInteger:&intVal];
                    break;
                }
                                
                [scan scanInteger:&intVal];
                self.rfPowerLevel = [NSNumber numberWithInteger:intVal];
                break;

            case amCarrierLevelToken:
                [scan scanInteger:&intVal];
                self.amCarrierLevel = [NSNumber numberWithInteger:intVal];
                break;

            case micSelectionToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                self.micSelection = stringVal;
                break;
                
             case micLevelToken:
                [scan scanInteger:&intVal];
                self.micLevel = [NSNumber numberWithInteger:intVal];
                break;
                
            case micAccToken:
                [scan scanInteger:&intVal];
                self.micAccEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case micBoostToken:
                [scan scanInteger:&intVal];
                self.micBoost = [NSNumber numberWithInteger:intVal];
                break;

            case micBiasToken:
                [scan scanInteger:&intVal];
                self.micBias = [NSNumber numberWithInteger:intVal];
                break;
                
             case companderToken:
                [scan scanInteger:&intVal];
                self.companderEnabled = [NSNumber numberWithInteger:intVal];
                break;

            case companderLevelToken:
                [scan scanInteger:&intVal];
                self.companderLevel = [NSNumber numberWithInteger:intVal];
                break;

            case speechProcToken:
                [scan scanInteger:&intVal];
                self.speechProcEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case speechProcLevelToken:
                [scan scanInteger:&intVal];
                self.speechProcLevel = [NSNumber numberWithInteger:intVal];
                break;
                
            case noiseGateLevelToken:
                [scan scanInteger:&intVal];
                self.noiseGateLevel = [NSNumber numberWithInteger:intVal];
                break;
                
            case pitchToken:
                [scan scanInteger:&intVal];
                self.cwPitch = [NSNumber numberWithInteger:intVal];
                break;

            case speedToken:
                [scan scanInteger:&intVal];
                self.cwSpeed = [NSNumber numberWithInteger:intVal];
                break;

            case iambicToken:
                [scan scanInteger:&intVal];
                self.cwIambicEnabled = [NSNumber numberWithInteger:intVal];
                break;
                
            case iambicModeToken:
                [scan scanInteger:&intVal];
                self.cwIambicMode = [NSString stringWithString:(intVal) ? @"B" : @"A"];
                break;
                
            case swapPaddlesToken:
                [scan scanInteger:&intVal];
                self.cwSwapPaddles = [NSNumber numberWithBool:intVal];
                break;

            case breakInToken:
                [scan scanInteger:&intVal];
                self.cwBreakinEnabled = [NSNumber numberWithInteger:intVal];
                break;

            case breakInDelayToken:
                [scan scanInteger:&intVal];
                self.cwBreakinDelay = [NSNumber numberWithInteger:intVal];
                break;

            case monitorToken:
                [scan scanInteger:&intVal];
                // Down rev radio - ignore
                break;

            case monitorGainToken:
                [scan scanInteger:&intVal];
                // Down rev radio - ignore
                break;
                
            case voxToken:
            case voxEnableToken:
                [scan scanInteger:&intVal];
                self.voxEnabled = [NSNumber numberWithInteger:intVal];
                break;

            case voxLevelToken:
                [scan scanInteger:&intVal];
                self.voxLevel = [NSNumber numberWithInteger:intVal];
                break;

            case voxDelayToken:
                [scan scanInteger:&intVal];
                self.voxDelay = [NSNumber numberWithInteger:intVal / 20];
                break;

            case voxVisibleToken:
                [scan scanInteger:&intVal];
                self.voxVisible = [NSNumber numberWithInteger:intVal];
                break;
                
            case monGainToken:
                [scan scanInteger:&intVal];
                // Down rev radio - ignore
                break;
                
            case tuneToken:
                [scan scanInteger:&intVal];
                self.tuneEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case tunePowerToken:
                [scan scanInteger:&intVal];
                self.tunePowerLevel = [NSNumber numberWithInteger:intVal];
                break;
                
            case hwAlcEnabledToken:
                [scan scanInteger:&intVal];
                self.hwAlcEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case metInRxToken:
                [scan scanInteger:&intVal];
                self.metInRxEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case daxTxEnabledToken:
                [scan scanInteger:&intVal];
                self.txDaxEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case inhibitToken:
                [scan scanInteger:&intVal];
                self.txInhibit = [NSNumber numberWithBool:intVal];
                break;
                
            case showTxInWaterFallToken:
                [scan scanInteger:&intVal];
                // Nothing to do for us at present
                break;
                
            case sidetoneToken:
                [scan scanInteger:&intVal];
                self.sidetone = [NSNumber numberWithBool:intVal];
                break;
                
            case sidetoneGainToken:
                [scan scanInteger:&intVal];
                self.sidetoneGain = [NSNumber numberWithInteger:intVal];
                break;
                
            case sidetonePanToken:
                [scan scanInteger:&intVal];
                self.sidetonePan = [NSNumber numberWithInteger:intVal];
                break;
                
            case phMonitorToken:
                [scan scanInteger:&intVal];
                self.phMonitor = [NSNumber numberWithBool:intVal];
                break;
                
            case monitorPHGainToken:
                [scan scanInteger:&intVal];
                self.monitorPHGain = [NSNumber numberWithInteger:intVal];
                break;
                
            case monitorPHPanToken:
                [scan scanInteger:&intVal];
                self.monitorPHPan = [NSNumber numberWithInteger:intVal];
                break;
                
            case cwlEnabledToken:
                [scan scanInteger:&intVal];
                self.cwlEnabled = [NSNumber numberWithBool:intVal];
                break;

            case rawIQEnabledToken:
                [scan scanInteger:&intVal];
                self.rawIQEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            default:
                // Unknown token and therefore an unknown argument type
                // Eat until the next space or \n
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]
                                     intoString:nil];
                NSLog(@"Unexpected token in parseTransmitToken - %@", token);
                break;
        }
        // Scanner is either at a space or at the end - eat either
        [scan scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"] intoString:nil];    }
};


- (void) parseSliceToken: (NSScanner *) scan {
    NSString *token;
    NSInteger intVal;
    NSString *stringVal;
    float floatVal;
    NSInteger thisSliceNum;
    BOOL play;
    
    // Next up in the slice message is the slice number - grab it and its
    // trailing space.
    
    [scan scanInteger:&thisSliceNum];
    [scan scanString:@" " intoString:nil];
    
    // Check and see whether we have a slice for this slice number; if not, we
    // need to create one.
    
    Slice *thisSlice;
    
    if (![(thisSlice = self.slices[thisSliceNum]) isKindOfClass:[Slice class]]) {
        self.slices[thisSliceNum] = [[Slice alloc] initWithRadio:self sliceNumber: thisSliceNum];
        thisSlice = self.slices[thisSliceNum];
        thisSlice.sliceAudioLevel = [NSNumber numberWithInt:50];
        thisSlice.slicePanControl = [NSNumber numberWithInt:50];
    }
    
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
                thisSlice.sliceFrequency = stringVal;
                break;
            
            case modeToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                thisSlice.sliceMode = stringVal;
                
                // This really shouldn't have to be here but...
                thisSlice.sliceApfEnabled = [NSNumber numberWithBool:NO];
                thisSlice.sliceAnfEnabled = [NSNumber numberWithBool:NO];
                thisSlice.sliceNrEnabled = [NSNumber numberWithBool:NO];
                break;

            case rxAntToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                thisSlice.sliceRxAnt = stringVal;
                break;
                
            case txAntToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                thisSlice.sliceTxAnt = stringVal;
                break;

            case filterLoToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceFilterLo = [NSNumber numberWithInteger:intVal];
                break;
                
            case filterHiToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceFilterHi = [NSNumber numberWithInteger:intVal];
                break;
                
            case nrToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceNrEnabled = [NSNumber numberWithInteger:intVal];
                break;

             case nrLevelToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceNrLevel = [NSNumber numberWithInteger:intVal];
                break;

             case nbToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceNbEnabled = [NSNumber numberWithInteger:intVal];
                break;
                
            case nbLevelToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceNbLevel = [NSNumber numberWithInteger:intVal];
                break;

            case anfToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceAnfEnabled = [NSNumber numberWithInteger:intVal];
                break;

            case anfLevelToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceAnfLevel = [NSNumber numberWithInteger:intVal];
                break;
                
            case apfToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceApfEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case apfLevelToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceApfLevel= [NSNumber numberWithInteger:intVal];
                break;

            case agcModeToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                thisSlice.sliceAgcMode = stringVal;
                break;
                                
            case agcThresholdToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceAgcThreshold = [NSNumber numberWithInteger:intVal];
                break;

            case agcOffLevelToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceAgcOffLevel = [NSNumber numberWithInteger:intVal];
                break;

            case txToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceTxEnabled = [NSNumber numberWithInteger:intVal];
                break;

            case activeToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceActive = [NSNumber numberWithBool:intVal];
                break;
                
            case ghostToken:
                [scan scanInteger:&intVal];
                // thisSlice.sliceGhost = [NSNumber numberWithInteger:intVal];
                break;

            case ownerToken:
                // [scan scanInteger:&intVal];
                // thisSlice.sliceOwner = [NSNumber numberWithInteger:intVal];
                break;

            case wideToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceWide = [NSNumber numberWithInteger:intVal];
                break;

            case inUseToken:
                [scan scanInteger:&intVal];
                
                if (!intVal) {
                    // If in_use=0, this slice has been deleted and we need to make it go away
                    // in an orderly fashion - BEFORE we update the property OR make it go away!
                    [thisSlice youAreBeingDeleted];
                    
                    // By the time this returns, the slice be deletable - post the transition to
                    // not in use and then delete from the slices array
                    thisSlice.sliceInUse = [NSNumber numberWithInteger:intVal];
                    self.slices[thisSliceNum] = [NSNull null];
                } else {
                    thisSlice.sliceInUse = [NSNumber numberWithInteger:intVal];
                }
                break;
                
            case panToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                thisSlice.panForSlice = stringVal;
                break;
                
            case loopaToken:
                [scan scanInteger:&intVal];
                thisSlice.loopAEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case loopbToken:
                [scan scanInteger:&intVal];
                thisSlice.loopBEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case qskToken:
                [scan scanInteger:&intVal];
                thisSlice.qskEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case audioGainToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceAudioLevel = [NSNumber numberWithInteger:intVal];
                break;
                
            case audioPanToken:
                [scan scanInteger:&intVal];
                thisSlice.slicePanControl = [NSNumber numberWithInteger:intVal];
                break;
                
            case audioMuteToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceMuteEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case xitOnToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceXitEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case ritOnToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceRitEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case xitFreqToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceXitOffset = [NSNumber numberWithInteger:intVal];
                break;
                
            case ritFreqToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceRitOffset = [NSNumber numberWithInteger:intVal];
                break;
                
            case daxToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceDax = [NSNumber numberWithInteger:intVal];
                break;
                
            case daxClientsToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceDaxClients = [NSNumber numberWithInteger:intVal];
                break;
                
            case daxTxToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceDaxTxEnabled = [NSNumber numberWithBool:intVal];
                break;
                 
            case lockToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceLocked = [NSNumber numberWithBool:intVal];
                break;
                
            case stepToken:
                [scan scanInteger:&intVal];
                break;
                
            case stepListToken:
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]
                                     intoString:nil];
                break;
                
            case recordToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceRecordEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case playToken:
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]
                                     intoString:&stringVal];
                
                // Depending on whether the command was sent with "enabled" or "1", the reply will be
                // similarly encoded...  SSDR sends enabled - we sent 1...
                // Argh!
                play = NO;
                play = [stringVal isEqualToString:@"enabled"] || [stringVal isEqualToString:@"1"];
                
                thisSlice.slicePlaybackEnabled = [NSNumber numberWithBool:play];
                break;
                
            case recordTimeToken:
                [scan scanFloat:&floatVal];
                thisSlice.sliceQRlength = [NSNumber numberWithFloat:floatVal];
                break;
                
            case diversityToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceDiversityEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case diversityParentToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceDiversityParent = [NSNumber numberWithBool:intVal];
                break;
                
            case diversityChildToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceDiversityChild = [NSNumber numberWithBool:intVal];
                break;
                
            case diversityIndexToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceDiversityIndex = [NSNumber numberWithBool:intVal];
                break;
                
            case antListToken:
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]
                                     intoString:&stringVal];
                thisSlice.antList = [[NSMutableArray alloc] initWithArray:[stringVal componentsSeparatedByString:@","]];
                break;
                
            default:
                // Unknown token and therefore an unknown argument type
                // Eat until the next space or \n
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]
                                     intoString:nil];
                NSLog(@"Unexpected token in parseSliceToken - %@", token);
                break;
        }
        
        // Scanner is either at a space or at the end - eat either
        [scan scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"] intoString:nil];
    }
}


- (void) parseMixerToken: (NSScanner *) scan {
    
};


- (void) parseDisplayToken: (NSScanner *) scan {
    
};


- (void) parseMeterToken: (NSScanner *) scan {
    
};


- (void) parseEqToken: (NSScanner *) scan selfStatus:(BOOL)selfStatus {
    NSString *token;
    NSInteger intVal, eqNum;
    NSString *stringVal;
    Equalizer *eq;
    BOOL firstUpdate = NO;
    
    // First parameter after eq is rx|tx
    [scan scanUpToString:@" " intoString:&stringVal];
    [scan scanString:@" " intoString:nil];
    
    
    // Check for bogus APF parameter..
    if ([stringVal isEqualToString:@"apf"])
        // ignore...
        return;
    
    if ([stringVal isEqualToString:@"rx"])
        eqNum = 0;
    else
        eqNum = 1;
    
    if ([self.equalizers[eqNum] isKindOfClass:[NSNull class]]) {
        // Allocate an equalizer
        eq = [[Equalizer alloc]init];
        eq.eqType = stringVal;
        eq.radio = self;
        self.equalizers[eqNum] = eq;
        firstUpdate = YES;
    }
    
    
    eq = self.equalizers[eqNum];
    
    if ([eq isKindOfClass:[Equalizer class]] && selfStatus && !firstUpdate)
        // Ignore the update - we already know the answer!
        return;
    
    while (![scan isAtEnd]) {
        // Grab the token between current scanner position and the '=' separator
        // and then eat the '='
        [scan scanUpToString:@"=" intoString:&token];
        [scan scanString:@"=" intoString:nil];
        
        // Look up in our dictionary
        int thisToken = [self.statusEqTokens[token] intValue];
        
        switch (thisToken) {
            case eqModeToken:
                [scan scanInteger:&intVal];
                eq.eqEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case eqBand0Token:
                [scan scanInteger:&intVal];
                eq.eqBand0Value = [NSNumber numberWithInteger:intVal];
                break;
                
            case eqBand1Token:
                [scan scanInteger:&intVal];
                eq.eqBand1Value = [NSNumber numberWithInteger:intVal];
                break;
                
            case eqBand2Token:
                [scan scanInteger:&intVal];
                eq.eqBand2Value = [NSNumber numberWithInteger:intVal];
                break;
                
            case eqBand3Token:
                [scan scanInteger:&intVal];
                eq.eqBand3Value = [NSNumber numberWithInteger:intVal];
                break;
                
            case eqBand4Token:
                [scan scanInteger:&intVal];
                eq.eqBand4Value = [NSNumber numberWithInteger:intVal];
                break;
                
            case eqBand5Token:
                [scan scanInteger:&intVal];
                eq.eqBand5Value = [NSNumber numberWithInteger:intVal];
                break;
                
            case eqBand6Token:
                [scan scanInteger:&intVal];
                eq.eqBand6Value = [NSNumber numberWithInteger:intVal];
                break;
                
            case eqBand7Token:
                [scan scanInteger:&intVal];
                eq.eqBand7Value = [NSNumber numberWithInteger:intVal];
                break;
        }
        // Scanner is either at a space or at the end - eat either
        [scan scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"] intoString:nil];

    }
}


- (void) parseGpsToken: (NSScanner *) scan {
    
}


// Currently there is only one issued command for which a response is waited - info
// to recover the settings for the Model, Callsign and Name which may be displayed
// as the "screensaver" on the 6500/6700 front panel display.
//
// If others are added here in the Radio model, then this should be modified to take
// the sequence number of the response, look it up to a selector of the appropriate
// response processor and then invoke it.

- (void) radioCommandResponse:(int)seqNum response:(NSString *)cmdResponse {
    NSScanner *scan = [[NSScanner alloc] initWithString:[cmdResponse substringFromIndex:1]];
    [scan setCharactersToBeSkipped:nil];
    
    // First up is the response error code... grab it and skip the |
    NSString *errorNumAsString;
    [scan scanUpToString:@"|" intoString:&errorNumAsString];
    [scan scanString:@"|" intoString:nil];
    
    if ([errorNumAsString integerValue])
        // Anything other than 0 is an error and we return
        return;
    
    NSString *response;
    [scan scanUpToString:@"\n" intoString:&response];
    
    // Split into strings on comma
    NSArray *list = [response componentsSeparatedByString:@","];
    
    enum wantedTerms {
        screensaver = 1,
        callsign,
        name,
        model,
    };
    
    NSDictionary *terms = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [NSNumber numberWithInt:screensaver], @"screensaver",
                           [NSNumber numberWithInt:callsign], @"callsign",
                           [NSNumber numberWithInt:name], @"name",
                           [NSNumber numberWithInt:model], @"model",
                           nil];
    
    for (NSString *term in list) {
        NSArray *fields = [term componentsSeparatedByString:@"="];
        
        int tVal = [terms[fields[0]] intValue];
        
        if (tVal) {
            NSString * val = [fields[1] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            switch(tVal) {
                case screensaver:
                    self.radioScreenSaver = val;
                    break;
                    
                case callsign:
                    self.radioCallsign = val;
                    break;
                    
                case model:
                    self.radioModel = val;
                    break;
                    
                case name:
                    self.radioName = val;
                    break;
            }
        }
    }    
}


#pragma mark
#pragma mark Radio Commands

- (void) cmdNewSlice {
    if ([self.availableSlices integerValue]) {
        NSString *cmd = [NSString stringWithFormat:@"slice c 14.15 ANT1 USB"];
        
        [self commandToRadio:cmd];
    }
}

- (void) cmdNewSlice:(NSString *)frequency antenna:(NSString *)antennaPort mode:(NSString *)mode {
    if ([self.availableSlices integerValue]) {
        NSString *cmd = [NSString stringWithFormat:@"slice c %@ %@ %@",
                         frequency, antennaPort, mode];
        
        [self commandToRadio:cmd];
    }
}

- (void) cmdRemoveSlice:(NSNumber *)sliceNum {
    NSString *cmd = [NSString stringWithFormat:@"slice remove %i", [sliceNum intValue]];
    
    [self commandToRadio:cmd];
}

- (void) cmdSetTxBandwidth:(NSNumber *)lo high:(NSNumber *)hi {
    NSString *cmd = [NSString stringWithFormat:@"transmit set filter_low=%i filter_high=%i",
                     [lo intValue], [hi intValue]];
    [self commandToRadio:cmd];
    self.transmitFilterLo = [lo stringValue];
    self.transmitFilterHi = [hi stringValue];
}


- (void) cmdSetRfPowerLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"transmit set rfpower=%i",
                     [level intValue]];

    [self commandToRadio:cmd];
    self.rfPowerLevel = level;
}

- (void) cmdSetAmCarrierLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"transmit set am_carrier=%i",
                     [level intValue]];
    
    [self commandToRadio:cmd];
    self.amCarrierLevel = level;
}

- (void) cmdSetDaxSource:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"transmit set dax=%i",
                     [state intValue]];
    
    [self commandToRadio:cmd];
    self.txDaxEnabled = state;
}

- (void) cmdSetMicSelection:(NSString *)source {
    NSString *cmd = [NSString stringWithFormat:@"mic input %@", source];
    
    [self commandToRadio:cmd];
    self.micSelection = source;
}

- (void) cmdSetMicLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"transmit set miclevel=%i",
                     [level intValue]];
    
    [self commandToRadio:cmd];
    self.micLevel = level;
}

- (void) cmdSetMicBias:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"mic bias %i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.micBias = state;
}

- (void) cmdSetMicBoost:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"mic boost %i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.micBoost = state;
}

- (void) cmdSetAccEnabled:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"mic acc %i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    // ??? Huh?  How do we find this value?
}

- (void) cmdSetCompander:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"transmit set compander=%i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.companderEnabled = state;
}

- (void) cmdSetCompanderLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"transmit set compander_level=%i",
                     [level intValue]];
    
    [self commandToRadio:cmd];
    self.companderLevel = level;
}

- (void) cmdSetSpeechProcEnabled:(NSNumber *) state {
    NSString *cmd = [NSString stringWithFormat:@"transmit set speech_processor_enable=%i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.speechProcEnabled = state;
}

- (void) cmdSetSpeechProcLevel:(NSNumber *) level {
    NSString *cmd = [NSString stringWithFormat:@"transmit set speech_processor_level=%i",
                     [level intValue]];
    
    [self commandToRadio:cmd];
    self.speechProcLevel = level;
}

- (void) cmdSetVoxEnabled:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"transmit set vox_enable=%i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.voxEnabled = state;
}

- (void) cmdSetVoxLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"transmit set vox_level=%i",
                     [level intValue]];
    
    [self commandToRadio:cmd];
    self.voxLevel = level;
}

- (void) cmdSetVoxDelay:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"transmit set vox_delay=%i",
                     [level intValue] * 20];
    
    [self commandToRadio:cmd];
    self.voxDelay = level;
}

- (void) cmdSetCwPitch:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"cw pitch %i",
                     [level intValue]];
    
    [self commandToRadio:cmd];
    self.cwPitch = level;
}

- (void) cmdSetCwSpeed:(NSNumber *)level {
    NSInteger speed = [level integerValue] < 5 ? 5 : [level integerValue];
    NSString *cmd = [NSString stringWithFormat:@"cw wpm %i",
                     (int)speed];
    
    [self commandToRadio:cmd];
    self.cwSpeed = [NSNumber numberWithInteger:speed];
}

- (void) cmdSetCwSwapPaddles: (NSNumber *) state {
    NSString *cmd = [NSString stringWithFormat:@"cw swap %i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.cwSwapPaddles = state;
}


- (void) cmdSetIambicEnabled:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"cw iambic %i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.cwIambicEnabled = state;
}

- (void) cmdSetIambicMode: (NSString *) mode {
    NSString *cmd = [NSString stringWithFormat:@"cw mode %i",
                     [mode isEqualToString:@"B"]];
    
    [self commandToRadio:cmd];
    self.cwIambicMode = mode;
}

- (void) cmdSetBreakinEnabled:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"cw break_in %i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.cwBreakinEnabled = state;
}

- (void) cmdSetQskDelay:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"cw break_in_delay %i",
                     [level intValue]];
    
    [self commandToRadio:cmd];
    self.cwBreakinDelay = level;
}

- (void) cmdSetSidetoneEnabled:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"cw sidetone %i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.sidetone = state;
}

- (void) cmdSetSidetoneGain:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"transmit set mon_gain_cw=%i",
                     [level intValue]];
    
    [self commandToRadio:cmd];
    self.sidetoneGain = level;
}

- (void) cmdSetSidetonePan:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"transmit set mon_pan_cw=%i",
                     [level intValue]];
    
    [self commandToRadio:cmd];
    self.sidetonePan = level;
}

- (void) cmdSetPHMonitorEnabled:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"transmit set mon=%i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.phMonitor = state;
}

- (void) cmdSetPHMonitorGain:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"transmit set mon_gain_sb=%i",
                     [level intValue]];
    
    [self commandToRadio:cmd];
    self.monitorPHGain = level;
}

- (void) cmdSetPHMonitorPan:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"transmit set mon_pan_sb=%i",
                     [level intValue]];
    
    [self commandToRadio:cmd];
    self.monitorPHPan = level;
}

- (void) cmdSetCWLEnabled:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"cw cwl_enabled %i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.cwlEnabled = state;
}

- (void) cmdSetTx:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"xmit %i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.txState = state;
}

- (void) cmdSetAtuTune:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"atu start %i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
}

- (void) cmdSetBypass {
    NSString *cmd = [NSString stringWithFormat:@"atu bypass 1"];
    
    [self commandToRadio:cmd];
}

- (void) cmdSetTune:(NSNumber *)state {
    if (!self.tuneEnabled)
        self.tuneEnabled = [NSNumber numberWithBool:YES];
    
    if (!txPowerLevel)  // Going into tune... save the power level
        txPowerLevel = [NSNumber numberWithInt:[self.rfPowerLevel intValue]];
    
    if ([state boolValue]) {
        // Tune requested - set TX power level and then command tune
        self.rfPowerLevel = self.tunePowerLevel;
        [self cmdSetRfPowerLevel:self.rfPowerLevel];
        [self commandToRadio:@"transmit tune 1"];
        self.tuneEnabled = [NSNumber numberWithBool:YES];
    } else {
        // Coming out of tune
        [self commandToRadio:@"transmit tune 0"];
        [self cmdSetRfPowerLevel:txPowerLevel];
        self.rfPowerLevel = txPowerLevel;
        self.tuneEnabled = [NSNumber numberWithBool:NO];
        txPowerLevel = nil;
    }
}

- (void) cmdSetMasterSpeakerGain:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"mixer lineout gain %i",
                     [level intValue]];
    
    [self commandToRadio:cmd];
    self.masterSpeakerAfGain = level;
}

- (void) cmdSetMasterHeadsetGain:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"mixer headphone gain %i",
                     [level intValue]];
    
    [self commandToRadio:cmd];
    self.masterHeadsetAfGain = level;
}

- (void) cmdSetMasterSpeakerMute:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"mixer lineout mute %i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.masterSpeakerMute = state;
}

- (void) cmdSetMasterHeadsetMute:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"mixer headphone mute %i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.masterHeadsetMute = state;
}


- (void) cmdSetRemoteOnEnabled:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"radio set remote_on_enabled=%i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.remoteOnEnabled = state;
}

- (void) cmdSetTxInhibit:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"transmit set inhibit=%i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.txInhibit = state;
}

- (void) cmdSetTxDelay: (NSNumber *) delay {
    NSString *cmd = [NSString stringWithFormat:@"interlock tx_delay=%i",
                     [delay intValue]];
    
    [self commandToRadio:cmd];
    self.txDelay = delay;
}


- (void) cmdSetTx1Delay: (NSNumber *) delay {
    NSString *cmd = [NSString stringWithFormat:@"interlock tx1_delay=%i",
                     [delay intValue]];
    
    [self commandToRadio:cmd];
    self.tx1Delay = delay;
}


- (void) cmdSetTx2Delay: (NSNumber *) delay {
    NSString *cmd = [NSString stringWithFormat:@"interlock tx2_delay=%i",
                     [delay intValue]];
    
    [self commandToRadio:cmd];
    self.tx2Delay = delay;
}

- (void) cmdSetTx3Delay: (NSNumber *) delay {
    NSString *cmd = [NSString stringWithFormat:@"interlock tx3_delay=%i",
                     [delay intValue]];
    
    [self commandToRadio:cmd];
    self.tx3Delay = delay;
}

- (void) cmdSetAccTxDelay: (NSNumber *) delay {
    NSString *cmd = [NSString stringWithFormat:@"interlock acc_tx_delay=%i",
                     [delay intValue]];
    
    [self commandToRadio:cmd];
    self.accTxDelay = delay;
}

- (void) cmdSetTx1Enabled: (NSNumber *) state {
    NSString *cmd = [NSString stringWithFormat:@"interlock tx1_enabled=%i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.tx1Enabled = state;
}


- (void) cmdSetTx2Enabled: (NSNumber *) state {
    NSString *cmd = [NSString stringWithFormat:@"interlock tx2_enabled=%i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.tx2Enabled = state;
}

- (void) cmdSetTx3Enabled: (NSNumber *) state {
    NSString *cmd = [NSString stringWithFormat:@"interlock tx3_enabled=%i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.tx3Enabled = state;
}

- (void) cmdSetAccTxEnabled: (NSNumber *) state {
    NSString *cmd = [NSString stringWithFormat:@"interlock acc_tx_enabled=%i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.accTxEnabled = state;
}


- (void) cmdSetHwAlcEnabled: (NSNumber *) state {
    NSString *cmd = [NSString stringWithFormat:@"transmit set hw_alc_enabled=%i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.hwAlcEnabled = state;
}


- (void) cmdSetRcaTxInterlockEnabled:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"interlock rca_txreq_enable=%i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.rcaTxReqEnable = state;
}

- (void) cmdSetRcaTXInterlockPolarity:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"interlock rca_txreq_polarity=%i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.rcaTxReqPolarity = state;
}

- (void) cmdSetAccTxInterlockEnabled:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"interlock acc_txreq_enable=%i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.accTxReqEnable = state;
}

- (void) cmdSetAccTxInterlockPolarity:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"interlock acc_txreq_polarity=%i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.accTxReqPolarity = state;
}

- (void) cmdSetInterlockTimeoutValue:(NSNumber *)value {
    NSString *cmd = [NSString stringWithFormat:@"interlock timeout=%i",
                     [value intValue]];
    
    [self commandToRadio:cmd];
    self.interlockTimeoutValue = value;
}

- (void) cmdSetRadioScreenSaver:(NSString *)source {
    NSString *cmd = [NSString stringWithFormat:@"radio screensaver %@",
                     source];
    
    [self commandToRadio:cmd];
    self.radioScreenSaver = source;
}

- (void) cmdSetRadioCallsign:(NSString *)callsign {
    NSString *cmd = [NSString stringWithFormat:@"radio callsign %@",
                     callsign];
    
    [self commandToRadio:cmd];
    self.radioCallsign = callsign;
}

- (void) cmdSetRadioName:(NSString *)name {
    NSString *cmd = [NSString stringWithFormat:@"radio name %@",
                     name];
    
    [self commandToRadio:cmd];
    self.radioName = name;
}

- (void) cmdSetSyncActiveSlice:(NSNumber *)state {
    self.syncActiveSlice = state;
}


#pragma mark
#pragma mark Socket Delegates


- (void) socket:(GCDAsyncSocket *)sock socketDidDisconnect:(NSError *)err  {
    if (err.code == GCDAsyncSocketConnectTimeoutError)
        connectionState = connectFailed;
    else
        connectionState = disConnected;
    
    if ([self.delegate respondsToSelector:@selector(radioConnectionStateChange:state:)]) {
        [self.delegate radioConnectionStateChange:self state:connectionState];
    }
}


// Called after connected - use this to initialize the connection to the radio and
// prime the initial read

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    // Connected to the radio
    connectionState = connected;
    
    // Advise any delegate
    if ([self.delegate respondsToSelector:@selector(radioConnectionStateChange:state:)]) {
        [self.delegate radioConnectionStateChange:self state:connectionState];
    }

    [self initializeRadio];
}



- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if ([data bytes]) {
        NSScanner *scan = [[NSScanner alloc] initWithString:[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding]];
        NSString *payload;
        
        [scan setCharactersToBeSkipped:nil];
        [scan scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\000"] intoString:nil];
        [scan scanUpToString:@"\n" intoString:&payload];
#ifdef DEBUG
        if (![payload hasPrefix:@"S0|gps"])
            NSLog(@"Data received - %@\n", payload);
#endif
        [self parseRadioStream: payload];
    }
    
    [socket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:0];
}



@end
