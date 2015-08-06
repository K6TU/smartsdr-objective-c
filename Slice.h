//
//  Slice.h
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

#import <Foundation/Foundation.h>
#import "Radio.h"

// Forward class definitions
@class Radio;
@class Meter;

// Slice is the model for a unique slice in the Radio model - notifications are sent
// via the default notification center on creation (SliceCreated) and deletion (SliceDeleted)
// of each slice.


@interface Slice : NSObject <RadioSliceMeter, RadioParser>

// Pointer to the object which created this Slice
@property (weak, nonatomic, readonly) Radio *radio;

// Pointer to private run queue for Radio
@property (nonatomic, readonly) dispatch_queue_t sliceRunQueue;

// All the following properties are KVO compliant for READ and WRITE except where marked READONLY

@property (strong, nonatomic, readonly) NSMutableDictionary *meters;// Dictionary of meters keyed by their short name
@property (strong, nonatomic, readonly) NSNumber *thisSliceNumber;  // Reference id of this slice - INTEGER [0 - 7]
@property (strong, nonatomic, readonly) NSNumber *sliceInUse;       // Slice in use - BOOL
@property (strong, nonatomic) NSString *sliceFrequency;             // Slice frequency in MHz - STRING (e.g: 14.225001)
@property (strong, nonatomic) NSString *sliceRxAnt;                 // RX Antenna port for this slice - STRING (ANT1, ANT2, RX_A, RX_B, XVTR)
@property (strong, nonatomic) NSString *sliceTxAnt;                 // TX Antenna port for this slice - STRING (ANT1, ANT2, XVTR)

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

@property (strong, nonatomic) NSNumber *sliceDiversityEnabled;      // This slice is part of a diversity pair - BOOL
@property (strong, nonatomic) NSNumber *sliceDiversityParent;       // True if this slice is the parent of the pair - BOOL
@property (strong, nonatomic) NSNumber *sliceDiversityChild;        // True if this slice is the child of the pair - BOOL
@property (strong, nonatomic) NSNumber *sliceDiversityIndex;        // Slice number of the other slice of the pair - INTEGER
@property (strong, nonatomic) NSMutableArray *stepList;             // Array of tuning steps set by the radio - STRING values, mode specific
@property (strong, nonatomic) NSMutableArray *antList;              // Array of available antenna ports for this slice
@property (strong, nonatomic) NSMutableArray *modeList;             // Array of NSStrings with available modes

@property (strong, nonatomic) NSNumber *squelchEnabled;             // Squelch enabled - BOOL
@property (strong, nonatomic) NSNumber *squelchLevel;               // Squelch level - INTEGER [0 - 100]
@property (strong, nonatomic) NSString *fmToneMode;                 // FM CTCSS tone mode - STRING (ON | OFF)
@property (strong, nonatomic) NSNumber *fmToneFreq;                 // FM CTCSS tone frequency - FLOAT
@property (strong, nonatomic) NSNumber *fmRepeaterOffset;           // FM repeater offset - FLOAT
@property (strong, nonatomic) NSNumber *txOffsetFreq;               // TX Offset Frequency - FLOAT
@property (strong, nonatomic) NSString *repeaterOffsetDir;          // Repeater offset direction - STRING (DOWN, UP, SIMPLEX)
@property (strong, nonatomic) NSNumber *fmToneBurstEnabled;         // FM Tone Burst enabled - BOOL
@property (strong, nonatomic) NSNumber *fmDeviation;                // FM Deviation for DFM mode - INTEGER
@property (strong, nonatomic) NSNumber *fmPreDeEmphasis;            // FM pre-deEmphasis for DFM mode - BOOL
@property (strong, nonatomic) NSNumber *postDemodLo;                // FM pre-emphasis low frequency - INTEGER
@property (strong, nonatomic) NSNumber *postDemodHi;                // FM pre-emphasis high frequency - INTEGER
@property (strong, nonatomic) NSNumber *rttyMark;                   // RTTY mark frequency - INTEGER
@property (strong, nonatomic) NSNumber *rttyShift;                  // RTTY Shift - INTEGER
@property (strong, nonatomic) NSNumber *diglOffset;                 // DIGL offset - INTEGER
@property (strong, nonatomic) NSNumber *diguOffset;                 // DIGH offset - INTEGER



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
- (NSString *) formatFrequencyNumberAsString:(NSNumber *) frequency;// Return slice RF frequenct as STRINF (e.g: 14.225001)

// Slice command functions - use these commands to change specific functions of this slice
- (void) setSliceFrequency:(NSString *)sliceFrequency
                   autopan: (BOOL) autopan;                         // Set property sliceFrequency - STRING (e.g: 14.225001) with autopan ON|OFF

@end
