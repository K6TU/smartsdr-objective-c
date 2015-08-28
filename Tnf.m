//
//  Tnf.m
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
#import "Tnf.h"
#import "Radio.h"

@interface Tnf()

// TNF ID number
@property (nonatomic, readwrite) uint ID;
// Radio object to which this Tnf belongs
@property (weak, nonatomic, readwrite) Radio *radio;
// Pointer to private run queue for Tnf
@property (strong, nonatomic) dispatch_queue_t tnfRunQueue;
// tnfToken enum values
@property (strong, nonatomic) NSDictionary *tnfTokens;

@end


typedef NS_ENUM(int, TnfToken) {
    tnfNullToken = 0,
    depth,
    frequency,
    permanent,
    width
};


@implementation Tnf

#pragma mark - Public methods

//
// Designated initializer
//
- (id)initWithRadio:(Radio *) radio ID:(uint)ID freq:(double)freq depth:(uint)depth width:(double)width permanent:(BOOL)permanent  {
    self = [super init];
    
    _radio = radio;
    _ID = ID;
    _frequency = freq;
    _depth = depth;
    _width = width;
    _permanent = permanent;
    
    [self inittnfTokens];

    _tnfRunQueue = dispatch_queue_create("net.k6tu.tnf", DISPATCH_QUEUE_SERIAL);

    return self;
}
//
// Convenience initializers
//
- (id)initWithRadio:(Radio *)radio ID:(uint)ID freq:(double)freq {
    self = [self initWithRadio:radio ID:ID freq:freq depth:0 width:0 permanent:NO];
    return self;
}

- (id)initWithRadio:(Radio *)radio ID:(uint)ID {
    self = [self initWithRadio:radio ID:ID freq:0 depth:0 width:0 permanent:NO];
    return self;
}

- (void) removeWithCommands:(BOOL)sendCommands {
    if (sendCommands) {
        // tell the Radio (hardware)
        NSString *cmd = [NSString stringWithFormat:@"tnf remove %i", _ID];
        [_radio commandToRadio:cmd];
    }
    // tell the Radio (class) to remove me from the tnfs collection
    [_radio removeTnf: self];
}

#pragma mark - Setters

// Private macro to improve readibility of setters

#define commandUpdateNotify(cmd, key, ivar, value) \
/* Let observers know the change on the main queue */ \
[self willChangeValueForKey:(key)]; \
(ivar) = (value); \
[self didChangeValueForKey:(key)]; \
\
__weak Tnf *safeSelf = self; \
dispatch_async(self.tnfRunQueue, ^(void) { \
/* Send the command to the radio on our private queue */ \
[safeSelf.radio commandToRadio:(cmd)]; \
});

- (void) setDepth:(uint)depth {
    
    if (_depth != depth) {
        // validate the depth
        if (depth > 3 || depth < 1) {return; }
        NSString *cmd = [NSString stringWithFormat:@"tnf set %i depth=%i", _ID, depth];
        commandUpdateNotify(cmd, @"depth", _depth, depth);
    }
}

- (void) setFrequency:(double)frequency {
    
    if (_frequency != frequency) {
        NSString *cmd = [NSString stringWithFormat:@"tnf set %i freq=%0.6f", _ID, frequency];
        commandUpdateNotify(cmd, @"frequency", _frequency, frequency);
    }
}

- (void) setPermanent:(BOOL)permanent {
    
    if (_permanent != permanent) {
        NSString *cmd = [NSString stringWithFormat:@"tnf set %i permanent=%i", _ID, permanent ? 1 : 0];
        commandUpdateNotify(cmd, @"permanent", _permanent, permanent);
    }
}

- (void) setWidth:(double)width {
    if (_width != width) {
        // validate the width
        if (width > 6000 * 1e-6 || width < 5 * 1e-6) {return; }
        NSString *cmd = [NSString stringWithFormat:@"tnf set %i width=%f", _ID, width];
        commandUpdateNotify(cmd, @"width", _width, width);
    }
}

- (void) setRadioAck:(BOOL)radioAck {
    if (_radioAck != radioAck) {
        [self willChangeValueForKey:@"radioAck"];
        _radioAck = radioAck;
        [self didChangeValueForKey:@"radioAck"];
    }
}

#pragma mark - RadioParser protocol methods

// Private Macro to perform inline update on an ivar with KVO notification

#define updateWithNotify(key,ivar,value)  \
{    \
__weak Tnf *safeSelf = self; \
dispatch_async(dispatch_get_main_queue(), ^(void) { \
[safeSelf willChangeValueForKey:(key)]; \
(ivar) = (value); \
[safeSelf didChangeValueForKey:(key)]; \
}); \
}

//
// Parse Tnf tokens
//      called on the GCD thread associated with the GCD tcpSocketQueue
//
//      format: <apiHandle>|tnf <tnfNumber> <key=value>,<key=value>,...<key=value>
//
//      scan is initially at scanLocation = 15, start of the <key=value> pairs
//      "<apiHandle>|tnf <tnfNumber> " has already been processed
//
- (void) statusParser:(NSScanner *)scan  selfStatus:(BOOL)selfStatus {

    // get the remaininder of the line
    NSString *all;
    [scan scanUpToString:@"\n" intoString:&all];
    // get an array of the <key=value> pairs
    NSArray *fields;
    fields = [all componentsSeparatedByString:@" "];
    // for each <key=value> pair
    for (NSString *f in fields) {
        NSArray *kv = [f componentsSeparatedByString:@"="];
        NSString *k = kv[0];        // key
        NSString *v = kv[1];        // value

        NSInteger tokenVal = [self.tnfTokens[k] integerValue];
        switch (tokenVal) {
            case depth:
                updateWithNotify(@"depth", _depth, [v intValue]);
                break;
            case frequency:
                updateWithNotify(@"frequency", _frequency, [v doubleValue]);
                break;
            case permanent:
                updateWithNotify(@"permanent", _permanent, [v boolValue]);
                break;
            case width:
                updateWithNotify(@"width", _width, [v doubleValue]);
                break;
        }
    }
    // when fully initialized, tell Radio to add this TNF to Radio's tnfs collection
    if (_ID != 0 && _width != 0 && _frequency != 0 && _depth != 0) {
        _radioAck = YES;
        [_radio addTnf: self];
    }
}

#pragma mark - Private methods

- (void) inittnfTokens {
    self.tnfTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                      [NSNumber numberWithInteger:depth], @"depth",
                      [NSNumber numberWithInteger:frequency], @"frequency",
                      [NSNumber numberWithInteger:permanent], @"permanent",
                      [NSNumber numberWithInteger:width], @"width",
                      nil];
}

@end
