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
- (void)insertAttachmentInRange:(NSRange)range attachment:(Attachment *_Nonnull)attachment;

@end
