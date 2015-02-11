//
//  WaterfallTile.h
//  VITA Engine
//
//  Created by STU PHILLIPS on 2/9/15.
//  Copyright (c) 2015 STU PHILLIPS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WaterfallTile : NSObject
@property (strong, nonatomic) NSData *buffer;                       // Buffer holding the Waterfall tile
@property (nonatomic) Float64 firstPixelFreq;                       // Frequency of first Pixel as 64 bit float in MHz
@property (nonatomic) Float64 binBandwidth;                         // Bandwidth of a single pixel bin as 64 bit float in MHz
@property (nonatomic) UInt32 lineDuration;                          // Duration of this line in mS
@property (nonatomic) UInt16 width;                                 // Width of tile in pixels
@property (nonatomic) UInt16 height;                                // Height of tile in pixels
@property (nonatomic) UInt32 timecode;                              // Timecode for this tile
@property (nonatomic) UInt32 autoBlackLevel;                        // Auto black level
@property (nonatomic) void *tile;                                   // Array of tile data as UInt16 values


@end
