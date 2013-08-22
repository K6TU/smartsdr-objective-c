//
//  K6TURadioFactory.h
//
//
//  Created by STU PHILLIPS, K6TU on 8/2/13.
//  Copyright (c) 2013 STU PHILLIPS. All rights reserved.
//
// NOTE: THe license under which this software will be generally released
// is still under consideration.  For now, use of this software requires
// the specific approval of Stu Phillips, K6TU.

#import <Foundation/Foundation.h>

// This model class is depedent on the AysncUDPSocket class developed by
// Robbie Hansen.  It is part of the CocoaAsyncSocket project which can
// be found on github at:
//
//  https://github.com/robbiehanson/CocoaAsyncSocket
//

#import "AsyncUdpSocket.h"


//
// RadioInstance:  Class to hold the specific information for each
// FlexRadio Systems 6000 series radio found by the RadioFactory via
// the radio disovery protocol.
//

@interface RadioInstance : NSObject

// ipAddress:  The IP address of the radio represented by this instance.
// NOTE:  The IP address is in decimal doted format - ie "1.1.1.1" as
// a string.

@property (strong, nonatomic) NSString *ipAddress;

// port: The TCP port number for accessing the Ethernet control API.

@property (strong, nonatomic) NSNumber *port;

// model: The model number of the radio returned as a string.  Currently
// this is "FLEX-6500" or "FLEX-6700".

@property (strong, nonatomic) NSString *model;

// serialNum:  The serial number of the radio represented in string form.

@property (strong, nonatomic) NSString *serialNum;

// name: The user conffigurable name of this radio instance as a string.

@property (strong, nonatomic) NSString *name;

// lastSeen:  The date and time of which a discovery message from this radio
// instance was last received.
@property (strong, nonatomic) NSDate *lastSeen;


// initWithData: class initializer for creating a RadioInstance.  Used by the
// RadioFactory when initializing a radio detected via the dicovery protocol.

- initWithData: (NSString *) ipAddress
          port: (NSNumber *) port
         model: (NSString *) model
     serialNum: (NSString *) serialNum
          name: (NSString *) name;
@end


// RadioFactory:  Instantiate this class to create a Radio Factory which will
// maintain a set of RadioInstances for radios discovered on the network.
//
// Changes to the set of RadioInstances are signaled via the default
// Notification Center using the notification name "K6TURadioFactory".
//
// This notification is provided whenever the set of RadioInstances changes
// either via a new radio being discovered or an existing radio timing out and
// being removed from the set of RadioInstances.

@interface RadioFactory : NSObject <AsyncUdpSocketDelegate>

// availableRadioInstances: returns an NSArray containing RadioInstance objects of
// all the radios currently discovered by the RadioFactory.

- (NSArray *) availableRadioInstances;

// close: Must be called to close down the RadioFactory and cause it to release
// all underlying resources.

- (void) close;
@end
