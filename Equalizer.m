//
//  Equalizer.m
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

#import "Equalizer.h"

@interface Equalizer ()
@property (strong, nonatomic) NSArray *bandCmdName;
@property (strong, nonatomic) NSDictionary *statusEqTokens;

// Pointer to private run queue for Radio
@property (strong, nonatomic, readwrite) dispatch_queue_t eqRunQueue;

// Type of this equalizer (rx or tx) as NSString
@property (strong, nonatomic, readwrite) NSString *eqType;

// Radio object to which this Equalizer belongs
@property (strong, nonatomic, readwrite) Radio *radio;

- (void) initStatusEqTokens;

@end

enum enumStatusEqTokens {
    enumStatusEqTokensNone = 0,
    eqRxToken,
    eqTxToken,
    eqModeToken,
    eqBand0Token,
    eqBand1Token,
    eqBand2Token,
    eqBand3Token,
    eqBand4Token,
    eqBand5Token,
    eqBand6Token,
    eqBand7Token,
};





@implementation Equalizer

- (id) init {
    self = [super init];
    
    self.radio = nil;
    self.eqType = nil;
    
    _eqBand0Value = [NSNumber numberWithInt:0];
    _eqBand1Value = [NSNumber numberWithInt:0];
    _eqBand2Value = [NSNumber numberWithInt:0];
    _eqBand3Value = [NSNumber numberWithInt:0];
    _eqBand4Value = [NSNumber numberWithInt:0];
    _eqBand5Value = [NSNumber numberWithInt:0];
    _eqBand6Value = [NSNumber numberWithInt:0];
    _eqBand7Value = [NSNumber numberWithInt:0];
    
    _eqEnabled = [NSNumber numberWithBool:NO];
    
    self.bandCmdName = [[NSArray alloc] initWithObjects:
                        @"63Hz", @"125Hz", @"250Hz", @"500Hz",
                        @"1000Hz", @"2000Hz", @"4000Hz", @"8000Hz",
                        nil];
    [self initStatusEqTokens];
    
    // Create a private run queue for us to run on
    NSString *qName = [NSString stringWithFormat:@"net.k6tu.eqQueue-%@", self.eqType];
    self.eqRunQueue = dispatch_queue_create([qName UTF8String], NULL);
    return self;
}


- (id) initWithTypeAndRadio:(NSString *)type radio:(Radio *)radio {
    self = [super init];
    
    self.radio = radio;
    self.eqType = type;

    _eqBand0Value = [NSNumber numberWithInt:0];
    _eqBand1Value = [NSNumber numberWithInt:0];
    _eqBand2Value = [NSNumber numberWithInt:0];
    _eqBand3Value = [NSNumber numberWithInt:0];
    _eqBand4Value = [NSNumber numberWithInt:0];
    _eqBand5Value = [NSNumber numberWithInt:0];
    _eqBand6Value = [NSNumber numberWithInt:0];
    _eqBand7Value = [NSNumber numberWithInt:0];
    
    _eqEnabled = [NSNumber numberWithBool:NO];
    
    self.bandCmdName = [[NSArray alloc] initWithObjects:
                        @"63Hz", @"125Hz", @"250Hz", @"500Hz",
                        @"1000Hz", @"2000Hz", @"4000Hz", @"8000Hz",
                        nil];
    [self initStatusEqTokens];
    
    // Create a private run queue for us to run on
    NSString *qName = [NSString stringWithFormat:@"net.k6tu.eqQueue-%@", self.eqType];
    self.eqRunQueue = dispatch_queue_create([qName UTF8String], NULL);
    return self;
}


- (void) initStatusEqTokens {
    self.statusEqTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [NSNumber numberWithInt:eqRxToken], @"rx",
                           [NSNumber numberWithInt:eqTxToken], @"tx",
                           [NSNumber numberWithInt:eqModeToken], @"mode",
                           [NSNumber numberWithInt:eqBand0Token], @"63Hz",
                           [NSNumber numberWithInt:eqBand1Token], @"125Hz",
                           [NSNumber numberWithInt:eqBand2Token], @"250Hz",
                           [NSNumber numberWithInt:eqBand3Token], @"500Hz",
                           [NSNumber numberWithInt:eqBand4Token], @"1000Hz",
                           [NSNumber numberWithInt:eqBand5Token], @"2000Hz",
                           [NSNumber numberWithInt:eqBand6Token], @"4000Hz",
                           [NSNumber numberWithInt:eqBand7Token], @"8000Hz",
                           nil];
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

// Private macro to improve readibility of setters

