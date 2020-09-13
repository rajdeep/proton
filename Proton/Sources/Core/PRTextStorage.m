//
//  PRTextStorage.m
//  Proton
//
//  Created by Rajdeep Kwatra on 13/9/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRTextStorage.h"
#import "EditorContentName.h"

#import <Proton/Proton-Swift.h>

@interface PRTextStorage ()
@property (nonatomic) NSTextStorage *storage;

@end

@implementation PRTextStorage

@synthesize storage = _storage;

- (instancetype)init {
    if (self = [super init]) {
        self.storage = [[NSTextStorage alloc] init];
    }
    return self;
}

- (NSString *)string {
    return self.storage.string;
}

- (UIFont *)defaultFont {
    return [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
}

- (NSParagraphStyle *)defaultParagraphStyle {
    return [[NSParagraphStyle alloc] init];
}

- (UIColor *)defaultTextColor {
    if (@available(iOS 13, *)) {
        return [UIColor labelColor];
    } else {
        return [UIColor blackColor];
    }
}

- (NSRange)textEndRange {
    return NSMakeRange(self.length, 0);
}

- (NSDictionary<NSString *,id> *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)effectiveRange {
    return [self.storage attributesAtIndex:location effectiveRange:effectiveRange];
}

- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attrString {
      // TODO: Add undo behaviour
   NSMutableAttributedString *replacementString = [attrString mutableCopy];
    // Fix any missing attribute that is in the location being replaced, but not in the text that
    // is coming in.
    if (range.length > 0 && attrString.length > 0) {
        id outgoingAttrs = [_storage attributesAtIndex:(range.location + range.length - 1) effectiveRange:nil];
        id incomingAttrs = [attrString attributesAtIndex:0 effectiveRange:nil];

        // We do not want to fix the underline since it can be added by the input method for
        // characters accepting diacritical marks (eg. in Vietnamese or Spanish) and should be transient.

        NSDictionary<NSAttributedStringKey,id> *diff = [NSDictionary init];

        for (id outgoingKey in outgoingAttrs) {
            if ([incomingAttrs containsValueForKey:outgoingKey] && outgoingKey != NSUnderlineStyleAttributeName) {
                [diff setValue:outgoingAttrs[outgoingKey] forKey:outgoingKey];
            }
        }

        [replacementString addAttributes:diff range:NSMakeRange(0, replacementString.length)];
    }

    id deletedText = [_storage attributedSubstringFromRange:range];
    [_textStorageDelegate textStorage:self willDeleteText: deletedText insertedText: replacementString range: range];
    [super replaceCharactersInRange:range withAttributedString:replacementString];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str {
    [self beginEditing];
    unsigned long delta = str.length - range.length;
    NSArray *attachmentsToDelete = [self getAttachments:range];
    for (id attachment in attachmentsToDelete) {
        [attachment removeFromSuperview];
    }

    [_storage replaceCharactersInRange:range withString:str];
    [_storage fixAttributesInRange:NSMakeRange(0, _storage.length)];
    [self edited:NSTextStorageEditedAttributes & NSTextStorageEditedCharacters range:range changeInLength:delta];

    [self endEditing];
}

- (NSArray *) getAttachments:(NSRange) range {
    NSMutableArray *attachments = [NSMutableArray array];
    [_storage enumerateAttribute:@"attachment" inRange:range options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        if ([value isKindOfClass: [Attachment class]]) {
            [attachments addObject: value];
        }
    }];
    return attachments;
}

- (void)setAttributes:(NSDictionary<NSString *,id> *)attrs range:(NSRange)range {
    [self beginEditing];

    id updatedAttributes = [self applyingDefaultFormattingIfRequiredToAttributes:attrs];
    [_storage setAttributes:updatedAttributes range:range];

    NSRange newlineRange = [_storage.string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]];
    while(newlineRange .location != NSNotFound) {
        [_storage addAttribute:@"blockContentType" value:[EditorContentName newlineName] range:newlineRange];
        newlineRange = [_storage.string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]
                                                        options:0
                                                          range:NSMakeRange(newlineRange.location + newlineRange.length, _storage.length)];
    }

    [_storage fixAttributesInRange:NSMakeRange(0, _storage.length)];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

- (NSDictionary<NSAttributedStringKey,id> *)applyingDefaultFormattingIfRequiredToAttributes:(NSDictionary<NSAttributedStringKey,id> *)attributes {
    NSMutableDictionary<NSAttributedStringKey,id> * updatedAttributes = attributes.mutableCopy;
    if (!updatedAttributes) {
        updatedAttributes = [NSMutableDictionary init];
    }

    if (![attributes objectForKey:NSParagraphStyleAttributeName]) {
        id value = _defaultTextFormattingProvider.paragraphStyle;
        [updatedAttributes setValue:value forKey:NSParagraphStyleAttributeName];
    }

    if (![attributes objectForKey:NSFontAttributeName]) {
        id value = _defaultTextFormattingProvider.font;
        [updatedAttributes setValue:value forKey:NSFontAttributeName];
    }

    if (![attributes objectForKey:NSForegroundColorAttributeName]) {
        id value = _defaultTextFormattingProvider.textColor;
        [updatedAttributes setValue:value forKey:NSForegroundColorAttributeName];
    }

    return updatedAttributes;
}

- (void)fixMissingAttributesForDeletedAttributes:(NSArray<NSAttributedStringKey> *)attrs range:(NSRange)range {
    if ([attrs containsObject:NSForegroundColorAttributeName]) {
        [_storage addAttribute:NSForegroundColorAttributeName value:[self defaultTextColor] range:range];
    }

    if ([attrs containsObject:NSParagraphStyleAttributeName]) {
        [_storage addAttribute:NSParagraphStyleAttributeName value:[self defaultParagraphStyle] range:range];
    }

    if ([attrs containsObject:NSFontAttributeName]) {
        [_storage addAttribute:NSFontAttributeName value:[self defaultFont] range:range];
    }
}

- (void) insertAttachmentInRange:(NSRange)range attachment:(Attachment *_Nonnull)attachment {
    id spacer = attachment.spacer.string;
    bool hasPrevSpacer = false;
    if (range.length + range.location > 0) {
        hasPrevSpacer = [self attributedSubstringFromRange: NSMakeRange(MAX(range.location - 1, 0), 1)].string == spacer;
    }
    bool hasNextSpacer = false;
    if ((range.location + range.length + 1) <= self.length) {
        hasNextSpacer = [self attributedSubstringFromRange: NSMakeRange(range.location, 1)].string == spacer;
    }

    NSAttributedString *attachmentString = [attachment stringWithSpacersWithAppendPrev:!hasNextSpacer appendNext:!hasNextSpacer];
    [self replaceCharactersInRange:range withAttributedString: attachmentString];
}

- (void)addAttributes:(NSDictionary<NSAttributedStringKey,id> *)attrs range:(NSRange)range {
    [self beginEditing];
    [_storage addAttributes:attrs range:range];
    [_storage fixAttributesInRange:NSMakeRange(0, _storage.length)];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

- (void)removeAttributes:(NSArray<NSAttributedStringKey> *_Nonnull)attrs range:(NSRange)range {
    [self beginEditing];
    for (id attr in attrs) {
        [_storage removeAttribute:attr range:range];
    }
    [self fixMissingAttributesForDeletedAttributes: attrs range: range];
    [_storage fixAttributesInRange:NSMakeRange(0, _storage.length)];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

- (void)removeAttribute:(NSAttributedStringKey)name range:(NSRange)range {
    [_storage removeAttribute:name range:range];
}

@end
