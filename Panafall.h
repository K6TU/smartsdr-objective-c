//
//  Panafall.h
//  VITA Engine
//
//  Created by STU PHILLIPS on 2/4/15.
//  Copyright (c) 2015 STU PHILLIPS. All rights reserved.
//
// NOTE: THe license under which this software will be generally released
// is still under consideration.  For now, use of this software requires
// the specific approval of Stu Phillips, K6TU.

#import <Foundation/Foundation.h>
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


@interface Panafall : NSObject <RadioParser, RadioDisplay, VitaStreamHandler>

@property (weak, readonly, nonatomic) Radio *radio;                         // The Radio which owns this panadaptor
@property (strong, readonly, nonatomic) NSString *streamId;                 // Identifier of this panadapator (STRING)
@property (weak, readonly, nonatomic) Waterfall *waterfall;                 // The Waterfall linked to this panadaptor (if any)
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
@property (readonly, nonatomic) NSString *band;                             // Band encompassed by this pan (STRING)
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
@property (readonly, nonatomic) UInt32 lastFFTFrameIndex;                   // Index of the last FFT frame received
@property (readonly, nonatomic) UInt32 droppedFrames;                       // Count of dropped FFT frames due to out of sequence
@property (weak, nonatomic) id <PanafallData> delegate;                     // delegate for this option
@property (strong, nonatomic) dispatch_queue_t runQueue;                    // Run queue for this panafall


@end

