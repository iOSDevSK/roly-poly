//
//  CardListViewController.m
//  RolyPoly
//
//  Created by Martin Ortega on 9/1/13.
//  Copyright (c) 2013 Martin Ortega. All rights reserved.
//

#import "CardListViewController.h"

////////////////////////////////////////////////////////////////////////////

@interface CardListViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, readonly) CGFloat padding;
@property (nonatomic, readonly) CGFloat cardWidth;
@property (nonatomic, readonly) CGFloat defaultCardHeight;
@property (nonatomic, strong) NSArray *cardPositions;
@property (nonatomic, strong) NSArray *cardHeights;
@property (nonatomic, strong) NSMutableDictionary *visibleCards;

@property (nonatomic, readonly) CGFloat slideDuration;
@property (nonatomic, readonly) CGFloat slideDelay;

@property (nonatomic, readwrite) int indexOfFirstVisibleCard;
@property (nonatomic, readwrite) int indexOfLastVisibleCard;

@end

////////////////////////////////////////////////////////////////////////////

@implementation CardListViewController

//--------------------------------------------------------------------------

#pragma mark - Default Initializer

- (CardListViewController *)initWithDataSource:(id<CardListDataSource>)dataSource
                                      delegate:(id<CardListDelegate>)delegate
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.dataSource = dataSource;
        self.delegate = delegate;
    }
    return self;
}

//--------------------------------------------------------------------------

#pragma mark - View Lifecycle

- (void)loadView
{
    UIScrollView *scrollView = [self createScrollView];
    scrollView.delegate = self;
    self.view = scrollView;

    [self loadInitiallyVisibleCards];
}

//--------------------------------------------------------------------------

#pragma mark - Scroll View Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // update index of first visible card
    while ([self shouldDecrementIndexOfFirstVisibleCard]) {
        self.indexOfFirstVisibleCard -= 1;
        [self loadCardAtIndex:self.indexOfFirstVisibleCard animated:NO];
    }
    
    while ([self shouldIncrementIndexOfFirstVisibleCard]) {
        [self unloadCardAtIndex:self.indexOfFirstVisibleCard];
        self.indexOfFirstVisibleCard += 1;
    }
    
    // update index of last visible card
    while ([self shouldIncrementIndexOfLastVisibleCard]) {
        self.indexOfLastVisibleCard += 1;
        [self loadCardAtIndex:self.indexOfLastVisibleCard animated:YES];
    }
    
    while ([self shouldDecrementIndexOfLastVisibleCard]) {
        [self unloadCardAtIndex:self.indexOfLastVisibleCard];
        self.indexOfLastVisibleCard -= 1;
    }
}

//--------------------------------------------------------------------------

#pragma mark - Property Getters and Setters

- (CGFloat)padding
{
    return 25;
}


- (CGFloat)cardWidth
{
    return self.view.frame.size.width - 20;
}


- (CGFloat)defaultCardHeight
{
    return 250;
}


- (NSArray *)cardPositions
{
    if (!_cardPositions) {
        _cardPositions = [NSArray array];
        int numberOfCards = [self.dataSource numberOfCardsForCardList:self];
        for (int i = 0; i < numberOfCards; i++) {
            CGFloat position = self.padding;
            
            if (i > 0) {
                NSNumber *positionOfPreviousCard = [_cardPositions objectAtIndex:i - 1];
                NSNumber *heightOfPreviousCard = [self.cardHeights objectAtIndex:i - 1];

                position += positionOfPreviousCard.floatValue + heightOfPreviousCard.floatValue;
            }
            
            _cardPositions = [_cardPositions arrayByAddingObject:[NSNumber numberWithFloat:position]];
        }
    }
    
    return _cardPositions;
}


- (NSArray *)cardHeights
{
    if (!_cardHeights) {
        _cardHeights = [NSArray array];
        int numberOfCards = [self.dataSource numberOfCardsForCardList:self];
        for (int i = 0; i < numberOfCards; i++) {
            CGFloat height = self.defaultCardHeight;
            if ([self.dataSource respondsToSelector:@selector(cardList:heightForCardAtIndex:)]) {
                height = [self.dataSource cardList:self heightForCardAtIndex:i];
            }
            _cardHeights = [_cardHeights arrayByAddingObject:[NSNumber numberWithFloat:height]];
        }
    }
    
    return _cardHeights;
}

- (NSMutableDictionary *)visibleCards
{
    if (!_visibleCards) {
        _visibleCards = [[NSMutableDictionary alloc] init];
    }

    return _visibleCards;
}


- (CGFloat)slideDuration
{
    return 0.4;
}


