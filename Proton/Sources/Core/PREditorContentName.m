//
//  PREditorContentName.m
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

#import <Foundation/Foundation.h>
#import "PREditorContentName.h"

@implementation PREditorContentName

- (instancetype)initWithRawValue:(NSString *)rawValue {
    self = [super init];
    if (self) {
        _rawValue = rawValue;
    }
    return self;
}

- (BOOL)isEqual:(id)other {
    if (self == other) {
        return YES;
    }
    
    if (![other isKindOfClass:PREditorContentName.class]) {
        return NO;
    }
    
    return [self.rawValue isEqualToString:((PREditorContentName *)other).rawValue];
}

- (NSUInteger)hash {
    return _rawValue.hash;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"EditorContent.Name(rawValue: \"%@\")", [self rawValue]];
}

+ (PREditorContentName *)paragraphName { return [[PREditorContentName alloc] initWithRawValue:@"_paragraph"]; }
+ (PREditorContentName *)viewOnlyName { return [[PREditorContentName alloc] initWithRawValue:@"_viewOnly"]; }
+ (PREditorContentName *)newlineName { return [[PREditorContentName alloc] initWithRawValue:@"_newline"]; }
+ (PREditorContentName *)textName { return [[PREditorContentName alloc] initWithRawValue:@"_text"]; }
+ (PREditorContentName *)unknownName { return [[PREditorContentName alloc] initWithRawValue:@"_unknown"]; }

@end
