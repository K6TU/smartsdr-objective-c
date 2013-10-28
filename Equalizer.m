//
//  Equalizer.m
//
//  Created by STU PHILLIPS on 9/16/13.
//  Copyright (c) 2013 STU PHILLIPS. All rights reserved.
//
// NOTE: THe license under which this software will be generally released
// is still under consideration.  For now, use of this software requires
// the specific approval of Stu Phillips, K6TU.
//

#import "Equalizer.h"

@interface Equalizer ()
@property (strong, nonatomic) NSArray *bandCmdName;

@end

@implementation Equalizer

- (id) init {
    if (! self)
        self = [super init];
    
    self.eqBand0Value = [NSNumber numberWithInt:0];
    self.eqBand1Value = [NSNumber numberWithInt:0];
    self.eqBand2Value = [NSNumber numberWithInt:0];
    self.eqBand3Value = [NSNumber numberWithInt:0];
    self.eqBand4Value = [NSNumber numberWithInt:0];
    self.eqBand5Value = [NSNumber numberWithInt:0];
    self.eqBand6Value = [NSNumber numberWithInt:0];
    self.eqBand7Value = [NSNumber numberWithInt:0];
    
    self.eqEnabled = [NSNumber numberWithBool:NO];
    
    self.bandCmdName = [[NSArray alloc] initWithObjects:
                        @"63Hz", @"125Hz", @"250Hz", @"500Hz",
                        @"1000Hz", @"2000Hz", @"4000Hz", @"8000Hz",
                        nil];
    
    return self;
}

- (NSArray *) eqBandNames {
    NSArray *names = [[NSArray alloc] initWithObjects:
        EQ_BAND_0_NAME, EQ_BAND_1_NAME, EQ_BAND_2_NAME, EQ_BAND_3_NAME,
        EQ_BAND_4_NAME, EQ_BAND_5_NAME, EQ_BAND_6_NAME, EQ_BAND_7_NAME,
        nil];
    
    return names;
}

- (NSArray *) eqBandValues {
    NSArray *bValues = [[NSArray alloc] initWithObjects:
                        self.eqBand0Value, self.eqBand1Value, self.eqBand2Value, self.eqBand3Value,
                        self.eqBand4Value, self.eqBand5Value, self.eqBand6Value, self.eqBand7Value,
                        nil];
    
    return bValues;
}

- (void) cmdEqSetValue:(NSInteger)bandNum value:(NSNumber *)value {
    BOOL changed = NO;
    
    switch (bandNum) {
        case 0:     changed = ![self.eqBand0Value isEqualToNumber:value]; self.eqBand0Value = value;    break;
        case 1:     changed = ![self.eqBand0Value isEqualToNumber:value]; self.eqBand1Value = value;    break;
        case 2:     changed = ![self.eqBand0Value isEqualToNumber:value]; self.eqBand2Value = value;    break;
        case 3:     changed = ![self.eqBand0Value isEqualToNumber:value]; self.eqBand3Value = value;    break;
        case 4:     changed = ![self.eqBand0Value isEqualToNumber:value]; self.eqBand4Value = value;    break;
        case 5:     changed = ![self.eqBand0Value isEqualToNumber:value]; self.eqBand5Value = value;    break;
        case 6:     changed = ![self.eqBand0Value isEqualToNumber:value]; self.eqBand6Value = value;    break;
        case 7:     changed = ![self.eqBand0Value isEqualToNumber:value]; self.eqBand7Value = value;    break;
    }
    
    if (changed)
        [self cmdEqSetEnabled:self.eqEnabled];
}

- (void) cmdEqSetEnabled:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"eq %@ mode=%i ",
                     self.eqType,
                     [state boolValue]];
    
    NSArray *bValues = [self eqBandValues];
    
    for (int i=0; i<EQ_NUMBER_OF_BANDS; i++) {
        NSString *apS = [NSString stringWithFormat:@"%@=%i ", self.bandCmdName[i], [bValues[i] integerValue]];
        cmd = [cmd stringByAppendingString:apS];
    }
    
    self.eqEnabled = state;
    [self.radio commandToRadio:cmd];
}

@end
