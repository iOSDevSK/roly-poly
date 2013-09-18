//
//  Bookmark.h
//  RolyPoly
//
//  Created by Martin Ortega on 9/18/13.
//  Copyright (c) 2013 Martin Ortega. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Bookmark : NSObject

@property (nonatomic, strong) NSString *productName;
@property (nonatomic, strong) NSString *productImagePath;
@property (nonatomic, strong) NSString *shopName;
@property (nonatomic) int price;
@property (nonatomic) float rating;
@property (nonatomic) int numberOfRatings;

- (id)initWithProductName:(NSString *)productName
         productImagePath:(NSString *)productImagePath
                 shopName:(NSString *)shopName
                    price:(int)price
                   rating:(float)rating
          numberOfRatings:(int)numberOfRatings;

@end
