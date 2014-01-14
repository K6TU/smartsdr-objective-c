//
//  Radio.h
//  
//  Created by STU PHILLIPS, K6TU on 8/3/13.
//  Copyright (c) 2013 STU PHILLIPS. All rights reserved.
//
// NOTE: THe license under which this software will be generally released
// is still under consideration.  For now, use of this software requires
// the specific approval of Stu Phillips, K6TU.

#import <Foundation/Foundation.h>
#import "RadioFactory.h"


// This model class is depedent on the AysncTCPSocket class developed by
// Robbie Hansen.  It is part of the CocoaAsyncSocket project which can
// be found on github at:
//
//  https://github.com/robbiehanson/CocoaAsyncSocket
//

#import "AsyncSocket.h"


// The primary interface object for a Flex 6000 series radio
// Must be instantiated from a RadioInstance provided from the RadioFactory

// The following enumerations provide state information for different aspects
// of the radio.

enum radioConnectionState {
    disConnected = 0,
    connecting,
    connected,
    disconnecting,
    connectFailed
};

enum radioInterlockState {
    enumStatusInterlockStatesNone = 0,
    receiveState,
    readyState,
    notReadyState,
    pttRequestedState,
    transmittingState,
    txFaultState,
    interlockTimeoutState,
    stuckInputState,
};



enum radioAtuState {
    enumStatusAtuStatesNone = 0,
    tuneNotStartedState,
    tuneInProgressState,
    tuneBypassState,
    tuneSuccessfulState,
    tuneOkState,
    tuneFailBypassState,
    tuneFailState,
    tuneAbortedState,
    tuneManualBypassState,
};


// Radio class protocol options
@class Radio;

@protocol RadioDelegate <NSObject>
@optional

// Invoked on Radio Connections State changes
- (void) radioConnectionStateChange: (Radio *) radio state: (enum radioConnectionState) state;

@end

#define MAX_SLICES_PER_RADIO    8

// Radio is the primary model for the interface to the FlexRadio 6000 series.
// It utilizes the Ethernet API to command, query and receive status updates
// from the radio being controlled.
//
// Radio provides a set of KVO properties for the features of the radio that
// are unique within the radio such as number of available slices, panadapters etc.
//

@interface Radio : NSObject <AsyncSocketDelegate>

// The RadioInstance this Radio was set up to access.
@property (strong, nonatomic) RadioInstance *radioInstance;

// Array to handle each slice for a radio - indexed by slice number
// with an entry set to NSNULL if the slice does not exist.

@property (strong, nonatomic) NSMutableArray *slices;

// Array to handle each equalizer for a radio - indexed by rx=0, tx=1
// Entries are NSNULL until the equalizer is created

@property (strong, nonatomic) NSMutableArray *equalizers;

// Mutable Dictionary to handle the filter specifications in use with this
// radio

@property (strong, nonatomic) NSMutableDictionary *filters;

// Available antenna ports - varies by model - set for read only when Radio is
// instantiated.

@property (strong, nonatomic) NSMutableArray *rxAntennaPorts;       // Array of strings with name for each RX antenna Port
@property (strong, nonatomic) NSMutableArray *txAntennaPorts;       // Same for TX antenna ports

// All the following properties are KVO compliant for READ
@property (strong, nonatomic) NSString *apiVersion;                 // NSString of format VM.m.x.y of Version of API
@property (strong, nonatomic) NSString *apiHandle;                  // NSString of our API handle

