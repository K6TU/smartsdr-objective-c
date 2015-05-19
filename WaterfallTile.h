//
//  WaterfallTile.h
//  VITA Engine
//
//  Created by STU PHILLIPS on 2/9/15.
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
