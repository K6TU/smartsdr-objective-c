//
//  VITA.m
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

#import "VITA.h"

#define VH_PKT_TYPE(x)      ((x & 0xF0000000) >> 28)
#define VH_C(x)             ((x & 0x08000000) >> 26)
#define VH_T(x)             ((x & 0x04000000) >> 25)
#define VH_TSI(x)           ((x & 0x00c00000) >> 22)
#define VH_TSF(x)           ((x & 0x00300000) >> 20)
#define VH_PKT_CNT(x)       ((x & 0x000f0000) >> 16)
#define VH_PKT_SIZE(x)      (x & 0x0000ffff)

#define V_SWAP32(x,y)       CFSwapInt32BigToHost(*(UInt32 *)(x+y))

// Minimum number of bytes for a valdid VITA packet

const UInt16 VITAmin = 28;



@implementation VITA

// Crack the VITA frame and grab the appropriate fields into our properties

- (VITA *)initWithPacket:(NSData *)packet {
    self = [super init];
    
    self.buffer = packet;
    
    if (!packet.bytes || [packet length] < VITAmin)
        // Null length data or packet too short - return
        return self;
    
    UInt32 offset = 0;
    UInt32 val = V_SWAP32(packet.bytes, offset);
    
    self.packetType = (enum VitaPacketType) VH_PKT_TYPE(val);
    self.classIdPresent = (BOOL) VH_C(val);
    self.trailerPresent = (BOOL) VH_T(val);
    self.tsi = VH_TSI(val);
    self.tsf = VH_TSF(val);
    self.packetCount = VH_PKT_CNT(val);
    self.packetSize = VH_PKT_SIZE(val);
    
    // Increment past header word
    offset += 4;
    
    if (self.packetType == IF_DATA_WITH_STREAM || self.packetType == EXT_DATA_WITH_STREAM) {
        // There is a steam identifier present
        self.streamIdPresent = YES;
        self.streamId = V_SWAP32(packet.bytes, offset);
        
        // Increment past stream id
        offset += 4;
    }
    
    if (self.classIdPresent) {
        // Class ID present
        self.oui = V_SWAP32(packet.bytes, offset);
        
        val = V_SWAP32(packet.bytes, offset + 4);
        
        self.informationClassCode = (val & 0xffff0000) >> 16;
        self.packetClassCode = val & 0x0000ffff;
        
        // Increment past second word of class id
        offset += 8;
    }
    
    if (self.tsi) {
        // Grab the Integer timestamp
        self.integerTimestamp = V_SWAP32(packet.bytes, offset);
        
        // Increment past integer timestamp
        offset += 4;
    }
    
    if (self.tsf) {
        // Fractional time stamp present
        
        self.fracTimeStamp0 = V_SWAP32(packet.bytes, offset);
        self.fracTimeStamp1 = V_SWAP32(packet.bytes, offset + 4);
        
        // Increment past fractional timestamp
        offset += 8;
    }
    
    self.payload = (void *) packet.bytes + offset;
    
    if (self.trailerPresent) {
        // Trailer is present and must be in the last word of the packet
        self.trailer = V_SWAP32(packet.bytes, (self.packetSize - 1) * 4);
    }

    self.payloadLength = (self.packetSize * 4) - offset - (self.trailerPresent ? 4 : 0);
    
    return self;
}


//
// encodeVitaPacket:
//
// Expects all the fields in the VITA to be set appropriately and the NSDATA object
// held by the buffer property to already have space for the VITA header and contain
// the payload in the appropriate byte order for the radio.
//
// This method takes and encodes the VITA fields from the object into their bit
// stuffed and correct endianism at the front of the payload - and if specified,
// the trailer.  The trailer word if supplied is expected to be correctly encoded
// and in host bit order (aka, it will be swapped!)
//


- (void) encodeVitaPacket:(VITA *)vitaPacket {
    UInt32 *buffer = (UInt32 *)vitaPacket.buffer.bytes;
    UInt32 word = 0;
    UInt32 offset = 0;
    
    
    // Build up the Header word - one byte value at a time and then shift
    word = (u_char)vitaPacket.packetType << 4 |
           (u_char)vitaPacket.classIdPresent << 3 |
    (u_char)vitaPacket.trailerPresent << 2;
    
    word <<= 8;
    
    word |= (u_char)vitaPacket.tsi << 6 |
            (u_char)vitaPacket.tsf << 4 |
    (u_char)vitaPacket.packetCount;
    
    word <<= 8;
    
    word |= (u_char)vitaPacket.packetSize >> 8;
    
    word <<= 8;
    
    word |= (u_char)(vitaPacket.packetSize & 0xff);
    
    // Place in the buffer
    buffer[offset++] = CFSwapInt32HostToBig(word);;
    
    // Next up - stream id...
    buffer[offset++] = CFSwapInt32HostToBig(vitaPacket.streamId);
    
    // Now  Class Id if present
    if (vitaPacket.classIdPresent) {
        buffer[offset++] = CFSwapInt32HostToBig(vitaPacket.oui);
        
        word = vitaPacket.informationClassCode << 16 | vitaPacket.packetClassCode;
        buffer[offset++] = CFSwapInt32HostToBig(word);
    }
    
    // Integer time stamp...
    if (vitaPacket.tsi != TSI_NONE) {
        buffer[offset++] = CFSwapInt32HostToBig(vitaPacket.fracTimeStamp0);
    }
    
    // Fractional time stamp...
    if (vitaPacket.tsf != TSI_NONE) {
        buffer[offset++] = CFSwapInt32HostToBig(vitaPacket.fracTimeStamp1);
    }
    
    // Last but not least, Trailer...
    if (vitaPacket.trailerPresent) {
        offset += vitaPacket.payloadLength;
        buffer[offset] = CFSwapInt32HostToBig(vitaPacket.trailer);
    }
}

@end
