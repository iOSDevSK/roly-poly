//
//  CardListViewController.m
//  RolyPoly
//
//  Created by Martin Ortega on 9/1/13.
//  Copyright (c) 2013 Martin Ortega. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "CardListViewController.h"

typedef enum {
    Left,
    Right
} Direction;

////////////////////////////////////////////////////////////////////////////

@interface CardListViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, readonly) CGFloat padding;
@property (nonatomic, readonly) CGFloat cardWidth;
@property (nonatomic, readonly) CGFloat defaultCardHeight;

@property (nonatomic, readwrite) int numberOfCards;
@property (nonatomic, strong) NSMutableArray *cardPositions;
@property (nonatomic, strong) NSMutableArray *cardHeights;
@property (nonatomic, strong) NSMutableDictionary *visibleCards;

@property (nonatomic, readonly) CGFloat slideDuration;
@property (nonatomic, readonly) CGFloat slideDelay;

@property (nonatomic, readwrite) int indexOfFirstVisibleCard;
@property (nonatomic, readwrite) int indexOfLastVisibleCard;

@property (nonatomic, readwrite) BOOL isScrollingProgrammatically;

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
    if (self.isScrollingProgrammatically || self.numberOfCards <= 0) return;
    
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


- (int)numberOfCards
{
    if (!_numberOfCards) {
        _numberOfCards = [self.dataSource numberOfCardsForCardList:self];
    }
    
    return _numberOfCards;
}


- (NSArray *)cardPositions
{
    if (!_cardPositions) {
        _cardPositions = [NSMutableArray array];
        for (int i = 0; i < self.numberOfCards; i++) {
            CGFloat position = self.padding;
            
            if (i > 0) {
                NSNumber *positionOfPreviousCard = [_cardPositions objectAtIndex:i - 1];
                NSNumber *heightOfPreviousCard = [self.cardHeights objectAtIndex:i - 1];

                position += positionOfPreviousCard.floatValue + heightOfPreviousCard.floatValue;
            }
            
            [_cardPositions addObject:[NSNumber numberWithFloat:position]];
        }
    }
    
    return _cardPositions;
}


- (NSArray *)cardHeights
{
    if (!_cardHeights) {
        _cardHeights = [NSMutableArray array];
        for (int i = 0; i < self.numberOfCards; i++) {
            CGFloat height = self.defaultCardHeight;
            if ([self.dataSource respondsToSelector:@selector(cardList:heightForCardAtIndex:)]) {
                height = [self.dataSource cardList:self heightForCardAtIndex:i];
            }
            [_cardHeights addObject:[NSNumber numberWithFloat:height]];
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

//--------------------------------------------------------------------------

#pragma mark - Loading and Unloading Cards

- (void)loadInitiallyVisibleCards
{
    [self loadCardAtIndex:self.indexOfLastVisibleCard animated:YES];
    
    CGFloat delay = 0.3;
    
    while ([self shouldIncrementIndexOfLastVisibleCard]) {
        self.indexOfLastVisibleCard += 1;
        int index = self.indexOfLastVisibleCard;
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self loadCardAtIndex:index animated:YES];
        });
        
        delay += 0.3;
    }
}


- (void)loadCardAtIndex:(int)index animated:(BOOL)animated
{
    UIView *card = [self.dataSource cardList:self cardForItemAtIndex:index];
    CGFloat width = self.cardWidth;
    CGFloat height = ((NSNumber *)[self.cardHeights objectAtIndex:index]).floatValue;
    CGFloat x = self.view.center.x - width/2;
    CGFloat y = ((NSNumber *)[self.cardPositions objectAtIndex:index]).floatValue;
    card.frame = CGRectMake(x, y, width, height);
        
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
                        options: UIViewAnimationOptionCurveEaseOut
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
    Direction direction = horizontalOffset < 0 ? Left : Right;
        
    CGFloat angle = [self angleForHorizontalOffset:horizontalOffset];
    CGFloat alpha = [self alphaForHorizontalOffset:horizontalOffset];
    
    card.transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(angle),
                                             CGAffineTransformMakeTranslation(horizontalOffset, 0));
    card.alpha = alpha;
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (fabs(horizontalOffset) > deleteThreshold) {
            [self slideCardOffScreen:card inDirection:direction completion:^(BOOL finished) {
                [self deleteCard:card];
            }];
        } else {
            [self returnCardToOriginalState:card];
        }
    }
}


