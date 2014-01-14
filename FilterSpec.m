//
//  FilterSpec.m
//  K6TU Control
//
//  Created by STU PHILLIPS on 10/18/13.
//  Copyright (c) 2013 STU PHILLIPS. All rights reserved.
//

#import "FilterSpec.h"

@implementation FilterSpec

- (FilterSpec *) initWithLabel:(NSString *)label mode:(NSString *)mode txFilterLo:(NSInteger)txFilterLo txFilterHi:(NSInteger)txFilterHi filterLo:(NSInteger)filterLo filterHi:(NSInteger)filterHi {
    self.label = label;
    self.mode = mode;
    self.txLo = [NSNumber numberWithInteger:txFilterLo];
    self.txHi = [NSNumber numberWithInteger:txFilterHi];
    self.lo = [NSNumber numberWithInteger:filterLo];
    self.hi = [NSNumber numberWithInteger:filterHi];
    
    return self;
}

@end
