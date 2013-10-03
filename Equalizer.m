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

- (void) cmdEqSetValue:(NSInteger)bandNum value:(NSNumber *)value {
    NSString *cmd = [NSString stringWithFormat:@"eq %@ %@=%i",
                     self.eqType,
                     self.bandCmdName[bandNum],
                     [value integerValue]];
    
    switch (bandNum) {
        case 0:     self.eqBand0Value = value;    break;
        case 1:     self.eqBand1Value = value;    break;
        case 2:     self.eqBand2Value = value;    break;
        case 3:     self.eqBand3Value = value;    break;
        case 4:     self.eqBand4Value = value;    break;
        case 5:     self.eqBand5Value = value;    break;
        case 6:     self.eqBand6Value = value;    break;
        case 7:     self.eqBand7Value = value;    break;
    }
    
    [self.radio commandToRadio:cmd];
}

- (void) cmdEqSetEnabled:(NSNumber *)state {
    NSString *cmd = [NSString stringWithFormat:@"eq %@ mode=%i",
                     self.eqType,
                     [state boolValue]];
    
    self.eqEnabled = state;
    [self.radio commandToRadio:cmd];
}

@end
