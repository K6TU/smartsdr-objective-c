
//
//  Radio.m
//
//  Created by STU PHILLIPS on 8/3/13.
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
#import "Meter.h"
#import "Slice.h"
#import "Equalizer.h"
#import "FilterSpec.h"
#import "VitaManager.h"
#import "Panafall.h"
#import "Waterfall.h"
#import "DAXAudio.h"
#import "OpusAudio.h"

@interface Radio ()

@property (strong, nonatomic) NSObject<RadioDelegate> *delegate;

@property (strong, readwrite, nonatomic) VitaManager *vitaManager;
@property (strong, readwrite, nonatomic) NSMutableDictionary *meters;
@property (strong, readwrite, nonatomic) NSMutableDictionary *panafalls;
@property (strong, readwrite, nonatomic) NSMutableDictionary *waterfalls;
@property (strong, readwrite, nonatomic) NSMutableDictionary *daxAudioStreamToStreamHandler;
@property (strong, readwrite, nonatomic) NSMutableDictionary *opusStreamToStreamHandler;

@property (strong, readwrite, nonatomic) NSString *apiVersion;                  // NSString of format VM.m.x.y of Version of API
@property (strong, readwrite, nonatomic) NSString *apiHandle;                   // NSString of our API handle

@property (strong, readwrite, nonatomic) NSNumber *availableSlices;             // Number of available slices which can be created - INTEGER
@property (strong, readwrite, nonatomic) NSNumber *availablePanadapters;        // Number of available panadaptors which can be created - INTEGER

@property (strong, readwrite, nonatomic) NSNumber *atuStatus;                   // ATU operation status - ENUM radioAtuState
@property (strong, readwrite, nonatomic) NSNumber *atuEnabled;

@property (strong, nonatomic) NSDictionary *statusTokens;
@property (strong, nonatomic) NSDictionary *statusRadioTokens;
@property (strong, nonatomic) NSDictionary *statusTransmitTokens;
@property (strong, nonatomic) NSDictionary *statusInterlockTokens;
@property (strong, nonatomic) NSDictionary *statusInterlockStateTokens;
@property (strong, nonatomic) NSDictionary *statusInterlockReasonTokens;
@property (strong, nonatomic) NSDictionary *statusAtuTokens;
@property (strong, nonatomic) NSDictionary *statusAtuStatusTokens;

@property (strong, nonatomic) NSMutableDictionary *responseCallbacks;           // Radio response callbacks within self

@property (strong, nonatomic) NSMutableDictionary *notifyList;
@property (nonatomic) dispatch_queue_t radioRunQueue;
@property (strong, nonatomic) NSString *clientId;

@property (nonatomic) dispatch_source_t pingTimer;                              // periodic timer for radio keepalive detection
@property (strong, nonatomic) NSDate *lastPingRxtime;                           // Time last ping response was received from the radio

@property (strong, readwrite, nonatomic) NSString *smartSdrVersion;             // ??? - STRING
@property (strong, readwrite, nonatomic) NSString *psocMbtrxVersion;            // ??? - STRING
@property (strong, readwrite, nonatomic) NSString *psocMbPa100Version;          // ??? - STRING
@property (strong, readwrite, nonatomic) NSString *fpgaMbVersion;               // ??? - STRING

@property (strong, readwrite, nonatomic) NSArray *antList;                      // Array of strings with name for each Antenna connection
@property (strong, readwrite, nonatomic) NSArray *micList;                      // Array of strings with name for each Mic connection

- (void) initStatusTokens;
- (void) initStatusRadioTokens;
- (void) initStatusAtuTokens;
- (void) initStatusAtuStatusTokens;
- (void) initStatusTransmitTokens;
- (void) initStatusInterlockTokens;
- (void) initStatusInterlockStateTokens;
- (void) initStatusInterlockReasonTokens;

- (void) parseRadioStream: (NSString *) payload;
- (void) parseHandleType: (NSString *) payload;
- (void) parseStatusType: (NSString *) payload;
- (void) parseMessageType: (NSString *) payload;
- (void) parseVersionType: (NSString *) payload;
- (void) parseResponseType: (NSString *) payload;
- (void) parseMixerToken: (NSScanner *) scan;
- (void) parseDisplayToken: (NSScanner *) scan selfStatus: (BOOL) selfStatus;
- (void) parseAudioStreamToken:(NSScanner *) scan selfStatus: (BOOL) selfStatus;
- (void) parseOpusStreamToken:(NSScanner *) scan selfStatus: (BOOL) selfStatus;
- (void) parseMeterToken: (NSScanner *) scan;
- (void) parseGpsToken: (NSScanner *) scan;
- (void) parseProfileToken: (NSScanner *) scan;
- (void) parseCwxToken: (NSScanner *) scan;
- (void) parseInterlockToken: (NSScanner *) scan;
- (void) parseEqToken: (NSScanner *) scan selfStatus: (BOOL) selfStatus;

- (int) commandToRadio:(NSString *) cmd notifySel:(SEL) callback;

@end


#pragma mark
#pragma mark Parser Enum Definitions

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
    profileToken,
    cwxToken,
    waveformToken,
    audioStreamToken,
    opusStreamToken,
};

enum enumStatusMixerTokens {
    enumStatusMixerTokensNone = 0,
    
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
    nicknameToken,
    callsignToken,
    binauralRxToken,
};

enum enumStatusAtuTokens {
    enumStatusAtuTokensNone = 0,
    atuStatusToken,
    atuEnabledToken,
    atuMemoriesEnabledToken,
    usingMemToken,
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
    txFilterChangesAllowedToken,
    txRfPowerChangesAllowedToken,
    synccwxToken,
    monAvailableToken,
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
    txAllowedToken,
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



@implementation Radio

GCDAsyncSocket *radioSocket;
unsigned int seqNum;
BOOL verbose;
enum radioConnectionState connectionState;
BOOL subscribedToDisplays = NO;

#pragma mark
#pragma mark Parser Token Initializers

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
                         [NSNumber numberWithInt:profileToken], @"profile",
                         [NSNumber numberWithBool:cwxToken], @"cwx",
                         [NSNumber numberWithInt:waveformToken], @"waveform",
                         [NSNumber numberWithInt:audioStreamToken], @"audio_stream",
                         [NSNumber numberWithInt:opusStreamToken], @"opus_stream",
                         nil];
    self.notifyList = [[NSMutableDictionary alloc]init];
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
                              [NSNumber numberWithInt:nicknameToken], @"nickname",
                              [NSNumber numberWithInt:callsignToken], @"callsign",
                              [NSNumber numberWithInt:binauralRxToken], @"binaural_rx",
                              nil];
}

- (void) initStatusAtuTokens {
    self.statusAtuTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [NSNumber numberWithInt:atuStatusToken],  @"status",
                            [NSNumber numberWithInt:atuEnabledToken], @"atu_enabled",
                            [NSNumber numberWithInt:atuMemoriesEnabledToken], @"atu memories_enabled",
                            [NSNumber numberWithInt:atuMemoriesEnabledToken], @"memories_enabled",
                            [NSNumber numberWithInt:usingMemToken], @"using_mem",
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
                                 [NSNumber numberWithInt:txFilterChangesAllowedToken], @"tx_filter_changes_allowed",
                                 [NSNumber numberWithInt:txRfPowerChangesAllowedToken], @"tx_rf_power_changes_allowed",
                                 [NSNumber numberWithInt:synccwxToken], @"synccwx",
                                 [NSNumber numberWithInt:monAvailableToken], @"mon_available",
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
                                  [NSNumber numberWithInt:txAllowedToken], @"tx_allowed",
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


#pragma mark
#pragma mark Radio Model Methods

- (id) initWithRadioInstanceAndDelegate:(RadioInstance *)thisRadio delegate: (NSObject<RadioDelegate> *) theDelegate clientId:(NSString *)clientId {
    self = [super init];
    
    if (self) {
        self.radioInstance = thisRadio;
        self.clientId = clientId;
        
        // Create a private run queue for us to run on
        NSString *qName = @"net.k6tu.RadioQueue";
        self.radioRunQueue = dispatch_queue_create([qName UTF8String], NULL);
        
        radioSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.radioRunQueue];

        [radioSocket setIPv4PreferredOverIPv6:YES];
        [radioSocket setIPv6Enabled:NO];
        
        NSError *error = nil;
        
        if (![radioSocket connectToHost:self.radioInstance.ipAddress
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
        [self initFilterSpecs];
        
        self.responseCallbacks = [[NSMutableDictionary alloc]init];
        
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
        
        // Set up the blank meter dictionary
        self.meters = [[NSMutableDictionary alloc]init];
        
        // Set up the blank panafall dictionary and waterfall dictionary
        self.panafalls = [[NSMutableDictionary alloc]init];
        self.waterfalls = [[NSMutableDictionary alloc]init];
        
        // Set up mapping tables for Audio Stream processing
        self.daxAudioStreamToStreamHandler = [[NSMutableDictionary alloc]init];
        
        // Set up mapping table for Opus Stream processing
        self.opusStreamToStreamHandler = [[NSMutableDictionary alloc]init];
        
        self.equalizers = [[NSMutableArray alloc] initWithCapacity:2];
        self.equalizers[0] = [[NSNull alloc] init];
        self.equalizers[1] = [[NSNull alloc] init];
        
        connectionState = connecting;
        self.delegate = theDelegate;
        
        // Set up list for notification of command results
        self.notifyList = [[NSMutableDictionary alloc]init];
       
        // Set any initial non zero state requirements
        _tunePowerLevel = [NSNumber numberWithInt:10];
        _syncActiveSlice = [NSNumber numberWithBool:YES];
        
#ifdef DEBUG
        self.logRadioMessages = YES;
#endif
        
        // Listen for notification of slice deletion
        //[[NSNotificationCenter defaultCenter] addObserver:self
        //                                         selector:@selector(sliceDeleteNotification:)
        //                                             name:@"SliceDeleted"
        //                                           object:nil];
    }
    return self;
}


// Notification handler for deleted slices

- (void) sliceDeleteNotification: (NSNotification *) notification {
    Slice *thisSlice = [notification object];
    self.slices[[thisSlice.thisSliceNumber integerValue]] = [NSNull null];
}


- (void) close {
    // Release all the slices...
    for (int s=0; s < [self.slices count]; s++) {
        if ([(self.slices[s]) isKindOfClass:[Slice class]])
            [self.slices[s] youAreBeingDeleted];
            [self.slices removeObjectAtIndex:s];
    }
    
    // Close the socket
    [radioSocket disconnectAfterWriting];
    [radioSocket setDelegate:nil];
}


- (void) dealloc {
    [self stopPingTimer];
    NSLog(@"Radio dealloc completed");
}


#pragma mark radioConnectionState

- (enum radioConnectionState) radioConnectionState {
    return connectionState;
}



// Conversation Handlers

#pragma mark
#pragma mark Radio Conversation Handlers


- (void) startPingTimer {
    [self stopPingTimer];
    
    if (!self.pingTimer) {
        self.pingTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, DISPATCH_TIMER_STRICT, self.radioRunQueue);
    }
    
    if (self.pingTimer) {
        // Set timer with 10% leeway...
        dispatch_source_set_timer(self.pingTimer, dispatch_walltime(NULL, 0), 1 * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);     // Every second +/- 10%
        
        // Use weak self for the callback in the block
        __weak Radio *weakSelf = self;
        dispatch_source_set_event_handler(self.pingTimer, ^(void) { [weakSelf pingTimerFired]; });
        dispatch_resume(self.pingTimer);
    }
}


- (void) stopPingTimer {
    if (self.pingTimer) {
        dispatch_source_cancel(self.pingTimer);
        self.pingTimer = nil;
    }
}


- (void) pingTimerFired {
    // Check and see if we have lost comm with the radio = ironic huh?
    NSDate *now = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
    
    if (self.lastPingRxtime && ([now timeIntervalSinceDate:self.lastPingRxtime] > 10.0)) {
        // More than 10 seconds since the last ping response - the radio has presumably gone AWOL
        // NB:  This should be lower but there are still intermittent hangs where the radio comes
        // back after 5 seconds...
        
        // Invoke close - this will close the socket and trigger a disconnect state change to
        // any delegate
        NSLog(@"Radio timed out - sending radio state change on radioTimedOut");
        
        connectionState = radioTimedOut;
        
        if ([self.delegate respondsToSelector:@selector(radioConnectionStateChange:state:)]) {
            __weak Radio *safeSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [safeSelf.delegate radioConnectionStateChange:self state:connectionState];
            });
        }
        
        [self stopPingTimer];
    } else {
        // The timer of the last received request will be updated in pingResponseCallback: - if
        // it gets a response!
        
        // Refire the ping...
        [self commandToRadio:@"ping" notifySel:@selector(pingResponseCallback:)];
    }
    
}



