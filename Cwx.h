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

@protocol CWXMessageEventHandler <NSObject>

@optional
- (void) messageQueued:(int)sequence bufferIndex:(int) index;
@end

@protocol CWXCharSentEventHandler <NSObject>

@optional
- (void) charSent:(int) index;
@end

@protocol CWXEraseSentEventHandler <NSObject>

@optional
- (void) eraseSent:(int)start stop:(int) stop;
@end



@interface Cwx : NSObject <RadioParser, RadioDelegate>

//
// The delegate handling here will be invoked on our run queue (or the TCP socket run queue more likely).
// These will NOT be called on the main dispatch queue. If there are any UI updates that are interested in the update,
// the user will have to arrange for their own dispatch onto the main queue to make the UI changes there.
//
@property (weak, nonatomic) id<CWXMessageEventHandler> messageQueuedEventDelegate;
@property (weak, nonatomic) id<CWXCharSentEventHandler> charSentEventDelegate;
@property (weak, nonatomic) id<CWXEraseSentEventHandler> eraseSentEventDelegate;

// Radio object to which this Cwx belongs
@property (weak, nonatomic, readonly) Radio *radio;

@property (nonatomic) int delay;
@property (nonatomic, readonly) NSMutableArray *macros;
@property (nonatomic) int speed;


- (id)initWithRadio:(Radio *) radio;
- (BOOL) setMacro:(int)index macro:(NSString *) msg;
- (BOOL) getMacro:(int)index macro:(NSString **)string;
- (int) sendMacro:(int) index;
- (void) clearBuffer;
- (void) erase:(int)numberOfChars;
- (void) send:(NSString *) string;
- (void) send:(NSString *) string andBlock:(int) block;


@end