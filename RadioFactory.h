//
//  K6TURadioFactory.h
//
//
//  Created by STU PHILLIPS, K6TU on 8/2/13.
//  Copyright (c) 2013 STU PHILLIPS. All rights reserved.
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

// This model class is depedent on the AysncUDPSocket class developed by
// Robbie Hansen.  It is part of the CocoaAsyncSocket project which can
// be found on github at:
//
//  https://github.com/robbiehanson/CocoaAsyncSocket
//

#import "GCDAsyncUdpSocket.h"


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
// this is ""FLEX-6300", FLEX-6500" or "FLEX-6700".

@property (strong, nonatomic) NSString *model;

// serialNum:  The serial number of the radio represented in string form.

@property (strong, nonatomic) NSString *serialNum;

// name: The user configurable name of this radio instance as a string.

@property (strong, nonatomic) NSString *name;

// callsign: The user configurable callsign of this radio instance as a string

@property (strong, nonatomic) NSString *callsign;

// dpVersion: The version of the discovery protocol emitted by this radio

@property (strong, nonatomic) NSString *dpVersion;

// version: The version of software in this radio

@property (strong, nonatomic) NSString *version;

// status:  status of this radio instance

@property (strong, nonatomic) NSString *status;



// lastSeen:  The date and time of which a discovery message from this radio
// instance was last received.
@property (strong, nonatomic) NSDate *lastSeen;


// initWithData: class initializer for creating a RadioInstance.  Used by the
// RadioFactory when initializing a radio detected via the dicovery protocol.

- initWithData: (NSString *) ipAddress
          port: (NSNumber *) port
         model: (NSString *) model
     serialNum: (NSString *) serialNum
          name: (NSString *) name
      callsign: (NSString *) callsign
     dpVersion: (NSString *) dpVersion
       version: (NSString *) version
        status: (NSString *) status;
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

@interface RadioFactory : NSObject <GCDAsyncUdpSocketDelegate>

// availableRadioInstances: returns an NSArray containing RadioInstance objects of
// all the radios currently discovered by the RadioFactory.

- (NSArray *) availableRadioInstances;

// close: Must be called to close down the RadioFactory and cause it to release
// all underlying resources.

- (void) close;
@end