// Sends the initialize requests to the radio and posts our first read

- (void) initializeRadio {
    // We are connected to the radio - create the VitaManager for this radio
    self.vitaManager = [[VitaManager alloc]init];
    if (![self.vitaManager handleRadio:self])
        // Failed to connect to a UDP port - drop the manager
        self.vitaManager = nil;
    
    // Create and start the keep alive timer so we can detect radio disconnection events
    [self startPingTimer];
    [self commandToRadio:@"ping" notifySel:@selector(pingResponseCallback:)];
    
    // Post initial commands
    [self commandToRadio:[NSString stringWithFormat:@"client program %@", self.clientId]];
    // [self commandToRadio:[NSString stringWithFormat:@"client start_persistence off"]];
    [self commandToRadio:@"remote_audio rx_on=0"];
    
    if (self.vitaManager)
        [self commandToRadio:[NSString stringWithFormat:@"client udpport %i", (int)self.vitaManager.vitaPort]];
    
    [self commandToRadio:@"keepalive enable"];
    [self commandToRadio:@"sub tx all"];
    [self commandToRadio:@"sub atu all"];
    [self commandToRadio:@"sub meter all"];
    [self commandToRadio:@"sub slice all"];
    [self commandToRadio:@"sub pan all"];
    [self commandToRadio:@"eq rx info"];
    [self commandToRadio:@"eq tx info"];
    [self commandToRadio:@"sub audio_stream all"];
    
    [self commandToRadio:@"info" notifySel:@selector(infoResponseCallback:)];
    [self commandToRadio:@"version" notifySel:@selector(versionResponseCallback:)];
    [self commandToRadio:@"ant list" notifySel:@selector(antListResponseCallback:)];
    [self commandToRadio:@"mic list" notifySel:@selector(micListResponseCallback:)];
    
    [self commandToRadio:@"profile global info"];
    [self commandToRadio:@"profile tx info"];
    [self commandToRadio:@"sub profile all"];

  [radioSocket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:0];
}



- (void) commandToRadio: (NSString *) cmd {
    unsigned int thisSeq;
    
    // Sync block protects mult-thread acccess to the sequence number possibly
    // causing (gross) timing problems in callback situations.
    @synchronized(self) {
        thisSeq = seqNum++;
    }
    
    NSString *cmdline = [[NSString alloc] initWithFormat:@"c%@%u|%@\n", verbose ? @"d" : @"", (unsigned int)thisSeq, cmd ];
    
    if (self.logRadioMessages)
        NSLog(@"Data sent - %@", cmdline);
    
    [radioSocket writeData: [cmdline dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:(long)thisSeq];
}


- (unsigned int) commandToRadio:(NSString *) cmd notify: (id<RadioDelegate>) notifyMe {
    unsigned int thisSeq;

    // Sync block protects mult-thread acccess to the sequence number possibly
    // causing (gross) timing problems in callback situations.
    @synchronized (self) {
        thisSeq = seqNum++;
    }
    
    NSString *cmdline = [[NSString alloc] initWithFormat:@"c%@%u|%@\n", verbose ? @"d" : @"", (unsigned int)thisSeq, cmd ];
    
    @synchronized (self.notifyList) {
        self.notifyList[[NSString stringWithFormat:@"%u", thisSeq]] = notifyMe;
    }
    
    if (self.logRadioMessages)
        NSLog(@"Data sent - %@", cmdline);

    [radioSocket writeData: [cmdline dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:(long)thisSeq];
    return thisSeq;
}

- (int) commandToRadio:(NSString *)cmd notifySel:(SEL)callback {
    unsigned int seq = [self commandToRadio:cmd notify:self];
    
    // At the cost of a sync block, protecting the addition (here) and removal (in radioCommandResponse:)
    // is cheap insurance
    @synchronized (self.responseCallbacks) {
        [self.responseCallbacks setValue:[NSValue valueWithPointer:callback] forKey:[NSString stringWithFormat:@"%u", seq]];
    }
    
    return seq;
}


// Private Macro
//
// Macro to perform inline update on an ivar with KVO notification

#define updateWithNotify(key,ivar,value)  \
{  \
    __weak Radio *safeSelf = self; \
    dispatch_async(dispatch_get_main_queue(), ^(void) { \
        [safeSelf willChangeValueForKey:(key)]; \
        (ivar) = (value); \
        [safeSelf didChangeValueForKey:(key)]; \
    }); \
}


//
// For the radio, we have our own table of which selectors to call for the
// callback
//


- (void) radioCommandResponse:(unsigned int)seqNum response:(NSString *)cmdResponse {
    NSString *key = [NSString stringWithFormat:@"%u", seqNum];
    SEL callback = [[self.responseCallbacks objectForKey:key] pointerValue];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (callback)
        [self performSelector:callback withObject:cmdResponse];
    else {
        NSLog(@"radioCommandResponse: selector NULL - seqNum = %u  key = %@", seqNum, key);
        for (NSString *s in self.notifyList) {
            NSLog(@"  Waiting key: %@", s);
        }
        for (NSString *s in self.responseCallbacks) {
            NSLog(@"  Callback key: %@", s);
        }
    }
#pragma clang diagnostic pop
    
    // At the cost of a sync block, protecting the addition (here) and removal (in radioCommandResponse:)
    // is cheap insurance
    @synchronized (self.responseCallbacks) {
        [self.responseCallbacks removeObjectForKey:key];
    }
}


#pragma mark
#pragma mark Reponse Callback Handlers

// Utility methods for hex conversion of stream ids

- (unsigned int)intFromHexString:(NSString *) hexStr {
    unsigned int hexInt = 0;
    
    // Create scanner
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    
    // Tell scanner to skip the # character if any
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"#"]];
    
    // Scan hex value
    [scanner scanHexInt:&hexInt];
    
    return hexInt;
}

- (NSString *) hexStringFormatFromInt:(unsigned int) val {
    return [NSString stringWithFormat:@"0x%08X", val];
}

- (NSString *) reformatStreamId:(NSString *) streamId {
    return [self hexStringFormatFromInt:[self intFromHexString:streamId]];
}


- (void) infoResponseCallback:(NSString *)cmdResponse {
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
                    updateWithNotify(@"radioScreenSaver", _radioScreenSaver, val);
                    break;
                    
                case callsign:
                    updateWithNotify(@"radioCallsign", _radioCallsign, val);
                    break;
                    
                case model:
                    updateWithNotify(@"radioModel", _radioModel, val);
                    break;
                    
                case name:
                    updateWithNotify(@"radioName", _radioName, val);
                    break;
            }
        }
    }    
}


//
// Process a response from a Version command
//     format: <errorNumber>|<SmartSDR-MB=a.b.c.d>#<PSoc-MBTRX=a.b.c.d>#<PSocMBPA100=a.b.c.d>#<FPGA-MB=a.b.c.d>
//
- (void) versionResponseCallback:(NSString *)cndResponse {
    NSString *versionToken;
    NSString *stringVal;
    
    NSScanner *scan = [[NSScanner alloc] initWithString:cndResponse];
    
    // First up is the response error code... grab it and skip the |
    NSString *errorNumAsString;
    [scan scanUpToString:@"|" intoString: &errorNumAsString];
    [scan scanString:@"|" intoString: nil];
    
    // Anything other than 0 is an error
    if ([errorNumAsString intValue] != 0) {
        // FIXME: Do something?
        return;
    }
    
    enum wantedTerms {
        SmartSDRMB = 1,
        PSoCMBTRX,
        PSoCMBPA100,
        FPGAMB,
    };
    
    NSDictionary *terms = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [NSNumber numberWithInt:SmartSDRMB], @"SmartSDR-MB",
                           [NSNumber numberWithInt:PSoCMBTRX], @"PSoC-MBTRX",
                           [NSNumber numberWithInt:PSoCMBPA100], @"PSoC-MBPA100",
                           [NSNumber numberWithInt:FPGAMB], @"FPGA-MB",
                           nil];
    
    while (![scan isAtEnd]) {
        // Grab the token between current scanner position and the '=' separator
        // and then eat the '='
        [scan scanUpToString:@"=" intoString: &versionToken];
        [scan scanString:@"=" intoString: nil];
        
        NSString *ref = @"";
        switch ([terms[versionToken] intValue]) {
                
            case SmartSDRMB:
                [scan scanUpToString:@"#" intoString: &stringVal];
                ref = stringVal;
                updateWithNotify(@"smartSdrVersion", _smartSdrVersion, ref);
                break;
                
            case PSoCMBTRX:
                [scan scanUpToString:@"#" intoString: &stringVal];
                ref = stringVal;
                updateWithNotify(@"psocMbtrxVersion", _psocMbtrxVersion, ref);
                break;
                
            case PSoCMBPA100:
                [scan scanUpToString:@"#" intoString: &stringVal];
                ref = stringVal;
                updateWithNotify(@"psocMbPa100Version", _psocMbPa100Version, ref);
                break;
                
            case FPGAMB:
                [scan scanUpToString:@"#" intoString: &stringVal];
                ref = stringVal;
                updateWithNotify(@"fpgaMbVersion", _fpgaMbVersion, ref);
                break;
                
            default:
                // Unknown token, Eat until the next # or \n
                [scan scanUpToCharactersFromSet: [NSCharacterSet characterSetWithCharactersInString: @"#\n"] intoString: nil];
                break;
                
        }
        // Scanner is either at a space or at the end - eat either
        [scan scanCharactersFromSet: [NSCharacterSet characterSetWithCharactersInString: @"#\n"] intoString: nil];
    }
}