#define commandUpdateNotify(cmd, key, ivar, value) \
    /* Let observers know the change on the main queue */ \
    [self willChangeValueForKey:(key)]; \
    (ivar) = (value); \
    [self didChangeValueForKey:(key)]; \
       \
    __weak Equalizer *safeSelf = self; \
    dispatch_async(self.eqRunQueue, ^(void) { \
        /* Send the command to the radio on our private queue */ \
        [safeSelf.radio commandToRadio:(cmd)]; \
    });


- (void) setEqBand0Value:(NSNumber *)eqBand0Value {
    if ([self.eqBand0Value isEqualToNumber:eqBand0Value])
        // No change
        return;
    
    NSString *cmd = [NSString stringWithFormat:@"eq %@ mode=%i %@=%i",
                     self.eqType, [self.eqEnabled boolValue], self.bandCmdName[0], (int)[eqBand0Value integerValue]];
    NSNumber *refValue = eqBand0Value;
    
    commandUpdateNotify(cmd, @"eqBand0Value", _eqBand0Value, refValue);
}


- (void) setEqBand1Value:(NSNumber *)eqBand1Value {
    if ([self.eqBand1Value isEqualToNumber:eqBand1Value])
        // No change
        return;  
    
    NSString *cmd = [NSString stringWithFormat:@"eq %@ mode=%i %@=%i",
                     self.eqType, [self.eqEnabled boolValue], self.bandCmdName[1], (int)[eqBand1Value integerValue]];
    NSNumber *refValue = eqBand1Value;
    
    commandUpdateNotify(cmd, @"eqBand1Value", _eqBand1Value, refValue);
}


- (void) setEqBand2Value:(NSNumber *)eqBand2Value {
    if ([self.eqBand2Value isEqualToNumber:eqBand2Value])
        // No change
        return;
    
    NSString *cmd = [NSString stringWithFormat:@"eq %@ mode=%i %@=%i",
                     self.eqType, [self.eqEnabled boolValue], self.bandCmdName[2], (int)[eqBand2Value integerValue]];
    NSNumber *refValue = eqBand2Value;
    
    commandUpdateNotify(cmd, @"eqBand2Value", _eqBand2Value, refValue);
}


- (void) setEqBand3Value:(NSNumber *)eqBand3Value {
    if ([self.eqBand3Value isEqualToNumber:eqBand3Value])
        // No change
        return;
    
    NSString *cmd = [NSString stringWithFormat:@"eq %@ mode=%i %@=%i",
                     self.eqType, [self.eqEnabled boolValue], self.bandCmdName[3], (int)[eqBand3Value integerValue]];
    NSNumber *refValue = eqBand3Value;
    
    commandUpdateNotify(cmd, @"eqBand3Value", _eqBand3Value, refValue);
}


- (void) setEqBand4Value:(NSNumber *)eqBand4Value {
    if ([self.eqBand4Value isEqualToNumber:eqBand4Value])
        // No change
        return;
    
    NSString *cmd = [NSString stringWithFormat:@"eq %@ mode=%i %@=%i",
                     self.eqType, [self.eqEnabled boolValue], self.bandCmdName[4], (int)[eqBand4Value integerValue]];
    NSNumber *refValue = eqBand4Value;
    
    commandUpdateNotify(cmd, @"eqBand4Value", _eqBand4Value, refValue);
}


- (void) setEqBand5Value:(NSNumber *)eqBand5Value {
    if ([self.eqBand5Value isEqualToNumber:eqBand5Value])
        // No change
        return;
    
    NSString *cmd = [NSString stringWithFormat:@"eq %@ mode=%i %@=%i",
                     self.eqType, [self.eqEnabled boolValue], self.bandCmdName[5], (int)[eqBand5Value integerValue]];
    NSNumber *refValue = eqBand5Value;
    
    commandUpdateNotify(cmd, @"eqBand5Value", _eqBand5Value, refValue);
}


- (void) setEqBand6Value:(NSNumber *)eqBand6Value {
    if ([self.eqBand6Value isEqualToNumber:eqBand6Value])
        // No change
        return;
    
    NSString *cmd = [NSString stringWithFormat:@"eq %@ mode=%i %@=%i",
                     self.eqType, [self.eqEnabled boolValue], self.bandCmdName[6], (int)[eqBand6Value integerValue]];
    NSNumber *refValue = eqBand6Value;
    
    commandUpdateNotify(cmd, @"eqBand6Value", _eqBand6Value, refValue);
}


- (void) setEqBand7Value:(NSNumber *)eqBand7Value {
    if ([self.eqBand7Value isEqualToNumber:eqBand7Value])
        // No change
        return;
    
    NSString *cmd = [NSString stringWithFormat:@"eq %@ mode=%i %@=%i",
                     self.eqType, [self.eqEnabled boolValue], self.bandCmdName[7], (int)[eqBand7Value integerValue]];
    NSNumber *refValue = eqBand7Value;
    
    commandUpdateNotify(cmd, @"eqBand7Value", _eqBand7Value, refValue);
}


