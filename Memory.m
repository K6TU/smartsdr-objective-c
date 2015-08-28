//
//  Memory.m
//
//  Created by STU PHILLIPS on 8/12/15.
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

#import "Memory.h"

@interface Memory()

typedef NS_ENUM(int, MemoryToken) {
    memoryNullToken = 0,
    owner,
    group,
    freq,
    name,
    mode,
    step,
    repeater,
    repeaterOffset,
    toneMode,
    toneValue,
    squelch,
    squelchLevel,
    rfPower,
    rxFilterLow,
    rxFilterHigh,
    highlight,
    highlightColor
};

// Memory ID number
@property (nonatomic, readwrite) uint ID;
// Radio object to which this Memory belongs
@property (weak, nonatomic, readwrite) Radio *radio;
// Pointer to private run queue for Memory
@property (strong, nonatomic) dispatch_queue_t memoryRunQueue;
// memoryToken enum values
@property (strong, nonatomic) NSDictionary *memoryTokens;

@end


@implementation Memory

#pragma mark - Public methods

//
// Designated initializer
//
- (id)initWithRadio:(Radio *) radio {
    self = [super init];
    
    _radio = radio;
    _index = -1;
    
    [self initMemoryTokens];
    
    _memoryRunQueue = dispatch_queue_create("net.k6tu.memory", DISPATCH_QUEUE_SERIAL);
    
    return self;
}
//
// Tell the Radio (hardware) to remove this Memory
//
- (void) remove {
    if (_radio != nil && _index > 0) {
        [_radio commandToRadio: [NSString stringWithFormat:@"memory remove %i", _index]];
    }
}
//
// Tell the Radio (hardware) to select this Memory
//
- (void) select {
    if (_radio != nil && _index > 0) {
        [_radio commandToRadio: [NSString stringWithFormat:@"memory apply %i", _index]];
    }
}
//
// Tell the Radio (hardware) to create a new Memory
//
//      The sequence of events is as follows:
//          Client creates an instance of Memory
//          Client calls this method on the newly created Memory instance
//          Radio (hardware) replies  with a Memory index
//                  (R<seqNumber>|<errorCode>|<memoryIndex>)
//          Radio (hardware) replies with a Status message
//                  (S<apiHandle>|memory <memoryIndex> <key=value>,<key=value>,...<key=value>
//          Memory is created with values from the Radio's current parameters
//
- (BOOL) requestMemoryFromRadio {
    // check to see if this object has already been activated
    if (_radioAck) { return NO; }
    // check to ensure this object is tied to a radio object
    if (_radio == nil) { return NO; }
    // check to make sure the radio is connected
//    if ([_radio radioConnectionState] != connected) { return NO; }
    // check that a duplicate memory item is not being added
    // when index != -1, an index has already been assigned
    // from the radio and we know that it is not a new memory
    if (_index != -1) { return NO; }
    // send the command to the radio to create the object
    // register for a Reply callback (to radioCommandResponse:(uint) seqNum response:(NSString *) response)
    [_radio commandToRadio:@"memory create" notify: self];
    
    return YES;
}

#pragma mark - Setters

// Private macro to improve readibility of setters

#define commandUpdateNotify(cmd, key, ivar, value) \
/* Let observers know the change on the main queue */ \
[self willChangeValueForKey:(key)]; \
(ivar) = (value); \
[self didChangeValueForKey:(key)]; \
\
__weak Memory *safeSelf = self; \
dispatch_async(self.memoryRunQueue, ^(void) { \
/* Send the command to the radio on our private queue */ \
[safeSelf.radio commandToRadio:(cmd)]; \
});

- (void) setOwner:(NSString *)owner {

    if (![_owner isEqualToString: owner]) {
        _owner = owner;
        if (_index >= 0) {
            owner = [owner stringByReplacingOccurrencesOfString:@" " withString:[NSString stringWithFormat: @"%C", 0x007f]];
            NSString *cmd = [NSString stringWithFormat:@"memory set %i owner=%@", _index, owner];
            commandUpdateNotify(cmd, @"owner", _owner, owner);
        }
    }
}

- (void) setGroup:(NSString *)group {
    
    if (![_group isEqualToString: group]) {
        _group = group;
        if (_index >= 0) {
            group = [group stringByReplacingOccurrencesOfString:@" " withString:[NSString stringWithFormat: @"%C", 0x007f]];
            NSString *cmd = [NSString stringWithFormat:@"memory set %i group=%@", _index, group];
            commandUpdateNotify(cmd, @"group", _group, group);
        }
    }
}