//
// Process a response from an Ant List command
//     format: <errorNumber>|<antennaConnection>,<antennaConnection>,...,<antennaConnection>
//
- (void) antListResponseCallback:(NSString *)cndResponse {
    
    NSScanner *scan = [[NSScanner alloc] initWithString:cndResponse];
    
    // First up is the response error code... grab it and skip the |
    NSString *errorNumAsString;
    [scan scanUpToString:@"|" intoString: &errorNumAsString];
    [scan scanString:@"|" intoString: nil];
    
    // Anything other than 0 is an error, just return
    if ([errorNumAsString intValue] != 0) {
        return;
    }
    // get the remainder of the Response
    NSString *stringVal;
    [scan scanUpToCharactersFromSet: [NSCharacterSet characterSetWithCharactersInString: @" \n"] intoString: &stringVal];
    // separate them out into an array
    NSArray *antListRef = [stringVal componentsSeparatedByString:@","];
    updateWithNotify(@"antList", _antList, antListRef);
}


//
// Process a response from a Mic List command
//     format: <errorNumber>|<micConnection>,<micConnection>,...,<micConnection>
//
- (void) micListResponseCallback:(NSString *)cmdResponse {
    
    NSScanner *scan = [[NSScanner alloc] initWithString:cmdResponse];
    
    // First up is the response error code... grab it and skip the |
    NSString *errorNumAsString;
    [scan scanUpToString:@"|" intoString: &errorNumAsString];
    [scan scanString:@"|" intoString: nil];
    
    // Anything other than 0 is an error, just return
    if ([errorNumAsString intValue] != 0) {
        return;
    }
    // get the remainder of the Response
    NSString *stringVal;
    [scan scanUpToCharactersFromSet: [NSCharacterSet characterSetWithCharactersInString: @" \n"] intoString: &stringVal];
    // separate them out into an array
    NSArray *micListRef = [stringVal componentsSeparatedByString:@","];
    updateWithNotify(@"antList", _micList, micListRef);
}


- (void) panafallCreateCallback:(NSString *)cmdResponse {
    // cmdResponse is the full response including the R<seqnum>|
    NSScanner *scan = [[NSScanner alloc] initWithString:[cmdResponse substringFromIndex:1]];
    [scan setCharactersToBeSkipped:nil];
    
    // Skip the sequence number and the following |
    [scan scanInteger:nil];
    [scan scanString:@"|" intoString:nil];
    
    // So now we have  <code>|<pan streamid>,<waterfall streamid>
    // Next up is the response error code... grab it and skip the |
    NSString *errorNumAsString;
    [scan scanUpToString:@"|" intoString:&errorNumAsString];
    [scan scanString:@"|" intoString:nil];
    
    if ([errorNumAsString integerValue])
        // Anything other than 0 is an error and we return
        return;
    
    NSString *response;
    [scan scanUpToString:@"\n" intoString:&response];

    // Split reponse on the ,
    NSArray *streamIds = [response componentsSeparatedByString:@","];
    NSString *streamIdPan = [self reformatStreamId:streamIds[0]];
    NSString *streamIdWf = [self reformatStreamId:streamIds[1]];
    
    // Create the panafall and waterfall so they are ready to handle status messages
    Panafall *pan = [[Panafall alloc]init];
    [pan attachedRadio:self streamId:streamIdPan];
    
    Waterfall *wf = [[Waterfall alloc]init];
    [wf attachedRadio:self streamId:streamIdWf];
    
    [pan updateWaterfallRef:wf];
    [wf updatePanafallRef:pan];
    
    // Add them to the list of Panafalls and Waterfalls
    @synchronized (self.panafalls) {
        [self.panafalls setObject:pan forKey:streamIdPan];
    }
    
    @synchronized (self.waterfalls) {
        [self.waterfalls setObject:wf forKey:streamIdWf];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PanafallCreated" object:pan];
    });
}


- (void) audioStreamCreateCallback:(NSString *)cmdResponse {
    // cmdResponse is the full response including the R<seqnum>|
    NSScanner *scan = [[NSScanner alloc] initWithString:[cmdResponse substringFromIndex:1]];
    [scan setCharactersToBeSkipped:nil];
    
    // Grab the response number, skip it and the trailing |
    [scan scanInteger:nil];
    [scan scanString:@"|" intoString:nil];
    
    // So now we have <code>|<audio streamid>
    // Next up is the response error code... grab it and skip the |
    NSString *errorNumAsString;
    [scan scanUpToString:@"|" intoString:&errorNumAsString];
    [scan scanString:@"|" intoString:nil];
    
    if ([errorNumAsString integerValue]) {
        // Anything other than 0 is an error and we return
        return;
    }
    
    // Grab the streamId and set things up...
    DAXAudio *streamHandler =  [[DAXAudio alloc]init];
    NSString *streamId;
    
    [scan scanUpToString:@"\n" intoString:&streamId];
    streamId = [self reformatStreamId:streamId];
    
    // Update the streamHandler with the streamId
    [streamHandler attachedRadio:self streamId:streamId];
    
    @synchronized (self.daxAudioStreamToStreamHandler) {
        // Add to dictionary of handlers for this stream id...
        [self.daxAudioStreamToStreamHandler setObject:streamHandler forKey:streamId];
    }
    
    // Finally, fire off the notification that the stream was created
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioStreamCreated" object:streamHandler];
    });
}


- (void) pingResponseCallback:(NSString *) cmdResponse {
    // Update the time we received the last ping response
    self.lastPingRxtime = [[NSDate alloc]initWithTimeIntervalSinceNow:0];
    
    // Nothing else to do - the pingTimerFired callback will handle everything else
}


#pragma mark
#pragma mark Parser Handlers




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
            [self parseSliceToken: scan selfStatus:selfStatus];
            break;
            
        case mixerToken:
            [self parseMixerToken: scan];
            break;
            
        case displayToken:
            [self parseDisplayToken: scan selfStatus:selfStatus];
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
            
        case profileToken:
            [self parseProfileToken: scan];
            break;
            
        case cwxToken:
            [self parseCwxToken: scan];
            break;
            
        case waveformToken:
            [self parseWaveformToken: scan];
            break;
            
        case audioStreamToken:
            [self parseAudioStreamToken: scan selfStatus:selfStatus];
            break;
            
        case opusStreamToken:
            [self parseOpusStreamToken: scan selfStatus:selfStatus];
            break;
            
        default:
            NSLog(@"Unexpected token in parseStatusType - %@", sourceToken);
            break;
    }
    return;
}



- (void) parseHandleType:(NSString *)payload {
    updateWithNotify(@"apiHandle", _apiHandle, [payload substringFromIndex:1]);
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
    updateWithNotify(@"apiVersion", _apiVersion, payload);
}



- (void) parseResponseType:(NSString *)payload {
    // See if someone is waiting for this response...
    NSScanner *scan = [[NSScanner alloc] initWithString:[payload substringFromIndex:1]];
    [scan setCharactersToBeSkipped:nil];
    
    // First up is the sequence number... grab it and skip the |
    NSString *seqNumAsString;
    [scan scanUpToString:@"|" intoString:&seqNumAsString];
    id<RadioDelegate> notifyIt = self.notifyList[seqNumAsString];
    
    if (notifyIt) {
        if ([notifyIt respondsToSelector:@selector(radioCommandResponse:response:)])
            [notifyIt radioCommandResponse:(unsigned int)[seqNumAsString integerValue] response:payload];
        
        // Remove the object for the notification list
        @synchronized (self.notifyList) {
            [self.notifyList removeObjectForKey:seqNumAsString];
        }
    }
}



- (void) parseMixerToken: (NSScanner *) scan {
    
};


