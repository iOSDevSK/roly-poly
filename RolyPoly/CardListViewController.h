//
//  CardListViewController.h
//  RolyPoly
//
//  Created by Martin Ortega on 9/1/13.
//  Copyright (c) 2013 Martin Ortega. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CardListViewController;

////////////////////////////////////////////////////////////////////////////

@protocol CardListDataSource <NSObject>

@required
- (int)numberOfCardsForCardList:(CardListViewController *)cardList;
- (UIView *)cardList:(CardListViewController *)cardList cardForItemAtIndex:(int)index;
- (void)cardList:(CardListViewController *)cardList removeCardAtIndex:(int)index;

@optional
- (CGFloat)cardList:(CardListViewController *)cardList heightForCardAtIndex:(int)index;

@end

////////////////////////////////////////////////////////////////////////////

@protocol CardListDelegate <NSObject>

@end

////////////////////////////////////////////////////////////////////////////

@interface CardListViewController : UIViewController

@property (nonatomic, strong) id dataSource;
@property (nonatomic, strong) id delegate;

- (CardListViewController *)initWithDataSource:(id<CardListDataSource>)dataSource
                                      delegate:(id<CardListDelegate>)delegate;

@end
