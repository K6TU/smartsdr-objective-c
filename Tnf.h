//
//  Tnf.h
//
//  Created by STU PHILLIPS on 8/6/15.
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


@class Radio;

@interface Tnf  : NSObject <RadioParser>


// Radio object to which this Cwx belongs
@property (weak, nonatomic, readonly) Radio *radio;

@property (nonatomic, readonly) uint ID;                    // unique ID number
@property (nonatomic, readwrite) double frequency;          // Frequency in MHz
@property (nonatomic, readwrite) uint depth;                // 1=Normal, 2=Deep, 3=Very Deep
@property (nonatomic, readwrite) bool permanent;            // True=Freq & Width fixed
@property (nonatomic, readwrite) bool radioAck;             // True if all properties are set
@property (nonatomic, readwrite) double width;              // Width in MHz


- (id) initWithRadio:(Radio *) radio ID:(uint)ID freq:(double)freq depth:(uint)depth width:(double)width permanent:(bool)permanent;
- (id) initWithRadio:(Radio *)radio ID:(uint)ID freq:(double)freq;
- (id) initWithRadio:(Radio *)radio ID:(uint)ID;
- (void) removeWithCommands:(bool)sendCommands;

@end
