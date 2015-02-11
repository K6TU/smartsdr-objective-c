//
//  VitaManager.m
//  VITA Engine
//
//  Created by STU PHILLIPS on 2/6/15.
//  Copyright (c) 2015 STU PHILLIPS. All rights reserved.
//
// NOTE: THe license under which this software will be generally released
// is still under consideration.  For now, use of this software requires
// the specific approval of Stu Phillips, K6TU.
//

#import "VitaManager.h"
#import "GCDAsyncUdpSocket.h"
#import <arpa/inet.h>
#import "Meter.h"
#import "Panafall.h"
#import "Waterfall.h"


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

GCDAsyncUdpSocket *vitaSocket;

- (id) init {
    self = [super init];
    
    // Create a private run queue for us to run on
    NSString *qName = @"com.k6tu.VitaQueue";
    self.vitaRunQueue = dispatch_queue_create([qName UTF8String], NULL);
    
    vitaSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:self.vitaRunQueue];
    [vitaSocket setPreferIPv4];
    [vitaSocket setIPv6Enabled:NO];
    [vitaSocket enableBroadcast:NO error:nil];
    
    return self;
}

- (BOOL) handleRadio:(Radio *)radio {
    self.radio = radio;
    
    BOOL socketSuccess = NO;
    NSError *error = nil;
    NSInteger portNum = VITA_DEFAULT_PORT;
    
    // Find a port for us - we scan from the default port up looking for an available port
    
    for (int i=0; i<20; i++) {
        if ([vitaSocket bindToPort:portNum error:&error]) {
            socketSuccess = YES;
            if (![vitaSocket connectToHost:self.radio.radioInstance.ipAddress onPort:0 error:&error])
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
    
    // Record our socket
    self.vitaPort = portNum;
   
    // Post a read
    [vitaSocket receiveOnce:&error];
    return YES;
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
                    streamId = [NSString stringWithFormat:@"0x%08X", vitaPacket.streamId];
                    pan = self.radio.panafalls[streamId];
                    [pan streamHandler:vitaPacket];
                    break;
                    
                case VS_Waterfall:
                    streamId = [NSString stringWithFormat:@"0x%08X", vitaPacket.streamId];
                    wf = self.radio.waterfalls[streamId];
                    [wf streamHandler:vitaPacket];
                    break;
            }
    }
    
    // Post the next read
    [vitaSocket receiveOnce:&error];
}


#pragma mark
#pragma mark Stream Handlers

- (void) meterStreamHandler:(VITA *)vitaPacket {
    NSInteger nMeters = vitaPacket.payloadLength / 4;
    NSInteger meterNum, meterValue;
    void *ptr = vitaPacket.payload;
    
    for (int i = 0 ; i < nMeters; i++) {
        meterNum = (short)CFSwapInt16BigToHost(*(short *)ptr);
        meterValue = (short)CFSwapInt16BigToHost(*(short *)(ptr+2));
        
        // Find the meter
        Meter *thisMeter = self.radio.meters[[NSString stringWithFormat:@"%i", (int)meterNum]];
        
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
