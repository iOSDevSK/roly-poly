//
//  BookmarkCardFactory.h
//  RolyPoly
//
//  Created by Martin Ortega on 9/17/13.
//  Copyright (c) 2013 Martin Ortega. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BookmarkCardFactory : NSObject

+ (UIView *)bookmarkCardWithProductName:(NSString *)productName
                       productImagePath:(NSString *)productImagePath
                               shopName:(NSString *)shopName
                                  price:(int)price
                                 rating:(float)rating
                        numberOfRatings:(int)numberOfRatings;

@end
