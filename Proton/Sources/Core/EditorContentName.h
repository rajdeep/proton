//
//  EditorContentName.h
//  Proton
//
//  Created by Rajdeep Kwatra on 13/9/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

#ifndef EditorContentName_h
#define EditorContentName_h


#endif /* EditorContentName_h */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EditorContentName : NSObject

@property (readonly, copy) NSString *rawValue;

- (instancetype)initWithRawValue:(NSString *)rawValue;

+ (EditorContentName *)paragraphName;
+ (EditorContentName *)viewOnlyName;
+ (EditorContentName *)newlineName;
+ (EditorContentName *)textName;
+ (EditorContentName *)unknownName;

@end

NS_ASSUME_NONNULL_END