- (void) parseDisplayToken: (NSScanner *) scan selfStatus:(BOOL)selfStatus {
    // Ignore status updates that are not our own - at least until panafall
    // mirroring is supported
    if (!selfStatus) return;
    
    NSString *dest, *streamId;
    BOOL removed;
    
    // we have the scanner at either pan or waterfall followed by the stream id
    [scan scanUpToString:@" " intoString:&dest];
    [scan scanString:@" " intoString:nil];
    [scan scanUpToString:@" " intoString:&streamId];
    
    // Is this stream being removed?
    removed = !([[scan string]rangeOfString:@"removed"].location == NSNotFound);
    
    if (removed) {
        if ([self.panafalls objectForKey:streamId]) {
            Panafall *thisPan = self.panafalls[streamId];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PanafallDeleted" object:thisPan];
            });
            [thisPan willRemoveStreamProcessor];
            [self.panafalls removeObjectForKey:streamId];
            
        } else if ([self.waterfalls objectForKey:streamId]) {
            Waterfall *thisWf = self.waterfalls[streamId];
            [thisWf willRemoveStreamProcessor];
            [self.waterfalls removeObjectForKey:streamId];
        }

        return;
    }
    
    // There are multiple ways in which a pan can be added in addition to an explicit
    // create by the client.  So...
    //
    // Check here to see if the pan objects have been created - if not, create one on
    // the fly...
    
    BOOL wfCreated = NO;
    
    if ([dest containsString:@"pan"] && ![self.panafalls objectForKey:streamId]) {
        // New pan - create and add to our list
        
        Panafall *pan = [[Panafall alloc]init];
        [pan attachedRadio:self streamId:streamId];
        
        @synchronized(self.panafalls) {
            [self.panafalls setObject:pan forKey:streamId];
        }
    } else if ([dest containsString:@"waterfall"] && ![self.waterfalls objectForKey:streamId]) {
        // New waterfall - create and add to waterfall list
        
        Waterfall *wf = [[Waterfall alloc]init];
        [wf attachedRadio:self streamId:streamId];
        
        @synchronized (self.waterfalls ) {
            [self.waterfalls setObject:wf forKey:streamId];
        }
        
        wfCreated = YES;
    }
    
    // Dispatch to the display
    if ([self.panafalls objectForKey:streamId]) {
        Panafall *pan = self.panafalls[streamId];
        [pan statusParser:scan selfStatus:selfStatus];
       
    } else if ([self.waterfalls objectForKey:streamId]) {
        Waterfall *wf = self.waterfalls[streamId];
        [wf statusParser:scan selfStatus:selfStatus];
        
        if (wfCreated) {
            // The waterfall object is also created after the pan to which it refers so
            // we should now figure out what the pan object stream id is, relate it to the
            // panafall object for that stream and send out a PanafallCreated notification
            
            NSString *streamIdWf = [self reformatStreamId:streamId];
            
            for (NSString *panId in self.panafalls) {
                Panafall *pan = self.panafalls[panId];
                
                if ([pan.waterfallId isEqualToString:streamIdWf]) {
                    // Update each object to point to its cousin
                    [pan updateWaterfallRef:wf];
                    [wf updatePanafallRef:pan];
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"PanafallCreated" object:pan];
                    });
                }
            }
        }
    }
}


- (void) parseMeterToken: (NSScanner *) scan {
    NSScanner *localScan = [scan copy];
    NSInteger meternum;
    BOOL removed;
    Meter *thisMeter;
    Slice *thisSlice;
    
    // Extract the meter number
    [localScan scanInteger:&meternum];
    NSString *mKey = [NSString stringWithFormat:@"%i", (int) meternum];
    removed = !([[localScan string]rangeOfString:@"removed"].location == NSNotFound);
    
    if (removed) {
        // If this is a meter for a slice, we need to update the slice's own
        // reference to the meter...  meters are added/removed when the mode
        // of the slice is changed.
        
        thisMeter = self.meters[mKey];
        
        if (thisMeter.meterSource == sliceSource) {
            // Remove the meter from the slice
            thisSlice = self.slices[thisMeter.sliceNum];
            [thisSlice removeMeter:thisMeter];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MeterDeleted" object:thisMeter];
        });
        
        @synchronized (self.meters) {
            [self.meters removeObjectForKey:mKey];
        }
        return;
    }

    // Do we already have a Meter object for this meter?
    @synchronized(self.meters) {
        if (self.meters[mKey])
            // Meter already exists - duplicate notification
            return;
    }
    
    // Meter is being created
    thisMeter = [[Meter alloc]init];

    // Pass meter status string to the meter to have it set itself up
    [thisMeter setupMeter:self scan:scan];
    
    @synchronized (self.meters) {
        [self.meters setObject:thisMeter forKey:mKey];
    }
    
    if (thisMeter.meterSource == sliceSource) {
        // Add the meter to the slices BUT be careful...  note that the
        // meters for a slice are notified BEFORE the slice itself is created
        // via the status notification...  If we dont have a slice object
        // for the relevant slice, we can punt here as all meters for the slice
        // will be added when the slice itself is created.
        if ([self.slices[thisMeter.sliceNum] isKindOfClass:[Slice class]]) {
            // Existing slice... safe to add the meter
            thisSlice = self.slices[thisMeter.sliceNum];
            [thisSlice addMeter:thisMeter];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MeterCreated" object:thisMeter];
        });
    }
}



- (void) parseGpsToken: (NSScanner *) scan {
    
}

//
// Parse Profile tokens
//     called on the GCD thread associated with the GCD tcpSocketQueue
//
//     format: <apiHandle>|profile <profileType> list=<value>^<value>^...<value>^
//                           OR
//     format: <apiHandle>|profile <profileType> current=<value>
//
//     scan is initially at scanLocation = 17, start of the <profileType>
//     "<apiHandle>|profile " has already been processed
//
- (void) parseProfileToken: (NSScanner *) scan {
    // get the Profile type
    NSString *profileType;
    [scan scanUpToString:@" " intoString: &profileType];
    // skip the space
    [scan scanString:@" " intoString: nil];
    
    // get the Sub type
    NSString *profileSubType;
    [scan scanUpToString:@"=" intoString: &profileSubType];
    // skip the "="
    [scan scanString:@"=" intoString: nil];
    
    // get the remainder of the command
    NSString *remainderOfCommand;
    [scan scanUpToString:@"\n" intoString: &remainderOfCommand];
    
    // List or Current value?
    if ([profileSubType isEqualToString: @"list"]) {
        // it's the List, separate the components
        NSMutableArray *profileNames;
        profileNames = [[remainderOfCommand componentsSeparatedByString:@"^"] mutableCopy];
        // remove the last (empty) string
        [profileNames removeLastObject];
        // save it in the appropriate property
        if ([profileType isEqualToString: @"global"]) {
            @synchronized (self.globalProfiles) {
                updateWithNotify(@"globalProfiles", _globalProfiles, profileNames)
            }
        } else if ([profileType isEqualToString: @"tx"]) {
            @synchronized (self.txProfiles) {
                updateWithNotify(@"txProfiles", _txProfiles, profileNames)
            }
        }
        
    } else if ([profileSubType isEqualToString: @"current"]) {
        // it's the Current value
        // save it in the appropriate property
        if ([profileType isEqualToString: @"global"]) {
            _currentGlobalProfile = remainderOfCommand;
            updateWithNotify(@"currentGlobalProfile", _currentGlobalProfile, remainderOfCommand)
        } else if ([profileType isEqualToString: @"tx"]) {
            updateWithNotify(@"currentTxProfile", _currentTxProfile, remainderOfCommand)
        }
    }
}


- (void) parseCwxToken: (NSScanner *) scan {
  
}


- (void) parseEqToken: (NSScanner *) scan selfStatus:(BOOL)selfStatus {
    NSInteger eqNum;
    Equalizer *eq;
    BOOL firstUpdate = NO;
    NSString *scannerString = scan.string;
    
    // Check for old bogus APF parameter and ignore
    if ([scannerString rangeOfString:@"apf"].location != NSNotFound)
        return;

    // Determine equalizer type
    
    if ([scannerString rangeOfString:@"rx"].location == NSNotFound)
        eqNum = 1;  // tx
    else
        eqNum = 0;  // rx
    
    if ([self.equalizers[eqNum] isKindOfClass:[NSNull class]]) {
        // Allocate an equalizer
        eq = [[Equalizer alloc]initWithTypeAndRadio:(eqNum == 1) ? @"tx" : @"rx" radio:self];
        self.equalizers[eqNum] = eq;
        firstUpdate = YES;
    }
    
    eq = self.equalizers[eqNum];
    
    if ([eq isKindOfClass:[Equalizer class]] && selfStatus && !firstUpdate)
        // Ignore the update - we already know the answer!
        return;
    
    // The equalizer updates can run on the Radio run queue which we should already be on...
    [eq statusParser:scan selfStatus:selfStatus];
}


