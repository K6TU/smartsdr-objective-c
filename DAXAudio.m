//
//  DAXAudio.m
//  VITA Engine
//
//  Created by STU PHILLIPS on 2/15/15.
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

#import "DAXAudio.h"

@interface DAXAudio ()

@property (weak, readwrite, nonatomic) Radio *radio;                         // The Radio which owns this panadaptor
@property (weak, readwrite, nonatomic) Slice *slice;                         // Slice associated with this audio stream
@property (strong, readwrite, nonatomic) NSString *streamId;                 // Stream ID associated with this DAX instance
@property (nonatomic, readwrite) int daxChannel;                             // DAX channel number of this DAX instance
@property (nonatomic, readwrite) NSInteger lostPacketCount;                  // Count of lost packets in this stream
@property (nonatomic, readwrite) NSInteger rxPackets;                        // Count of received packets processed
@property (nonatomic, readwrite) NSInteger txPackets;                        // Count of TX packets sent
@property (nonatomic, readwrite) NSInteger rxBytes;                          // Count of RX bytes received
@property (nonatomic, readwrite) NSInteger txBytes;                          // Count of TX bytes sent
@property (nonatomic, readwrite) NSInteger rxRate;                           // RX rate in bytes/second
@property (nonatomic, readwrite) NSInteger txRate;                           // TX rate in bytes/second

// Private properties
@property (strong, nonatomic) NSDictionary *parserTokens;                    // Tokenizer for our parser
@property (strong, nonatomic) NSString *txStreamId;                          // Stream handle for use when this channel is TX source
@property (nonatomic) dispatch_source_t rateTimer;                           // One second callback for rate calculator/stats update
@property (nonatomic) NSInteger rxSeq;                                       // Rx sequence number
@property (nonatomic) NSInteger txSeq;                                       // Tx sequence number
@property (nonatomic) NSInteger rcRxPackets;                                 // Rate calculator packet count- RX
@property (nonatomic) NSInteger rcTxPackets;                                 //   - TX
@property (nonatomic) NSInteger rcRxBytes;                                   // Total byte counter - RX
@property (nonatomic) NSInteger rcTxBytes;                                   //   - TX
@property (nonatomic) NSInteger rcLostPacketCount;                           // Lost packet counter


// Private methods
- (void) initParserTokens;

@end


enum audioStreamTokens {
    noneToken = 0,
    daxToken,
    inUseToken,
    daxTxToken,
    daxClientsToken,
    sliceToken,
    txStreamToken,
    ipToken,
    portToken,
};


// Private Macro
//
// Macro to perform inline update on an ivar with KVO notification

#define updateWithNotify(key,ivar,value)  \
    {    \
        __weak DAXAudio *safeSelf = self; \
        dispatch_async(dispatch_get_main_queue(), ^(void) { \
        [safeSelf willChangeValueForKey:(key)]; \
        (ivar) = (value); \
        [safeSelf didChangeValueForKey:(key)]; \
        }); \
    }

@implementation DAXAudio

- (id) init {
    if (!self)
        self = [super init];
    
    self.rxSeq = -1;
    self.txSeq = 0;
    [self initParserTokens];
    
    self.runQueue = dispatch_queue_create("DaxAudio", NULL);
    
    // Start rate calculator timer on our queue
    [self startRateTimer];
    
    return self;
}


- (void) startRateTimer {
    [self stopRateTimer];
    
    if (!self.rateTimer)
        self.rateTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, DISPATCH_TIMER_STRICT, self.runQueue);
    
    if (self.rateTimer) {
        // Set 10% leeway in our call back timer...
        dispatch_source_set_timer(self.rateTimer, dispatch_walltime(NULL, 0), 1 * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(self.rateTimer, ^(void) { [self rateCalculator]; });
        dispatch_resume(self.rateTimer);
    }
}

- (void) stopRateTimer {
    if (self.rateTimer) {
        dispatch_source_cancel(self.rateTimer);
        self.rateTimer = nil;
    }
}

