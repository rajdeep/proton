//
//  EditorContentName.m
//  Proton
//
//  Created by Rajdeep Kwatra on 13/9/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EditorContentName.h"

@implementation EditorContentName

- (instancetype)initWithRawValue:(NSString *)rawValue {
    self = [super init];
    if (self) {
        _rawValue = rawValue;
    }
    return self;
}

- (BOOL)isEqual:(id)other {
    EditorContentName *otherName = (EditorContentName *)other;
    return otherName.hash == self.hash;
}

- (NSUInteger)hash {
    return _rawValue.hash;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"EditorContent.Name(rawValue: \"%@\")", [self rawValue]];
}

+ (EditorContentName *)paragraphName { return [[EditorContentName alloc] initWithRawValue:@"_paragraph"]; }
+ (EditorContentName *)viewOnlyName { return [[EditorContentName alloc] initWithRawValue:@"_viewOnly"]; }
+ (EditorContentName *)newlineName { return [[EditorContentName alloc] initWithRawValue:@"_newline"]; }
+ (EditorContentName *)textName { return [[EditorContentName alloc] initWithRawValue:@"_text"]; }
+ (EditorContentName *)unknownName { return [[EditorContentName alloc] initWithRawValue:@"_unknown"]; }

@end
