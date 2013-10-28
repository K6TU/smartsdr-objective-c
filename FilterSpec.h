//
//  FilterSpec.h
//  K6TU Control
//
//  Created by STU PHILLIPS on 10/18/13.
//  Copyright (c) 2013 STU PHILLIPS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FilterSpec : NSObject
@property (strong, nonatomic) NSString *label;
@property (strong, nonatomic) NSNumber *lo;
@property (strong, nonatomic) NSNumber *hi;

- (FilterSpec *) initWithLabel: (NSString *) label filterLo: (float) filterLo filterHi: (float) filterHi;
@end