- (id) initWithRadio:(Radio *)radio channel:(int)daxChannel {
    if (!self) {
        self = [super init];
        self = [self init];
    }
    
    self.radio = radio;
    self.daxChannel = daxChannel;

    // Ask the radio to set up the stream for us
    [radio cmdNewAudioStream:daxChannel];
    return self;
}


- (void) closeStream {
    [self.radio cmdRemoveAudioStreamHandler:self];
}


- (void) dealloc {
    // Cancel the timer...
    [self stopRateTimer];
    
    // Close the stream in case our user didn't...
    [self closeStream];
}


- (void) initParserTokens {
    self.parserTokens = [[NSDictionary alloc]initWithObjectsAndKeys:
                         [NSNumber numberWithInt:daxToken], @"dax",
                         [NSNumber numberWithInt:inUseToken], @"in_use",
                         [NSNumber numberWithInt:daxTxToken], @"dax_tx",
                         [NSNumber numberWithInt:daxClientsToken], @"dax_clients",
                         [NSNumber numberWithInt:sliceToken], @"slice",
                         [NSNumber numberWithInt:txStreamToken], @"tx_stream",
                         [NSNumber numberWithInt:ipToken], @"ip",
                         [NSNumber numberWithInt:portToken], @"port",
                         nil];
}



- (void) rateCalculator {
    // updateWithNotify(@"rxPackets", _rxPackets, self.rcRxPackets);
    // updateWithNotify(@"txPackets", _txPackets, self.rcTxPackets);
    // updateWithNotify(@"lostPacketCount", _lostPacketCount, self.rcLostPacketCount);
    // updateWithNotify(@"rxRate", _rxRate, self.rcRxBytes - self.rxBytes);
    // updateWithNotify(@"txRate", _txRate, self.rcTxBytes - self.txBytes);
    
    self.rxPackets = self.rcRxPackets;
    self.txPackets = self.rcTxPackets;
    self.lostPacketCount = self.rcLostPacketCount;
    self.rxRate = self.rcRxBytes - self.rxBytes;
    self.txRate = self.rcTxBytes - self.txBytes;
    self.rxBytes = self.rcRxBytes;
    self.txBytes = self.rcTxBytes;
    
    NSLog(@"Rx: %li  RxR: %li  Lost:%li", (long)self.rcRxPackets, (long)self.rxRate, (long)self.rcLostPacketCount);
}

//
// streamSend does all the work of encoding the provided buffer into one or more
// VITA packets
//

- (void) streamSend:(Float32 *)buffer length:(int)length {
    if (!self.transmitEnabled || self.slice == nil)
        return;
    
    VITA *vita = [[VITA alloc]init];
    NSMutableData *vitaPacket;
    int offset = 0;
    int nSamples;
    Float32 *samples;
    
    while (offset < length) {
        // See how many samples to send
        nSamples = MIN(256, (length - offset));
        
        // Allocate an NSMutableData object to hold the number of samples plus the VITA overhead
        // nSamples * bytes per sample * channels + overhead
        vitaPacket = [[NSMutableData alloc] initWithLength:(nSamples * 4 * 2 + VITA_HEADER_SIZE_BYTES)];
        
        // Prepare the header
        vita.buffer = vitaPacket;
        vita.packetType = IF_DATA_WITH_STREAM;
        vita.classIdPresent = YES;
        vita.trailerPresent = NO;
        vita.tsi = TSI_OTHER;
        vita.tsf = TSF_SAMPLE_COUNT;
        vita.streamId = [self intFromHexString:self.txStreamId];
        vita.oui = FRS_OUI;
        vita.informationClassCode = 0x543c;
        vita.packetClassCode = VS_DAX_Audio;
        vita.packetCount = self.txSeq;
        vita.packetSize = nSamples + VITA_HEADER_SIZE_WORDS;
        
        // Increment the tx sequence number
        self.txSeq = ++self.txSeq % 16;
        
        // Set up the payload and copy the data byte swapping as we go...
        vita.payload = (void *)(vitaPacket.bytes + VITA_HEADER_SIZE_BYTES);
        vita.payloadLength = nSamples;
        samples = (Float32 *)vita.payload;
        
        Float32 sample;
        unsigned char *wArray = (unsigned char *)&sample, b;
        
        for (int i=0; i < (nSamples * 2); i++) {
            sample = buffer[offset+i];
            
            // Swamp byte order
            b = wArray[0];
            wArray[0] = wArray[3];
            wArray[3]= b;
            
            b = wArray[1];
            wArray[1] = wArray[2];
            wArray[2] = b;

            samples[i] = sample;
        }
            
        // Update the offset
        offset += nSamples;
        
        // Update the VITA header in the packet buffer
        [vita encodeVitaPacket:vita];
        
        // Transmit the packet
        [self.radio.vitaManager txStreamPacket:vitaPacket];
        
        // Update counters
        self.rcTxPackets++;
        self.rcTxBytes += (int)vitaPacket.length;
    }
}


