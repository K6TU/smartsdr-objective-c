//
//  Meter.h
//  VITA Engine
//
//  Created by STU PHILLIPS on 2/4/15.
//  Copyright (c) 2015 STU PHILLIPS. All rights reserved.
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
@property (readonly, nonatomic) int sliceNum;                         // Number of the slice owning this meter
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

@end






