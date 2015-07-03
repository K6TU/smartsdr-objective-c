//
//  VITA.h
//  VITA component of SMART-SDR Objective-C model
//
//  Created by STU PHILLIPS on 10/30/14.
//  Copyright (c) 2014 STU PHILLIPS. All rights reserved.
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

#define FRS_OUI 0x1c2d
#define VITA_PORT 4991


#define  VS_Meter      0x8002
#define  VS_PAN_FFT    0x8003
#define  VS_Waterfall  0x8004
#define  VS_Opus       0x8005
#define  DAX_IQ_24Khz  0x00e3
#define  DAX_IQ_48Khz  0x00e4
#define  DAX_IQ_96Khz  0x00e5
#define  DAX_IQ_192KHz 0x00e6
#define  VS_DAX_Audio  0x03e3
#define  VS_Discovery  0xffff

#define  VITA_HEADER_SIZE_BYTES   28
#define  VITA_HEADER_SIZE_WORDS   (VITA_HEADER_SIZE_BYTES / 4)

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
- (void) encodeVitaPacket:(VITA *) vitaPacket;

@end