- (void) parseRadioToken: (NSScanner *) scan {
    NSString *token;
    NSString *value;
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
                updateWithNotify(@"availableSlices", _availableSlices, [NSNumber numberWithInteger:intVal]);
                break;
                
            case panadaptersToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"availablePanadapters", _availablePanadapters, [NSNumber numberWithInteger:intVal]);
                break;
                
            case lineoutGainToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"masterSpeakerAfGain", _masterSpeakerAfGain, [NSNumber numberWithInteger:intVal]);
                break;
                
            case lineoutMuteToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"masterSpeakerMute", _masterSpeakerMute, [NSNumber numberWithBool:intVal]);
                break;
                
            case headphoneGainToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"masterHeadsetAfGain", _masterHeadsetAfGain, [NSNumber numberWithInteger:intVal]);
                break;
                
            case headphoneMuteToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"masterHeadsetMute", _masterHeadsetMute, [NSNumber numberWithBool:intVal]);
                break;
                
            case remoteOnToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"remoteOnEnabled", _remoteOnEnabled, [NSNumber numberWithBool:intVal]);
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
                
            case nicknameToken:
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"] intoString:&value];
                updateWithNotify(@"radioName", _radioName, value);
                break;
                
            case callsignToken:
                [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"] intoString:&value];
                updateWithNotify(@"radioCallsign", _radioCallsign, value);
                break;
                
            case binauralRxToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"binauralRx", _binauralRx, [NSNumber numberWithBool:intVal]);
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
                updateWithNotify(@"atuEnabled", _atuEnabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case atuMemoriesEnabledToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"atuMemoriesEnabled", _atuMemoriesEnabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case usingMemToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"atuUsingMemories", _atuUsingMemories, [NSNumber numberWithBool:intVal]);
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
}


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
                updateWithNotify(@"transmitFrequency", _transmitFrequency, stringVal);
                break;
                
            case loTxFilterToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                updateWithNotify(@"transmitFilterLo", _transmitFilterLo, stringVal);
                break;
                
            case hiTxFilterToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                updateWithNotify(@"transmitFilterHi", _transmitFilterHi, stringVal);
                break;
                
            case rfPowerToken:
                // Ignore the update if we are in tune state
                if ([self.tuneEnabled boolValue]) {
                    // pitch the value
                    
                    [scan scanInteger:&intVal];
                    break;
                }
                
                [scan scanInteger:&intVal];
                updateWithNotify(@"rfPowerLevel", _rfPowerLevel, [NSNumber numberWithInteger:intVal]);
                break;
                
            case amCarrierLevelToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"amCarrierLevel", _amCarrierLevel, [NSNumber numberWithInteger:intVal]);
                break;
                
            case micSelectionToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                updateWithNotify(@"micSelection", _micSelection, stringVal);
                break;
                
            case micLevelToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"micLevel", _micLevel, [NSNumber numberWithInteger:intVal]);
                break;
                
            case micAccToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"micAccEnabled", _micAccEnabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case micBoostToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"micBoost", _micBoost, [NSNumber numberWithBool:intVal]);
                break;
                
            case micBiasToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"micBias", _micBias, [NSNumber numberWithBool:intVal]);
                break;
                
            case companderToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"companderEnabled", _companderEnabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case companderLevelToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"companderLevel", _companderLevel, [NSNumber numberWithInteger:intVal]);
                break;
                
            case speechProcToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"speechProcEnabled", _speechProcEnabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case speechProcLevelToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"speechProcLevel", _speechProcLevel, [NSNumber numberWithInteger:intVal]);
                break;
                
            case noiseGateLevelToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"noiseGateLevel", _noiseGateLevel, [NSNumber numberWithInteger:intVal]);
                break;
                
            case pitchToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"cwPitch", _cwPitch, [NSNumber numberWithInteger:intVal]);
                break;
                
            case speedToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"cwSpeed", _cwSpeed, [NSNumber numberWithInteger:intVal]);
                break;
                
            case iambicToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"cwIambicEnabled", _cwIambicEnabled, [NSNumber numberWithInteger:intVal]);
                break;
                
            case iambicModeToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"cwIambicMode", _cwIambicMode, [NSString stringWithString:(intVal) ? @"B" : @"A"]);
                break;
                
            case swapPaddlesToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"cwSwapPaddles", _cwSwapPaddles, [NSNumber numberWithBool:intVal]);
                break;
                
            case breakInToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"cwBreakinEnabled", _cwBreakinEnabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case breakInDelayToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"cwBreakinDelay", _cwBreakinDelay, [NSNumber numberWithInteger:intVal]);
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
                updateWithNotify(@"voxEnabled", _voxEnabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case voxLevelToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"voxLevel", _voxLevel, [NSNumber numberWithInteger:intVal]);
                break;
                
            case voxDelayToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"voxDelay", _voxDelay, [NSNumber numberWithInteger:intVal]);
                break;
                
            case voxVisibleToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"voxVisible", _voxVisible, [NSNumber numberWithBool:intVal]);
                break;
                
            case monGainToken:
                [scan scanInteger:&intVal];
                // Down rev radio - ignore
                break;
                
            case tuneToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"tuneEnabled", _tuneEnabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case tunePowerToken:
                if ([self.tuneEnabled boolValue]) {
                    // Ignore the update
                    
                    [scan scanInteger:&intVal];
                    break;
                }
                [scan scanInteger:&intVal];
                updateWithNotify(@"tunePowerLevel", _tunePowerLevel, [NSNumber numberWithInteger:intVal]);
                break;
                
            case hwAlcEnabledToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"hwAlcEnabled", _hwAlcEnabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case metInRxToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"metInRxEnabled", _metInRxEnabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case daxTxEnabledToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"txDaxEnabled", _txDaxEnabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case inhibitToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"txInhibit", _txInhibit, [NSNumber numberWithBool:intVal]);
                break;
                
            case showTxInWaterFallToken:
                [scan scanInteger:&intVal];
                // Nothing to do for us at present
                break;
                
            case sidetoneToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sidetone", _sidetone, [NSNumber numberWithBool:intVal]);
                break;
                
            case sidetoneGainToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sidetoneGain", _sidetoneGain, [NSNumber numberWithInteger:intVal]);
                break;
                
            case sidetonePanToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"sidetonePan", _sidetonePan, [NSNumber numberWithInteger:intVal]);
                break;
                
            case phMonitorToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"phMonitor", _phMonitor, [NSNumber numberWithBool:intVal]);
                break;
                
            case monitorPHGainToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"monitorPHGain", _monitorPHGain, [NSNumber numberWithInteger:intVal]);
                break;
                
            case monitorPHPanToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"monitorPHPan", _monitorPHPan, [NSNumber numberWithInteger:intVal]);
                break;
                
            case cwlEnabledToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"cwlEnabed", _cwlEnabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case rawIQEnabledToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"rawIQEnabled", _rawIQEnabled,  [NSNumber numberWithBool:intVal]);
                break;
                
            case txFilterChangesAllowedToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"txFilterChangedAllowed", _txFilterChangesAllowed,  [NSNumber numberWithBool:intVal]);
                break;
                
            case txRfPowerChangesAllowedToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"txRfPowerChangesAllowed", _txRfPowerChangesAllowed,  [NSNumber numberWithBool:intVal]);
                break;
                
            case synccwxToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"syncCWX", _syncCWX,  [NSNumber numberWithBool:intVal]);
                break;
                
            case monAvailableToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"monAvailable", _monAvailable,  [NSNumber numberWithBool:intVal]);
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
                updateWithNotify(@"interlockTimeoutValue", _interlockTimeoutValue, [NSNumber numberWithInteger:intVal]);
                break;
                
            case acc_txreq_enableToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"accTxReqEnable", _accTxReqEnable, [NSNumber numberWithBool:intVal]);
                break;
                
            case rca_txreq_enableToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"rcaTxReqEnable", _rcaTxReqEnable, [NSNumber numberWithBool:intVal]);
                break;
                
            case acc_txreq_polarityToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"accTxReqPolarity", _accTxReqPolarity, [NSNumber numberWithInteger:intVal]);
                break;
                
            case rca_txreq_polarityToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"rcaTxRefPolarity", _rcaTxReqPolarity, [NSNumber numberWithInteger:intVal]);
                break;
                
            case ptt_delayToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"pttDelay", _pttDelay, [NSNumber numberWithInteger:intVal]);
                break;
                
            case tx1_delayToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"tx1Delay", _tx1Delay, [NSNumber numberWithInteger:intVal]);
                break;
                
            case tx2_delayToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"tx2Delay", _tx2Delay, [NSNumber numberWithInteger:intVal]);
                break;
                
            case tx3_delayToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"tx3Delay", _tx3Delay, [NSNumber numberWithInteger:intVal]);
                break;
                
            case acc_tx_delayToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"accTxDelay", _accTxDelay, [NSNumber numberWithInteger:intVal]);
                break;
                
            case tx_delayToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"txDelay", _txDelay, [NSNumber numberWithInteger:intVal]);
                break;
                
            case stateToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                updateWithNotify(@"interlockState", _interlockState, [self.statusInterlockStateTokens objectForKey: stringVal]);
                break;
                
            case sourceToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                updateWithNotify(@"pttSource", _pttSource, stringVal);
                break;
                
            case reasonToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                updateWithNotify(@"interlockReason", _interlockReason, stringVal);
                break;
                
            case tx1EnabledToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"tx1Enabled", _tx1Enabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case tx2EnabledToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"tx2Enabled", _tx2Enabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case tx3EnabledToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"tx3Enabled", _tx3Enabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case accTxEnabledToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"accTxEnabled", _accTxEnabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case txAllowedToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"txAllowed", _txAllowed, [NSNumber numberWithBool:intVal]);
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



- (void) parseSliceToken: (NSScanner *) scan selfStatus:(BOOL)selfStatus{
    NSInteger thisSliceNum;
    
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
        
        // Slice is created - scan the meters looking for the meters associated with this
        // slice and tell the slice to add them to its own list.  We can run this on our own
        // queue since as the slice has just been created, there won't yet be any observers
        
        for (id key in self.meters) {
            Meter *m = self.meters[key];
            if (m.meterSource == sliceSource && m.sliceNum == thisSliceNum)
                [thisSlice addMeter:m];
        }
        
        dispatch_sync(thisSlice.sliceRunQueue, ^(void){
            [thisSlice statusParser:scan selfStatus:selfStatus];
        });
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SliceCreated" object:thisSlice];
        });
        
        return;
    }
    
    // Slice identified, created if necessary - pass remaining scanner to the slice
    // for processing after checking whether the slice is being deleted.
    
    if ([[scan string] rangeOfString:@"in_use=0"].location != NSNotFound) {
        // Slice is being deleted.  Post the notification here but do it via an async dispatch on
        // the main queue...
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SliceDeleted" object:thisSlice];
        });
        
        // Now release the slice
        self.slices[thisSliceNum] = [[NSNull alloc]init];
        return;
    }
    
    dispatch_async(thisSlice.sliceRunQueue, ^(void){[thisSlice statusParser:scan selfStatus:selfStatus];});
}


- (void) parseWaveformToken:(NSScanner *) scan {
    // For now, ignore
}


- (void) parseAudioStreamToken:(NSScanner *) scan selfStatus:(BOOL)selfStatus{
    NSString *streamId;
    BOOL removed;
    
    // we have the scanner at  the stream id
    [scan scanUpToString:@" " intoString:&streamId];
    
    streamId = [self reformatStreamId:streamId];
    
    // Is this stream being removed?
    removed = !([[scan string]rangeOfString:@"in_use=0"].location == NSNotFound);
    
    if (removed) {
        if ([self.daxAudioStreamToStreamHandler objectForKey:streamId]) {
            DAXAudio *streamHandler = self.daxAudioStreamToStreamHandler[streamId];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioStreamDeleted" object:streamHandler];
            });
         
            @synchronized (self.daxAudioStreamToStreamHandler) {
                [self.daxAudioStreamToStreamHandler removeObjectForKey:streamId];
            }
        }
        
        return;
    }
    
    // Dispatch to the stream Handler
    if ([self.daxAudioStreamToStreamHandler objectForKey:streamId]) {
        DAXAudio *streamHandler = self.daxAudioStreamToStreamHandler[streamId];
        [streamHandler statusParser:scan selfStatus:selfStatus];
    }
}


- (void) parseOpusStreamToken:(NSScanner *) scan selfStatus:(BOOL) selfStatus {
    NSString *streamId;
    
    if (!selfStatus)
        return;
    
    // we have the scanner at the stream id
    [scan scanUpToString:@" " intoString:&streamId];
    
    streamId = [self reformatStreamId:streamId];

    // Do we have a handler for this Opus stream?  It's a bit bloody moot for now
    // as there is currently only ever one stream supported and its never removed
    // however... that's how it goes!
    
    OpusAudio *opus =  [self.opusStreamToStreamHandler objectForKey:streamId];
    
    if (!opus) {
        // Create the handler and set it up
        opus = [[OpusAudio alloc]init];
        [opus attachedRadio:self streamId:streamId];
        
        @synchronized(self.opusStreamToStreamHandler) {
            self.opusStreamToStreamHandler[streamId] = opus;
        }
        
        // Finally, fire off the notification that the stream was created
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"OpusStreamCreated" object:opus];
        });
    }
    
    [opus statusParser:scan selfStatus:selfStatus];
}



#pragma mark
#pragma mark Radio Setter methods

