//
//  Radio.h
//  
//  Created by STU PHILLIPS, K6TU on 8/3/13.
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

#if OS_IS_IPHONE
    #import <UIKit/UIKit.h>
#endif
#import "RadioFactory.h"

// This model class is depedent on the AysncTCPSocket class developed by
// Robbie Hansen.  It is part of the CocoaAsyncSocket project which can
// be found on github at:
//
//  https://github.com/robbiehanson/CocoaAsyncSocket
//

#import "GCDAsyncSocket.h"


// The primary interface object for a Flex 6000 series radio
// Must be instantiated from a RadioInstance provided from the RadioFactory

// The following enumerations provide state information for different aspects
// of the radio.

enum radioConnectionState {
    disConnected = 0,
    connecting,
    connected,
    connectedAsGui,
    disconnecting,
    connectFailed,
    radioTimedOut,
    tooManyGuiClients,
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


// forward class definitions
@class Radio;
@class Meter;
@class VitaManager;
@class Panafall;
@class Waterfall;
@class DAXAudio;
@class OpusAudio;
@class Cwx;
@class Tnf;
@class Memory;

@protocol RadioDelegate <NSObject>
@optional

// Invoked on Radio Connections State changes
- (void) radioConnectionStateChange: (Radio *) radio state: (enum radioConnectionState) state;
- (void) radioCommandResponse: (unsigned int) seqNum response: (NSString *) cmdResponse;

@end


// Internal process used between Radio and related objects to provide the related object
// with radio gerneated status messages relevant to the object e.g: Slice, Equalizer

@protocol RadioParser <NSObject>

- (void) statusParser: (NSScanner *) scan selfStatus: (BOOL) selfStatus;

@end

// Internal process used between Radio and Meter to update meter value

@protocol RadioMeter <NSObject>

- (void) setupMeter:(Radio *) radio scan:(NSScanner *) scan;

@end

// Internal protocol used between Radio and Slice to add and remove meters

@protocol RadioSliceMeter <NSObject>

- (void) addMeter:(Meter *)meter;
- (void) removeMeter:(Meter *)meter;

@end

// Internal protocol used between Radio and Displays

@protocol RadioStreamProcessor <NSObject>
- (void)attachedRadio:(Radio *)radio streamId:(NSString *) streamId;
- (void)willRemoveStreamProcessor;

@optional
- (void) updatePanafallRef:(Panafall *) pan;
- (void) updateWaterfallRef:(Waterfall *) waterfall;
@end

@protocol TNFEventHandler <NSObject>

@optional
- (void) tnfAdded:(Tnf *)tnf;
- (void) tnfRemoved:(Tnf *)tnf;
@end

@protocol MemoryEventHandler <NSObject>

@optional
- (void) memoryAdded:(Memory *)mem;
- (void) memoryRemoved:(Memory *)mem;
@end


#define MAX_SLICES_PER_RADIO    8

// Radio is the primary model for the interface to the FlexRadio 6000 series.
// It utilizes the Ethernet API to command, query and receive status updates
// from the radio being controlled.
//
// Radio provides a set of KVO properties for the features of the radio that
// are unique within the radio such as number of available slices, panadapters etc.
//

@interface Radio : NSObject <GCDAsyncSocketDelegate, RadioDelegate>

// The RadioInstance this Radio was set up to access.
@property (strong, nonatomic) RadioInstance *radioInstance;

// The VitaManager which handles all incoming VITA encoded streams except
// for VITA_DISCOVERY (see RadioFactory).  The VitaManager is only created
// once the radio is connected.

@property (strong, readonly, nonatomic) VitaManager *vitaManager;

// Mutable Dictionary to handle the meters for the radio and related objects
// Key is the meter number as an NSString

@property (strong, readonly, nonatomic) NSMutableDictionary *meters;

// Mutable Dictionary to handle the panafall objects for the radio
// Key is the stream id as a hex encoded string - like 0x40000000

@property (strong, readonly, nonatomic) NSMutableDictionary *panafalls;
@property (strong, readonly, nonatomic) NSMutableDictionary *waterfalls;

// Mutable dictionary to handle the Audio Stream (Dax Audio) handlers
// for the radio.  Key is the stream id

@property (strong, readonly, nonatomic) NSMutableDictionary *daxAudioStreamToStreamHandler;

// Mutable dictionary to handle the Opus Stream handlers
// for the radio.  Key is the stream id
@property (strong, readonly, nonatomic) NSMutableDictionary *opusStreamToStreamHandler;


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

// All the following properties are KVO compliant

@property (strong, readonly, nonatomic) NSString *apiVersion;                 // NSString of format VM.m.x.y of Version of API
@property (strong, readonly, nonatomic) NSString *apiHandle;                  // NSString of our API handle
@property (strong, readonly, nonatomic) NSNumber *availableSlices;            // Number of available slices which can be created - INTEGER
@property (strong, readonly, nonatomic) NSNumber *availablePanadapters;       // Number of available panadaptors which can be created - INTEGER

@property (strong, nonatomic) NSNumber *interlockTimeoutValue;      // Interlock timeout value in milliseconds - INTEGER
@property (strong, nonatomic) NSNumber *interlockState;             // Interlock state - ENUM radioInterlockState
@property (strong, nonatomic) NSString *interlockReason;            // Reason for the interlock - STRING
@property (strong, nonatomic) NSNumber *txAllowed;                  // TX allowed - BOOL
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
@property (strong, nonatomic) NSNumber *txInhibit;                  // TX Inhibit - BOOL
@property (strong, nonatomic) NSNumber *cwlEnabled;                 // CWL offset enabled - BOOL
@property (strong, nonatomic) NSNumber *rawIQEnabled;               // Transmission of RAW IQ data - BOOL
@property (strong, nonatomic) NSNumber *txFilterChangesAllowed;     // TX filter changes allowed - BOOL
@property (strong, nonatomic) NSNumber *txRfPowerChangesAllowed;    // TX RF Power level changes allowed - BOOL
@property (strong, nonatomic) NSNumber *syncCWX;                    // Synchronize CWX - BOOL
@property (strong, nonatomic) NSNumber *monAvailable;               // Monitor available - BOOL

// NOTE:  The values provided in the next three properties will change TYPE - likely at the next
// release (from STRINGS to INTEGER.

@property (strong, nonatomic) NSString *transmitFrequency;          // Transmit frequency in MHz - STRING (e.g: 14.225001)
@property (strong, nonatomic) NSString *transmitFilterLo;           // Transmit filter low frequency in MHz - STRING (e.g: -0.0028)
@property (strong, nonatomic) NSString *transmitFilterHi;           // Transmit filter high frequency in MHz - STRING (e.g: 0.0028)

@property (strong, readonly, nonatomic) NSNumber *atuStatus;        // ATU operation status - ENUM radioAtuState
@property (strong, readonly, nonatomic) NSNumber *atuEnabled;       // ATU enabled - BOOL
@property (strong, nonatomic) NSNumber *atuMemoriesEnabled;         // ATU Memories Enabled - BOOL
@property (strong, nonatomic) NSNumber *atuUsingMemories;           // ATU memories in use - BOOL


@property (strong, nonatomic) NSNumber *txState;                    // State of tranmsitter on/off - BOOL
@property (strong, nonatomic) NSNumber *tuneEnabled;                // State of TUNE on/off - BOOL
@property (strong, nonatomic) NSNumber *rfPowerLevel;               // RF power level in Watts - INTEGER
@property (strong, nonatomic) NSNumber *maxPowerLevel;              // Maximum transmit power in Watts - INTEGER
@property (strong, nonatomic) NSNumber *tunePowerLevel;             // TUNE power level in Watts - INTEGER
@property (strong, nonatomic) NSNumber *amCarrierLevel;             // AM Carrier level in Watts - INTEGER
@property (strong, nonatomic) NSNumber *voxEnabled;                 // State of VOX enable - BOOL
@property (strong, nonatomic) NSNumber *voxLevel;                   // Vox level - INTEGER
@property (strong, nonatomic) NSNumber *voxVisible;                 // VOX Visble - BOOL
@property (strong, nonatomic) NSNumber *voxDelay;                   // VOX Delay - INTEGER
@property (strong, nonatomic) NSNumber *micLevel;                   // Mic gain level - INTEGER [0 - 100]
@property (strong, nonatomic) NSString *micSelection;               // Mic source selection - STRING [MIC, LINE, BAL, ACC]
@property (strong, nonatomic) NSNumber *txDaxEnabled;               // DAX Enabled as TX audio source - BOOL
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

@property (strong, nonatomic) NSNumber *sidetone;                   // CW Sidetone enabled - BOOL
@property (strong, nonatomic) NSNumber *sidetoneGain;               // CW Sidetone level - INTEGER [0 - 100]
@property (strong, nonatomic) NSNumber *sidetonePan;                // CW sidetone audio pan - INTEGER [0 - 100]
@property (strong, nonatomic) NSNumber *phMonitor;                  // Phone Monitor Enabled - BOOL
@property (strong, nonatomic) NSNumber *monitorPHGain;              // Phone Monitor level - INTEGER [0 - 100]
@property (strong, nonatomic) NSNumber *monitorPHPan;               // Phone Monitor audio pan - INTEGER [0 - 100]
@property (strong, nonatomic) NSNumber *metInRxEnabled;             // Enable Mic Level meter in RX mode - BOOL
@property (strong, nonatomic) NSNumber *speechProcEnabled;          // Speech Processor enabled - BOOL
@property (strong, nonatomic) NSNumber *speechProcLevel;            // Speech Processor level - INTEGER (0 = NORM, 1 = DX, 2 = DX+)

@property (strong, nonatomic) NSString *radioScreenSaver;           // ScreenSaver value - STRING
@property (strong, nonatomic) NSString *radioCallsign;              // Callsign value for radio if set - STRING
@property (strong, nonatomic) NSString *radioModel;                 // Model of radio - STRING
@property (strong, nonatomic) NSString *radioName;                  // Name of radio if set - STRING

@property (strong, nonatomic) NSNumber *binauralRx;                 // Binaural RX enable - BOOL
@property (strong, nonatomic) NSNumber *fullDuplexEnabled;          // Full Duplex Enabled - BOOL


@property (strong, nonatomic) NSNumber *syncActiveSlice;            // Client should sync active slice with radio - BOOL [Default YES]

@property (strong, nonatomic) NSNumber *remoteAudio;                // State or Remote (Opus) Audio - BOOL

@property (strong, nonatomic) NSString *currentGlobalProfile;       // Name of active Global Profile - STRING
@property (strong, nonatomic) NSString *currentTxProfile;           // Name of active Tx Profile - STRING
@property (strong, nonatomic) NSMutableArray *globalProfiles;       // Array of strings with name for each Global Profile
@property (strong, nonatomic) NSMutableArray *txProfiles;           // Array of strings with name for each Tx Profile

@property (strong, nonatomic, readonly) NSString *smartSdrVersion;            // Revision number of radio OS
@property (strong, nonatomic, readonly) NSString *psocMbtrxVersion;           // TRX board PSOC firmware version
@property (strong, nonatomic, readonly) NSString *psocMbPa100Version;         // PA board PSOC firmware version
@property (strong, nonatomic, readonly) NSString *fpgaMbVersion;              // FPGA microcode load version

@property (strong, nonatomic, readonly) NSArray *antList;           // Array of strings with name for each Antenna connection
@property (strong, nonatomic, readonly) NSArray *micList;           // Array of strings with name for each Mic connection

// NOTE: Set this property if the client support a graphical user interface.
// The behavior of the radio is heavily dependent on this property - so for correct operation,
// make sure that this property is set if necessary immediately after the radio connection state change is
// signalled via the RadioDelegate protocol.

@property (strong, nonatomic) NSNumber *isGui;                      // Set true if client supports a graphical user interface

@property (nonatomic) BOOL logRadioMessages;                        // Set true automatically if a debug build, otherwise, set true to
                                                                    // turn on logging of messages to/from the radio API
@property (strong, nonatomic, readonly) Cwx *cwx;                   // reference to the CWX object

@property (nonatomic) NSNumber *tnfEnabled;                         // Set true if TNF's are enabled - BOOL
@property (strong, nonatomic, readonly) NSMutableArray *tnfs;       // Array of TNF's

@property (strong, nonatomic, readonly) NSMutableArray *memoryList; // Array of Memories


// Class methods

// initWithRadioUInstanceAndDelegate: Invoke with the RadioInstance of the radio to be
// commanded.
- (id) initWithRadioInstanceAndDelegate: (RadioInstance *) thisRadio delegate: (id) theDelegate clientId:(NSString *) clientId;

// close: Call to disconnect from this Radio and release all resources.
- (void) close;

// Returns the state of the Radio connection
- (enum radioConnectionState) radioConnectionState;

// DO NOT USE DIRECTLY - provided here since all other model classes need to communicate
// with a specific radio - e.g: Slice, Meters, Pandaptors...
- (void) commandToRadio:(NSString *) cmd;

// DO NOT USE DIRECTLY - same proviso as above
- (unsigned int) commandToRadio:(NSString *) cmd notify: (id<RadioDelegate>) notifyMe;

// Command methods for non-property based radio attributes
- (void) cmdSetAtuTune: (NSNumber *) state;                         // Set ATU command state (on/off) - BOOL
- (void) cmdSetBypass;                                              // Set ATU bypass
- (void) cmdNewSlice;                                               // Create a new slice (14.150, USB, ANT1 - hardcoded)
- (void) cmdNewSlice: (NSString *) frequency
             antenna: (NSString *) antennaPort
                mode: (NSString *) mode;                            // Create a new slice with the specified mode, frequency and port
- (void) cmdNewSlice: (NSString *) frequency
             antenna: (NSString *) antennaPort
                mode: (NSString *) mode
            panafall: (NSString *) streamId;                        // Create a new slice with the specified mode, frequency and port in pan
- (void) cmdRemoveSlice: (NSNumber *) sliceNum;                     // Remove slice N - INTEGER
- (BOOL) cmdNewPanafall:(CGSize) size;                              // Create a new panadaptor on the radio
- (void) cmdRemovePanafall:(Panafall *) pan;                        // Remove this panafall from the radio
- (void) cmdNewAudioStream:(int) daxChannel;                        // Create a new audio stream handler for the specified DAX channel
- (void) cmdRemoveAudioStreamHandler:(DAXAudio *) streamProcessor;  // Remove the audio stream handler from the radio
- (void) cmdSaveGlobalProfile:(NSString *)profile;                  // Save the current state as a global profile
- (void) cmdDeleteGlobalProfile:(NSString *)profile;                // Remove the global profile from the radio
- (void) cmdSaveTxProfile:(NSString *)profile;                      // Save the current state as a transmit profile
- (void) cmdDeleteTxProfile:(NSString *)profile;                    // Remove the transmit profile from the radio

- (Tnf *)createTnf;                                                 // Create a TNF with next available ID & default values
- (Tnf *)createTnfWithID:(uint)ID;                                  // Create a TNF with the specified ID & default values
- (Tnf *)createTnfWithFreq:(double)freq;                            // Create a TNF with next available ID, specified Frequency & default values
- (void) addTnf:(Tnf *)tnf;                                         // Add a TNF to the tnfs list
- (void) removeTnf:(Tnf *)tnf;                                      // Remove a TNF from the tnfs list
- (void) updateTnfFrequency:(uint)ID freq:(double)freq;             // Update the Frequency of an existing TNF
- (void) updateTnfWidth:(uint)ID width:(double)width;               // Update the width of an existing TNF
- (void) updateTnfDepth:(uint)ID depth:(uint)depth;                 // Update the Depth of an existing TNF
- (void) updateTnfPermanent:(uint)ID permanent:(BOOL)permanent;     // Update the Permanent of an existing TNF
- (void) requestTnf:(double)freq panID:(NSString *)panID;           // Create a TNF on the specified Pan at the specified Frequency

- (void) addMemory:(Memory *)mem;
- (void) removeMemory:(Memory *)mem;
- (void) onMemoryAdded:(Memory *)mem;
- (Memory *) findMemoryByIndex:(int)index;

//
// The delegate handling here will be invoked on our run queue (or the TCP socket run queue more likely).
// It will NOT be called on the main dispatch queue. If there are any UI updates that are interested in the update,
// the user will have to arrange for their own dispatch onto the main queue to make the UI changes there.
//
@property (weak, nonatomic) id<MemoryEventHandler> memoryEventDelegate;


@end
