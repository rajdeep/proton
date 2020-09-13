//
//  PRTextStorage.h
//  Proton
//
//  Created by Rajdeep Kwatra on 13/9/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

#ifndef PRTextStorage_h
#define PRTextStorage_h


#endif /* PRTextStorage_h */

#import <UIKit/UIKit.h>
@protocol DefaultTextFormattingProviding;
@protocol TextStorageDelegate;
@class Attachment;

@interface PRTextStorage : NSTextStorage

@property (weak, nullable) id<DefaultTextFormattingProviding> defaultTextFormattingProvider;
@property (weak, nullable) id<TextStorageDelegate> textStorageDelegate;


@property(nonatomic, readonly, nonnull) UIFont *defaultFont;
@property(nonatomic, readonly, nonnull) NSParagraphStyle *defaultParagraphStyle;
@property(nonatomic, readonly, nonnull) UIColor *defaultTextColor;
@property(nonatomic, readonly) NSRange textEndRange;

- (void)removeAttributes:(NSArray<NSAttributedStringKey> *_Nonnull)attrs range:(NSRange)range;
- (void) insertAttachmentInRange:(NSRange)range attachment:(Attachment *_Nonnull)attachment;

@end