- (void) setName:(NSString *)name {
    
    if (![_name isEqualToString: name]) {
        _name = name;
        if (_index >= 0) {
            name = [name stringByReplacingOccurrencesOfString:@" " withString:[NSString stringWithFormat: @"%C", 0x007f]];
            NSString *cmd = [NSString stringWithFormat:@"memory set %i name=%@", _index, name];
            commandUpdateNotify(cmd, @"name", _name, name);
        }
    }
}

- (void) setFreq:(double)freq {
    
    if (_freq != freq) {
        _freq = freq;
        if (_index >= 0) {
            NSString *cmd = [NSString stringWithFormat:@"memory set %i freq=%0.6f", _index, freq];
            commandUpdateNotify(cmd, @"freq", _freq, freq);
        }
    }
}

- (void) setMode:(NSString *)mode {
    
    if (![_mode isEqualToString: mode]) {
        _mode = mode;
        if (_index >= 0) {
            NSString *cmd = [NSString stringWithFormat:@"memory set %i mode=%@", _index, mode];
            commandUpdateNotify(cmd, @"mode", _mode, mode);
        }
    }
}

- (void) setStep:(int)step {
    
    if (_step != step) {
        _step = freq;
        if (_index >= 0) {
            NSString *cmd = [NSString stringWithFormat:@"memory set %i step=%i", _index, step];
            commandUpdateNotify(cmd, @"step", _step, step);
        }
    }
}

- (void) setOffsetDirection:(enum FMTXOffsetDirection)offsetDirection {
    
    if (_offsetDirection != offsetDirection) {
        _offsetDirection = offsetDirection;
        if (_index >= 0) {
            NSString * dir = [self fmtxOffsetDirectionToString: offsetDirection];
            NSString *cmd = [NSString stringWithFormat:@"memory set %i repeater=%@", _index, dir];
            commandUpdateNotify(cmd, @"offsetDirection", _offsetDirection, offsetDirection);
        }
    }
}

- (void) setRepeaterOffset:(double)repeaterOffset {
    
    if (_repeaterOffset != repeaterOffset) {
        _repeaterOffset = repeaterOffset;
        if (_index >= 0) {
            NSString *cmd = [NSString stringWithFormat:@"memory set %i repeater_offset=%0.6f", _index, repeaterOffset];
            commandUpdateNotify(cmd, @"repeaterOffset", _repeaterOffset, repeaterOffset);
        }
    }
}

- (void) setToneMode:(enum FMToneMode)toneMode {
    
    if (_toneMode != toneMode) {
        _toneMode = toneMode;
        if (_index >= 0) {
            NSString * mode = [self fmToneModeToString: toneMode];
            NSString *cmd = [NSString stringWithFormat:@"memory set %i tone_mode=%@", _index, mode];
            commandUpdateNotify(cmd, @"toneMode", _toneMode, toneMode);
        }
    }
}

- (void) setToneValue:(NSString *)toneValue {
    
    if (![_toneValue isEqualToString: toneValue]) {
        _toneValue = toneValue;
        
        // validate the Tone value
        if (_toneMode != CtcssTx) { return; }
        if ([toneValue floatValue] < 0.0 || [toneValue floatValue] > 300.0 ) { return; }
        if (_index >= 0) {
            NSString *cmd = [NSString stringWithFormat:@"memory set %i tone_value=%@", _index, toneValue];
            commandUpdateNotify(cmd, @"toneValue", _toneValue, toneValue);
        }
    }
}

- (void) setSquelchOn:(BOOL)squelchOn {
    
    if (_squelchOn != squelchOn) {
        _squelchOn = squelchOn;
        if (_index >= 0) {
            NSString *cmd = [NSString stringWithFormat:@"memory set %i squelch=%i", _index, squelchOn == YES ? 1 : 0];
            commandUpdateNotify(cmd, @"squelchOn", _squelchOn, squelchOn);
        }
    }
}

