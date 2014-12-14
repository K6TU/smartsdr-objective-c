//
//  VITA.h
//  VITA component of SMART-SDR Objective-C model
//
//  Created by STU PHILLIPS on 10/30/14.
//  Copyright (c) 2014 STU PHILLIPS. All rights reserved.
//
//
// NOTE: THe license under which this software will be generally released
// is still under consideration.  For now, use of this software requires
// the specific approval of Stu Phillips, K6TU.

#import <Foundation/Foundation.h>

// Enumerates for field values

enum VitaPacketType {
    IF_DATA = 0,
    IF_DATA_WITH_STREAM,
    EXT_DATA,
    EXT_DATA_WITH_STREAM,
    IF_CONTEXT,
    EXT_CONTEXT
};

enum VitaTSI {
    TSI_NONE = 0,
    TSI_UTC,
    TSI_GPS,
    TSI_OTHER
};

enum VitaTSF {
    TSF_NONE,
    TSF_SAMPLE_COUNT,
    TSF_REALTIME,
    TSF_FREERUN,
};

// Constant defines
const UInt16 FRS_OUI = 0x12cd;
const UInt16 VITA_PORT = 4991;


const UInt16 VS_Meter      = 0x8002;
const UInt16 VS_PAN_FFT    = 0x8003;
const UInt16 VS_Waterfall  = 0x8004;
const UInt16 VS_Opus       = 0x8005;

const UInt16 DAX_IQ_24Khz  = 0x00e3;
const UInt16 DAX_IQ_48Khz  = 0x00e4;
const UInt16 DAX_IQ_96Khz  = 0x00e5;
const UInt16 DAX_IQ_192KHz = 0x00e6;
const UInt16 VS_DAX_Audio  = 0x03e3;

const UInt16 VS_Discovery  = 0xffff;

@interface VITA : NSObject

@property (strong, nonatomic) NSData *buffer;
@property enum VitaPacketType packetType;
@property BOOL classIdPresent;
@property BOOL trailerPresent;
@property UInt16 tsi;
@property UInt16 tsf;
@property UInt16 packetCount;
@property UInt16 packetSize;
@property UInt32 integerTimestamp;
@property UInt32 fracTimeStamp0;
@property UInt32 fracTimeStamp1;
@property UInt32 oui;
@property UInt16 informationClassCode;
@property UInt16 packetClassCode;
@property void *payload;
@property UInt32 payloadLength;
@property UInt32 trailer;

@property BOOL streamIdPresent;
@property UInt32 streamId;

- (VITA *) initWithPacket: (NSData *) packet;

@end
