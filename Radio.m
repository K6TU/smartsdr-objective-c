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



@interface Radio () {
    AsyncSocket *socket;
    UInt16 seqNum;
    BOOL verbose;
    enum radioConnectionState connectionState;
}

@property (weak, nonatomic) NSObject<RadioDelegate> *delegate;
@property (strong, nonatomic) NSString *apiVersion;
@property (strong, nonatomic) NSString *apiHandle;
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
- (void) parseEqToken: (NSScanner *) scan;

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
};

enum enumStatusRadioTokens {
    enumStatusRadioTokensNone = 0,
    slicesToken,
    panadaptersToken,
    lineoutGainToken,
    lineoutMuteToken,
    headphoneGainToken,
    headphoneMuteToken,
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
                              nil];
}


- (void) initStatusAtuTokens {
    self.statusAtuTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [NSNumber numberWithInt:atuStatusToken],  @"status",
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


- (id) initWithRadioInstanceAndDelegate:(RadioInstance *)thisRadio delegate: (NSObject<RadioDelegate> *) theDelegate {
    self = [super init];
    
    if (self) {
        self.radioInstance = thisRadio;
        socket = [[AsyncSocket alloc] initWithDelegate:self];
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
        
        self.slices = [[NSMutableArray alloc] init];
        for (int i=0; i < MAX_SLICES_PER_RADIO; i++) {
            [self.slices insertObject:[NSNull null] atIndex:i];
        }
        
        self.equalizers = [[NSMutableArray alloc] initWithCapacity:2];
        self.equalizers[0] = [[NSNull alloc] init];
        self.equalizers[1] = [[NSNull alloc] init];
        
        connectionState = connecting;
        self.delegate = theDelegate;
        
        // Set any initial non zero state requirements
        self.tunePowerLevel = [NSNumber numberWithInt:10];
        
        // Currently no way to retrieve the mixer settings - plug values for
        // the speaker and headset gains
        self.masterSpeakerAfGain = [NSNumber numberWithInt:50];
        self.masterHeadsetAfGain = [NSNumber numberWithInt:50];
        self.masterSpeakerMute = [NSNumber numberWithBool:NO];
        self.masterHeadsetMute = [NSNumber numberWithBool:NO];
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
    [self commandToRadio:@"sub slice all"];
    [self commandToRadio:@"eq rx info"];
    [self commandToRadio:@"eq tx info"];
    
    [socket readDataToData:[AsyncSocket LFData] withTimeout:-1 tag:0];
}



- (void) commandToRadio: (NSString *) cmd {
    seqNum++;
    NSString *cmdline = [[NSString alloc] initWithFormat:@"c%@%u|%@\n", verbose ? @"d" : @"", (unsigned int)seqNum, cmd ];
    
#ifdef DEBUG
    NSLog(@"Data sent - %@", cmdline);
#endif
    [socket writeData: [cmdline dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:(long)seqNum];
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
    
    int thisToken = [self.statusTokens[sourceToken] integerValue];
    
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
            [self parseEqToken: scan];
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
    // Should check to see whether the radio understand our versio of
    // the api commands...  leave this for later.
    // For now, save the version string
    self.apiVersion = payload;
}



- (void) parseResponseType:(NSString *)payload {
    // For now, this does nothing
    // It likely should examine the response number and then post
    // a notification or call a delegate function in case something
    // needs or is waiting on the result of a command
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
        int thisToken = [self.statusInterlockTokens[token] integerValue];
        
        
        switch (thisToken) {
            case timeoutToken:
                [scan scanInteger:&intVal];
                self.interlockTimeoutValue = [NSNumber numberWithInt:intVal];
                break;
                
            case acc_txreq_enableToken:
                [scan scanInteger:&intVal];
                self.accTxReqEnable = [NSNumber numberWithInt:intVal];
                break;
                
            case rca_txreq_enableToken:
                [scan scanInteger:&intVal];
                self.rcaTxReqEnable = [NSNumber numberWithInt:intVal];
                break;
                
            case acc_txreq_polarityToken:
                [scan scanInteger:&intVal];
                self.accTxReqPolarity = [NSNumber numberWithInt:intVal];
                break;
                
            case rca_txreq_polarityToken:
                [scan scanInteger:&intVal];
                self.rcaTxReqPolarity = [NSNumber numberWithInt:intVal];
                break;
                
            case ptt_delayToken:
                [scan scanInteger:&intVal];
                self.pttDelay = [NSNumber numberWithInt:intVal];
                break;
                
            case tx1_delayToken:
                [scan scanInteger:&intVal];
                self.tx1Delay = [NSNumber numberWithInt:intVal];
                break;
                
            case tx2_delayToken:
                [scan scanInteger:&intVal];
                self.tx2Delay = [NSNumber numberWithInt:intVal];
                break;
                
            case tx3_delayToken:
                [scan scanInteger:&intVal];
                self.tx3Delay = [NSNumber numberWithInt:intVal];
                break;
                
            case acc_tx_delayToken:
                [scan scanInteger:&intVal];
                self.accTxDelay = [NSNumber numberWithInt:intVal];
                break;
                
            case tx_delayToken:
                [scan scanInteger:&intVal];
                self.txDelay = [NSNumber numberWithInt:intVal];
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
                
            default:
                NSLog(@"Unexpected token in parseInterlockToken - %@", token);
                break;
        }
    
        // Scanner is either at a space or at the end - eat either
        [scan scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"] intoString:nil];    }
}



- (void) parseRadioToken: (NSScanner *) scan {
    NSString *token;
    NSInteger intVal;
    
    while (![scan isAtEnd]) {
        // Grab the token between current scanner position and the '=' separator
        // and then eat the '='
        [scan scanUpToString:@"=" intoString:&token];
        [scan scanString:@"=" intoString:nil];
        
        // Look up in our dictionary
        int thisToken = [self.statusRadioTokens[token] integerValue];
        
        switch (thisToken) {
            case slicesToken:
                [scan scanInteger:&intVal];
                self.availableSlices = [NSNumber numberWithInt:intVal];
                break;
                
            case panadaptersToken:
                [scan scanInteger:&intVal];
                self.availablePanadapters = [NSNumber numberWithInt:intVal];
                break;
                
            case lineoutGainToken:
                [scan scanInteger:&intVal];
                self.masterSpeakerAfGain = [NSNumber numberWithInt:intVal];
                break;
                
            case lineoutMuteToken:
                [scan scanInteger:&intVal];
                self.masterSpeakerMute = [NSNumber numberWithBool:intVal];
                break;
                
            case headphoneGainToken:
                [scan scanInteger:&intVal];
                self.masterHeadsetAfGain = [NSNumber numberWithInt:intVal];
                break;
                
            case headphoneMuteToken:
                [scan scanInteger:&intVal];
                self.masterHeadsetMute = [NSNumber numberWithBool:intVal];
                break;

            default:
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
    
    
    while (![scan isAtEnd]) {
        // Grab the token between current scanner position and the '=' separator
        // and then eat the '='
        [scan scanUpToString:@"=" intoString:&token];
        [scan scanString:@"=" intoString:nil];
        
        // Look up in our dictionary
        int thisToken = [self.statusAtuTokens[token] integerValue];
        
        switch (thisToken) {
            case atuStatusToken:
                [scan scanUpToString:@"\n" intoString:&stringVal];
                self.atuStatus = [self.statusAtuStatusTokens objectForKey: stringVal];
                break;
                
            default:
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
        int thisToken = [self.statusTransmitTokens[token] integerValue];
        
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
                if ([self.tuneEnabled boolValue] || selfStatus) {
                    // pitch the value
                    
                    [scan scanInteger:&intVal];
                    break;
                }
                                
                [scan scanInteger:&intVal];
                self.rfPowerLevel = [NSNumber numberWithInt:intVal];
                break;

            case amCarrierLevelToken:
                [scan scanInteger:&intVal];
                self.amCarrierLevel = [NSNumber numberWithInt:intVal];
                break;

            case micSelectionToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                self.micSelection = stringVal;
                break;
                
             case micLevelToken:
                [scan scanInteger:&intVal];
                self.micLevel = [NSNumber numberWithInt:intVal];
                break;
                
            case micAccToken:
                [scan scanInteger:&intVal];
                self.micAccEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case micBoostToken:
                [scan scanInteger:&intVal];
                self.micBoost = [NSNumber numberWithInt:intVal];
                break;

            case micBiasToken:
                [scan scanInteger:&intVal];
                self.micBias = [NSNumber numberWithInt:intVal];
                break;
                
             case companderToken:
                [scan scanInteger:&intVal];
                self.companderEnabled = [NSNumber numberWithInt:intVal];
                break;

            case companderLevelToken:
                [scan scanInteger:&intVal];
                self.companderLevel = [NSNumber numberWithInt:intVal];
                break;

            case noiseGateLevelToken:
                [scan scanInteger:&intVal];
                self.noiseGateLevel = [NSNumber numberWithInt:intVal];
                break;
                
            case pitchToken:
                [scan scanInteger:&intVal];
                self.cwPitch = [NSNumber numberWithInt:intVal];
                break;

            case speedToken:
                [scan scanInteger:&intVal];
                self.cwSpeed = [NSNumber numberWithInt:intVal];
                break;

            case iambicToken:
                [scan scanInteger:&intVal];
                self.cwIambicEnabled = [NSNumber numberWithInt:intVal];
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
                self.cwBreakinEnabled = [NSNumber numberWithInt:intVal];
                break;

            case breakInDelayToken:
                [scan scanInteger:&intVal];
                self.cwBreakinDelay = [NSNumber numberWithInt:intVal];
                break;

            case monitorToken:
                [scan scanInteger:&intVal];
                self.monitorEnabled = [NSNumber numberWithInt:intVal];
                break;

            case monitorGainToken:
                [scan scanInteger:&intVal];
                self.monitorLevel = [NSNumber numberWithInt:intVal];
                break;
                
            case voxToken:
            case voxEnableToken:
                [scan scanInteger:&intVal];
                self.voxEnabled = [NSNumber numberWithInt:intVal];
                break;

            case voxLevelToken:
                [scan scanInteger:&intVal];
                self.voxLevel = [NSNumber numberWithInt:intVal];
                break;

            case voxDelayToken:
                [scan scanInteger:&intVal];
                self.voxDelay = [NSNumber numberWithInt:intVal / 20];
                break;

            case voxVisibleToken:
                [scan scanInteger:&intVal];
                self.voxVisible = [NSNumber numberWithInt:intVal];
                break;
                
            case monGainToken:
                [scan scanInteger:&intVal];
                self.monitorLevel = [NSNumber numberWithInt:intVal];
                break;
                
            case tuneToken:
                [scan scanInteger:&intVal];
                self.tuneEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case metInRxToken:
                [scan scanInteger:&intVal];
                self.metInRxEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            default:
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
        thisSlice.sliceAudioLevel = [NSNumber numberWithInt:50];
        thisSlice.slicePanControl = [NSNumber numberWithInt:50];
    }
    
    while (![scan isAtEnd]) {
        // Grab the token between current scanner position and the '=' separator
        // and then eat the '='
        [scan scanUpToString:@"=" intoString:&token];
        [scan scanString:@"=" intoString:nil];
        
        // Look up in our dictionary
        int thisToken = [self.statusSliceTokens[token] integerValue];
        
        switch (thisToken) {
            case rfFrequencyToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                thisSlice.sliceFrequency = stringVal;
                break;
            
            case modeToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                thisSlice.sliceMode = stringVal;
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
                thisSlice.sliceNrEnabled = [NSNumber numberWithInt:intVal];
                break;

             case nrLevelToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceNrLevel = [NSNumber numberWithInt:intVal];
                break;

             case nbToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceNbEnabled = [NSNumber numberWithInt:intVal];
                break;
                
            case nbLevelToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceNbLevel = [NSNumber numberWithInt:intVal];
                break;

            case anfToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceAnfEnabled = [NSNumber numberWithInt:intVal];
                break;

            case anfLevelToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceAnfLevel = [NSNumber numberWithInt:intVal];
                break;

            case agcModeToken:
                [scan scanUpToString:@" " intoString:&stringVal];
                thisSlice.sliceAgcMode = stringVal;
                break;
                                
            case agcThresholdToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceAgcThreshold = [NSNumber numberWithInt:intVal];
                break;

            case agcOffLevelToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceAgcOffLevel = [NSNumber numberWithInt:intVal];
                break;

            case txToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceTxEnabled = [NSNumber numberWithInt:intVal];
                break;

            case activeToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceActive = [NSNumber numberWithInt:intVal];
                break;
                
                
            case ghostToken:
                [scan scanInteger:&intVal];
                // thisSlice.sliceGhost = [NSNumber numberWithInt:intVal];
                break;

            case ownerToken:
                // [scan scanInteger:&intVal];
                // thisSlice.sliceOwner = [NSNumber numberWithInt:intVal];
                break;

            case wideToken:
                [scan scanInteger:&intVal];
                thisSlice.sliceWide = [NSNumber numberWithInt:intVal];
                break;

            case inUseToken:
                [scan scanInteger:&intVal];
                
                if (!intVal) {
                    // If in_use=0, this slice has been deleted and we need to make it go away
                    // in an orderly fashion - BEFORE we update the property OR make it go away!
                    [thisSlice youAreBeingDeleted];
                    
                    // By the time this returns, the slice be deletable - post the transition to
                    // not in use and then delete from the slices array
                    thisSlice.sliceInUse = [NSNumber numberWithInt:intVal];
                    self.slices[thisSliceNum] = [NSNull null];
                } else {
                    thisSlice.sliceInUse = [NSNumber numberWithInt:intVal];
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
                
            default:
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


- (void) parseEqToken: (NSScanner *) scan {
    NSString *token;
    NSInteger intVal, eqNum;
    NSString *stringVal;
    Equalizer *eq;
    
    // First parameter after eq is rx|tx
    [scan scanUpToString:@" " intoString:&stringVal];
    [scan scanString:@" " intoString:nil];
    
    if ([stringVal isEqualToString:@"rx"])
        eqNum = 0;
    else
        eqNum = 1;
    
    if ([self.equalizers[eqNum] isKindOfClass:[NSNull class]]) {
        // Allocate an equalizer
        self.equalizers[eqNum] = [[Equalizer alloc] init];
    }
    
    eq = self.equalizers[eqNum];
    
    while (![scan isAtEnd]) {
        // Grab the token between current scanner position and the '=' separator
        // and then eat the '='
        [scan scanUpToString:@"=" intoString:&token];
        [scan scanString:@"=" intoString:nil];
        
        // Look up in our dictionary
        int thisToken = [self.statusEqTokens[token] integerValue];
        
        switch (thisToken) {
            case eqModeToken:
                [scan scanInt:&intVal];
                eq.eqEnabled = [NSNumber numberWithBool:intVal];
                break;
                
            case eqBand0Token:
                [scan scanInt:&intVal];
                eq.eqBand0Value = [NSNumber numberWithInt:intVal];
                break;
                
            case eqBand1Token:
                [scan scanInt:&intVal];
                eq.eqBand1Value = [NSNumber numberWithInt:intVal];
                break;
                
            case eqBand2Token:
                [scan scanInt:&intVal];
                eq.eqBand2Value = [NSNumber numberWithInt:intVal];
                break;
                
            case eqBand3Token:
                [scan scanInt:&intVal];
                eq.eqBand3Value = [NSNumber numberWithInt:intVal];
                break;
                
            case eqBand4Token:
                [scan scanInt:&intVal];
                eq.eqBand4Value = [NSNumber numberWithInt:intVal];
                break;
                
            case eqBand5Token:
                [scan scanInt:&intVal];
                eq.eqBand5Value = [NSNumber numberWithInt:intVal];
                break;
                
            case eqBand6Token:
                [scan scanInt:&intVal];
                eq.eqBand6Value = [NSNumber numberWithInt:intVal];
                break;
                
            case eqBand7Token:
                [scan scanInt:&intVal];
                eq.eqBand7Value = [NSNumber numberWithInt:intVal];
                break;
        }
        // Scanner is either at a space or at the end - eat either
        [scan scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"] intoString:nil];

    }
}


- (void) parseGpsToken: (NSScanner *) scan {
    
}


#pragma mark
#pragma mark Radio Commands

- (void) cmdNewSlice {
    if ([self.availableSlices integerValue]) {
        NSString *cmd = [NSString stringWithFormat:@"slice c 14.15 ANT1 USB"];
        
        [self commandToRadio:cmd];
    }
}

- (void) cmdRemoveSlice:(NSNumber *)sliceNum {
    NSString *cmd = [NSString stringWithFormat:@"slice remove %i", [sliceNum integerValue]];
    
    [self commandToRadio:cmd];
}

- (void) cmdSetRfPowerLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"transmit set rfpower=%i",
                     [level integerValue]];

    [self commandToRadio:cmd];
    self.rfPowerLevel = level;
}

- (void) cmdSetAmCarrierLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"transmit set am_carrier=%i",
                     [level integerValue]];
    
    [self commandToRadio:cmd];
    self.amCarrierLevel = level;
}

- (void) cmdSetMicSelection:(NSString *)source {
    NSString *cmd = [NSString stringWithFormat:@"mic input %@", source];
    
    [self commandToRadio:cmd];
    self.micSelection = source;
}

- (void) cmdSetMicLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"transmit set miclevel=%i",
                     [level integerValue]];
    
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
                     [level integerValue]];
    
    [self commandToRadio:cmd];
    self.companderLevel = level;
}

- (void) cmdSetVoxEnabled:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"transmit set vox_enable=%i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.voxEnabled = state;
}

- (void) cmdSetVoxLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"transmit set vox_level=%i",
                     [level integerValue]];
    
    [self commandToRadio:cmd];
    self.voxLevel = level;
}

- (void) cmdSetVoxDelay:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"transmit set vox_delay=%i",
                     [level integerValue] * 20];
    
    [self commandToRadio:cmd];
    self.voxDelay = level;
}

