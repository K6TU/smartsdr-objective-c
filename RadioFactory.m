//
//  K6TURadioFactory.m
//
//  Created by STU PHILLIPS on 8/2/13.
//  Copyright (c) 2013 STU PHILLIPS. All rights reserved.
//
// NOTE: THe license under which this software will be generally released
// is still under consideration.  For now, use of this software requires
// the specific approval of Stu Phillips, K6TU.

#import "RadioFactory.h"
#import "VITA.h"
#import "arpa/inet.h"

#define FLEX_DISCOVERY  4992
#define FLEX_CONNECT    4992


#pragma mark Radio Instance

// Enum definition for VITA formed discovery message parser
enum vitaTokens {
    nullToken = 0,
    ipToken,
    portToken,
    modelToken,
    serialToken,
    callsignToken,
    nameToken,
    dpVersionToken,
    versionToken,
    statusToken,
};




@implementation RadioInstance


- (id) initWithData: (NSString *) ipAddress
               port: (NSNumber *) port
              model: (NSString *) model
          serialNum: (NSString *) serialNum
               name: (NSString *) name
           callsign: (NSString *) callsign
          dpVersion: (NSString *) dpVersion
            version: (NSString *) version
             status: (NSString *) status {
    self = [super init];
    self.ipAddress = ipAddress;
    self.port = port;
    self.model = model;
    self.serialNum = serialNum;
    self.name = name;
    if (callsign)  self.callsign = callsign;
    if (dpVersion) self.dpVersion = dpVersion;
    if (version)   self.version = version;
    if (status) self.status = status;
    self.lastSeen = [NSDate date];
    return self;
}


- (BOOL) isEqual:(id)object {
    RadioInstance *radio = (RadioInstance *)object;
    
    if ([self.ipAddress isEqualToString:radio.ipAddress] &&
        [self.port isEqualToNumber:radio.port] &&
        [self.model isEqualToString:radio.model] &&
        [self.serialNum isEqualToString:radio.serialNum]) {
        return YES;
    }
    return NO;
}

@end


#pragma mark Radio Factory

@interface RadioFactory () {
    long tag;
    GCDAsyncUdpSocket *udpSocket;
}

@property (strong, nonatomic) NSMutableDictionary *discoveredRadios;
@property (strong, nonatomic) NSTimer *timeoutTimer;
@property (strong, nonatomic) NSDictionary *parserTokens;

- (void) radioFound: (RadioInstance *) radio;
- (void) radioTimeoutCheck: (NSTimer *) timer;
@end

@implementation RadioFactory

#pragma mark init

- (id) init {
    self = [super init];
    
    if (self) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [udpSocket setPreferIPv4];
        [udpSocket setIPv6Enabled:NO];
        [udpSocket enableBroadcast:YES error:nil];
        
        NSError *error = nil;
        
        if (![udpSocket bindToPort:FLEX_DISCOVERY error:&error]) {
            NSLog(@"Error binding: %@", error);
            return nil;;
        }
        
        [udpSocket receiveOnce:&error];
        
        // Initialize dictionary
         self.discoveredRadios = [[NSMutableDictionary alloc] initWithCapacity:0];
        
        // Start timeout timer
        
       self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                             target:self
                                                           selector:@selector(radioTimeoutCheck:)
                                                           userInfo:nil
                                                           repeats:YES];
        NSLog(@"Ready");
    }

#ifdef DEBUG
    // Create a fake radio for testing...
    RadioInstance *fake = [[RadioInstance alloc] initWithData:@"10.1.1.155"
                                                         port:[NSNumber numberWithInt:4992]
                                                        model:@"FLEX-6300"
                                                    serialNum:@"1340-1100-0001-0007"
                                                         name:@"K6TU"
                                                     callsign:nil
                                                    dpVersion:nil
                                                      version:nil
                                                       status:nil];
    [self radioFound:fake];
#endif
    
    // Initialize parser tokens
    self.parserTokens = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSNumber numberWithInt:ipToken] , @"ip",
                         [NSNumber numberWithInt:portToken], @"port",
                         [NSNumber numberWithInt:modelToken], @"model",
                         [NSNumber numberWithInt:serialToken], @"serial",
                         [NSNumber numberWithInt:callsignToken], @"callsign",
                         [NSNumber numberWithInt:nameToken], @"nickname",
                         [NSNumber numberWithInt:dpVersionToken], @"discovery_protocol_version",
                         [NSNumber numberWithInt:versionToken], @"version",
                         [NSNumber numberWithInt:statusToken], @"status"
                         , nil];
    return self;
}


- (void) close {
    [self.discoveredRadios removeAllObjects];
    [udpSocket close];
    [udpSocket setDelegate:nil];
    [self.timeoutTimer invalidate];
}


- (void) dealloc {
    NSLog(@"Radio Factory dealloc");
}

#pragma mark radioFound

// radioFound
//
// A radio has been found via the discovery protocol - check and see whether this is a new radio
// or one already in our list.

- (void) radioFound:(RadioInstance *)radio {
    // Check if in list...
    NSString *key = radio.ipAddress;
    RadioInstance *inList;
    
    @synchronized(self) {
        inList = self.discoveredRadios[key];
    }
    
    if (!inList) {
        // New radio for us - simply add
        @synchronized(self) {
            self.discoveredRadios[key] = radio;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"K6TURadioFactory" object:self];
        NSLog(@"Radio added");
        
    } else if (![inList isEqual:radio]) {
        // The radio instance has changed... a different radio is at the same address
        // or some attribute of it has changed.
        @synchronized(self) {
            [self.discoveredRadios removeObjectForKey:key];
            self.discoveredRadios[key] = radio;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"K6TURadioFactory" object:self];
        NSLog(@"Radio updated");
    } else {
        // Update the last time this radio was seen
        inList.lastSeen = [NSDate date];
    }
}