- (CGFloat)angleForHorizontalOffset:(CGFloat)horizontalOffset
{
    static CGFloat rotationThreshold = 80;
    
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
    static CGFloat alphaThreshold = 80;
    
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
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         card.transform = CGAffineTransformIdentity;
                         card.alpha = 1.0;
                     }
                     completion:nil];
}


- (void)slideCardOffScreen:(UIView *)card inDirection:(Direction)direction completion:(void (^)(BOOL finished))completion
{
    CGFloat finalOffset = 1.5 * self.view.frame.size.width;
    if (direction == Left) {
        finalOffset *= -1;
    }
    
    CGFloat finalAngle = [self angleForHorizontalOffset:finalOffset];
    CGFloat finalAlpha = [self alphaForHorizontalOffset:finalOffset];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         card.transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(finalAngle),
                                                                  CGAffineTransformMakeTranslation(finalOffset, 0));
                         card.alpha = finalAlpha;
                     }
                     completion:completion];
}


- (void)deleteCard:(UIView *)card
{
    int index = [self indexForVisibleCard:card];
    
    NSMutableArray *oldCardPositions = [NSMutableArray arrayWithArray:self.cardPositions];
    [oldCardPositions removeObjectAtIndex:index];
    
    [self removeStateForCardAtIndex:index];
    CGFloat overlap = [self makeScrollViewShorter];
    
    if (self.numberOfCards <= 0) return;
    
    [self updateVisibleCardsAfterCardRemovedFromIndex:index];
    
    // put visible cards in their old positions
    for (int visibleCardIndex = self.indexOfFirstVisibleCard; visibleCardIndex <= self.indexOfLastVisibleCard; visibleCardIndex++) {
        UIView *card = [self.visibleCards objectForKey:[NSNumber numberWithInt:visibleCardIndex]];
        CGFloat x = card.frame.origin.x;
        CGFloat y = ((NSNumber *)[oldCardPositions objectAtIndex:visibleCardIndex]).floatValue - overlap;
        CGFloat width = card.frame.size.width;
        CGFloat height = card.frame.size.height;
        card.frame = CGRectMake(x, y, width, height);
    }
    
    [self fillEmptySpaceLeftByCardAtIndex:index];
}


- (void)removeStateForCardAtIndex:(int)index
{
    [self.dataSource cardList:self removeCardAtIndex:index];
    [self unloadCardAtIndex:index];
    self.numberOfCards--;
    
    CGFloat removedCardHeight = ((NSNumber *)[self.cardHeights objectAtIndex:index]).floatValue;
    [self.cardHeights removeObjectAtIndex:index];
    
    [self.cardPositions removeObjectAtIndex:index];
    for (int i = index; i < [self.cardPositions count]; i++) {
        CGFloat position = ((NSNumber *)[self.cardPositions objectAtIndex:i]).floatValue;
        position -= removedCardHeight + self.padding;
        [self.cardPositions replaceObjectAtIndex:i withObject:[NSNumber numberWithFloat:position]];
    }
    
    self.indexOfLastVisibleCard--;
    
    NSArray *keysInOrder =  [self.visibleCards.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSNumber *a, NSNumber *b) {
        return [a compare:b];
    }];
    
    for (NSNumber *key in keysInOrder) {
        int cardIndex = key.intValue;
        if (cardIndex > index) {
            UIView *card = [self.visibleCards objectForKey:key];
            [self.visibleCards removeObjectForKey:key];
            cardIndex--;
            NSNumber *newKey = [NSNumber numberWithInt:cardIndex];
            [self.visibleCards setObject:card forKey:newKey];
        }
    }
}


