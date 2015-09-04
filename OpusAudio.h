//
//  OpusAudio.h
//  K6TU Remote
//
//  Created by STU PHILLIPS on 5/21/15.
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
#import "Radio.h"
#import "VitaManager.h"
#import "StreamFrame.h"


//
// Protocol used between stream handler and the ultimate consumer of the data
//

@protocol OpusStreamHandler

- (void) streamReceive:(StreamFrame *) frame;

@end



@interface OpusAudio : NSObject <RadioParser, RadioStreamProcessor, VitaStreamHandler>
@property (weak, readonly, nonatomic) Radio *radio;                         // The Radio which owns this audio stream
@property (strong, readonly, nonatomic) NSString *streamId;                 // Stream ID associated with this DAX instance
@property (nonatomic, readonly) BOOL opusRxStreamStopped;                   // Opus stream for RX has stopped
@property (nonatomic) BOOL rxOn;                                            // Enable remote audio
@property (nonatomic, readonly) BOOL txOn;                                  // This stream is enabled as a transmitter audio source
@property (nonatomic) int rxGain;                                           // RX gain setting - 0-100
@property (nonatomic) int txGain;                                           // TX gain setting - 0-100
@property (nonatomic, readonly) NSInteger lostPacketCount;                  // Count of lost packets in this stream
@property (nonatomic, readonly) NSInteger rxPackets;                        // Count of received packets processed
@property (nonatomic, readonly) NSInteger txPackets;                        // Count of TX packets sent
@property (nonatomic, readonly) NSInteger rxBytes;                          // Count of RX bytes received
@property (nonatomic, readonly) NSInteger txBytes;                          // Count of TX bytes sent
@property (nonatomic, readonly) NSInteger rxRate;                           // RX rate in bytes/second
@property (nonatomic, readonly) NSInteger txRate;                           // TX rate in bytes/second
@property (weak, nonatomic) id <OpusStreamHandler> delegate;                // Delegate to handle the receive stream
@property (nonatomic) dispatch_queue_t runQueue;                            // Run queue for this Opus instance
@property (nonatomic) DDLogLevel debugLogLevel;                             // Set for level of debugging


- (void) setDelegate:(id<OpusStreamHandler>)delegate runQueue:(dispatch_queue_t) runQueue;
- (void) streamSend:(NSData *) frame;
- (id) initWithRadio:(Radio *)radio streamId:(NSString *) streamId;
- (void) closeStream;

@end