@property (strong, nonatomic) NSNumber *availableSlices;            // Number of available slices which can be created - INTEGER
@property (strong, nonatomic) NSNumber *availablePanadapters;       // Number of available panadaptors which can be created - INTEGER
@property (strong, nonatomic) NSNumber *interlockTimeoutValue;      // Interlock timeout value in milliseconds - INTEGER
@property (strong, nonatomic) NSNumber *interlockState;             // Interlock state - ENUM radioInterlockState
@property (strong, nonatomic) NSString *interlockReason;            // Reason for the interlock - STRING
@property (strong, nonatomic) NSString *pttSource;                  // PTT Source - STRING
@property (strong, nonatomic) NSNumber *accTxReqEnable;             // ACC TX Request Enable - BOOL
@property (strong, nonatomic) NSNumber *rcaTxReqEnable;             // RCA TX Request Enable - BOOL
@property (strong, nonatomic) NSNumber *accTxReqPolarity;           // ACC RX Request Polarity - BOOL
@property (strong, nonatomic) NSNumber *rcaTxReqPolarity;           // RCA TX Request Polarity - BOOL
@property (strong, nonatomic) NSNumber *pttDelay;                   // PTT Delay in milliseconds - INTEGER
@property (strong, nonatomic) NSNumber *tx1Delay;                   // TX1 Delay in millisoconds - INTEGER
@property (strong, nonatomic) NSNumber *tx2Delay;                   // TX2 Delay in millisoconds - INTEGER
@property (strong, nonatomic) NSNumber *tx3Delay;                   // TX3 Delay in millisoconds - INTEGER
@property (strong, nonatomic) NSNumber *tx1Enabled;                 // TX1 Delay enabled - BOOL
@property (strong, nonatomic) NSNumber *tx2Enabled;                 // TX2 Delay enabled - BOOL
@property (strong, nonatomic) NSNumber *tx3Enabled;                 // TX3 Delay enabled - BOOL
@property (strong, nonatomic) NSNumber *accTxEnabled;               // ACC tx enabled - BOOL
@property (strong, nonatomic) NSNumber *accTxDelay;                 // ACC TX Delay in milliseconds - INTEGER
@property (strong, nonatomic) NSNumber *txDelay;                    // TX Delay in milliseconds - INTEGER
@property (strong, nonatomic) NSNumber *hwAlcEnabled;               // Hardware ALC enabled - BOOL
@property (strong, nonatomic) NSNumber *masterSpeakerAfGain;        // Mixer master speaker AF gain - INTEGER [0 - 100]
@property (strong, nonatomic) NSNumber *masterHeadsetAfGain;        // Mixer master headset AF gain - INTEGER [0 - 100]
@property (strong, nonatomic) NSNumber *masterSpeakerMute;          // Mixer master speaker mute - BOOL
@property (strong, nonatomic) NSNumber *masterHeadsetMute;          // Mixer master headset mute - BOOL
@property (strong, nonatomic) NSNumber *remoteOnEnabled;            // Remote on enabled - BOOL

// NOTE:  The values provided in the next three properties will change TYPE - likely at the next
// release (from STRINGS to INTEGER.

@property (strong, nonatomic) NSString *transmitFrequency;          // Transmit frequency in MHz - STRING (e.g: 14.225001)
@property (strong, nonatomic) NSString *transmitFilterLo;           // Transmit filter low frequency in MHz - STRING (e.g: -0.0028)
@property (strong, nonatomic) NSString *transmitFilterHi;           // Transmit filter high frequency in MHz - STRING (e.g: 0.0028)

@property (strong, nonatomic) NSNumber *atuStatus;                  // ATU operation status - ENUM radioAtuState

