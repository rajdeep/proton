//
//  PREditorContentName.h
//  ProtonCore
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

#ifndef EditorContentName_h
#define EditorContentName_h

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(EditorContentName)
@interface PREditorContentName : NSObject

@property (readonly, copy) NSString *rawValue;

- (instancetype)initWithRawValue:(NSString *)rawValue;

+ (PREditorContentName *)paragraphName;
+ (PREditorContentName *)viewOnlyName;
+ (PREditorContentName *)newlineName;
+ (PREditorContentName *)textName;
+ (PREditorContentName *)unknownName;

@end

NS_ASSUME_NONNULL_END

#endif /* EditorContentName_h */
