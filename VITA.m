//
//  VITA.m
//  VITA component of SMART-SDR Objective-C model
//
//  Created by STU PHILLIPS on 10/30/14.
//  Copyright (c) 2014 STU PHILLIPS. All rights reserved.
//
//
// NOTE: THe license under which this software will be generally released
// is still under consideration.  For now, use of this software requires
// the specific approval of Stu Phillips, K6TU.

#import "VITA.h"

#define VH_PKT_TYPE(x)      ((x & 0xF0000000) >> 28)
#define VH_C(x)             ((x & 0x08000000) >> 26)
#define VH_T(x)             ((x & 0x04000000) >> 25)
#define VH_TSI(x)           ((x & 0x00c00000) >> 21)
#define VH_TSF(x)           ((x & 0x00300000) >> 19)
#define VH_PKT_CNT(x)       ((x & 0x000f0000) >> 16)
#define VH_PKT_SIZE(x)      (x & 0x0000ffff)

#define V_SWAP32(x,y)       CFSwapInt32BigToHost(*(UInt32 *)(x+y))

// Minimum number of bytes for a valdid VITA packet

const UInt16 VITAmin = 28;



@implementation VITA

// Crack the VITA frame and grab the appropriate fields into our properties

- (VITA *)initWithPacket:(NSData *)packet {
    (void)[self init];
    
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

@end
