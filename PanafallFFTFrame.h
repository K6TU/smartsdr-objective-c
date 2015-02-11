//
//  PanafallFFTFrame.h
//  VITA Engine
//
//  Created by STU PHILLIPS on 2/9/15.
//  Copyright (c) 2015 STU PHILLIPS. All rights reserved.
//

#import <Foundation/Foundation.h>



//
// PanafallFFTFrame
//

@interface PanafallFFTFrame : NSObject
@property (strong, readwrite, nonatomic) NSData *buffer;                     // Buffer holding the FFT frame
@property (readwrite, nonatomic) UInt32 startBinIndex;                       // Starting bin number for the bins in this update
@property (readwrite, nonatomic) UInt32 numBins;                             // Number of bins in this update
@property (readwrite, nonatomic) UInt32 binSize;                             // Size of bins in bytes
@property (readwrite, nonatomic) UInt32 frameIndex;                          // Index number of this FFT frame
@property (readwrite, nonatomic) UInt16 *bins;                               // Pointer to array of binned data in this update;
@end