//
// streamHandler - converts the VITA payload into a StreamFrame and then passes it to the delegate
//

- (void) streamHandler:(VITA *)vitaPacket {
    // Check the sequence of the packet...
    if (vitaPacket.packetCount == ((self.rxSeq + 1) % 16) || self.rxSeq == -1) {
        // Correct ordered packet
        self.rxSeq = vitaPacket.packetCount;
    } else if (vitaPacket.packetCount < ((self.rxSeq + 1) % 16)) {
        // packet is out of order pitch it
        self.rcLostPacketCount++;
        return;
    } else {
        // This packet is ahead of what we were expecting - likely we lost a packet
        // Forward this one on and reset the sequence number so that we will take the
        // next packet
        self.rcLostPacketCount++;
        self.rxSeq = -1;
    }
    
    if (!self.delegate)
        // No handler
        return;
    
    StreamFrame *dax = [[StreamFrame alloc]init];
    Float32 *samples = (Float32 *)vitaPacket.payload;
    
    dax.buffer = vitaPacket.buffer;
    dax.numSamples = vitaPacket.payloadLength / 8;      // 2 channels, each with a 32 bit Float
    dax.sizeofSample = 4;
    dax.samples = vitaPacket.payload;
    
    // Swap the endianism of the samples - we multiply by 2 because of one sample for each
    // of two channels
    
    unsigned char *wArray;
    unsigned char b;
    
    for (int i=0; i < (dax.numSamples * 2); i++) {
        wArray = (unsigned char *)&samples[i];
        
        // Swamp byte order
        b = wArray[0];
        wArray[0] = wArray[3];
        wArray[3]= b;
        
        b = wArray[1];
        wArray[1] = wArray[2];
        wArray[2] = b;
    }
    
    // Create a weak reference to self before the block
    __weak DAXAudio *safeSelf = self;
    dispatch_async(self.runQueue, ^(void) {
        @autoreleasepool {
            [safeSelf.delegate streamReceive:dax];
        }
    });
    
    // Update counters
    self.rcRxPackets++;
    self.rcRxBytes += (int)vitaPacket.buffer.length;
}




// Utility method
- (unsigned int)intFromHexString:(NSString *) hexStr {
    unsigned int hexInt = 0;
    
    // Create scanner
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    
    // Tell scanner to skip the # character
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"#"]];
    
    // Scan hex value
    [scanner scanHexInt:&hexInt];
    
    return hexInt;
}

#pragma mark
#pragma mark Radio Parser Support

