//
//  Slice.h
//  
//  Created by STU PHILLIPS on 8/5/13.
//  Copyright (c) 2013 STU PHILLIPS. All rights reserved.
//
// NOTE: THe license under which this software will be generally released
// is still under consideration.  For now, use of this software requires
// the specific approval of Stu Phillips, K6TU.

#import <Foundation/Foundation.h>
#import "Radio.h"

// Slice is the model for a unique slice in the Radio model - notifications are sent
// via the default notification center on creation (SliceCreated) and deletion (SliceDeleted)
// of each slice.


@interface Slice : NSObject

// Pointer to the object which created this Slice
@property (strong, nonatomic) Radio *radio;

// All the following properties are KVO compliant for READ

@property (strong, nonatomic) NSNumber *thisSliceNumber;            // Reference id of this slice - INTEGER [0 - 7]
@property (strong, nonatomic) NSNumber *sliceInUse;                 // Slice in use - BOOL
@property (strong, nonatomic) NSString *sliceFrequency;             // Slice frequency in MHz - STRING (e.g: 14.225001)
@property (strong, nonatomic) NSString *sliceRxAnt;                 // RX Antenna port for this slice - STRING (ANT1, ANT2, RX_A, RX_B, XVTR)
@property (strong, nonatomic) NSNumber *sliceXitEnabled;            // XIT state ON|OFF - BOOL
@property (strong, nonatomic) NSNumber *sliceXitOffset;             // XIT offset value - INTEGER
@property (strong, nonatomic) NSNumber *sliceRitEnabled;            // RIT state ON|OFF - BOOL
@property (strong, nonatomic) NSNumber *sliceRitOffset;             // RIT offset value - INTEGER
@property (strong, nonatomic) NSString *sliceMode;                  // Slice mode - STRING (USB, LSB, CW, DIGU, DIGL)
@property (strong, nonatomic) NSNumber *sliceWide;                  // State of slice bandpass filter (BPF or WIDE) - BOOL (TRUE == WIDE)
@property (strong, nonatomic) NSNumber *sliceFilterLo;              // RX filter low frequency - INTEGER
@property (strong, nonatomic) NSNumber *sliceFilterHi;              // RX filter high frequency - INTEGER
@property (strong, nonatomic) NSNumber *sliceNbEnabled;             // State of DSP Noise Blanker - BOOL
@property (strong, nonatomic) NSNumber *sliceNbLevel;               // DSP Noise Blanker level - INTEGER (0 -100)
@property (strong, nonatomic) NSNumber *sliceNrEnabled;             // State of DSP Noise Reduction - BOOL
@property (strong, nonatomic) NSNumber *sliceNrLevel;               // DSP Noise Reduction level - INTEGER (0 - 100)
@property (strong, nonatomic) NSNumber *sliceAnfEnabled;            // State of DSP Automatic Notch Filter - BOOL
@property (strong, nonatomic) NSNumber *sliceAnfLevel;              // DSP Automatic Notch Filter level (0 - 100)
@property (strong, nonatomic) NSNumber *sliceApfEnabled;            // DSP Audio Peaking Filter for CW -  BOOL
@property (strong, nonatomic) NSNumber *sliceApfLevel;              // DSP APF Level - INTEGER (0 - 100)
@property (strong, nonatomic) NSString *sliceAgcMode;               // Slice AGC mode - STRING (FAST, MED, SLOW, OFF)
@property (strong, nonatomic) NSNumber *sliceAgcThreshold;          // Slice AGC Threshold level - INTEGER (0 - 100)
@property (strong, nonatomic) NSNumber *sliceAgcOffLevel;           // Slice AGC Off level
@property (strong, nonatomic) NSString *sliceTxAnt;                 // TX Antenna port for this slice - STRING (ANT1, ANT2, XVTR)
@property (strong, nonatomic) NSNumber *sliceTxEnabled;             // TX on ths slice frequency/mode - BOOL
@property (strong, nonatomic) NSNumber *sliceActive;                // Slice active - This is the active slice = BOOL
@property (strong, nonatomic) NSNumber *sliceLocked;                // Slice frequency locked - BOOL
@property (strong, nonatomic) NSNumber *sliceGhostStatus;           // Slice ghost - RESERVED for FUTURE use
@property (strong, nonatomic) NSNumber *sliceOwner;                 // Slice owner - RESERVED for FUTURE use

@property (strong, nonatomic) NSNumber *sliceDax;                   // DAX channel for this slice - INTEGER (1-8)
@property (strong, nonatomic) NSNumber *sliceDaxClients;            // Count of  the number of DAX clients for this slice
@property (strong, nonatomic) NSNumber *sliceDaxTxEnabled;          // DAX transmit channel
@property (strong, nonatomic) NSNumber *sliceMuteEnabled;           // State of slice MUTE - BOOL
@property (strong, nonatomic) NSNumber *sliceAudioLevel;            // Slice audio level - INTEGER (0 - 100)
@property (strong, nonatomic) NSNumber *slicePanControl;            // Slice PAN control - INTEGER (0 == LEFT, 100 == RIGHT)

