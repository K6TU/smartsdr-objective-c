//
//  FilterSpec.m
//  K6TU Control
//
//  Created by STU PHILLIPS on 10/18/13.
//  Copyright (c) 2013 STU PHILLIPS. All rights reserved.
//

#import "FilterSpec.h"

@implementation FilterSpec

- (FilterSpec *) initWithLabel: (NSString *) label filterLo: (float)filterLo filterHi:(float)filterHi {
    self.label = label;
    self.lo = [NSNumber numberWithInt:filterLo];
    self.hi = [NSNumber numberWithInt:filterHi];
    
    return self;
}

@end
