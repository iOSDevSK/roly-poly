//
//  BookmarkCardFactory.m
//  RolyPoly
//
//  Created by Martin Ortega on 9/17/13.
//  Copyright (c) 2013 Martin Ortega. All rights reserved.
//

#import "BookmarkCardFactory.h"

////////////////////////////////////////////////////////////////////////////

@interface BookmarkCardProxy : NSObject

@property (weak, nonatomic) IBOutlet UILabel *productName;
@property (weak, nonatomic) IBOutlet UIImageView *productImage;
@property (weak, nonatomic) IBOutlet UILabel *shopName;
@property (weak, nonatomic) IBOutlet UILabel *price;
@property (weak, nonatomic) IBOutlet UIImageView *rating;
@property (weak, nonatomic) IBOutlet UILabel *numberOfRatings;

@end

@implementation BookmarkCardProxy
@end

////////////////////////////////////////////////////////////////////////////

@implementation BookmarkCardFactory

+ (UIView *)bookmarkCardWithProductName:(NSString *)productName
                       productImagePath:(NSString *)productImagePath
                               shopName:(NSString *)shopName
                                  price:(int)price
                                 rating:(float)rating
                        numberOfRatings:(int)numberOfRatings
{
    BookmarkCardProxy *proxy = [[BookmarkCardProxy alloc] init];
    UIView *bookmarkCard = [[[NSBundle mainBundle] loadNibNamed:@"BookmarkCardView" owner:proxy options:nil] objectAtIndex:0];
    
    proxy.productName.text = productName;
    proxy.productImage.image = [UIImage imageNamed:productImagePath];
    proxy.shopName.text = shopName;
    proxy.price.text = [NSString stringWithFormat:@"¥ %d", price];
    proxy.rating.image = [UIImage imageNamed:[BookmarkCardFactory starImagePathForRating:rating]];
    proxy.numberOfRatings.text = [NSString stringWithFormat:@"(%d)", numberOfRatings];

    return bookmarkCard;
}


+ (NSString *)starImagePathForRating:(float)rating
{
    if (rating < 0.5) {
        return @"stars-0.png";
    }
    
    else if (rating < 1) {
        return @"stars-0.5.png";
    }
    
    else if (rating < 1.5) {
        return @"stars-1.png";
    }
    
    else if (rating < 2) {
        return @"stars-1.5.png";
    }
    
    else if (rating < 2.5) {
        return @"stars-2.png";
    }
    
    else if (rating < 3) {
        return @"stars-2.5.png";
    }
    
    else if (rating < 3.5) {
        return @"stars-3.png";
    }
    
    else if (rating < 4) {
        return @"stars-3.5.png";
    }
    
    else if (rating < 4.5) {
        return @"stars-4.png";
    }
    
    else if (rating < 5) {
        return @"stars-4.5.png";
    }
    
    return @"stars-5.png"; 
}

@end
