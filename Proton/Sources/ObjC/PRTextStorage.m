//
//  PRTextStorage.m
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

#import "PRTextStorage.h"
#import "PREditorContentName.h"

@interface PRTextStorage ()
@property (nonatomic) NSTextStorage *storage;
@end

@implementation PRTextStorage

- (instancetype)init {
    if (self = [super init]) {
        _storage = [[NSTextStorage alloc] init];
    }
    return self;
}

- (NSString *)string {
    return _storage.string;
}

- (UIFont *)defaultFont {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

- (NSParagraphStyle *)defaultParagraphStyle {
    return [[NSParagraphStyle alloc] init];
}

- (UIColor *)defaultTextColor {
    if (@available(iOS 13, *)) {
        return UIColor.labelColor;
    } else {
        return UIColor.blackColor;
    }
}

- (id)attribute:(NSAttributedStringKey)attrName atIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range {
    return [_storage attribute:attrName atIndex:location effectiveRange:range];
}

- (NSDictionary<NSString *, id> *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)effectiveRange {
    return [_storage attributesAtIndex:location effectiveRange:effectiveRange];
}

- (void)edited:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta {
    [super edited:editedMask range:editedRange changeInLength:delta];
//    [self.textStorageDelegate textStorage:self edited:editedMask range:editedRange changeInLength:delta];
    [self.textStorageDelegate textStorage:self edited:editedMask in:editedRange changeInLength:delta];
}

- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attrString {
    // TODO: Add undo behaviour
    
    // Handles the crash when nested list receives enter key in quick succession that unindents the list item.
    // Check only required with Obj-C based TextStorage
    if ((range.location + range.length) > _storage.length) {
        // Out of bounds
        return;
    }
    
    NSMutableAttributedString *replacementString = [attrString mutableCopy];
    // Fix any missing attribute that is in the location being replaced, but not in the text that
    // is coming in.
    if (range.length > 0 && attrString.length > 0) {
        NSDictionary<NSAttributedStringKey, id> *outgoingAttrs = [_storage attributesAtIndex:(range.location + range.length - 1) effectiveRange:nil];
        NSDictionary<NSAttributedStringKey, id> *incomingAttrs = [attrString attributesAtIndex:0 effectiveRange:nil];

        NSMutableDictionary<NSAttributedStringKey, id> *diff = [NSMutableDictionary dictionary];
        for (NSAttributedStringKey outgoingKey in outgoingAttrs) {
            // We do not want to fix the underline since it can be added by the input method for
            // characters accepting diacritical marks (eg. in Vietnamese or Spanish) and should be transient.
            if (incomingAttrs[outgoingKey] == nil && outgoingKey != NSUnderlineStyleAttributeName) {
                diff[outgoingKey] = outgoingAttrs[outgoingKey];
            }
        }
        [replacementString addAttributes:diff range:NSMakeRange(0, replacementString.length)];
    }

    NSAttributedString *deletedText = [_storage attributedSubstringFromRange:range];
    [_textStorageDelegate textStorage:self will:deletedText insertText:replacementString in:range];
    [super replaceCharactersInRange:range withAttributedString:replacementString];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str {
    [self beginEditing];
    NSInteger delta = str.length - range.length;

    NSArray<NSTextAttachment *> *attachmentsToDelete = [self attachmentsForRange:range];
    for (NSTextAttachment *attachment in attachmentsToDelete) {
        [_textStorageDelegate textStorage:self didDelete:attachment];
    }

    [_storage replaceCharactersInRange:range withString:str];
    [_storage fixAttributesInRange:NSMakeRange(0, _storage.length)];
    [self edited:NSTextStorageEditedCharacters & NSTextStorageEditedAttributes range:range changeInLength:delta];

    [self endEditing];
}

- (void)setAttributes:(NSDictionary<NSString *, id> *)attrs range:(NSRange)range {
    [self beginEditing];

    NSDictionary<NSAttributedStringKey, id> *updatedAttributes = [self applyingDefaultFormattingIfRequiredToAttributes:attrs];
    [_storage setAttributes:updatedAttributes range:range];

    NSRange newlineRange = [_storage.string rangeOfCharacterFromSet:NSCharacterSet.newlineCharacterSet];
    while (newlineRange.location != NSNotFound) {
        [_storage addAttribute:@"_blockContentType" value:PREditorContentName.newlineName range:newlineRange];
        NSUInteger remainingLocation = newlineRange.location + newlineRange.length;
        NSUInteger remainingLength = _storage.length - remainingLocation;
        newlineRange = [_storage.string rangeOfCharacterFromSet:NSCharacterSet.newlineCharacterSet
                                                        options:0
                                                          range:NSMakeRange(remainingLocation, remainingLength)];
    }

    [_storage fixAttributesInRange:NSMakeRange(0, _storage.length)];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

- (void)insertAttachmentInRange:(NSRange)range attachment:(NSTextAttachment *_Nonnull)attachment withSpacer: (NSAttributedString *) spacer {
    NSCharacterSet *spacerCharacterSet = [NSCharacterSet whitespaceCharacterSet];  //attachment.spacerCharacterSet;
    BOOL hasNextSpacer = NO;
    if (range.location + 1 < self.length) {
        NSUInteger characterIndex = range.location + 1;
        hasNextSpacer = [spacerCharacterSet characterIsMember:[self.string characterAtIndex:characterIndex]];
    }

    NSMutableAttributedString *attachmentString = [[NSMutableAttributedString attributedStringWithAttachment:attachment] mutableCopy];

    if (hasNextSpacer == NO) {
        [attachmentString appendAttributedString: spacer];
    }

    [self replaceCharactersInRange:range withAttributedString:attachmentString];
}

- (void)addAttributes:(NSDictionary<NSAttributedStringKey, id> *)attrs range:(NSRange)range {
    [self beginEditing];
    [_storage addAttributes:attrs range:range];
    [_storage fixAttributesInRange:NSMakeRange(0, _storage.length)];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

- (void)removeAttributes:(NSArray<NSAttributedStringKey> *_Nonnull)attrs range:(NSRange)range {
    [self beginEditing];
    for (NSAttributedStringKey attr in attrs) {
        [_storage removeAttribute:attr range:range];
    }
    [self fixMissingAttributesForDeletedAttributes:attrs range:range];
    [_storage fixAttributesInRange:NSMakeRange(0, _storage.length)];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

- (void)removeAttribute:(NSAttributedStringKey)name range:(NSRange)range {
    [_storage removeAttribute:name range:range];
}

#pragma mark - Private

- (void)fixMissingAttributesForDeletedAttributes:(NSArray<NSAttributedStringKey> *)attrs range:(NSRange)range {
    if ([attrs containsObject:NSForegroundColorAttributeName]) {
        [_storage addAttribute:NSForegroundColorAttributeName value:self.defaultTextColor range:range];
    }

    if ([attrs containsObject:NSParagraphStyleAttributeName]) {
        [_storage addAttribute:NSParagraphStyleAttributeName value:self.defaultParagraphStyle range:range];
    }

    if ([attrs containsObject:NSFontAttributeName]) {
        [_storage addAttribute:NSFontAttributeName value:self.defaultFont range:range];
    }
}

- (NSDictionary<NSAttributedStringKey, id> *)applyingDefaultFormattingIfRequiredToAttributes:(NSDictionary<NSAttributedStringKey, id> *)attributes {
    NSMutableDictionary<NSAttributedStringKey, id> *updatedAttributes = attributes.mutableCopy ?: [NSMutableDictionary dictionary];

    if (!attributes[NSParagraphStyleAttributeName]) {
        updatedAttributes[NSParagraphStyleAttributeName] = _defaultTextFormattingProvider.paragraphStyle.copy ?: self.defaultParagraphStyle;
    }

    if (!attributes[NSFontAttributeName]) {
        updatedAttributes[NSFontAttributeName] = _defaultTextFormattingProvider.font ?: self.defaultFont;
    }

    if (!attributes[NSForegroundColorAttributeName]) {
        updatedAttributes[NSForegroundColorAttributeName] = _defaultTextFormattingProvider.textColor ?: self.defaultTextColor;
    }

    return updatedAttributes;
}

- (NSArray<NSTextAttachment *> *)attachmentsForRange:(NSRange)range {
    NSMutableArray<NSTextAttachment *> *attachments = [NSMutableArray array];
    [_storage enumerateAttribute:NSAttachmentAttributeName
                         inRange:range
                         options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                      usingBlock:^(id _Nullable value, NSRange range, BOOL *_Nonnull stop) {
        if ([value isKindOfClass:[NSTextAttachment class]]) {
            [attachments addObject:value];
        }
    }];
    return attachments;
}

@end