- (CGFloat)slideDelay
{
    return 0.2;
}


- (CGFloat)deletionSwipeThreshold
{
    return 0.75 * self.cardWidth;
}

//--------------------------------------------------------------------------

#pragma mark - Loading and Unloading Cards

- (void)loadInitiallyVisibleCards
{
    [self loadCardAtIndex:self.indexOfLastVisibleCard animated:YES];
    
    CGFloat delay = 0.3;
    
    while ([self shouldIncrementIndexOfLastVisibleCard]) {
        self.indexOfLastVisibleCard += 1;
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self loadCardAtIndex:self.indexOfLastVisibleCard animated:YES];
        });
        
        delay += 0.3;
    }
}


- (void)loadCardAtIndex:(int)index animated:(BOOL)animated
{
    NSLog(@"loading card at index\t%d", index);

    UIView *card = [self.dataSource cardList:self cardForItemAtIndex:index];
    CGFloat width = self.cardWidth;
    CGFloat height = ((NSNumber *)[self.cardHeights objectAtIndex:index]).floatValue;
    CGFloat x = self.view.center.x - width/2;
    CGFloat y = ((NSNumber *)[self.cardPositions objectAtIndex:index]).floatValue;
    card.frame = CGRectMake(x, y, width, height);
    
    NSLog(@"adding recognizer to card %d", index);
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFromRecognizer:)];
    panRecognizer.delegate = self;
    [card addGestureRecognizer:panRecognizer];
    
    NSNumber *key = [NSNumber numberWithInt:index];
    [self.visibleCards setObject:card forKey:key];
    [self.view addSubview:card];
    
    if (animated) {
        [self slideCardIntoPlace:card];
    }
}


- (void)unloadCardAtIndex:(int)index
{
    NSLog(@"unloading card at index\t%d", index);
    
    NSNumber *key = [NSNumber numberWithInt:index];
    UIView *card = [self.visibleCards objectForKey:key];
    
    [self.visibleCards removeObjectForKey:key];
    [card removeFromSuperview];
}


- (void)slideCardIntoPlace:(UIView *)card
{
    static BOOL enterFromLeft = NO;
    enterFromLeft = !enterFromLeft;
    
    UIScrollView *scrollView = (UIScrollView *)self.view;
    CGFloat yOffset = 200 + scrollView.contentOffset.y + scrollView.frame.size.height - card.frame.origin.y;
    
    card.transform = CGAffineTransformConcat(CGAffineTransformMakeTranslation(0, yOffset),
                                             CGAffineTransformMakeRotation(enterFromLeft ? M_PI/10 : -M_PI/10));
    [UIView animateWithDuration:self.slideDuration
                          delay:self.slideDelay
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         card.transform = CGAffineTransformIdentity;
                     }
                     completion:nil];
}

//--------------------------------------------------------------------------

#pragma mark - Swipe To Delete Cards

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    UIPanGestureRecognizer *panRecognizer = (UIPanGestureRecognizer *)gestureRecognizer;
    
    CGPoint translation = [panRecognizer translationInView:self.view];
    CGFloat x = translation.x;
    CGFloat y = translation.y;
    
    BOOL slopeLessThanOneThird = fabs(y/x) < 1.0/3.0;
    BOOL slopeUndefined = x == 0 && y == 0;
            
    return slopeLessThanOneThird || slopeUndefined;
}


- (void)handlePanFromRecognizer:(UIPanGestureRecognizer *)recognizer
{
    static CGFloat deleteThreshold = 190.0;
    
    UIView *card = recognizer.view;

    CGFloat horizontalOffset = [recognizer translationInView:self.view].x;
        
    CGFloat angle = [self angleForHorizontalOffset:horizontalOffset];
    CGFloat alpha = [self alphaForHorizontalOffset:horizontalOffset];
    
    card.transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(angle),
                                             CGAffineTransformMakeTranslation(horizontalOffset, 0));
    card.alpha = alpha;
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (fabs(horizontalOffset) > deleteThreshold) {
            [self deleteCard:card];
        } else {
            [self returnCardToOriginalState:card];
        }
    }
}


- (CGFloat)angleForHorizontalOffset:(CGFloat)horizontalOffset
{
    static CGFloat rotationThreshold = 60;
    
    CGFloat direction = horizontalOffset >= 0 ? 1.0 : -1.0;
    horizontalOffset = fabsf(horizontalOffset);
    
    if (horizontalOffset < rotationThreshold) {
        return 0;
    }
    
    CGFloat angle = direction * (horizontalOffset - rotationThreshold) * (M_PI/1000);
    
    return angle;
}


