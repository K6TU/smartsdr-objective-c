//
//  Cwx.m
//
//  Created by STU PHILLIPS on 7/7/15.
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
#import "Cwx.h"
#import "Slice.h"

#define MAX_CWX_DELAY_MS 2000
#define MAX_CWX_SPEED 100
#define MAX_NUMBER_OF_MACROS 12
#define MIN_CWX_SPEED 5


@interface Cwx()

// Radio object to which this Cwx belongs
@property (weak, nonatomic, readwrite) Radio *radio;
// Pointer to private run queue for Cwx
@property (strong, nonatomic) dispatch_queue_t cwxRunQueue;
// Array of strings
@property (nonatomic, readwrite) NSMutableArray *macros;

@property (strong, nonatomic) NSDictionary *cwxTokens;


@end


enum cwxToken {
    cwxNullToken=0,
    breakinDelay,
    eraseSent,
    macro,
    sent,
    wpm,
};


@implementation Cwx

- (id)initWithRadio:(Radio *) radio {
    self = [super init];
    
    self.radio = radio;
    // populate the Macros array with empty strings
    self.macros = [[NSMutableArray alloc] initWithCapacity:MAX_NUMBER_OF_MACROS];
    for (int i=0 ; i < MAX_NUMBER_OF_MACROS ; i++) {
        [_macros addObject: @""];
    }
    [self initcwxTokens];
    
    _cwxRunQueue = dispatch_queue_create("net.k6tu.cwx", DISPATCH_QUEUE_SERIAL);
    
    return self;
}



- (void) initcwxTokens {
  self.cwxTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                          [NSNumber numberWithInteger:breakinDelay], @"break_in_delay",
                          [NSNumber numberWithInteger:eraseSent], @"erase",
                          [NSNumber numberWithInteger:macro], @"macro",
                          [NSNumber numberWithInteger:sent], @"sent",
                          [NSNumber numberWithInteger:wpm], @"wpm",
                          nil];
}

// Private macro to improve readibility of setters

#define commandUpdateNotify(cmd, key, ivar, value) \
/* Let observers know the change on the main queue */ \
[self willChangeValueForKey:(key)]; \
(ivar) = (value); \
[self didChangeValueForKey:(key)]; \
\
__weak Cwx *safeSelf = self; \
dispatch_async(self.cwxRunQueue, ^(void) { \
/* Send the command to the radio on our private queue */ \
[safeSelf.radio commandToRadio:(cmd)]; \
});


- (void) setDelay:(int)delay {
    if (delay < 0) delay = 0;
    if (delay > MAX_CWX_DELAY_MS) delay = MAX_CWX_DELAY_MS;
//    if (_delay == delay) return;
    
    NSString *cmd = [NSString stringWithFormat:@"cwx delay %i", delay];
    
    commandUpdateNotify(cmd, @"delay", _delay, delay);
}


- (void) setSpeed:(int)speed {
    if (speed < MIN_CWX_SPEED) speed = MIN_CWX_SPEED;
    if (speed > MAX_CWX_SPEED) speed = MAX_CWX_SPEED;
//    if (_speed == speed) return;
    
    NSString *cmd = [NSString stringWithFormat:@"cwx wpm %i", speed];
    
    commandUpdateNotify(cmd, @"speed", _speed, speed);
}


- (bool) setMacro:(int)index macro:(NSString *) msg {
    if (index < 0 || index > MAX_NUMBER_OF_MACROS - 1) return false;
    
    NSString *cmd = [NSString stringWithFormat:@"cwx macro save %i \"%@\"" , index + 1, msg];
    
    NSMutableArray * macrosRef = _macros;
    macrosRef[index] = msg;
    commandUpdateNotify(cmd, @"macros", _macros, macrosRef);
    return true;
}


- (bool) getMacro:(int)index macro:(NSString **)string {
    *string = @"";
    if (index < 0 || index > MAX_NUMBER_OF_MACROS - 1) return false;
    *string = (NSString *)_macros[index];
    return true;
}


- (int) sendMacro:(int) index {
    if (index < 0 || index > MAX_NUMBER_OF_MACROS - 1) return 0;
    NSString *cmd = [NSString stringWithFormat:@"cwx macro send %i", index + 1];
    return [_radio commandToRadio:cmd notify:self];
}


- (void) clearBuffer {
    [_radio commandToRadio:@"cwx clear"];
}


- (void) erase:(int)numberOfChars {
    NSString *cmd = [NSString stringWithFormat:@"cwx erase %i", numberOfChars];
    [_radio commandToRadio:cmd ];
}


- (void) send:(NSString *) string {
    NSString *cmd = [NSString stringWithFormat:@"cwx send \"%@\"", string];
    [_radio commandToRadio:cmd];
}


- (void) send:(NSString *) string andBlock:(int) block {
    NSString *cmd = [NSString stringWithFormat:@"cwx send \"%@\" %i", string, block];
    [_radio commandToRadio:cmd];
}