// Private macro to improve readibility of setters

#define commandUpdateNotify(cmd, key, ivar, value) \
/* Let observers know the change on the main queue */ \
    [self willChangeValueForKey:(key)]; \
    (ivar) = (value); \
    [self didChangeValueForKey:(key)]; \
     \
    __weak Radio *safeSelf = self; \
    dispatch_async(self.radioRunQueue, ^(void) { \
        /* Send the command to the radio on our private queue */ \
        [safeSelf commandToRadio:(cmd)]; \
    });


- (void) cmdNewAudioStream:(int)daxChannel {
    NSString *cmd = [NSString stringWithFormat:@"stream create dax=%i", daxChannel];
    [self commandToRadio:cmd notifySel:@selector(audioStreamCreateCallback:)];
}


- (void) cmdRemoveAudioStreamHandler:(DAXAudio *)streamProcessor {
    // Workaround until FlexRadio bug fixes issue with remove status for the audio stream...
    // We handle the removal here and issue the notification
    
    @synchronized (self.daxAudioStreamToStreamHandler) {
        [self.daxAudioStreamToStreamHandler removeObjectForKey:streamProcessor.streamId];
    }
    
    // Having remove the streamHandler, it will get no further stream updates from the VitaManager
    // or parsed status updates...  Issue the deletion notification
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioStreamDeleted" object:streamProcessor];
    
    // Now tell the radio to remove this processor
    NSString *cmd = [NSString stringWithFormat:@"stream remove %@", streamProcessor.streamId];
    [self commandToRadio:cmd];
}


- (void) cmdDeleteGlobalProfile:(NSString *)profile {
  
  NSString *cmd = [NSString stringWithFormat:@"profile global delete \"%@\"", profile];
  [self commandToRadio: cmd];
  // notify listeners
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GlobalProfileDeleted" object:profile];
  });
}


- (void) cmdDeleteTxProfile:(NSString *)profile {
  
  NSString *cmd = [NSString stringWithFormat:@"profile transmit delete \"%@\"", [profile stringByReplacingOccurrencesOfString:@"*" withString:@""]];
  [self commandToRadio: cmd];
  // notify listeners
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TxProfileDeleted" object:profile];
  });
}


- (void) cmdSaveGlobalProfile:(NSString *)profile {
  NSString *notificationName;
  
  NSString *cmd = [NSString stringWithFormat:@"profile global save \"%@\"", profile];
  [self commandToRadio: cmd];
  // notify listeners
  // is this a new profile?
  if ([_globalProfiles indexOfObject: profile] == NSNotFound) {
    // YES, new profile
    notificationName = @"GlobalProfileCreated";
  } else {
    // NO, existing profile
    notificationName = @"GlobalProfileUpdated";
  }
  // notify listeners
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:profile];
  });
  
}


- (void) cmdSaveTxProfile:(NSString *)profile {
  NSString *notificationName;
  
    NSString *cmd = [NSString stringWithFormat:@"profile transmit save \"%@\"", [profile stringByReplacingOccurrencesOfString:@"*" withString:@""]];
  [self commandToRadio: cmd];
  // notify listeners
  // is this a new profile?
  if ([_txProfiles indexOfObject: profile] == NSNotFound) {
    // YES, new profile
    notificationName = @"TxProfileCreated";
  } else {
    // NO, existing profile
    notificationName = @"TxProfileUpdated";
  }
  // notify listeners
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:profile];
  });
  
}

- (BOOL) cmdNewPanafall:(CGSize) size {
    if (self.availablePanadapters && ![self.availablePanadapters integerValue])
        return NO;
    
    if (!subscribedToDisplays) {
        subscribedToDisplays = YES;
        [self commandToRadio:@"sub pan all"];
    }
    
    [self commandToRadio:[NSString stringWithFormat:@"display panafall create x=%i y=%i",
               (int)size.width, (int)size.height] notifySel:@selector(panafallCreateCallback:)];
    return YES;
}

- (void) cmdRemovePanafall:(Panafall *)pan {
    NSString *cmd = [NSString stringWithFormat:@"display pan remove %@", pan.streamId];
    
    // Fire off the commmand - we will get status messages that unwind the underlying
    // objects
    [self commandToRadio:cmd];
}


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

- (void) cmdNewSlice: (NSString *) frequency antenna: (NSString *) antennaPort mode: (NSString *) mode panafall: (NSString *) streamId {
    if ([self.availableSlices integerValue]) {
        NSString *cmd = [NSString stringWithFormat:@"slice c pan=%@ freq=%@ ant=%@ mode=%@",
                         streamId, frequency, antennaPort, mode];
        
        [self commandToRadio:cmd];
    }
}

- (void) cmdRemoveSlice:(NSNumber *)sliceNum {
    NSString *cmd = [NSString stringWithFormat:@"slice remove %i", [sliceNum intValue]];
    
    [self commandToRadio:cmd];
}

- (void) setCurrentGlobalProfile:(NSString *)currentGlobalProfile {
  NSString *cmd = [NSString stringWithFormat:@"profile global load \"%@\"", currentGlobalProfile];
  
  NSString *refCurrentGlobalProfile = currentGlobalProfile;
  
  commandUpdateNotify(cmd, @"currentGlobalProfile", _currentGlobalProfile, refCurrentGlobalProfile);
}

- (void) setCurrentTxProfile:(NSString *)currentTxProfile {
  NSString *cmd = [NSString stringWithFormat:@"profile transmit load \"%@\"", currentTxProfile];
  
  NSString *refCurrentTxProfile = currentTxProfile;
  
  commandUpdateNotify(cmd, @"currentTxProfile", _currentTxProfile, refCurrentTxProfile);
}

- (void) setTransmitFilterLo:(NSString *)transmitFilterLo  {
    NSString *cmd = [NSString stringWithFormat:@"transmit set filter_low=%i",
                     [transmitFilterLo intValue]];
    NSString *refTransmitFilterLo = transmitFilterLo;
    
    commandUpdateNotify(cmd, @"transmitFilterLo", _transmitFilterLo, refTransmitFilterLo);
}

- (void) setTransmitFilterHi:(NSString *)transmitFilterHi  {
    NSString *cmd = [NSString stringWithFormat:@"transmit set filter_high=%i",
                     [transmitFilterHi intValue]];
    NSString *refTransmitFilerHi = transmitFilterHi;
    
    commandUpdateNotify(cmd, @"transmitFilterHi", _transmitFilterHi, refTransmitFilerHi);
}

- (void) setRfPowerLevel:(NSNumber *)rfPowerLevel {
    NSString *cmd = [NSString stringWithFormat:@"transmit set rfpower=%i",
                     [rfPowerLevel intValue]];
    NSNumber *refRfPowerLevel = rfPowerLevel;
    
    commandUpdateNotify(cmd, @"rfPowerLevel", _rfPowerLevel, refRfPowerLevel);
}

- (void) setTunePowerLevel:(NSNumber *)tunePowerLevel {
    NSString *cmd = [NSString stringWithFormat:@"transmit set tunepower=%i",
                     [tunePowerLevel intValue]];
    NSNumber *refTunePowerLevel = tunePowerLevel;
    
    commandUpdateNotify(cmd, @"tunePowerLevel", _tunePowerLevel, refTunePowerLevel);
}

- (void) setAmCarrierLevel:(NSNumber *)amCarrierLevel {
    NSString *cmd = [NSString stringWithFormat:@"transmit set am_carrier=%i",
                     [amCarrierLevel intValue]];
    NSNumber *refAmCarrierLevel = amCarrierLevel;
    
    commandUpdateNotify(cmd, @"amCarrierLevel", _amCarrierLevel, refAmCarrierLevel);
}

- (void) setTxDaxEnabled:(NSNumber *)txDaxEnabled {
    NSString *cmd = [NSString stringWithFormat:@"transmit set dax=%i",
                     [txDaxEnabled intValue]];
    NSNumber *refTxDaxEnabled = txDaxEnabled;
    
    commandUpdateNotify(cmd, @"txDaxEnabled", _txDaxEnabled, refTxDaxEnabled);
}

- (void) setMicSelection:(NSString *)micSelection {
    NSString *cmd = [NSString stringWithFormat:@"mic input %@", micSelection];
    NSString *refMicSelection = micSelection;
    
    commandUpdateNotify(cmd, @"micSelection", _micSelection, refMicSelection);
}

- (void)setMicLevel:(NSNumber *)micLevel {
    NSString *cmd = [NSString stringWithFormat:@"transmit set miclevel=%i",
                     [micLevel intValue]];
    NSNumber *refMicLevel = micLevel;
    
    commandUpdateNotify(cmd, @"micLevel", _micLevel, refMicLevel);
}

- (void) setMicBias:(NSNumber *)micBias {
    NSString *cmd = [NSString stringWithFormat:@"mic bias %i",
                     [micBias boolValue]];
    NSNumber *refMicBias = micBias;
    
    commandUpdateNotify(cmd, @"micBias", _micBias, refMicBias);
}

- (void) setMicBoost:(NSNumber *)micBoost {
    NSString *cmd = [NSString stringWithFormat:@"mic boost %i",
                     [micBoost boolValue]];
    NSNumber *refMicBoost = micBoost;
    
    commandUpdateNotify(cmd, @"micBoost", _micBoost, refMicBoost);
}

- (void) setMicAccEnabled:(NSNumber *)micAccEnabled {
    NSString *cmd = [NSString stringWithFormat:@"mic acc %i",
                     [micAccEnabled boolValue]];
    NSNumber *refMicAccEnabled = micAccEnabled;
    
    commandUpdateNotify(cmd, @"micAccEnabled", _micAccEnabled, refMicAccEnabled);
}

- (void)setCompanderEnabled:(NSNumber *)companderEnabled {
    NSString *cmd = [NSString stringWithFormat:@"transmit set compander=%i",
                     [companderEnabled boolValue]];
    NSNumber *refCompanderEnabled = companderEnabled;
    
    commandUpdateNotify(cmd, @"companderEnabled", _companderEnabled, refCompanderEnabled);
}

- (void) setCompanderLevel:(NSNumber *)companderLevel {
    NSString *cmd = [NSString stringWithFormat:@"transmit set compander_level=%i",
                     [companderLevel intValue]];
    NSNumber *refCompanderLevel = companderLevel;
    
    commandUpdateNotify(cmd, @"companderLevel", _companderLevel, refCompanderLevel);
}