#pragma mark radioTimeoutCheck

// radioTimeoutCheck
//
// Runs every second - we delete any radio from the discovered radio list that
// hasnt been seen for > 1.5 seconds

- (void) radioTimeoutCheck: (NSTimer *) timer {
    NSDate *now = [NSDate date];
    BOOL sendNotification = NO;
    NSArray *keys;
    
#ifdef DEBUG
    // [[NSNotificationCenter defaultCenter] postNotificationName:@"K6TURadioFactory" object:self];
    // return;   // Comment this out to renable timeout
#endif
    @synchronized(self) {
        keys = [self.discoveredRadios allKeys];

        for (int i=0; i < [keys count]; i++) {
            RadioInstance *radio = [self.discoveredRadios objectForKey:keys[i]];
            if (radio && [now timeIntervalSinceDate:radio.lastSeen] > 5.0) {
                // This radio has timed out - remove it
                [self.discoveredRadios removeObjectForKey:keys[i]];
                sendNotification = YES;
                NSLog(@"Radio timeout");
            }
        }
    }
    if (sendNotification)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"K6TURadioFactory" object:self];
}


#pragma mark availabeRadioInstances

- (NSArray *) availableRadioInstances {
    @synchronized(self) {
        return [self.discoveredRadios allValues];
    }
}

#pragma mark 

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
#define MAX_NAME_LENGTH 32
    
    // The typedef below is only used here - it is the format of the discovery packets
    // emitted by the 6000 series radios.  Since we could get other forms of packets or
    // there could be a corruption (unlikely), we check that the port included in the
    // packet matches what we expect.  Probably should check the model number as well
    // to make sure its one we support.
    
    // NOTA BENE: The byte ordering of the data in the payload is little endian for all
    // integer fields - loading 32 bits works without a swap, 16 bits have to be swapped.
    // Go figure...
    
    NSString *host;
    UInt16 hostPort;
    [GCDAsyncUdpSocket getHost:&host port:&hostPort fromAddress:address];

    
    typedef struct _discovery
    {
        UInt32 ip;									// ip address of system
        UInt16 port;								// Port number for control of this radio
        UInt16 radios;								// Number of SCUs in the radio
        UInt32 mask;								// radio present mask
        UInt32 model_len;
        char model[MAX_NAME_LENGTH];                // model number
        UInt32 serial_len;
        char serial[MAX_NAME_LENGTH];               // serial number
        UInt32 name_len;
        char name[MAX_NAME_LENGTH];					// system name
    } discovery_type;
    
    discovery_type *thisRadio = (discovery_type *) (char *)[data bytes];
    
    if (CFSwapInt16(thisRadio->port) == FLEX_CONNECT) {
        // Passes the first test...  FLEX-DISCOVERY protocol and FLEX_CONNECT as
        // the port...
        NSNumber *cPort = [NSNumber numberWithUnsignedInt:CFSwapInt16(thisRadio->port)];
        NSString *model = [NSString stringWithUTF8String:thisRadio->model];
        NSString *serialNum = [NSString stringWithUTF8String:thisRadio->serial];
        NSString *name = [NSString stringWithUTF8String:thisRadio->name];
        
        RadioInstance *newRadio = [[RadioInstance alloc] initWithData:host
                                                                 port:cPort
                                                                model:model
                                                            serialNum:serialNum
                                                                 name:name
                                                             callsign:nil
                                                            dpVersion:nil
                                                              version:nil
                                                               status:nil];
        [self radioFound:newRadio];
    } else {
        // Could be a VITA encoded discovery packet - sent on the same UDP Port
        VITA *vita = [[VITA alloc]initWithPacket:data];
        RadioInstance *newRadio = [[RadioInstance alloc]init];
        
        if (vita.classIdPresent && vita.packetClassCode == VS_Discovery) {
            // Vita encoded discovery packet - crack the payload and parse
            // Payload is a series of strings separated by ' '
            NSString *ds = [[NSString alloc] initWithBytes:vita.payload length:vita.payloadLength encoding:NSASCIIStringEncoding];
            NSArray *fields = [ds componentsSeparatedByString:@" "];
            
            for (NSString *p in fields) {
                NSArray *kv = [p componentsSeparatedByString:@"="];
                
                // One field report of a malformed discovery packet from a 6300 with a null value k/v pair
                // So check in case this is the case (no pun intended) here...
                if( kv.count < 2 )
                    continue;	// Don’t parse an invalid pair
                
                NSString *k = kv[0];
                NSString *v = kv[1];
                int token = [self.parserTokens[k] intValue];
                
                switch (token) {
                    case ipToken:
                        newRadio.ipAddress = v;
                        break;
                        
                    case portToken:
                        newRadio.port = [NSNumber numberWithInt:[v intValue]];
                        break;
                        
                    case modelToken:
                        newRadio.model = v;
                        break;
                        
                    case serialToken:
                        newRadio.serialNum = v;
                        break;
                        
                    case nameToken:
                        newRadio.name = v;
                        break;
                        
                    case callsignToken:
                        newRadio.callsign = v;
                        break;
                        
                    case dpVersionToken:
                        newRadio.dpVersion = v;
                        break;
                        
                    case versionToken:
                        newRadio.version = v;
                        
                    case statusToken:
                        newRadio.status = v;
                        
                    default:
                        break;
                }
            }
            
            [self radioFound:newRadio];
        }
    }
	
    // Post a new read
    NSError *error = nil;
    
	[udpSocket receiveOnce:&error];
}

@end