- (void) setEqEnabled:(NSNumber *)eqEnabled {
    NSString *cmd = [NSString stringWithFormat:@"eq %@ mode=%i",
                     self.eqType,
                     [eqEnabled boolValue]];
    NSNumber *refValue = eqEnabled;
    
    commandUpdateNotify(cmd, @"eqEnabled", _eqEnabled, refValue);
}


- (void) cmdEqUpdateRadio:(Radio *) radio {
    NSString *cmd = [NSString stringWithFormat:@"eq %@ mode=%i ",
                     self.eqType,
                     [self.eqEnabled boolValue]];
    
    NSArray *bValues = [self eqBandValues];
    self.radio = radio;
    
    for (int i=0; i<EQ_NUMBER_OF_BANDS; i++) {
        NSString *apS = [NSString stringWithFormat:@"%@=%i ", self.bandCmdName[i], (int)[bValues[i] integerValue]];
        cmd = [cmd stringByAppendingString:apS];
    }
    
    [self.radio commandToRadio:cmd];
}


#pragma mark
#pragma mark Parser support 

// Private Macro
//
// Macro to perform inline update on an ivar with KVO notification

#define updateWithNotify(key,ivar,value)  \
{  \
    __weak Equalizer *safeSelf = self; \
    dispatch_async(dispatch_get_main_queue(), ^(void) { \
        [safeSelf willChangeValueForKey:(key)]; \
        (ivar) = (value); \
        [safeSelf didChangeValueForKey:key]; \
    }); \
}

- (void) statusParser:(NSScanner *)scan selfStatus:(BOOL)selfStatus {
    NSString *token;
    NSString *stringVal;
    NSInteger intVal;
    BOOL eqSc;
    
    eqSc = ([stringVal rangeOfString:@"sc"].location == NSNotFound);
    
    // First parameter after eq is rx|tx or rxsc|txsc
    // Gobble it up and discard...
    [scan scanUpToString:@" " intoString:&stringVal];
    [scan scanString:@" " intoString:nil];
    
    while (![scan isAtEnd]) {
        // Grab the token between current scanner position and the '=' separator
        // and then eat the '='
        [scan scanUpToString:@"=" intoString:&token];
        [scan scanString:@"=" intoString:nil];
        
        // Look up in our dictionary
        int thisToken = [self.statusEqTokens[token] intValue];
        
        switch (thisToken) {
            case eqModeToken:
                [scan scanInteger:&intVal];
                updateWithNotify(@"eqEnabled", _eqEnabled, [NSNumber numberWithBool:intVal]);
                break;
                
            case eqBand0Token:
                [scan scanInteger:&intVal];
                updateWithNotify(@"eqBand0Value", _eqBand0Value, [NSNumber numberWithInteger:eqSc ? intVal+10 : intVal]);
                break;
                
            case eqBand1Token:
                [scan scanInteger:&intVal];
                updateWithNotify(@"eqBand1Value", _eqBand1Value, [NSNumber numberWithInteger:eqSc ? intVal+10 : intVal]);
                break;
                
            case eqBand2Token:
                [scan scanInteger:&intVal];
                updateWithNotify(@"eqBand2Value", _eqBand2Value, [NSNumber numberWithInteger:eqSc ? intVal+10 : intVal]);
                break;
                
            case eqBand3Token:
                [scan scanInteger:&intVal];
                updateWithNotify(@"eqBand3Value", _eqBand3Value, [NSNumber numberWithInteger:eqSc ? intVal+10 : intVal]);
                break;
                
            case eqBand4Token:
                [scan scanInteger:&intVal];
                updateWithNotify(@"eqBand4Value", _eqBand4Value, [NSNumber numberWithInteger:eqSc ? intVal+10 : intVal]);
                break;
                
            case eqBand5Token:
                [scan scanInteger:&intVal];
                updateWithNotify(@"eqBand5Value", _eqBand5Value, [NSNumber numberWithInteger:eqSc ? intVal+10 : intVal]);
                break;
                
            case eqBand6Token:
                [scan scanInteger:&intVal];
                updateWithNotify(@"eqBand6Value", _eqBand6Value, [NSNumber numberWithInteger:eqSc ? intVal+10 : intVal]);
                break;
                
            case eqBand7Token:
                [scan scanInteger:&intVal];
                updateWithNotify(@"eqBand7Value", _eqBand7Value, [NSNumber numberWithInteger:eqSc ? intVal+10 : intVal]);
                break;
        }
        // Scanner is either at a space or at the end - eat either
        [scan scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"] intoString:nil];
    }

}

@end