- (void) statusParser:(NSScanner *)scan selfStatus:(BOOL)selfStatus {
    NSString *all;
    NSString *cmd;
    NSArray *fields;
    [scan scanString:@" " intoString:nil];
    [scan scanUpToString:@"\n" intoString:&all];
    
    fields = [all componentsSeparatedByString:@" "];
    
    for (NSString *f in fields) {
        NSArray *kv = [f componentsSeparatedByString:@"="];
        NSString *k = kv[0];
        NSString *v = kv[1];
        
        NSInteger tokenVal = [self.parserTokens[k] integerValue];
        
        switch (tokenVal) {
            case inUseToken:
                // Ignore - this is handled by the Radio model
                break;
                
            case daxToken:
                updateWithNotify(@"daxChannel", _daxChannel, (int)[v integerValue]);
                break;
                
            case daxTxToken:
                updateWithNotify(@"transmitEnabled", _transmitEnabled, [v boolValue]);
                break;
                
            case txStreamToken:
                self.txStreamId = v;
                break;
                
            case sliceToken:
                if ([v integerValue] == -1) {
                    // No slice attached
                    updateWithNotify(@"slice", _slice, nil);
                } else {
                    updateWithNotify(@"slice", _slice, self.radio.slices[[v integerValue]]);
                    
                    // Its possible that the slice associated with the stream is either a different
                    // slice or was deleted/recreated - in either event, send the rxGain setting
                    if ([self.radio.slices[[v integerValue]] isKindOfClass:[Slice class]]) {
                        cmd = [NSString stringWithFormat:@"audio stream %@ slice %i gain %i",
                               self.streamId, (int)[v integerValue], self.rxGain];
                        [self.radio commandToRadio:cmd];
                    }
                }
                break;
                
            case daxClientsToken:
            case ipToken:
            case portToken:
                break;
                
            default:
                // Ignore
                NSLog(@"AudioStream statusParser: Unknown key %@", k);
                break;
        }
    }
}


#pragma mark
#pragma mark RadioDisplay protoocol handlers
    
- (void) attachedRadio:(Radio *)radio streamId:(NSString *)streamId {
    self.radio = radio;
    self.streamId = streamId;
    
    if (!self.runQueue) {
        NSString *qName = [NSString stringWithFormat:@"net.k6tu.audioStreamQueue-%@", streamId];
        self.runQueue = dispatch_queue_create([qName UTF8String], NULL);
    }
}


- (void) willRemoveStreamProcessor {
    
}
    
#pragma mark
#pragma mark Setters with Commands
    
    // Private macro to improve readibility of setters
    
#define commandUpdateNotify(cmd, key, ivar, value) \
    /* Let observers know the change on the main queue */ \
    [self willChangeValueForKey:(key)]; \
    (ivar) = (value); \
    [self didChangeValueForKey:(key)]; \
    \
    @synchronized(self) {\
        __weak DAXAudio *safeSelf = self; \
        dispatch_async(self.runQueue, ^(void) { \
            /* Send the command to the radio on our private queue */ \
            [safeSelf.radio commandToRadio:(cmd)]; \
        }); \
    }
    
- (void) setTransmitEnabled:(BOOL)transmitEnabled {
    NSString *cmd = [NSString stringWithFormat:@"dax audio set %i tx=%i",
                     self.daxChannel, transmitEnabled];
    
    commandUpdateNotify(cmd, @"transmitEnabled", _transmitEnabled, transmitEnabled);
}


- (void) setRxGain:(int)rxGain {
    if (!self.slice) {
        updateWithNotify(@"rxGain", _rxGain, rxGain);
    }
    
    NSString *cmd = [NSString stringWithFormat:@"audio stream %@ slice %i gain %i",
                     self.streamId, (int)[self.slice.thisSliceNumber integerValue], rxGain];

    commandUpdateNotify(cmd, @"rxGain", _rxGain, rxGain);
}


- (void) setTxGain:(int)txGain {
    // Currently no command - wonder how this gets handled?
    
    updateWithNotify(@"txGain", _txGain, txGain);
}


- (void) setRunQueue:(dispatch_queue_t)runQueue {
    @synchronized(self) {
        _runQueue = runQueue;
        [self startRateTimer];
    }
}


- (void) setDelegate:(id)delegate {
    @synchronized(self) {
        _delegate = delegate;
    }
}

- (void) setDelegate:(id<DaxAudioStreamHandler>)delegate runQueue:(dispatch_queue_t)runQueue {
    @synchronized(self) {
        _delegate = delegate;
        _runQueue = runQueue;
        [self startRateTimer];
    }
}



@end