- (void)updateVisibleCardsAfterCardRemovedFromIndex:(int)index
{
    while ([self shouldIncrementIndexOfFirstVisibleCard]) {
        [self unloadCardAtIndex:self.indexOfFirstVisibleCard];
        self.indexOfFirstVisibleCard += 1;
    }
    
    while ([self shouldDecrementIndexOfFirstVisibleCard]) {
        self.indexOfFirstVisibleCard -= 1;
        [self loadCardAtIndex:self.indexOfFirstVisibleCard animated:NO];
    }
    
    while ([self shouldIncrementIndexOfLastVisibleCard]) {
        self.indexOfLastVisibleCard += 1;
        [self loadCardAtIndex:self.indexOfLastVisibleCard animated:NO];
    }
    
    while ([self shouldDecrementIndexOfLastVisibleCard]) {
        [self unloadCardAtIndex:self.indexOfLastVisibleCard];
        self.indexOfLastVisibleCard -= 1;
    }
}


- (CGFloat)makeScrollViewShorter
{
    UIScrollView *scrollView = (UIScrollView *)self.view;
    
    CGFloat bottomOfScrollView = scrollView.contentSize.height;
    CGFloat bottomOfScreen = scrollView.contentOffset.y + scrollView.frame.size.height;
    CGFloat bottomOfScreenToBottomOfScrollView = MAX(0, bottomOfScrollView - bottomOfScreen);
    
    CGFloat heightOfAllCards = 0;
    for (NSNumber *cardHeight in self.cardHeights) {
        heightOfAllCards += cardHeight.floatValue;
    }
    
    CGFloat spaceLeftByRemovedCard = scrollView.contentSize.height - heightOfAllCards - (self.numberOfCards + 1)*self.padding;
    CGFloat amountScrollViewHeightWillChange = MIN(scrollView.contentSize.height - scrollView.frame.size.height, spaceLeftByRemovedCard);
    CGFloat overlap = MAX(0, bottomOfScreen - (bottomOfScrollView - amountScrollViewHeightWillChange));
    
    // make scrollView shorter
    BOOL removedRegionOverlapsVisibleRegion = bottomOfScreenToBottomOfScrollView < amountScrollViewHeightWillChange;
    
    if (removedRegionOverlapsVisibleRegion) {
        self.isScrollingProgrammatically = YES;
        scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, scrollView.contentOffset.y - overlap);
        self.isScrollingProgrammatically = NO;
    }
    
    scrollView.contentSize = CGSizeMake(scrollView.contentSize.width, scrollView.contentSize.height - amountScrollViewHeightWillChange);

    return overlap;
}