- (void) setSpeechProcEnabled:(NSNumber *)speechProcEnabled {
    NSString *cmd = [NSString stringWithFormat:@"transmit set speech_processor_enable=%i",
                     [speechProcEnabled boolValue]];
    NSNumber *refSpeechProcEnabled = speechProcEnabled;
    
    commandUpdateNotify(cmd, @"speechProcEnabled", _speechProcEnabled, refSpeechProcEnabled);
}

- (void) setSpeechProcLevel:(NSNumber *)speechProcLevel {
    NSString *cmd = [NSString stringWithFormat:@"transmit set speech_processor_level=%i",
                     [speechProcLevel intValue]];
    NSNumber *refSpeechProcLevel = speechProcLevel;
    
    commandUpdateNotify(cmd, @"speechProcLevel", _speechProcLevel, refSpeechProcLevel);
}

- (void) setVoxEnabled:(NSNumber *)voxEnabled {
    NSString *cmd = [NSString stringWithFormat:@"transmit set vox_enable=%i",
                     [voxEnabled boolValue]];
    NSNumber *refVoxEnabled = voxEnabled;
    
    commandUpdateNotify(cmd, @"voxEnabled", _voxEnabled, refVoxEnabled);
}

- (void) setVoxLevel:(NSNumber *)voxLevel {
    NSString *cmd = [NSString stringWithFormat:@"transmit set vox_level=%i",
                     [voxLevel intValue]];
    NSNumber *refVoxLevel = voxLevel;
    
    commandUpdateNotify(cmd, @"voxLevel", _voxLevel, refVoxLevel);
}

- (void) setVoxDelay:(NSNumber *)voxDelay {
    NSString *cmd = [NSString stringWithFormat:@"transmit set vox_delay=%i",
                     [voxDelay intValue]];
    NSNumber *refVoxDelay = voxDelay;
    
    commandUpdateNotify(cmd, @"voxDelay", _voxDelay, refVoxDelay);
}

- (void) setCwPitch:(NSNumber *)cwPitch {
    NSString *cmd = [NSString stringWithFormat:@"cw pitch %i",
                     [cwPitch intValue]];
    NSNumber *refCwPitch = cwPitch;
    
    commandUpdateNotify(cmd, @"cwPitch", _cwPitch, refCwPitch);
}

- (void) setCwSpeed:(NSNumber *)cwSpeed {
    NSInteger speed = [cwSpeed integerValue] < 5 ? 5 : [cwSpeed integerValue];
    NSString *cmd = [NSString stringWithFormat:@"cw wpm %i",
                     (int)speed];
    NSNumber *refCwSpeed = [NSNumber numberWithInteger:speed];
    
    commandUpdateNotify(cmd, @"cwSpeed", _cwSpeed, refCwSpeed);
}

- (void) setCwSwapPaddles:(NSNumber *)cwSwapPaddles {
    NSString *cmd = [NSString stringWithFormat:@"cw swap %i",
                     [cwSwapPaddles boolValue]];
    NSNumber *refCwSwapPaddles = cwSwapPaddles;
    
    commandUpdateNotify(cmd, @"cwSwapPaddles", _cwSwapPaddles, refCwSwapPaddles);
}

- (void) setCwIambicEnabled:(NSNumber *)cwIambicEnabled {
    NSString *cmd = [NSString stringWithFormat:@"cw iambic %i",
                     [cwIambicEnabled boolValue]];
    NSNumber *refCwIambicEnabled = cwIambicEnabled;
    
    commandUpdateNotify(cmd, @"cwIambicEnabled", _cwIambicEnabled, refCwIambicEnabled);
}

- (void) setCwIambicMode:(NSString *)cwIambicMode {
    NSString *cmd = [NSString stringWithFormat:@"cw mode %i",
                     [cwIambicMode isEqualToString:@"B"]];
    NSString *refCwIambicMode = cwIambicMode;
    
    commandUpdateNotify(cmd, @"cwIambicMode", _cwIambicMode, refCwIambicMode);
}

- (void) setCwBreakinEnabled:(NSNumber *)cwBreakinEnabled {
    NSString *cmd = [NSString stringWithFormat:@"cw break_in %i",
                     [cwBreakinEnabled boolValue]];
    NSNumber *refCwBreakinEnabled = cwBreakinEnabled;
    
    commandUpdateNotify(cmd, @"cwBreakinEnabled", _cwBreakinEnabled, refCwBreakinEnabled);
}

- (void) setCwBreakinDelay:(NSNumber *)cwBreakinDelay {
    NSString *cmd = [NSString stringWithFormat:@"cw break_in_delay %i",
                     [cwBreakinDelay intValue]];
    NSNumber *refCwBreakinDelay = cwBreakinDelay;
    
    commandUpdateNotify(cmd, @"cwBreakinDelay", _cwBreakinDelay, refCwBreakinDelay);
}

- (void) setSidetone:(NSNumber *)sidetone {
    NSString *cmd = [NSString stringWithFormat:@"cw sidetone %i",
                     [sidetone boolValue]];
    NSNumber *refSidetone = sidetone;
    
    commandUpdateNotify(cmd, @"sidetone", _sidetone, refSidetone);
}

- (void) setSidetoneGain:(NSNumber *)sidetoneGain {
    NSString *cmd = [NSString stringWithFormat:@"transmit set mon_gain_cw=%i",
                     [sidetoneGain intValue]];
    NSNumber *refSidetoneGain = sidetoneGain;
    
    commandUpdateNotify(cmd, @"sidetoneGain", _sidetoneGain, refSidetoneGain);
}

- (void) setSidetonePan:(NSNumber *)sidetonePan {
    NSString *cmd = [NSString stringWithFormat:@"transmit set mon_pan_cw=%i",
                     [sidetonePan intValue]];
    NSNumber *refSidetonePan = sidetonePan;
    
    commandUpdateNotify(cmd, @"setSidetonePan", _sidetonePan, refSidetonePan);
}

- (void) setPhMonitor:(NSNumber *)phMonitor {
    NSString *cmd = [NSString stringWithFormat:@"transmit set mon=%i",
                     [phMonitor boolValue]];
    NSNumber *refPhMonitor = phMonitor;
    
    commandUpdateNotify(cmd, @"phMonitor", _phMonitor, refPhMonitor);
}

- (void) setMonitorPHGain:(NSNumber *)monitorPHGain {
    NSString *cmd = [NSString stringWithFormat:@"transmit set mon_gain_sb=%i",
                     [monitorPHGain intValue]];
    NSNumber *refMonitorPHGain = monitorPHGain;
    
    commandUpdateNotify(cmd, @"monitorGain", _monitorPHGain, refMonitorPHGain);
}

- (void) setMonitorPHPan:(NSNumber *)monitorPHPan {
    NSString *cmd = [NSString stringWithFormat:@"transmit set mon_pan_sb=%i",
                     [monitorPHPan intValue]];
    NSNumber *refMonitorPHPan = monitorPHPan;
    
    commandUpdateNotify(cmd, @"monitorPHPan", _monitorPHPan, refMonitorPHPan);
}

- (void) setCwlEnabled:(NSNumber *)cwlEnabled {
    NSString *cmd = [NSString stringWithFormat:@"cw cwl_enabled %i",
                     [cwlEnabled boolValue]];
    NSNumber *refCwlEnabled = cwlEnabled;
    
    commandUpdateNotify(cmd, @"cwlEnabled", _cwlEnabled, refCwlEnabled);
}

