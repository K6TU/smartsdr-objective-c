//
//  Waterfall.h
//  VITA Engine
//
//  Created by STU PHILLIPS on 2/4/15.
//  Copyright (c) 2015 STU PHILLIPS. All rights reserved.
//
// NOTE: THe license under which this software will be generally released
// is still under consideration.  For now, use of this software requires
// the specific approval of Stu Phillips, K6TU.

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


@interface Waterfall : NSObject <RadioParser, RadioDisplay, PanafallWaterfallData, VitaStreamHandler>

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
@property (weak, nonatomic) id delegate;                                    // Delegate for this waterfall
@property (strong, nonatomic) dispatch_queue_t runQueue;                    // Run queue for this waterfall

@end

