//
//  Equalizer.h
//
//  Created by STU PHILLIPS on 9/16/13.
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

// Equalizer is the model for a specific equalizer in the Radio model.
// There are two equalizers in the radio - for for TX and the other for RX.

// Constants
#define EQ_NUMBER_OF_BANDS  8
#define EQ_BAND_0_NAME      @"63 Hz"
#define EQ_BAND_1_NAME      @"125 Hz"
#define EQ_BAND_2_NAME      @"250 Hz"
#define EQ_BAND_3_NAME      @"500 Hz"
#define EQ_BAND_4_NAME      @"1 KHz"
#define EQ_BAND_5_NAME      @"2 KHz"
#define EQ_BAND_6_NAME      @"4 KHz"
#define EQ_BAND_7_NAME      @"8 KHz"

// Macros
#define EQ_GAIN_TO_VAL(x)   (x + 10)
#define EQ_VAL_TO_GAIN(x)   (x - 10)

@interface Equalizer : NSObject <RadioParser>

// Pointer to private run queue for Radio
@property (nonatomic, readonly) dispatch_queue_t eqRunQueue;

// Radio object to which this Equalizer belongs
@property (strong, nonatomic, readonly) Radio *radio;

// Type of this equalizer (rx or tx) as NSString
@property (strong, nonatomic, readonly) NSString *eqType;

// Property for each band is KVO compliant
@property (strong, nonatomic) NSNumber *eqBand0Value;       // Value from 0 (-10 dB) to 20 (+10 dB) per band
@property (strong, nonatomic) NSNumber *eqBand1Value;
@property (strong, nonatomic) NSNumber *eqBand2Value;
@property (strong, nonatomic) NSNumber *eqBand3Value;
@property (strong, nonatomic) NSNumber *eqBand4Value;
@property (strong, nonatomic) NSNumber *eqBand5Value;
@property (strong, nonatomic) NSNumber *eqBand6Value;
@property (strong, nonatomic) NSNumber *eqBand7Value;

// Enabled property - BOOL
@property (strong, nonatomic) NSNumber *eqEnabled;

- (NSArray *) eqBandNames;
- (NSArray *) eqBandValues;

- (id) initWithTypeAndRadio:(NSString *) type radio:(Radio *) radio;
- (void) cmdEqUpdateRadio:(Radio *) radio;

@end