@property (strong, nonatomic) NSNumber *txState;                    // State of tranmsitter on/off - BOOL
@property (strong, atomic)    NSNumber *tuneEnabled;                // State of TUNE on/off - BOOL
@property (strong, nonatomic) NSNumber *rfPowerLevel;               // RF power level in Watts - INTEGER
@property (strong, nonatomic) NSNumber *tunePowerLevel;             // TUNE power level in Watts - INTEGER
@property (strong, nonatomic) NSNumber *amCarrierLevel;             // AM Carrier level in Watts - INTEGER
@property (strong, nonatomic) NSNumber *voxEnabled;                 // State of VOX enable - BOOL
@property (strong, nonatomic) NSNumber *voxLevel;                   // Vox level - INTEGER
@property (strong, nonatomic) NSNumber *voxVisible;                 // VOX Visble - BOOL
@property (strong, nonatomic) NSNumber *voxDelay;                   // VOX Delay - INTEGER
@property (strong, nonatomic) NSNumber *micLevel;                   // Mic gain level - INTEGER [0 - 100]
@property (strong, nonatomic) NSString *micSelection;               // Mic source selection - STRING [MIC, LINE, BAL, ACC]
@property (strong, nonatomic) NSNumber *micBoost;                   // State of Mic Boost - BOOL
@property (strong, nonatomic) NSNumber *micBias;                    // State of Mic Bias - BOOL
@property (strong, nonatomic) NSNumber *micAccEnabled;              // Accessory connector mic input enabled - BOOL
@property (strong, nonatomic) NSNumber *companderEnabled;           // State of Compander - BOOL
@property (strong, nonatomic) NSNumber *companderLevel;             // Compander level - INTEGER [0 - 100]
@property (strong, nonatomic) NSNumber *noiseGateLevel;             // Noise gate level - INTEGER **UNIMPLEMENTED**
@property (strong, nonatomic) NSNumber *cwPitch;                    // CW pitch in Hertz - INTEGER
@property (strong, nonatomic) NSNumber *cwSpeed;                    // CW speed in WPM - INTEGER
@property (strong, nonatomic) NSNumber *cwIambicEnabled;            // State of Iambic - BOOL
@property (strong, nonatomic) NSString *cwIambicMode;               // Mode of internal iambic keyer - STRING ("A" or "B")
@property (strong, nonatomic) NSNumber *cwSwapPaddles;              // Internal Iambic keyer - swap dot paddle to right (for lefties) - BOOL
@property (strong, nonatomic) NSNumber *cwBreakinEnabled;           // State of CW QSK - BOOL
@property (strong, nonatomic) NSNumber *cwBreakinDelay;             // CW QSK delay in milliseconds - INTEGER [0 - 2000]
@property (strong, nonatomic) NSNumber *monitorEnabled;             // State of TX monitor - BOOL
@property (strong, nonatomic) NSNumber *monitorLevel;               // Monitor Audio level - INTEGER [0 - 100]
@property (strong, nonatomic) NSNumber *metInRxEnabled;             // Enable Mic Level meter in RX mode - BOOL




// Class methods

// initWithRadioUInstanceAndDelegate: Invoke with the RadioInstance of the radio to be
// commanded.
- (id) initWithRadioInstanceAndDelegate: (RadioInstance *) thisRadio delegate: (id) theDelegate;

// close: Call to disconnect from this Radio and release all resources.
- (void) close;

// Returns the state of the Radio connection
- (enum radioConnectionState) radioConnectionState;

// DO NOT USE DIRECTLY - provided here since all other model classes need to communicate
// with a specific radio - e.g: Slice, Meters, Pandaptors...
- (void) commandToRadio:(NSString *) cmd;

- (void) cmdSetTxBandwidth: (NSNumber *) lo high: (NSNumber *) hi;  // Set TX bandwidth
- (void) cmdSetRfPowerLevel: (NSNumber *) level;                    // Set RF power level in Watts - INTEGER
- (void) cmdSetAmCarrierLevel: (NSNumber *) level;                  // Set AM Carrier power level in Watts - INTEGER

- (void) cmdSetMicSelection: (NSString *) source;                   // Set MIC selection source - STRING
- (void) cmdSetMicLevel: (NSNumber *) level;                        // Set MIC gain level - INTEGER
- (void) cmdSetMicBias: (NSNumber *) state;                         // Set state of MIC Bias - BOOL
- (void) cmdSetMicBoost: (NSNumber *) state;                        // Set state of MIC Boost - BOOL
- (void) cmdSetAccEnabled: (NSNumber *) state;                      // Set state of MIC via ACC connector - BOOL
- (void) cmdSetCompander: (NSNumber *) state;                       // Set state of Compander - BOOL
- (void) cmdSetCompanderLevel: (NSNumber *) level;                  // Set Compander Level - INTEGER
- (void) cmdSetVoxEnabled: (NSNumber *) state;                      // Set state of VOX - BOOL
- (void) cmdSetVoxLevel: (NSNumber *) level;                        // Set VOX gain - INTEGER
- (void) cmdSetVoxDelay: (NSNumber *) level;                        // Set VOX delay - INTEGER

- (void) cmdSetCwPitch: (NSNumber *) level;                         // Set CW pitch in Hertz - INTEGER
- (void) cmdSetCwSpeed: (NSNumber *) level;                         // Set CW keyer speed in WPM - INTEGER
- (void) cmdSetCwSwapPaddles: (NSNumber *) state;                   // Set Swap CW paddles - BOOL (F = Dot/Dash, T = Dash/Dot)
- (void) cmdSetIambicEnabled: (NSNumber *) state;                   // Set state of Iambic - BOOL
- (void) cmdSetIambicMode: (NSString *) mode;                       // Iambic mode - STRING "A" or "B"
- (void) cmdSetBreakinEnabled: (NSNumber *) state;                  // Set state of QSK - BOOL
- (void) cmdSetQskDelay: (NSNumber *) level;                        // Set QSK delay in milliseconds - INTEGER

