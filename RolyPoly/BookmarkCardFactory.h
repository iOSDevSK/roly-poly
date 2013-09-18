//
//  BookmarkCardFactory.h
//  RolyPoly
//
//  Created by Martin Ortega on 9/17/13.
//  Copyright (c) 2013 Martin Ortega. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Bookmark.h"

@interface BookmarkCardFactory : NSObject

+ (UIView *)createBookmarkCardFromBookmark:(Bookmark *)bookmark;

@end
