//
//  CardListDataSource.m
//  RolyPoly
//
//  Created by Martin Ortega on 9/2/13.
//  Copyright (c) 2013 Martin Ortega. All rights reserved.
//

#import "CardListDataSource.h"
#import "BookmarkCardFactory.h"
#import "Bookmark.h"

////////////////////////////////////////////////////////////////////////////

@interface CardListDataSource ()

@property (nonatomic, strong) NSMutableArray *bookmarks;
@property (nonatomic, strong) NSMutableArray *cards;

@end

////////////////////////////////////////////////////////////////////////////

@implementation CardListDataSource


//--------------------------------------------------------------------------

- (NSMutableArray *)bookmarks
{
    if (!_bookmarks) {
        Bookmark *canonRebel = [[Bookmark alloc] initWithProductName:@"Canon EOS Rebel T4i"
                                                    productImagePath:@"canon-rebel.png"
                                                            shopName:@"New Egg"
                                                               price:80614
                                                              rating:4.5
                                                     numberOfRatings:756];
        
        Bookmark *marketPlace = [[Bookmark alloc] initWithProductName:@"Marketplace 3.0"
                                                     productImagePath:@"marketplace.png"
                                                             shopName:@"Rakuten Books"
                                                                price:1802
                                                               rating:5
                                                      numberOfRatings:1];
        
        Bookmark *basketball = [[Bookmark alloc] initWithProductName:@"NBA Game Ball"
                                                    productImagePath:@"basketball.png"
                                                            shopName:@"Jump USA"
                                                               price:9913
                                                              rating:5
                                                     numberOfRatings:84];
        
        Bookmark *iphone = [[Bookmark alloc] initWithProductName:@"iPhone 5C"
                                                productImagePath:@"iphone-5c.png"
                                                        shopName:@"Apple Inc."
                                                           price:53457
                                                          rating:4.5
                                                 numberOfRatings:405];
        
        Bookmark *espresso = [[Bookmark alloc] initWithProductName:@"Phillips Saeco"
                                                  productImagePath:@"phillips-saeco.png"
                                                          shopName:@"Sears"
                                                             price:63453
                                                            rating:4
                                                   numberOfRatings:245];
        
        Bookmark *glove = [[Bookmark alloc] initWithProductName:@"Mizuno Pro Limited Edition"
                                               productImagePath:@"baseball-glove.png"
                                                       shopName:@"Mizuno USA"
                                                          price:49565
                                                         rating:5
                                                numberOfRatings:422];
        
        Bookmark *baloons = [[Bookmark alloc] initWithProductName:@"Party Balloons"
                                               productImagePath:@"balloons.png"
                                                       shopName:@"Party City"
                                                          price:1231
                                                         rating:3
                                                numberOfRatings:27];
        
        Bookmark *batman = [[Bookmark alloc] initWithProductName:@"Batman Utitility Belt"
                                                productImagePath:@"batman-utility-belt.png"
                                                        shopName:@"Wayne Enterprises"
                                                           price:29991
                                                          rating:5
                                                 numberOfRatings:124];
        
        Bookmark *chia = [[Bookmark alloc] initWithProductName:@"Mr. T Chia Pet"
                                              productImagePath:@"chia-pet.png"
                                                      shopName:@"Walmart"
                                                         price:500
                                                        rating:2
                                               numberOfRatings:833];
        
        Bookmark *competitiveness = [[Bookmark alloc] initWithProductName:@"Competitiveness"
                                                         productImagePath:@"competitiveness.png"
                                                                 shopName:@"Rakuten Books"
                                                                    price:5231
                                                                   rating:4.5
                                                          numberOfRatings:15];
        
        _bookmarks = [NSMutableArray arrayWithArray:@[ canonRebel, marketPlace, basketball, iphone, espresso, glove, baloons, batman, competitiveness, chia ]];
    }
    
    return _bookmarks;
}

//--------------------------------------------------------------------------

- (NSMutableArray *)cards
{
    if (!_cards) {
        _cards = [NSMutableArray array];
        for (Bookmark *bookmark in self.bookmarks) {
            UIView *card = [BookmarkCardFactory createBookmarkCardFromBookmark:bookmark];
            [_cards addObject:card];
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
    return [self.cards objectAtIndex:index];
}

//--------------------------------------------------------------------------

- (void)cardList:(CardListViewController *)cardList removeCardAtIndex:(int)index
{
    [self.cards removeObjectAtIndex:index];
}

@end