@property (strong, nonatomic) NSNumber *slicePlaybackEnabled;       // Quick record playback is active - BOOL
@property (strong, nonatomic) NSNumber *sliceRecordEnabled;         // Quick record record is active - BOOL
@property (strong, nonatomic) NSNumber *sliceQRlength;              // Length of quick recording in seconds - FLOAT


@property (strong, nonatomic) NSNumber *loopAEnabled;               // Loop A enabled - BOOL
@property (strong, nonatomic) NSNumber *loopBEnabled;               // Loop B enabled - BOOL
@property (strong, nonatomic) NSNumber *qskEnabled;                 // QSK capable on slice - BOOL
@property (strong, nonatomic) NSString *panForSlice;                // Pan adaptor stream for this slice - STRING

// Interface of use between Radio and Slice - DO NOT USE
- (id) initWithRadio: (Radio *) radio sliceNumber: (NSInteger) sliceNum;
- (void) youAreBeingDeleted;

// Utility functions

- (NSString *) formatSliceFrequency;                                // Return slice RF frequency as STRING (e.g: 14.225.001)
- (NSNumber *) formatSliceFrequencyAsNumber;                        // Return slice RF frequency as INTEGER (e.g: 14225001)
- (NSString *) formatSliceFilterBandwidth;                          // Return slice filter bandwidth as STRING (e:g: 500 Hz, 1.0 KHz)

// Slice command functions - use these commands to change specific functions of this slice

- (void) cmdSetTx: (NSNumber *) state;                              // Set this slice as reference for Transmit - BOOL

- (void) cmdTuneSlice: (NSNumber *) frequency;                      // Tune this slice to frequency in Hertz - INTEGER
- (void) cmdSetMode: (NSString *) mode;                             // Set mode for this slice - STRING
- (void) cmdSetRxAnt: (NSString *) antenna;                         // Set RX antenna port - STRING
- (void) cmdSetTxAnt: (NSString *) antenna;                         // Set TX antenna port - STIRNG

- (void) cmdSetMute: (NSNumber *) state;                            // Set MUTE for this slice - BOOL
- (void) cmdSetLock: (NSNumber *) state;                            // Set LOCK state for this slice - BOOL
- (void) cmdSetAfLevel: (NSNumber *) level;                         // Set AF level for this slice - INTEGER
- (void) cmdSetAfPan: (NSNumber *) level;                           // Set PAN for this slice - FLOAT

- (void) cmdSetAgcMode: (NSString *) mode;                          // Set AGC mode for this slice - STRING
- (void) cmdSetAgcLevel: (NSNumber *) level;                        // Set AGC threshold for this slice - INTEGER

- (void) cmdSetDspNb: (NSNumber *) state;                           // Set state of DSP NB - BOOL
- (void) cmdSetDspNr: (NSNumber *) state;                           // Set state of DSP NR - BOOL
- (void) cmdSetDspAnf: (NSNumber *) state;                          // Set state of DSP ANF - BOOL
- (void) cmdSetDspApf: (NSNumber *) state;                          // Set state of DSP APF - BOOL

- (void) cmdSetDspNbLevel: (NSNumber *) level;                      // Set DSP NB level - INTEGER
- (void) cmdSetDspNrLevel: (NSNumber *) level;                      // Set DSP NR level - INTEGER
- (void) cmdSetDspAnfLevel: (NSNumber *) level;                     // Set DSP ANF level - INTEGER
- (void) cmdSetDspApfLevel: (NSNumber *) level;                     // Set DSP APF level - INTEGER

- (void) cmdSetXitEnable: (NSNumber *) state;                       // Set XIT state ON|OFF - BOOL
- (void) cmdSetRitEnable: (NSNumber *) state;                       // Set RIT state ON|OFF - BOOL
- (void) cmdSetDaxEnable: (NSNumber *) channel;                     // Set DAX channel - INTEGER [0-8]
- (void) cmdSetXitOffset: (NSNumber *) offset;                      // Set XIT offset - INTEGER
- (void) cmdSetRitOffset: (NSNumber *) offset;                      // Set RIT offset - INTEGER

- (void) cmdSetSliceActive: (NSNumber *) state;                     // Set this slice to be active slice - BOOL
- (void) cmdSetQRPlayback: (NSNumber *) state;                      // Set the state of quick record playback
- (void) cmdSetQRRecord: (NSNumber *) state;                        // Set the state of quick record record

- (void) cmdSetFilter:(NSNumber *) filterLo
             filterHi: (NSNumber *) filterHi;

@end
