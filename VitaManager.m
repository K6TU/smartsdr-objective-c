//
//  VitaManager.m
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

#import "VitaManager.h"
#import "GCDAsyncUdpSocket.h"
#import <arpa/inet.h>
#import "Meter.h"
#import "Panafall.h"
#import "Waterfall.h"
#import "DAXAudio.h"
#import "OpusAudio.h"


@interface VitaManager () <GCDAsyncUdpSocketDelegate>

// streamProcessor is a dictionary of NSMutableArray objects keyed by a stream
// identifier represented as a hex string of the form 0xXXXXXXXX where
// XXXXXXXX is the stream handle.
//
// Each NSMutableArray contains objects that must support the VitaStream protocol
// and each objects VitaStream Protocol handler is called when a message arrives on
// the given stream
@property (strong, nonatomic) NSMutableDictionary *streamProcessor;

@property (strong, nonatomic) dispatch_queue_t vitaRunQueue;
@property (readwrite, nonatomic) NSInteger vitaPort;
@property (weak, readwrite, nonatomic) Radio *radio;

- (void) meterStreamHandler:(VITA *) vitaPacket;

@end

#define VITA_DEFAULT_PORT 4991

@implementation VitaManager

GCDAsyncUdpSocket *vitaRxSocket;
GCDAsyncUdpSocket *vitaTxSocket;

- (id) init {
    self = [super init];
    
    // Create a private run queue for us to run on
    NSString *qName = @"net.k6tu.VitaQueue";
    self.vitaRunQueue = dispatch_queue_create([qName UTF8String], NULL);
    
    vitaRxSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:self.vitaRunQueue];
    [vitaRxSocket setPreferIPv4];
    [vitaRxSocket setIPv6Enabled:NO];
    [vitaRxSocket enableBroadcast:NO error:nil];
    
    return self;
}

- (BOOL) handleRadio:(Radio *)radio {
    self.radio = radio;
    
    BOOL socketSuccess = NO;
    NSError *error = nil;
    NSInteger portNum = VITA_DEFAULT_PORT;
    
    // Find a port for us - we scan from the default port up looking for an available port
    
    for (int i=0; i<20; i++) {
        if ([vitaRxSocket bindToPort:portNum error:&error]) {
            socketSuccess = YES;
            if (![vitaRxSocket connectToHost:self.radio.radioInstance.ipAddress onPort:0 error:&error])
                NSLog(@"VitaManager: Error connecting to host - %@", error);
            
            break;
        }
        
        // We didn't get the port we wanted
        NSLog(@"VitaManager: Error binding port = %i - %@", (int)portNum, error);
        portNum++;
    }
    
    if (!socketSuccess) {
        NSLog(@"VitaManager: Unable to find free socket");
        return NO;
    }
    
    // Grab the tx socket for sending streams to the radio
    vitaTxSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:self.vitaRunQueue];
    [vitaTxSocket setPreferIPv4];
    [vitaTxSocket setIPv6Enabled:NO];
    [vitaTxSocket enableBroadcast:NO error:nil];
    
    if (![vitaTxSocket connectToHost:self.radio.radioInstance.ipAddress onPort:VITA_DEFAULT_PORT error:&error])
        NSLog(@"VitaManager: Error connecting to tx host - %@", error);
    
    // Record our socket
    self.vitaPort = portNum;
   
    // Start receiving
    [vitaRxSocket beginReceiving:nil];
    return YES;
}


- (void) txStreamPacket:(NSData *)vitaPacket {
    // Send this VITA encoded frame to the radio
    [vitaTxSocket sendData:vitaPacket withTimeout:-1 tag:0];
}


- (void) udpSocket:(GCDAsyncUdpSocket *)sock
    didReceiveData:(NSData *)data
       fromAddress:(NSData *)address
 withFilterContext:(id)filterContext {
    
    VITA *vitaPacket = [[VITA alloc]initWithPacket:data];
    NSError *error;
    
    NSString *streamId;
    Panafall *pan;
    Waterfall *wf;
    DAXAudio *sh;
    OpusAudio *opus;
    
    // TODO:
    // Packet statistics - received, dropped
    
    switch (vitaPacket.packetType) {
        case EXT_DATA_WITH_STREAM:
            // Stream of data - figure out what type and call the dispatcher
            switch (vitaPacket.packetClassCode) {
                case VS_Meter:
                    [self meterStreamHandler:vitaPacket];
                    break;
                    
                case VS_PAN_FFT:
                    streamId = [NSString stringWithFormat:@"0x%08X", (unsigned int)vitaPacket.streamId];
                    
                    @synchronized (self.radio.panafalls) {
                        pan = self.radio.panafalls[streamId];
                    }
                    
                    [pan streamHandler:vitaPacket];
                    break;
                    
                case VS_Waterfall:
                    streamId = [NSString stringWithFormat:@"0x%08X", (unsigned int)vitaPacket.streamId];
                    
                    @synchronized (self.radio.waterfalls) {
                        wf = self.radio.waterfalls[streamId];
                    }
                    
                    [wf streamHandler:vitaPacket];
                    break;
                    
                case VS_DAX_Audio:
                    streamId = [NSString stringWithFormat:@"0x%08X", (unsigned int)vitaPacket.streamId];

                    @synchronized (self.radio.daxAudioStreamToStreamHandler) {
                        sh = self.radio.daxAudioStreamToStreamHandler[streamId];
                    }
                    
                    [sh streamHandler:vitaPacket];
                    break;
                    
                case VS_Opus:
                    streamId = [NSString stringWithFormat:@"0x%08X", (unsigned int)vitaPacket.streamId];
                    
                    @synchronized(self.radio.opusStreamToStreamHandler) {
                        opus = self.radio.opusStreamToStreamHandler[streamId];
                    }
                    
                    [opus streamHandler:vitaPacket];

                    break;
            }
            break;
            
        case IF_DATA_WITH_STREAM:
            // IF Data with stream - this is DAX IQ data...
            streamId = [NSString stringWithFormat:@"0x%08X", (unsigned int)vitaPacket.streamId];

            break;
            
        default:
            // Ignore any other packetTypes we don't process
            break;
    }
}


#pragma mark
#pragma mark Stream Handlers

- (void) meterStreamHandler:(VITA *)vitaPacket {
    NSInteger nMeters = vitaPacket.payloadLength / 4;
    NSInteger meterNum, meterValue;
    void *ptr = vitaPacket.payload;
    Meter *thisMeter;
    
    for (int i = 0 ; i < nMeters; i++) {
        meterNum = (short)CFSwapInt16BigToHost(*(short *)ptr);
        meterValue = (short)CFSwapInt16BigToHost(*(short *)(ptr+2));
        
        // Find the meter
        @synchronized (self.radio.meters) {
            thisMeter = self.radio.meters[[NSString stringWithFormat:@"%i", (int)meterNum]];
        }
        
        if (!thisMeter) continue;
        
        // Now update the meter on the default run queue so KVO happens
        // there and not on our queue
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [thisMeter updateMeter:meterValue];
        });

        // Step to the next meter
        ptr += 4;
    }
}

@end
