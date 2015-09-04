//
//  Meter.h
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

#import <Foundation/Foundation.h>
#import "Radio.h"
#import "VitaManager.h"
#import "Slice.h"



enum meterSource {
    nullSource = 0,
    codecSource,
    txSource,
    sliceSource,
    radioSource,
};

enum meterUnits {
    noUnits = 0,
    dbmUnits,
    dbfsUnits,
    swrUnits,
    voltUnits,
    ampUnits,
    degreeUnits,
};

//
// Model for a Meter associated with an object on a Flex 6000 series radio


@interface Meter : NSObject <RadioMeter, VitaManagerMeterUpdate>

@property (weak, readonly, nonatomic) Radio *radio;                         // The Radio which owns this panadaptor
@property (readonly, nonatomic) int sliceNum;                               // Number of the slice owning this meter
@property (readonly, nonatomic) enum meterSource meterSource;               // Internal origin of this meter in the radio
@property (readonly, nonatomic) int meter;                                  // Meter number (INT)
@property (readonly, nonatomic) NSString *shortName;                        // Short name for the meter
@property (strong, readonly, nonatomic) NSString *meterDescription;         // Text description of meter
@property (readonly, nonatomic) Float32 low;                                // Low level of meter
@property (readonly, nonatomic) Float32 high;                               // High level of meter
@property (readonly, nonatomic) enum meterUnits units;                      // Meter units
@property (strong, readonly, nonatomic) NSString *unitsLabel;               // Meter units in human readable form
@property (readonly, nonatomic) int fps;                                    // Meter updates in frames per second
@property (readonly, nonatomic) Float32 value;                              // Scaled meter value
@property (nonatomic) DDLogLevel debugLogLevel;                             // Set for level of debugging

@end






