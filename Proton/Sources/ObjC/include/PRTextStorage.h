//
//  PRTextStorage.h
//  Proton
//
//  Created by Rajdeep Kwatra on 13/9/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#ifndef PRTextStorage_h
#define PRTextStorage_h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DefaultTextFormattingProviding)
@protocol PRDefaultTextFormattingProviding<NSObject>
@property (nonatomic, readonly) UIFont *font;
@property (nonatomic, readonly) NSMutableParagraphStyle *paragraphStyle;
@property (nonatomic, readonly) UIColor *textColor;
@end

@class PRTextStorage;

NS_SWIFT_NAME(TextStorageDelegate)
@protocol PRTextStorageDelegate<NSObject>
@required
- (void)textStorage:(PRTextStorage *)textStorage didDelete:(NSTextAttachment *)attachment;
- (void)textStorage:(PRTextStorage *)textStorage will:(NSAttributedString *)deleteText insertText:(NSAttributedString *)insertedText in:(NSRange)range;
- (void)textStorage:(PRTextStorage *)textStorage edited:(NSTextStorageEditActions)actions in:(NSRange)editedRange changeInLength:(NSInteger)delta;
@end

@interface PRTextStorage : NSTextStorage

@property (weak, nullable) id<PRDefaultTextFormattingProviding> defaultTextFormattingProvider;
@property (weak, nullable) id<PRTextStorageDelegate> textStorageDelegate;

@property (nonatomic, assign) BOOL preserveNewlineBeforeBlock;
@property (nonatomic, assign) BOOL preserveNewlineAfterBlock;

@property (nonatomic, readonly) UIFont *defaultFont;
@property (nonatomic, readonly) NSParagraphStyle *defaultParagraphStyle;
@property (nonatomic, readonly) UIColor *defaultTextColor;

- (void)removeAttributes:(NSArray<NSAttributedStringKey> *)attrs range:(NSRange)range;
- (void)insertAttachmentInRange:(NSRange)range attachment:(NSTextAttachment *)attachment withSpacer:(NSAttributedString *)spacer;

@end

NS_ASSUME_NONNULL_END

#endif /* PRTextStorage_h */
