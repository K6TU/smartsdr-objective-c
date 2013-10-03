//
//  Equalizer.h
//
//  Created by STU PHILLIPS on 9/16/13.
//  Copyright (c) 2013 STU PHILLIPS. All rights reserved.
//
// NOTE: THe license under which this software will be generally released
// is still under consideration.  For now, use of this software requires
// the specific approval of Stu Phillips, K6TU.
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

@interface Equalizer : NSObject

// Radio object to which this Equalizer belongs
@property (strong, nonatomic) Radio *radio;

// Type of this equalizer (rx or tx) as NSString
@property (strong, nonatomic) NSString *eqType;

// Property for each band so KVO compliant
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
- (void) cmdEqSetValue:(NSInteger) bandNum value: (NSNumber *) value;
- (void) cmdEqSetEnabled: (NSNumber *) state;
@end
