//
//  Meter.m
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

#import "Meter.h"

@interface Meter ()
@property (weak, readwrite, nonatomic) Radio *radio;                         // The Radio which owns this panadaptor
@property (readwrite, nonatomic) int sliceNum;                               // Number of the slice to which this meter belongs
@property (readwrite, nonatomic) enum meterSource meterSource;               // Internal origin of this meter in the radio
@property (readwrite, nonatomic) int meter;                                  // Meter number (INT)
@property (readwrite, nonatomic) NSString *shortName;                        // Short name for the meter
@property (strong, readwrite, nonatomic) NSString *meterDescription;         // Text description of meter
@property (readwrite, nonatomic) Float32 low;                                // Low level of meter
@property (readwrite, nonatomic) Float32 high;                               // High level of meter
@property (readwrite, nonatomic) enum meterUnits units;                      // Meter units
@property (strong, readwrite, nonatomic) NSString *unitsLabel;               // Meter units in human readable form
@property (readwrite, nonatomic) int fps;                                    // Meter updates in frames per second
@property (readwrite, nonatomic) Float32 value;                              // Scaled meter value

@property (strong, nonatomic) NSDictionary *meterTokens;                     // Tokens for the meter parser
@end


static DDLogLevel ddLogLevel = DDLogLevelError;


enum meterTokens {
    nullMeterToken = 0,
    srcToken,
    numToken,
    namToken,
    lowToken,
    hiToken,
    descToken,
    unitToken,
    fpsToken,
};




@implementation Meter


- (void) initMeterTokens {
    self. meterTokens = [[NSDictionary alloc]initWithObjectsAndKeys:
                         [NSNumber numberWithInteger:srcToken], @"src",
                         [NSNumber numberWithInteger:numToken], @"num",
                         [NSNumber numberWithInteger:namToken], @"nam",
                         [NSNumber numberWithInteger:lowToken], @"low",
                         [NSNumber numberWithInteger:hiToken], @"hi",
                         [NSNumber numberWithInteger:descToken], @"desc",
                         [NSNumber numberWithInteger:unitToken], @"unit",
                         [NSNumber numberWithInteger:fpsToken], @"fps",
                         nil];
}

- (id) init {
    self = [super init];
    [self initMeterTokens];
    return self;
}


- (void) dealloc {
    self.meterTokens = nil;
    self.meterDescription = nil;
    self.unitsLabel = nil;
}


- (void) updateMeter:(long)value {
    Float32 scaled_value = value;
    
    switch (self.units) {
        case voltUnits:
        case ampUnits:
            scaled_value /= 1024.0;
            break;
            
        case swrUnits:
        case dbmUnits:
        case dbfsUnits:
            scaled_value /= 128.0;
            break;
            
        case degreeUnits:
            scaled_value /= 64.0;
            break;
            
        default:
            break;
    }
    
    self.value = scaled_value;
}


- (void) setupMeter:(Radio *)radio scan:(NSScanner *) scan {
    // Set up our properties
    self.radio = radio;
    self.debugLogLevel = radio.debugLogLevel;
    
    // Split the meter into key=value fields, then separate into key and value based on = delimiter
    NSString *all;
    [scan scanUpToString:@"\n" intoString:&all];
    NSArray *kv = [all componentsSeparatedByString:@"#"];
    
    for (int i = 0; i < [kv count] - 1; i++) {
        NSString *s = kv[i];
        
        // s is of the form <num>.<key>=<value>
        NSArray *kAndV = [s componentsSeparatedByString:@"="];
        NSArray *kFields = [kAndV[0] componentsSeparatedByString:@"."];
        NSInteger num = [kFields[0] integerValue];
        NSString *key = kFields[1];
        NSString *value = kAndV[1];
        NSInteger tokenVal = [self.meterTokens[key] integerValue];
        
        self.meter = (int)num;
        
        switch (tokenVal) {
            case srcToken:
                if ([value isEqualToString:@"TX-"])
                    self.meterSource = txSource;
                else if ([value isEqualToString:@"COD-"])
                    self.meterSource = codecSource;
                else if ([value isEqualToString:@"RAD"])
                    self.meterSource = radioSource;
                else if ([value isEqualToString:@"SLC"])
                    self.meterSource = sliceSource;
                else {
                    DDLogError(@"Unknown meter source in setupMeter (src=%@)", value);
                    self.meterSource = nullSource;
                }
                
                break;
                
            case numToken:
                if (self.meterSource == sliceSource) {
                    // num is the number of the slice for which this meter belongs
                    // The slice is identified by the value of the num field
                    self.sliceNum = (int)[value integerValue];
                }
                
                // For all other meters, we don't appear to need this field as its just a sub identifier under
                // the meter number in self.meter
                
                break;
                
            case namToken:
                // Internal meter name
                self.shortName = value;
                break;
                
            case lowToken:
                self.low = [value floatValue];
                break;
                
            case hiToken:
                self.high = [value floatValue];
                break;
                
            case descToken:
                self.meterDescription = value;
                break;
                
            case unitToken:
                self.unitsLabel = value;
                
                if ([value isEqualToString:@"dBFS"])
                    self.units = dbfsUnits;
                else if ([value isEqualToString:@"Volts"])
                    self.units = voltUnits;
                else if ([value isEqualToString:@"Amps"])
                    self.units = ampUnits;
                else if ([value isEqualToString:@"degC"])
                    self.units = degreeUnits;
                else if ([value isEqualToString:@"dBm"])
                    self.units = dbmUnits;
                else if ([value isEqualToString:@"SWR"])
                    self.units = swrUnits;
                break;
                
            case fpsToken:
                self.fps = (int)[value integerValue];
                break;
                
            default:
                DDLogVerbose(@"Unkown KV pair in meter - %@", s);
                break;
        }
    }
}


#pragma mark
#pragma mark Custom Setters

-(void) setDebugLogLevel:(DDLogLevel)debugLogLevel {
    ddLogLevel = debugLogLevel;
    _debugLogLevel = debugLogLevel;
}

@end

