//
//  Panafall.h
//  VITA Engine
//
//  Created by STU PHILLIPS on 2/4/15.
//  Copyright (c) 2015 STU PHILLIPS. All rights reserved.
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
#import "Radio.h"
#import "VitaManager.h"
#import "PanafallFFTFrame.h"



// Forward definition for waterfall
@class Waterfall;
@class Panafall;

//
// Protocol used between model and View Controller when data is available
// for the Panafall

@protocol PanafallData <NSObject>

- (void) fftFrame:(PanafallFFTFrame *) frame;

@end


//
// Protocol interface between Panafall and its Waterfall sibling
//

@protocol PanafallWaterfallData <NSObject>

- (void) updateXPixelSize:(int) x;

@end

//
// Model for a Pandaptor for the Flex-6000 series radios
//

//
// Note: Each Panafall will instantiate its own runQueue and use it for any
// actions that requires a command to be sent to the radio to change the
// panafall state.
//
// In addition, the delegate supporting the PanafallData protocol will also
// be called on the run queue identified by the runQueue property below.
//
// The delegare is free to override the run queue instantiated by the
// Panafall model when it is created.
//


@interface Panafall : NSObject <RadioParser, RadioStreamProcessor, VitaStreamHandler>

@property (weak, readonly, nonatomic) Radio *radio;                         // The Radio which owns this panadaptor
@property (strong, readonly, nonatomic) NSString *streamId;                 // Identifier of this panadapator (STRING)
@property (weak, readonly, nonatomic) Waterfall <PanafallWaterfallData>*waterfall;  // The Waterfall linked to this panadaptor (if any)
@property (nonatomic) CGSize panDimensions;                                 // Size of this panadaptor in pixels (CGSIZE)
@property (nonatomic) Float32 center;                                       // Center of the panadaptor in MHz (FLOAT)
@property (nonatomic) Float32 bandwidth;                                    // Bandwidth of panadapor in MHz (FLOAT)
@property (nonatomic) BOOL autoCenter;                                      // Set before changing bandwidth to recenter nearest slice
@property (nonatomic) Float32 minDbm;                                       // Minimum dBm level of panadaptor (FLOAT)
@property (nonatomic) Float32 maxDbm;                                       // Maximum dBm level of panadaptor (FLOAT)
@property (nonatomic) int fps;                                              // Refresh rate in frames per second (INT)
@property (nonatomic) int average;                                          // Setting for panadaptor averaging threshold (INT)
@property (nonatomic) BOOL weightedAverage;                                 // State of weighted averaging (BOOL)
@property (nonatomic) int rfGain;                                           // RF Gain of preamp/attenutator for associated SCU (INT)
@property (strong, nonatomic) NSString *rxAnt;                              // Receive antenna name (STRING)
@property (readonly, nonatomic) BOOL wide;                                  // State of preselector for associated SCU (BOOL)
@property (nonatomic) BOOL loopA;                                           // Enable LOOPA for RXA (BOOL)
@property (nonatomic) BOOL loopB;                                           // Enable LOOPB for RXB (BOOL)
@property (nonatomic) BOOL nb;                                              // Enable NB on this panafall
@property (nonatomic) int nbLevel;                                         // Noise Blanker level - 0-100
@property (nonatomic, readonly) BOOL nbUpdating;                            // NB is recalculating its threshold (BOOL)
@property (nonatomic) BOOL wnb;                                             // Enable WNB on this panafall
@property (nonatomic) int wnbLevel;                                        // Wideband Noise Blanker level - 0-100
@property (nonatomic, readonly) BOOL wnbUpdating;                           // WNB is recalculating its threshold (BOOL)
@property (strong, nonatomic) NSString *band;                               // Band encompassed by this pan (STRING)
@property (nonatomic) int daxIQ;                                            // DAX IQ channel number for this pan (INT 0=none)
@property (readonly, nonatomic) long int daxIQRate;                         // DAX IQ Rate in bps (LONG INT)
@property (readonly, nonatomic) int capacity;                               // Capacity maximum indicator (INT)
@property (readonly, nonatomic) int available;                              // Capacity available (INT)
@property (strong, readonly, nonatomic) NSString *waterfallId;              // Waterfall linked to this panadaptor (NSString)
@property (readonly, nonatomic) Float64 minBW;                              // Minimum bandwidth in MHz (Float)
@property (readonly, nonatomic) Float64 maxBW;                              // Maximum bandwidth in MHz (Float)
@property (strong, readonly, nonatomic) NSString *xvtrLabel;                // Label of selected XVTR profile (STRING)
@property (strong, readonly, nonatomic) NSString *preLabel;                 // Label of preselector selected (STRING)
@property (strong, readonly, nonatomic) NSArray *antList;                   // Array of NSString of antenna options available
@property (strong, readonly, nonatomic) NSArray *preAmpList;                // Array of NSString of preamp gain options available
@property (readonly, nonatomic) UInt32 lastFFTFrameIndex;                   // Index of the last FFT frame received
@property (readonly, nonatomic) UInt32 droppedFrames;                       // Count of dropped FFT frames due to out of sequence
@property (weak, nonatomic) id <PanafallData> delegate;                     // delegate for this option
@property (nonatomic) dispatch_queue_t runQueue;                            // Run queue for this panafall


@end

