//
//  PlatformTypes.h
//  
//
//  Created by Michał Śmiałko on 02/08/2021.
//

#ifndef PlatformTypes_h
#define PlatformTypes_h

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
typedef UIColor PlatformColor;
typedef UIFont PlatformFont;
typedef NSMutableParagraphStyle MutableParagraphStyle;
#else
#import <AppKit/AppKit.h>
typedef NSColor PlatformColor;
typedef NSFont PlatformFont;
typedef NSMutableParagraphStyle MutableParagraphStyle;

#endif

#endif /* PlatformTypes_h */