- (void) setSquelchLevel:(int)squelchLevel {
    
    int newSquelchLevel = squelchLevel;
    // override if squelchLevel is too large or too small
    if (newSquelchLevel > 100) { newSquelchLevel = 100; }
    if (newSquelchLevel < 0) { newSquelchLevel = 0; }
    
    if (_squelchLevel != newSquelchLevel) {
        // squelchLevel is being changed
        _squelchLevel = newSquelchLevel;
        if (_index >= 0) {
            NSString *cmd = [NSString stringWithFormat:@"memory set %i squelch_level=%i", _index, newSquelchLevel];
            commandUpdateNotify(cmd, @"squelchLevel", _squelchLevel, newSquelchLevel);
        }
    } else if (newSquelchLevel != squelchLevel) {
        // squelchLevel was overridden but did not change the existing value
        [self didChangeValueForKey:@"squelchLevel"];
    }
}

- (void) setRfPower:(int)rfPower {
    
    int newRfPower = rfPower;
    // override if rfPower is too large or too small
    if (newRfPower > 100) { newRfPower = 100; }
    if (newRfPower < 0) { newRfPower = 0; }
    
    if (_rfPower != newRfPower) {
        // rfPower is being changed
        _rfPower = newRfPower;
        if (_index >= 0) {
            NSString *cmd = [NSString stringWithFormat:@"memory set %i power=%i", _index, newRfPower];
            commandUpdateNotify(cmd, @"rfPower", _rfPower, newRfPower);
        }
    } else if (newRfPower != rfPower) {
        // rfPower was overridden but did not change the existing value
        [self didChangeValueForKey:@"rfPower"];
    }
}

- (void) setRxFilterLow:(int)rxFilterLow {
    
    int newRxFilterLow = rxFilterLow;
    // override if rxFilterLow is too large or too small
    if (newRxFilterLow > _rxFilterHigh - 10) { newRxFilterLow = _rxFilterHigh - 10; }
    if ([_mode isEqualToString:@"LSB"] || [_mode isEqualToString:@"DIGL"]) {
        if (newRxFilterLow < -12000) { newRxFilterLow = -12000;}
    } else if ([_mode isEqualToString:@"CW"]) {
        if (newRxFilterLow < -12000 - [_radio.cwPitch intValue]) {
            newRxFilterLow = -12000 - [_radio.cwPitch intValue];
        }
    } else if ([_mode isEqualToString:@"DSB"] || [_mode isEqualToString:@"AM"] ||
               [_mode isEqualToString:@"SAM"] || [_mode isEqualToString:@"FM"] ||
               [_mode isEqualToString:@"NFM"] || [_mode isEqualToString:@"DFM"]) {
        if (newRxFilterLow < -12000) { newRxFilterLow = -12000;}
        if (newRxFilterLow > -10) { newRxFilterLow = -10;}

    } else if([_mode isEqualToString:@"USB"] || [_mode isEqualToString:@"DIGU"]) {
        if (newRxFilterLow < 0) { newRxFilterLow = 0;}
    } else {
        if (newRxFilterLow < 0) { newRxFilterLow = 0;}
    }
    
    if (_rxFilterLow != newRxFilterLow) {
        // rxFilterLow is being changed
        _rxFilterLow = newRxFilterLow;
        if (_index >= 0) {
            NSString *cmd = [NSString stringWithFormat:@"memory set %i rx_filter_low=%i", _index, newRxFilterLow];
            commandUpdateNotify(cmd, @"rxFilterLow", _rxFilterLow, newRxFilterLow);
        }
    } else if (newRxFilterLow != _rxFilterLow) {
        // rxFilterLow was overridden but did not change the existing value
        [self didChangeValueForKey:@"rxFilterLow"];
    }
}

