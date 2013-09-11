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
#define NUM_CARDS           10

////////////////////////////////////////////////////////////////////////////

@interface CardListDataSource ()

@property (nonatomic, strong) NSMutableArray *cards;

@end

////////////////////////////////////////////////////////////////////////////

@implementation CardListDataSource


//--------------------------------------------------------------------------

- (NSMutableArray *)cards
{
    if (!_cards) {
        _cards = [NSMutableArray array];
        for (int i = 0; i < NUM_CARDS; i++) {
            [_cards addObject:[self randomCard]];
        }
    }
    
    return _cards;
}

//--------------------------------------------------------------------------

- (int)numberOfCardsForCardList:(CardListViewController *)cardList
{
    return self.cards.count;
}

//--------------------------------------------------------------------------

- (UIView *)cardList:(CardListViewController *)cardList cardForItemAtIndex:(int)index
{
    UIView *card = [self.cards objectAtIndex:index];
    return card;
}

//--------------------------------------------------------------------------

- (void)cardList:(CardListViewController *)cardList removeCardAtIndex:(int)index
{
    [self.cards removeObjectAtIndex:index];
}

//--------------------------------------------------------------------------

- (UIView *)randomCard
{
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    card.backgroundColor = [self randomColor];
    card.layer.cornerRadius = 3;
    card.layer.rasterizationScale = [UIScreen mainScreen].scale;
    card.layer.shouldRasterize = YES;
    return card;
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
