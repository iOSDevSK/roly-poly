//
//  Bookmark.m
//  RolyPoly
//
//  Created by Martin Ortega on 9/18/13.
//  Copyright (c) 2013 Martin Ortega. All rights reserved.
//

#import "Bookmark.h"

@implementation Bookmark

- (id)initWithProductName:(NSString *)productName
         productImagePath:(NSString *)productImagePath
                 shopName:(NSString *)shopName
                    price:(int)price
                   rating:(float)rating
          numberOfRatings:(int)numberOfRatings
{
    self = [super init];
    if (self) {
        self.productName = productName;
        self.productImagePath = productImagePath;
        self.shopName = shopName;
        self.price = price;
        self.rating = rating;
        self.numberOfRatings = numberOfRatings;
    }
    return self;
}

@end