- (void) cmdSetCwPitch:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"cw pitch %i",
                     [level integerValue]];
    
    [self commandToRadio:cmd];
    self.cwPitch = level;
}

- (void) cmdSetCwSpeed:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"cw wpm %i",
                     [level integerValue]];
    
    [self commandToRadio:cmd];
    self.cwSpeed = level;
}

- (void) cmdSetIambicEnabled:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"cw iambic %i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.cwIambicEnabled = state;
}

- (void) cmdSetBreakinEnabled:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"cw break_in %i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.cwBreakinEnabled = state;
}

- (void) cmdSetQskDelay:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"cw break_in_delay %i",
                     [level integerValue]];
    
    [self commandToRadio:cmd];
    self.cwBreakinDelay = level;
}

- (void) cmdSetMonitorEnabled:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"transmit set mon=%i",
                     [state boolValue]];
    
    [self commandToRadio:cmd];
    self.monitorEnabled = state;
}

- (void) cmdSetMonitorLevel:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"transmit set monitor_gain=%i",
                     [level integerValue]];
    
    [self commandToRadio:cmd];
    self.monitorLevel = level;
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
        txPowerLevel = [NSNumber numberWithInt:[self.rfPowerLevel integerValue]];
    
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
                     [level integerValue]];
    
    [self commandToRadio:cmd];
    self.masterSpeakerAfGain = level;
}

- (void) cmdSetMasterHeadsetGain:(NSNumber *)level {
    NSString *cmd = [NSString stringWithFormat:@"mixer headphone gain %i",
                     [level integerValue]];
    
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


#pragma mark
#pragma mark Socket Delegates


- (void) onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err  {
    if (err.code == AsyncSocketConnectTimeoutError)
        connectionState = connectFailed;
    else
        connectionState = disConnected;
    
    if ([self.delegate respondsToSelector:@selector(radioConnectionStateChange:state:)]) {
        [self.delegate radioConnectionStateChange:self state:connectionState];
    }
}


// Called after connected - use this to initialize the connection to the radio and
// prime the initial read

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    // Connected to the radio
    connectionState = connected;
    
    // Advise any delegate
    if ([self.delegate respondsToSelector:@selector(radioConnectionStateChange:state:)]) {
        [self.delegate radioConnectionStateChange:self state:connectionState];
    }

    [self initializeRadio];
}



- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
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
    
    [socket readDataToData:[AsyncSocket LFData] withTimeout:-1 tag:0];
}



@end