- (CGFloat)alphaForHorizontalOffset:(CGFloat)horizontalOffset
{
    static CGFloat alphaThreshold = 60;
    
    horizontalOffset = fabsf(horizontalOffset);
    
    if (horizontalOffset < alphaThreshold) {
        return 1.0;
    }
    
    CGFloat alpha = powf(M_E, -powf((horizontalOffset - alphaThreshold)/125, 2));
    
    return alpha;
}


- (void)returnCardToOriginalState:(UIView *)card
{
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         card.transform = CGAffineTransformIdentity;
                         card.alpha = 1.0;
                     }
                     completion:nil];
}


- (void)deleteCard:(UIView *)card
{
    NSLog(@"DELETE");
}

//--------------------------------------------------------------------------

#pragma mark - Card Visibility

- (BOOL)shouldDecrementIndexOfFirstVisibleCard
{
    UIScrollView *scrollView = (UIScrollView *)self.view;
    
    NSNumber *positionOfFirstVisibleCard = [self.cardPositions objectAtIndex:self.indexOfFirstVisibleCard];
    BOOL cardAboveIsVisible = positionOfFirstVisibleCard.floatValue - scrollView.contentOffset.y > self.padding;
    BOOL isFirstCardInList = self.indexOfFirstVisibleCard == 0;
    
    return cardAboveIsVisible && !isFirstCardInList;
}


- (BOOL)shouldIncrementIndexOfFirstVisibleCard
{
    UIScrollView *scrollView = (UIScrollView *)self.view;
    int numberOfCards = [self.dataSource numberOfCardsForCardList:self];
    
    NSNumber *positionOfFirstVisibleCard = [self.cardPositions objectAtIndex:self.indexOfFirstVisibleCard];
    NSNumber *heightOfFirstVisibleCard = [self.cardHeights objectAtIndex:self.indexOfFirstVisibleCard];
    
    BOOL cardIsNotVisible = positionOfFirstVisibleCard.floatValue + heightOfFirstVisibleCard.floatValue <= scrollView.contentOffset.y;
    BOOL isLastCardInList = self.indexOfFirstVisibleCard == numberOfCards - 1;
    
    return cardIsNotVisible && !isLastCardInList;
}


- (BOOL)shouldDecrementIndexOfLastVisibleCard
{
    UIScrollView *scrollView = (UIScrollView *)self.view;
    
    NSNumber *positionOfLastVisibleCard = [self.cardPositions objectAtIndex:self.indexOfLastVisibleCard];
    CGFloat positionOfScreenBottom = scrollView.contentOffset.y + scrollView.frame.size.height;
    
    BOOL cardIsNotVisible = positionOfLastVisibleCard.floatValue > positionOfScreenBottom;
    BOOL isFirstCardInList = self.indexOfLastVisibleCard == 0;
    
    return cardIsNotVisible && !isFirstCardInList;
}


- (BOOL)shouldIncrementIndexOfLastVisibleCard
{
    UIScrollView *scrollView = (UIScrollView *)self.view;
    int numberOfCards = [self.dataSource numberOfCardsForCardList:self];
    
    NSNumber *positionOfLastVisibleCard = [self.cardPositions objectAtIndex:self.indexOfLastVisibleCard];
    NSNumber *heightOfLastVisibleCard = [self.cardHeights objectAtIndex:self.indexOfLastVisibleCard];
    
    CGFloat positionOfScreenBottom = scrollView.contentOffset.y + scrollView.frame.size.height;
    CGFloat positionOfCardBottom = positionOfLastVisibleCard.floatValue + heightOfLastVisibleCard.floatValue;
    
    BOOL cardBelowIsVisble = positionOfScreenBottom - positionOfCardBottom > self.padding;
    BOOL isLastCardInList = self.indexOfLastVisibleCard == numberOfCards - 1;
    
    return cardBelowIsVisble && !isLastCardInList;
}

//--------------------------------------------------------------------------

#pragma mark - Helpers

- (UIScrollView *)createScrollView
{
    CGRect fullScreenRect = [[UIScreen mainScreen] applicationFrame];
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:fullScreenRect];
    scrollView.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    
    CGFloat contentWidth = [[UIScreen mainScreen] applicationFrame].size.width;
    CGFloat contentHeight = self.padding;
    
    for (NSNumber *cardHeight in self.cardHeights) {
        contentHeight += self.padding + cardHeight.floatValue;
    }
    
    scrollView.contentSize = CGSizeMake(contentWidth, contentHeight);
    
    return scrollView;
}

@end
