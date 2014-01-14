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
@property (strong, nonatomic) NSString *mode;
@property (strong, nonatomic) NSNumber *txLo;
@property (strong, nonatomic) NSNumber *txHi;
@property (strong, nonatomic) NSNumber *lo;
@property (strong, nonatomic) NSNumber *hi;

- (FilterSpec *) initWithLabel: (NSString *) label
                          mode: (NSString *) mode
                    txFilterLo: (NSInteger) txFilterLo
                    txFilterHi: (NSInteger) txFilterHi
                      filterLo: (NSInteger) filterLo
                      filterHi: (NSInteger) filterHi;
@end
