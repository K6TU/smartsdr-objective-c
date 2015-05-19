//
//  Waterfall.h
//  VITA Engine
//
//  Created by STU PHILLIPS on 2/4/15.
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

#import <Foundation/Foundation.h>
#import "Radio.h"
#import "VitaManager.h"
#import "Panafall.h"
#import "WaterfallTile.h"



//
// Protocol used between model and View Controller when data is available for
// the waterfall
//

@protocol WaterfallData <NSObject>

- (void)waterfallTile:(WaterfallTile *) tile;

@end

//
// Model for a Pandaptor for the Flex-6000 series radios
//


@interface Waterfall : NSObject <RadioParser, RadioStreamProcessor, PanafallWaterfallData, VitaStreamHandler>

@property (weak, readonly, nonatomic) Radio *radio;                         // The Radio which owns this panadaptor
@property (weak, readonly, nonatomic) Panafall *panafall;                   // Panafall associated with this waterfall
@property (strong, readonly, nonatomic) NSString *streamId;                 // Identifier of this waterfall (STRING)
@property (readonly, nonatomic) int xPixels;                                // Size of waterfall in pixels
@property (nonatomic) int lineDuration;                                     // Line duration in milliseconds
@property (strong, readonly, nonatomic) NSString *panadaptorId;             // Panadaptor linked to this waterfall (if any)
@property (nonatomic) int colorGain;                                        // Setting of color gain (INT)
@property (nonatomic) BOOL autoBlack;                                       // State of auto black (BOOL)
@property (nonatomic) int blackLevel;                                       // Setting of black level (INT)
@property (nonatomic) int gradientIndex;                                    // Index of selected color gradient (INT)
@property (readonly, nonatomic) UInt32 timecode;                            // Time code of last tile received
@property (readonly, nonatomic) UInt32 droppedTiles;                        // Count of tile dropped because received after current timecode
@property (weak, nonatomic) id <WaterfallData> delegate;                    // Delegate for this waterfall
@property (strong, nonatomic) dispatch_queue_t runQueue;                    // Run queue for this waterfall

@end