- (void) cmdSetTxDelay: (NSNumber *) delay;                         // Set TX Delay in milliseconds - INTEGER
- (void) cmdSetTx1Delay: (NSNumber *) delay;                        // Set RCA TX1 Delay in milliseconds - INTEGER
- (void) cmdSetTx2Delay: (NSNumber *) delay;                        // Set RCA TX2 Delay in milliseconds - INTEGER
- (void) cmdSetTx3Delay: (NSNumber *) delay;                        // Set RCA TX3 Delay in milliseconds - INTEGER
- (void) cmdSetAccTxDelay: (NSNumber *) delay;                      // Set ACC TX Delay in milliseconds - INTEGER

- (void) cmdSetTx1Enabled: (NSNumber *) state;                      // Set RCA TX1 Enabled - BOOL
- (void) cmdSetTx2Enabled: (NSNumber *) state;                      // Set RCA TX2 Enabled - BOOL
- (void) cmdSetTx3Enabled: (NSNumber *) state;                      // Set RCA TX3 Enabled - BOOL
- (void) cmdSetAccTxEnabled: (NSNumber *) state;                    // Set ACC TX Enabled - BOOL


- (void) cmdSetMonitorEnabled: (NSNumber *) state;                  // Set state of TX Monitor - BOOL
- (void) cmdSetMonitorLevel: (NSNumber *) level;                    // Set TX Monitor level - INTEGER
- (void) cmdSetTx: (NSNumber *) state;                              // Set TX state (on/off) - BOOL
- (void) cmdSetAtuTune: (NSNumber *) state;                         // Set ATU command state (on/off) - BOOL
- (void) cmdSetBypass;                                              // Set ATU bypass
- (void) cmdSetTune: (NSNumber *) state;                            // Set TUNE state (on/off) - BOOL

- (void) cmdSetMasterSpeakerGain: (NSNumber *) level;               // Set mixer master speaker AF level - INTEGER
- (void) cmdSetMasterHeadsetGain: (NSNumber *) level;               // Set mixer master headset AF level - INTEGER

- (void) cmdSetMasterSpeakerMute: (NSNumber *) state;               // Set mixer master speaker mute - BOOL
- (void) cmdSetMasterHeadsetMute: (NSNumber *) state;               // Set mixer master headset mute - BOOL

- (void) cmdSetRemoteOnEnabled: (NSNumber *) state;                 // Set remote on enabled - BOOL
- (void) cmdSetHwAlcEnabled: (NSNumber *) state;                    // Set HW ALC enabled - BOOL

- (void) cmdSetRcaTxInterlockEnabled: (NSNumber *) state;           // Set RCA Interlock enabled - BOOL
- (void) cmdSetRcaTXInterlockPolarity: (NSNumber *) state;          // Set RCA Interlock Polarity - BOOL (F = active lo, T = active hi)

- (void) cmdSetAccTxInterlockEnabled: (NSNumber *) state;           // Set ACC Interlock enabled - BOOL
- (void) cmdSetAccTxInterlockPolarity: (NSNumber *) state;          // Set ACC Interlock Polarity - BOOL (F = active lo, T = active hi)

- (void) cmdSetInterlockTimeoutValue: (NSNumber *) value;           // Set Interlock timeout in minutes - INTEGER


// NOTE:  The cmdNewSlice will change to add the ability to specify frequency, mode and antenna selections
// in some upcoming release.

- (void) cmdNewSlice;                                               // Create a new slice (14.150, USB, ANT1 - hardcoded)
- (void) cmdNewSlice: (NSString *) frequency
             antenna: (NSString *) antennaPort
                mode: (NSString *) mode;                            // Create a new slice withthe specified mode, frequency and port

- (void) cmdRemoveSlice: (NSNumber *) sliceNum;                     // Remove slice N - INTEGER


@end