- (void) setTxState:(NSNumber *)txState {
    NSString *cmd = [NSString stringWithFormat:@"xmit %i",
                     [txState boolValue]];
    NSNumber *refTxState = txState;
    
    commandUpdateNotify(cmd, @"txState", _txState, refTxState);
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

- (void) setAtuMemoriesEnabled:(NSNumber *)atuMemoriesEnabled {
    NSString *cmd = [NSString stringWithFormat:@"atu set memories_enabled=%i",
                     [atuMemoriesEnabled boolValue]];
    NSNumber *refAtuMemoriesEnabled = atuMemoriesEnabled;
    
    commandUpdateNotify(cmd, @"atuMemoriesEnabled", _atuMemoriesEnabled, refAtuMemoriesEnabled);
}

- (void) setTuneEnabled:(NSNumber *)tuneEnabled {
    NSString *cmd = [NSString stringWithFormat:@"transmit tune %i",
                     [tuneEnabled boolValue]];
    NSNumber *refTuneEnabled = tuneEnabled;
    
    commandUpdateNotify(cmd, @"tuneEnabled", _tuneEnabled, refTuneEnabled);
}

- (void) setMasterSpeakerAfGain:(NSNumber *)masterSpeakerAfGain {
    NSString *cmd = [NSString stringWithFormat:@"mixer lineout gain %i",
                     [masterSpeakerAfGain intValue]];
    NSNumber *refMasterSpeakerGain = masterSpeakerAfGain;
    
    commandUpdateNotify(cmd, @"masterSpeakerAfGain", _masterSpeakerAfGain, refMasterSpeakerGain);
}

- (void) setMasterHeadsetAfGain:(NSNumber *)masterHeadsetAfGain {
    NSString *cmd = [NSString stringWithFormat:@"mixer headphone gain %i",
                     [masterHeadsetAfGain intValue]];
    NSNumber *refMasterHeadsetAfGain = masterHeadsetAfGain;
    
    commandUpdateNotify(cmd, @"masterHeadsetAfGain", _masterHeadsetAfGain, refMasterHeadsetAfGain);
}

- (void) setMasterSpeakerMute:(NSNumber *)masterSpeakerMute {
    NSString *cmd = [NSString stringWithFormat:@"mixer lineout mute %i",
                     [masterSpeakerMute boolValue]];
    NSNumber *refMasterSpeakerMute = masterSpeakerMute;
    
    commandUpdateNotify(cmd, @"masterSpeakerMute", _masterSpeakerMute, refMasterSpeakerMute);
}

- (void) setMasterHeadsetMute:(NSNumber *)masterHeadsetMute {
    NSString *cmd = [NSString stringWithFormat:@"mixer headphone mute %i",
                     [masterHeadsetMute boolValue]];
    NSNumber *refMasterHeadsetMute = masterHeadsetMute;
    
    commandUpdateNotify(cmd, @"masterHeadsetMute", _masterHeadsetMute, refMasterHeadsetMute);
}

- (void) setRemoteOnEnabled:(NSNumber *)remoteOnEnabled {
    NSString *cmd = [NSString stringWithFormat:@"radio set remote_on_enabled=%i",
                     [remoteOnEnabled boolValue]];
    NSNumber *refRemoteOnEnabled = remoteOnEnabled;
    
    commandUpdateNotify(cmd, @"remoteOnEnabled", _remoteOnEnabled, refRemoteOnEnabled);
}

- (void) setTxInhibit:(NSNumber *)txInhibit {
    NSString *cmd = [NSString stringWithFormat:@"transmit set inhibit=%i",
                     [txInhibit boolValue]];
    NSNumber *refTxInhibit = txInhibit;
    
    commandUpdateNotify(cmd, @"txInhibit", _txInhibit, refTxInhibit);
}

- (void) setTxDelay:(NSNumber *)txDelay {
    NSString *cmd = [NSString stringWithFormat:@"interlock tx_delay=%i",
                     [txDelay intValue]];
    NSNumber *refTxDelay = txDelay;
    
    commandUpdateNotify(cmd, @"txDelay", _txDelay, refTxDelay);
}

- (void) setTx1Delay:(NSNumber *)tx1Delay {
    NSString *cmd = [NSString stringWithFormat:@"interlock tx1_delay=%i",
                     [tx1Delay intValue]];
    NSNumber *refTx1Delay = tx1Delay;
    
    commandUpdateNotify(cmd, @"tx1Delay", _tx1Delay, refTx1Delay);
}

- (void) setTx2Delay:(NSNumber *)tx2Delay {
    NSString *cmd = [NSString stringWithFormat:@"interlock tx2_delay=%i",
                     [tx2Delay intValue]];
    NSNumber *refTx2Delay = tx2Delay;
    
    commandUpdateNotify(cmd, @"tx2Delay", _tx2Delay, refTx2Delay);
}

- (void) setTx3Delay:(NSNumber *)tx3Delay {
    NSString *cmd = [NSString stringWithFormat:@"interlock tx3_delay=%i",
                     [tx3Delay intValue]];
    NSNumber *refTx3Delay = tx3Delay;
    
    commandUpdateNotify(cmd, @"tx3Delay", _tx3Delay, refTx3Delay);
}

- (void) setAccTxDelay:(NSNumber *)accTxDelay {
    NSString *cmd = [NSString stringWithFormat:@"interlock acc_tx_delay=%i",
                     [accTxDelay intValue]];
    NSNumber *refAccTxDelay = accTxDelay;
    
    commandUpdateNotify(cmd, @"accTxDelay", _accTxDelay, refAccTxDelay);
}

- (void)setTx1Enabled:(NSNumber *)tx1Enabled {
    NSString *cmd = [NSString stringWithFormat:@"interlock tx1_enabled=%i",
                     [tx1Enabled boolValue]];
    NSNumber *refTx1Enabled = tx1Enabled;
    
    commandUpdateNotify(cmd, @"tx1Enabled", _tx1Enabled, refTx1Enabled);
}

- (void) setTx2Enabled:(NSNumber *)tx2Enabled {
    NSString *cmd = [NSString stringWithFormat:@"interlock tx2_enabled=%i",
                     [tx2Enabled boolValue]];
    NSNumber *refTx2Enabled = tx2Enabled;
    
    commandUpdateNotify(cmd, @"tx2Enabled", _tx2Enabled, refTx2Enabled);
}

- (void) setTx3Enabled:(NSNumber *)tx3Enabled {
    NSString *cmd = [NSString stringWithFormat:@"interlock tx3_enabled=%i",
                     [tx3Enabled boolValue]];
    NSNumber *refTx3Enabled = tx3Enabled;
    
    commandUpdateNotify(cmd, @"tx3Enabled", _tx3Enabled, refTx3Enabled);
}

- (void) setAccTxEnabled:(NSNumber *)accTxEnabled {
    NSString *cmd = [NSString stringWithFormat:@"interlock acc_tx_enabled=%i",
                     [accTxEnabled boolValue]];
    NSNumber *refAccTxEnabled = accTxEnabled;
    
    commandUpdateNotify(cmd, @"accTxEnabled", _accTxEnabled, refAccTxEnabled);
}

- (void) setHwAlcEnabled:(NSNumber *)hwAlcEnabled {
    NSString *cmd = [NSString stringWithFormat:@"transmit set hw_alc_enabled=%i",
                     [hwAlcEnabled boolValue]];
    NSNumber *refHwAlcEnabled = hwAlcEnabled;
    
    commandUpdateNotify(cmd, @"hwAlcEnabled", _hwAlcEnabled, refHwAlcEnabled);
}

- (void) setRcaTxReqEnable:(NSNumber *)rcaTxReqEnable {
    NSString *cmd = [NSString stringWithFormat:@"interlock rca_txreq_enable=%i",
                     [rcaTxReqEnable boolValue]];
    NSNumber *refRcaTxReqEnable = rcaTxReqEnable;
    
    commandUpdateNotify(cmd, @"rcaTxReqEnable", _rcaTxReqEnable, refRcaTxReqEnable);
}

- (void) setRcaTxReqPolarity:(NSNumber *)rcaTxReqPolarity {
    NSString *cmd = [NSString stringWithFormat:@"interlock rca_txreq_polarity=%i",
                     [rcaTxReqPolarity boolValue]];
    NSNumber *refRcaTxReqPolarity = rcaTxReqPolarity;
    
    commandUpdateNotify(cmd, @"rcaTxReqPolarity", _rcaTxReqPolarity, refRcaTxReqPolarity);
}

- (void) setAccTxReqEnable:(NSNumber *)accTxReqEnable {
    NSString *cmd = [NSString stringWithFormat:@"interlock acc_txreq_enable=%i",
                     [accTxReqEnable boolValue]];
    NSNumber *refAccTxReqEnable = accTxReqEnable;
    
    commandUpdateNotify(cmd, @"accTxReqEnable", _accTxReqEnable, refAccTxReqEnable);
}

- (void) setAccTxReqPolarity:(NSNumber *)accTxReqPolarity {
    NSString *cmd = [NSString stringWithFormat:@"interlock acc_txreq_polarity=%i",
                     [accTxReqPolarity boolValue]];
    NSNumber *refAccTxReqPolarity = accTxReqPolarity;
    
    commandUpdateNotify(cmd, @"accTxReqPolarity", _accTxReqPolarity, refAccTxReqPolarity);
}

- (void) setInterlockTimeoutValue:(NSNumber *)interlockTimeoutValue {
    NSString *cmd = [NSString stringWithFormat:@"interlock timeout=%i",
                     [interlockTimeoutValue intValue]];
    NSNumber *refInterlockTimeoutValue = interlockTimeoutValue;
    
    commandUpdateNotify(cmd, @"interlockTimeoutValue", _interlockTimeoutValue, refInterlockTimeoutValue);
}

- (void) setRadioScreenSaver:(NSString *)radioScreenSaver {
    NSString *cmd = [NSString stringWithFormat:@"radio screensaver %@",
                     radioScreenSaver];
    NSString *refRadioScreenSaver = radioScreenSaver;
    
    commandUpdateNotify(cmd, @"radioScreenSaver", _radioScreenSaver, refRadioScreenSaver);
}

- (void) setRadioCallsign:(NSString *)radioCallsign {
    NSString *cmd = [NSString stringWithFormat:@"radio callsign %@",
                     radioCallsign];
    NSString *refRadioCallsign = radioCallsign;
    
    commandUpdateNotify(cmd, @"radioCallsign", _radioCallsign, refRadioCallsign);
}

- (void) setRadioName:(NSString *)radioName {
    NSString *cmd = [NSString stringWithFormat:@"radio name %@",
                     radioName];
    NSString *refRadioName = radioName;
    
    commandUpdateNotify(cmd, @"radioName", _radioName, refRadioName);
}

- (void) setBinauralRx:(NSNumber *)binauralRx {
    NSString *cmd = [NSString stringWithFormat:@"radio set binaural_rx=%i",
                     [binauralRx boolValue]];
    NSNumber *refBinauralRx = binauralRx;
    
    commandUpdateNotify(cmd, @"binarualRx", _binauralRx, refBinauralRx);
}

- (void) setSyncActiveSlice:(NSNumber *)syncActiveSlice {
    NSNumber *refSyncActiveSlice = syncActiveSlice;
    
    updateWithNotify(@"syncActiveSlice", _syncActiveSlice, refSyncActiveSlice);
}

- (void) setRemoteAudio:(NSNumber *)remoteAudio {
    NSString *cmd = [NSString stringWithFormat:@"remote_audio rx_on %i",
                     [remoteAudio boolValue]];
    NSNumber *refRemoteAudio = remoteAudio;
    
    commandUpdateNotify(cmd, @"remoteAudio", _remoteAudio, refRemoteAudio);
}

- (void) setIsGui:(NSNumber *)isGui {
    if (![isGui boolValue])
        return;
    
    NSString *cmd = [NSString stringWithFormat:@"client gui"];
    NSNumber *refIsGui = isGui;
    
    commandUpdateNotify(cmd, @"isGui", _isGui, refIsGui);
    
    if (self.vitaManager) {
        NSString *cmd2 = [NSString stringWithFormat:@"client udpport %i", (int)self.vitaManager.vitaPort];
        commandUpdateNotify(cmd2, @"isGui", _isGui, refIsGui);
    }
}

#pragma mark
#pragma mark Socket Delegates


- (void) socket:(GCDAsyncSocket *)sock socketDidDisconnect:(NSError *)err  {
    if (err.code == GCDAsyncSocketConnectTimeoutError)
        connectionState = connectFailed;
    else
        connectionState = disConnected;
    
    if ([self.delegate respondsToSelector:@selector(radioConnectionStateChange:state:)]) {
        __weak Radio *safeSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [safeSelf.delegate radioConnectionStateChange:self state:connectionState];
        });
    }
}


// Called after connected - use this to initialize the connection to the radio and
// prime the initial read

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    // Connected to the radio
    connectionState = connected;
    [self initializeRadio];
    
    // Advise any delegate
    if ([self.delegate respondsToSelector:@selector(radioConnectionStateChange:state:)]) {
        __weak Radio *safeSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [safeSelf.delegate radioConnectionStateChange:self state:connectionState];
        });
    }
}



- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if ([data bytes]) {
        NSScanner *scan = [[NSScanner alloc] initWithString:[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding]];
        NSString *payload;
        
        [scan setCharactersToBeSkipped:nil];
        [scan scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\000"] intoString:nil];
        [scan scanUpToString:@"\n" intoString:&payload];

        if (self.logRadioMessages)
            NSLog(@"Data received - %@\n", payload);

        [self parseRadioStream: payload];
    }
    
    [radioSocket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:0];
}



@end
