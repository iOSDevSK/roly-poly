//
//  CardListDataSource.m
//  RolyPoly
//
//  Created by Martin Ortega on 9/2/13.
//  Copyright (c) 2013 Martin Ortega. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "CardListDataSource.h"

#define ARC4RANDOM_MAX      0x100000000

////////////////////////////////////////////////////////////////////////////

@interface CardListDataSource ()

@property (nonatomic, readwrite) int numberOfCardsForCardList;

@end

////////////////////////////////////////////////////////////////////////////

@implementation CardListDataSource

//--------------------------------------------------------------------------

- (int)numberOfCardsForCardList:(CardListViewController *)cardList
{
    return 10;
}

//--------------------------------------------------------------------------

- (UIView *)cardList:(CardListViewController *)cardList cardForItemAtIndex:(int)index
{
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    card.backgroundColor = [self randomColor];
    card.layer.cornerRadius = 3;
    card.layer.rasterizationScale = [UIScreen mainScreen].scale;
    card.layer.shouldRasterize = YES;
    return card;
}

//--------------------------------------------------------------------------

- (void)cardList:(CardListViewController *)cardList removeCardAtIndex:(int)index
{
    NSLog(@"Ok, I'm removing the item at index %d", index);
}

//--------------------------------------------------------------------------

- (UIColor *)randomColor
{
    static CGFloat mixRed   = 0;
    static CGFloat mixGreen = 0.7843;
    static CGFloat mixBlue  = 1.0;
    
    CGFloat randomRed   = 0.471 * (2*((double)arc4random() / ARC4RANDOM_MAX) - 1);
    CGFloat randomGreen = 0.471 * (2*((double)arc4random() / ARC4RANDOM_MAX) - 1);
    CGFloat randomBlue  = 0.471 * (2*((double)arc4random() / ARC4RANDOM_MAX) - 1);
    
    UIColor *randomColor = [[UIColor alloc] initWithRed:(randomRed + mixRed)/2.0
                                                  green:(randomGreen + mixGreen)/2.0
                                                   blue:(randomBlue + mixBlue)/2.0 alpha:1.0];
    
    return randomColor;
}

@end
