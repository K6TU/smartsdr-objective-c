//
//  Cwx.h
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

#import "Radio.h"

@protocol MessageEventHandler <NSObject>

@optional
- (void) messageQueued:(int)sequence bufferIndex:(int) index;
@end

@protocol CharSentEventHandler <NSObject>

@optional
- (void) charSent:(int) index;
@end

@protocol EraseSentEventHandler <NSObject>

@optional
- (void) eraseSent:(int)start stop:(int) stop;
@end



@interface Cwx : NSObject <RadioParser, RadioDelegate>

@property (nonatomic) id<MessageEventHandler> messageQueuedEventDelegate;
@property (nonatomic) id<CharSentEventHandler> charSentEventDelegate;
@property (nonatomic) id<EraseSentEventHandler> eraseSentEventDelegate;

// Radio object to which this Cwx belongs
@property (strong, nonatomic, readonly) Radio *radio;

@property (nonatomic) int delay;
@property (nonatomic, readonly) NSMutableArray *macros;
@property (nonatomic) int speed;


- (id)initWithRadio:(Radio *) radio;
- (bool) setMacro:(int)index macro:(NSString *) msg;
- (int) sendMacro:(int) index;
- (void) clearBuffer;
- (void) erase:(int)numberOfChars;
- (double) getTxFrequency;
- (void) send:(NSString *) string;
- (void) send:(NSString *) string andBlock:(int) block;


@end