- (void)fillEmptySpaceLeftByCardAtIndex:(int)index
{
    NSArray *sortedKeys =  [self.visibleCards.allKeys sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSNumber *distanceFromAToRemovedCard = [NSNumber numberWithInt:abs(((NSNumber *)a).intValue - index)];
        NSNumber *distanceFromBToRemovedCard = [NSNumber numberWithInt:abs(((NSNumber *)b).intValue - index)];
        return [distanceFromAToRemovedCard compare:distanceFromBToRemovedCard];
    }];
    
    CGFloat delay = 0.0;
    for (NSNumber *key in sortedKeys) {
        UIView *card = [self.visibleCards objectForKey:key];
        CGFloat oldPosition = card.frame.origin.y;
        CGFloat newPosition = ((NSNumber *)[self.cardPositions objectAtIndex:key.intValue]).floatValue;
        BOOL needsToBeMoved = oldPosition != newPosition;
        if (needsToBeMoved) {
            card.frame = CGRectMake(card.frame.origin.x, newPosition, card.frame.size.width, card.frame.size.height);
            card.transform = CGAffineTransformMakeTranslation(0, oldPosition - newPosition);
            CGFloat duration = 0.4;
            
            // slide
            [UIView animateWithDuration:duration
                                  delay:delay
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 card.transform = CGAffineTransformIdentity;
                             }
                             completion:nil];
            
            // rotation
            CGFloat angle = newPosition < oldPosition ? 2*(M_PI/180) : -2*(M_PI/180);
            CAKeyframeAnimation *rotationAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
            rotationAnimation.duration = duration;
            rotationAnimation.beginTime = CACurrentMediaTime() + delay + 0.01;
            rotationAnimation.calculationMode = kCAAnimationCubic;
            rotationAnimation.values = @[[NSNumber numberWithFloat:0.0],
                                         [NSNumber numberWithFloat:angle],
                                         [NSNumber numberWithFloat:angle],
                                         [NSNumber numberWithFloat:0.0]];
            rotationAnimation.keyTimes = @[[NSNumber numberWithFloat:0.0],
                                           [NSNumber numberWithFloat:0.35],
                                           [NSNumber numberWithFloat:0.65],
                                           [NSNumber numberWithFloat:1.0]];
            [card.layer addAnimation:rotationAnimation forKey:nil];
            
            delay += 0.2;
        }
    }
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
    
    NSNumber *positionOfFirstVisibleCard = [self.cardPositions objectAtIndex:self.indexOfFirstVisibleCard];
    NSNumber *heightOfFirstVisibleCard = [self.cardHeights objectAtIndex:self.indexOfFirstVisibleCard];
    
    BOOL cardIsNotVisible = positionOfFirstVisibleCard.floatValue + heightOfFirstVisibleCard.floatValue <= scrollView.contentOffset.y;
    BOOL isLastCardInList = self.indexOfFirstVisibleCard == self.numberOfCards - 1;
    
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
    
    NSNumber *positionOfLastVisibleCard = [self.cardPositions objectAtIndex:self.indexOfLastVisibleCard];
    NSNumber *heightOfLastVisibleCard = [self.cardHeights objectAtIndex:self.indexOfLastVisibleCard];
    
    CGFloat positionOfScreenBottom = scrollView.contentOffset.y + scrollView.frame.size.height;
    CGFloat positionOfCardBottom = positionOfLastVisibleCard.floatValue + heightOfLastVisibleCard.floatValue;
    
    BOOL cardBelowIsVisble = positionOfScreenBottom - positionOfCardBottom > self.padding;
    BOOL isLastCardInList = self.indexOfLastVisibleCard == self.numberOfCards - 1;
    
    return cardBelowIsVisble && !isLastCardInList;
}

//--------------------------------------------------------------------------

#pragma mark - Helpers

- (UIScrollView *)createScrollView
{
    CGRect fullScreenRect = [[UIScreen mainScreen] applicationFrame];
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:fullScreenRect];
    scrollView.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    scrollView.alwaysBounceVertical = YES;
    
    CGFloat contentWidth = [[UIScreen mainScreen] applicationFrame].size.width;
    CGFloat contentHeight = self.padding;
    
    for (NSNumber *cardHeight in self.cardHeights) {
        contentHeight += self.padding + cardHeight.floatValue;
    }
    
    scrollView.contentSize = CGSizeMake(contentWidth, contentHeight);
    
    return scrollView;
}


- (int)indexForVisibleCard:(UIView *)card
{
    int index = self.indexOfFirstVisibleCard;
        
    while (index < self.indexOfLastVisibleCard) {
        NSNumber *key = [NSNumber numberWithInt:index];
        if ([self.visibleCards objectForKey:key] == card) break;
        index++;
    }
    
    return index;
}


- (CGRect)frameForCardAtIndex:(int)index
{
    return CGRectMake(0, 0, 0, 0);
}

@end
