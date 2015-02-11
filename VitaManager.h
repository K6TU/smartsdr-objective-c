//
//  VitaManager.h
//  VITA Engine
//
//  Created by STU PHILLIPS on 2/6/15.
//  Copyright (c) 2015 STU PHILLIPS. All rights reserved.
//
// NOTE: THe license under which this software will be generally released
// is still under consideration.  For now, use of this software requires
// the specific approval of Stu Phillips, K6TU.
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

// handleRadio initiates the VitaManager for the specified radio
// On success, returns YES after which the vitaPort property provides the port to
// which streams should be directed

- (BOOL) handleRadio:(Radio *)radio;

@end
