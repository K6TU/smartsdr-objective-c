//
//  Memory.h
//
//  Created by STU PHILLIPS on 8/12/15.
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

#import <Foundation/Foundation.h>
#import "Radio.h"

typedef NS_ENUM(int, FMTXOffsetDirection) {
    Down = 0,
    Simplex,
    Up
};

typedef NS_ENUM(int, FMToneMode) {
    Off = 0,
    CtcssTx
};

@interface Memory : NSObject <RadioParser, RadioDelegate>

// Radio object to which this Memory belongs
@property (weak, nonatomic, readonly) Radio *radio;

@property (nonatomic, readwrite) int index;                 // Index of this Memory
@property (nonatomic, readwrite) NSString * owner;          // Owner
@property (nonatomic, readwrite) NSString * group;          // Group
@property (nonatomic, readwrite) NSString * name;           // Name
@property (nonatomic, readwrite) double freq;               // Frequency
@property (nonatomic, readwrite) NSString * mode;           // Mode
@property (nonatomic, readwrite) int step;                  // Step
@property (nonatomic, readwrite) FMTXOffsetDirection offsetDirection;   // Up, Down, Simplex
@property (nonatomic, readwrite) double repeaterOffset;     // Offset in Hz
@property (nonatomic, readwrite) FMToneMode toneMode;       // Off, CtcssTx
@property (nonatomic, readwrite) NSString * toneValue;      //
@property (nonatomic, readwrite) BOOL squelchOn;            // Squelch enabled
@property (nonatomic, readwrite) int squelchLevel;          // Squelch level (0 - 100)
@property (nonatomic, readwrite) int rfPower;               // RfPower (0 - 100)
@property (nonatomic, readwrite) int rxFilterLow;           // Filter low (diff from cenetr in Hz)
@property (nonatomic, readwrite) int rxFilterHigh;          // Filter high (diff from cenetr in Hz)
@property (nonatomic, readwrite) BOOL radioAck;             // True if ack'ed by Radio


- (id)initWithRadio:(Radio *) radio;

- (void) remove;                                            // Remove this Memory
- (void) select;                                            // Select this memory
- (BOOL) requestMemoryFromRadio;                            // Tell Radio (hardware) to create a new Memory


@end