- (void) setRxFilterHigh:(int)rxFilterHigh {
    
    int newRxFilterHigh = rxFilterHigh;
    // override if rxFilterHigh is too large or too small
    if (newRxFilterHigh > _rxFilterLow + 10) { newRxFilterHigh = _rxFilterLow + 10; }
    if ([_mode isEqualToString:@"LSB"] || [_mode isEqualToString:@"DIGL"]) {
        if (newRxFilterHigh > 0) { newRxFilterHigh = 0;}
    } else if ([_mode isEqualToString:@"CW"]) {
        if (newRxFilterHigh > 12000 - [_radio.cwPitch intValue]) {
            newRxFilterHigh = 12000 - [_radio.cwPitch intValue];
        }
    } else if ([_mode isEqualToString:@"DSB"] || [_mode isEqualToString:@"AM"] ||
               [_mode isEqualToString:@"SAM"] || [_mode isEqualToString:@"FM"] ||
               [_mode isEqualToString:@"NFM"] || [_mode isEqualToString:@"DFM"]) {
        if (newRxFilterHigh > 12000) { newRxFilterHigh = 12000;}
        if (newRxFilterHigh < 10) { newRxFilterHigh = 10;}
        
    } else if([_mode isEqualToString:@"USB"] || [_mode isEqualToString:@"DIGU"]) {
        if (newRxFilterHigh > 12000) { newRxFilterHigh = 12000;}
    } else {
        if (newRxFilterHigh > 12000) { newRxFilterHigh = 12000;}
    }
    
    if (_rxFilterHigh != newRxFilterHigh) {
        // rxFilterHigh is being changed
        _rxFilterHigh = newRxFilterHigh;
        if (_index >= 0) {
            NSString *cmd = [NSString stringWithFormat:@"memory set %i rx_filter_high=%i", _index, newRxFilterHigh];
            commandUpdateNotify(cmd, @"rxFilterHigh", _rxFilterHigh, newRxFilterHigh);
        }
    } else if (newRxFilterHigh != _rxFilterHigh) {
        // rxFilterHigh was overridden but did not change the existing value
        [self didChangeValueForKey:@"rxFilterHigh"];
    }
}

- (void) setRadioAck:(BOOL)radioAck {
    if (_radioAck != radioAck) {
        [self willChangeValueForKey:@"radioAck"];
        _radioAck = radioAck;
        [self didChangeValueForKey:@"radioAck"];
        if (_radioAck) {
            [_radio onMemoryAdded:self];
        }
    }
}

#pragma mark - RadioParser protocol methods

// Private Macro to perform inline update on an ivar with KVO notification

#define updateWithNotify(key,ivar,value)  \
{    \
__weak Memory *safeSelf = self; \
dispatch_async(dispatch_get_main_queue(), ^(void) { \
[safeSelf willChangeValueForKey:(key)]; \
(ivar) = (value); \
[safeSelf didChangeValueForKey:(key)]; \
}); \
}

//
// Parse Memory tokens
//      called on the GCD thread associated with the GCD tcpSocketQueue
//
//      format: <apiHandle>|memory <memoryIndex> <key=value> <key=value> ...<key=value>
//
//      scan is initially at scanLocation = 15, start of the <key=value> pairs
//      "<apiHandle>|memory <memoryIndex> " has already been processed
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
        
        if (kv.count !=2) {continue; }
        
        NSInteger tokenVal = [self.memoryTokens[k.lowercaseString] integerValue];
        switch (tokenVal) {
            case owner:
                v = [v stringByReplacingOccurrencesOfString:[NSString stringWithFormat: @"%C", 0x007f] withString: @" "];
                updateWithNotify(@"owner", _owner, v);
                break;
            case group:
                v = [v stringByReplacingOccurrencesOfString:[NSString stringWithFormat: @"%C", 0x007f] withString: @" "];
                updateWithNotify(@"group", _group, v);
                break;
            case name:
                v = [v stringByReplacingOccurrencesOfString:[NSString stringWithFormat: @"%C", 0x007f] withString: @" "];
                updateWithNotify(@"name", _name, v);
                break;
            case freq:
                updateWithNotify(@"freq", _freq, [v doubleValue]);
                break;
            case mode:
                updateWithNotify(@"mode", _mode, v);
                break;
            case step:
                updateWithNotify(@"step", _step, [v intValue]);
                break;
            case repeater:
                updateWithNotify(@"offsetDirection", _offsetDirection, [self parseFMTXOffsetDirection: v ]);
                break;
            case repeaterOffset:
                updateWithNotify(@"repeaterOffset", _repeaterOffset, [v doubleValue]);
                break;
            case toneMode:
                updateWithNotify(@"toneMode", _toneMode, [self parseFMToneMode: v ]);
                break;
            case toneValue:
                updateWithNotify(@"toneValue", _toneValue, v);
                break;
            case squelch:
                updateWithNotify(@"squelchOn", _squelchOn, [v isEqualToString: @"1"] ? YES : NO);
                break;
            case squelchLevel:
                updateWithNotify(@"squelchLevel", _squelchLevel, [v intValue]);
                break;
            case rfPower:
                updateWithNotify(@"rfPower", _rfPower, [v intValue]);
                break;
            case rxFilterLow:
                updateWithNotify(@"rxFilterLow", _rxFilterLow, [v intValue]);
                break;
            case rxFilterHigh:
                updateWithNotify(@"rxFilterHigh", _rxFilterHigh, [v intValue]);
                break;
        }
    }
    if (!_radioAck) {
        [self setRadioAck: YES];
    }
}