//
// sendMacroCommand Response
//     called on the GCD thread associated with the GCD tcpSocketQueue
//
//     format: <sequenceNumber>|<errorResponse>|<charPos,block>
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
    if ([errorNumAsString intValue] != 0) {
        return;
    }
    
    // get the rest of the response
    NSString *remainder;
    [scan scanUpToString:@"\n" intoString:&remainder];
    
    NSArray *values = [remainder componentsSeparatedByString:@","];
    if ([values count] != 2) return;
    
    int charPos = (int)[values[0] integerValue];
    int block = (int)[values[1] integerValue];
    
    // inform the Event Handler (if any)
    if (_messageQueuedEventDelegate != nil) {
        if ([_messageQueuedEventDelegate respondsToSelector:@selector(messageQueued: bufferIndex:)]) {
            [_messageQueuedEventDelegate messageQueued: block bufferIndex: charPos ];
        }
    }
}

// Private Macro
//
// Macro to perform inline update on an ivar with KVO notification

#define updateWithNotify(key,ivar,value)  \
{    \
__weak Cwx *safeSelf = self; \
dispatch_async(dispatch_get_main_queue(), ^(void) { \
[safeSelf willChangeValueForKey:(key)]; \
(ivar) = (value); \
[safeSelf didChangeValueForKey:(key)]; \
}); \
}

//
// Cwx tokens
//     called on the GCD thread associated with the GCD tcpSocketQueue
//
//     format: <apiHandle>|cwx <key=value> <key=value> ...<key=value>
//
//     scan is initially at scanLocation = 13, start of the first <key=value>
//     "<apiHandle>|cwx " has already been processed
//
- (void) statusParser:(NSScanner *)scan  selfStatus:(BOOL)selfStatus {

    // get the remaininder of the line
    NSString *all;
    [scan scanUpToString:@"\n" intoString:&all];
    
    // We could have spaces inside quotes, so we have to convert them to something else for the split.
    // We could also have an equal sign '=' (for Prosign BT) inside the quotes, so we're converting to a '*' so that the split on "="
    // will still work.  This will prevent the character '*' from being stored in a macro.  Using the ascii byte for '=' will not work.
    NSString *newString = @"";
    bool quotes = false;
    for (int i = 0 ; i < all.length; i++) {
        NSString *c = [all substringWithRange:NSMakeRange(i, 1)];
        if ([c isEqualToString:@"\""])
            quotes = !quotes;
        else if ([c isEqualToString:@" "] && quotes)
            newString = [newString stringByAppendingString: [NSString stringWithFormat: @"%C", 0x007f]];
        else if ([c isEqualToString:@"="] && quotes)
            newString = [newString stringByAppendingString:@"*"];
        else
            newString = [newString stringByAppendingString: c];
    }
    NSArray *fields;
    fields = [newString componentsSeparatedByString:@" "];
    
    for (NSString *f in fields) {
        NSArray *kv = [f componentsSeparatedByString:@"="];
        NSString *k = kv[0];
        NSString *v = kv[1];
        
        // is it a Macro?
        if ([k hasPrefix: @"macro"] && [k length] > 5) {
            // it's a Macro, get the index
            // Macro Indexes in Radio Messages are from 1 -> MAX_NUMBER_OF_MACROS
            // Macro Indexes for the property _macros are from 0 -> (MAX_NUMBER_OF_MACROS - 1)
            int index = [[k substringFromIndex: 5] intValue];
            // ignore invalid indexes
            if (index < 1 || index > MAX_NUMBER_OF_MACROS) continue ;
            // fixup the macro string
            newString = @"";
            for (int i = 0 ; i < v.length; i++) {
                NSString *c = [v substringWithRange:NSMakeRange(i, 1)];
                if ([c isEqualToString:[NSString stringWithFormat: @"%C", 0x007f]])
                    newString = [newString stringByAppendingString: @" "];
                else if ([c isEqualToString:@"*"])
                    newString = [newString stringByAppendingString: @"="];
                else
                    newString = [newString stringByAppendingString: c];
            }
            // update the Macro
            NSMutableArray * macrosRef = _macros;
            macrosRef[index-1] = newString;
            updateWithNotify(@"macros", _macros, macrosRef);
            
        } else {
            // Something other than a Macro
            NSInteger tokenVal = [self.cwxTokens[k] integerValue];
            
            NSArray *ss;
            
            switch (tokenVal) {
                case breakinDelay:
                    updateWithNotify(@"delay", _delay, (int)[v integerValue]);
                    break;
                    
                case eraseSent:
                    ss = [v componentsSeparatedByString:@","];
                    if (ss.count != 2) return;
                    int start = [ss[0] intValue];
                    int stop = [ss[1] intValue];
                    // inform the Event Handler (if any)
                    if (_eraseSentEventDelegate != nil) {
                        if ([_eraseSentEventDelegate respondsToSelector:@selector(eraseSent:stop:)]) {
                            [_eraseSentEventDelegate eraseSent: start stop: stop];
                        }
                    }
                    break;
                    
                case sent:
                    // inform the Event Handler (if any)
                    if (_charSentEventDelegate != nil) {
                        if ([_charSentEventDelegate respondsToSelector:@selector(charSent:)]) {
                            [_charSentEventDelegate charSent: (int)[v integerValue]];
                        }
                    }
                    break;
                    
                case wpm:
                    updateWithNotify(@"speed", _speed, (int)[v integerValue]);
                    break;
            }
        }
    }
}

@end
