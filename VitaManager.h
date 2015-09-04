//
//  VitaManager.h
//  VITA Engine
//
//  Created by STU PHILLIPS on 2/6/15.
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
#import "VITA.h"

//
// VitaManager is the model supporting all VITA encoded data streams from a
// Flex 6000 series radio EXCEPT the Radio Discovery stream (see RadioFactory).
//


// Protocol definitions
@class VitaManager;

@protocol VitaStreamHandler
- (void) streamHandler:(VITA *) vitaPacket;
@end

@protocol VitaManagerMeterUpdate
- (void) updateMeter:(long int) value;
@end

@interface VitaManager : NSObject

@property (readonly, nonatomic) NSInteger vitaPort;                     // The UDP port on which this VitaManager is expecting streams
@property (weak, readonly, nonatomic) Radio *radio;                     // The radio on which we are receiving streams
@property (nonatomic) DDLogLevel debugLogLevel;                         // Set for level of debugging


// handleRadio initiates the VitaManager for the specified radio
// On success, returns YES after which the vitaPort property provides the port to
// which streams should be directed

- (BOOL) handleRadio:(Radio *)radio;
- (void) txStreamPacket:(NSData *)vitaPacket;

@end