#pragma mark - RadioDelegate protocol methods

//
//  Process the response to the "memory create" command (sent by requestMemoryFromRadio)
//     called on the GCD thread associated with the GCD tcpSocketQueue
//
//     response format: <sequenceNumber>|<errorResponse>|<memoryIndex>
//
- (void) radioCommandResponse:(uint) seqNum response:(NSString *) response {
    
    NSScanner *scan = [[NSScanner alloc] initWithString: response];
    
    // get the sequence number... grab it and skip the |
    NSString *seqNumAsString;
    [scan scanUpToString:@"|" intoString: &seqNumAsString];
    [scan scanString:@"|" intoString: nil];
    
    // get the response error code... grab it and skip the |
    NSString *errorNumAsString;
    [scan scanUpToString:@"|" intoString: &errorNumAsString];
    [scan scanString:@"|" intoString: nil];

    // Anything other than 0 is an error, just return
    if ([errorNumAsString intValue] != 0) { return; }
    
    // get the index assigned to this Memory
    [scan scanInt: &_index];
    
    // add this Memory to the memoryList collection
    [_radio addMemory: self];
}

#pragma mark - Private methods

- (void) initMemoryTokens {
    self.memoryTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSNumber numberWithInteger:owner], @"owner",
                         [NSNumber numberWithInteger:group], @"group",
                         [NSNumber numberWithInteger:name], @"name",
                         [NSNumber numberWithInteger:freq], @"freq",
                         [NSNumber numberWithInteger:mode], @"mode",
                         [NSNumber numberWithInteger:step], @"step",
                         [NSNumber numberWithInteger:repeater], @"repeater",
                         [NSNumber numberWithInteger:repeaterOffset], @"repeater_offset",
                         [NSNumber numberWithInteger:toneMode], @"tone_mode",
                         [NSNumber numberWithInteger:toneValue], @"tone_value",
                         [NSNumber numberWithInteger:squelch], @"squelch",
                         [NSNumber numberWithInteger:squelchLevel], @"squelch_level",
                         [NSNumber numberWithInteger:rfPower], @"power",
                         [NSNumber numberWithInteger:rxFilterLow], @"rx_filter_low",
                         [NSNumber numberWithInteger:rxFilterHigh], @"rx_filter_high",
                         [NSNumber numberWithInteger:highlight], @"highlight",
                         [NSNumber numberWithInteger:highlightColor], @"highlight_color",
                         nil];
}
//
// Return a string version of a FMTXOffsetDirection enum value
//
- (NSString *) fmtxOffsetDirectionToString:(enum FMTXOffsetDirection) dir {
    NSString *returnValue = @"";
    switch (dir) {
        case Down:
            returnValue = @"down";
            break;
        case Simplex:
            returnValue = @"simplex";
            break;
        case Up:
            returnValue = @"up";
            break;
    }
    return returnValue;
}
//
// Return an FMTXOffsetDirection enum value for a string
//
- (enum FMTXOffsetDirection) parseFMTXOffsetDirection:( NSString *)s {
    
    s = s.lowercaseString;
    if ([s isEqualToString: @"down"]) {
        return Down;
    } else if ([s isEqualToString: @"simplex"]) {
        return Simplex;
    } else if ([s isEqualToString: @"up"]) {
        return Up;
    } else {
        return Simplex;
    }
}
//
// Return a string version of a FMToneMode enum value
//
- (NSString *) fmToneModeToString:(enum FMToneMode) mode {
    NSString *returnValue = @"";
    switch (mode) {
        case Off:
            returnValue = @"off";
            break;
        case CtcssTx:
            returnValue = @"ctcss_tx";
            break;
    }
    return returnValue;
}
//
// Return an FMToneMode enum value for a string
//
- (enum FMToneMode) parseFMToneMode:( NSString *)s {
    
    s = s.lowercaseString;
    if ([s isEqualToString: @"off"]) {
        return Off;
    } else if ([s isEqualToString: @"ctcss_tx"]) {
        return CtcssTx;
    } else {
        return Off;
    }
}

@end
