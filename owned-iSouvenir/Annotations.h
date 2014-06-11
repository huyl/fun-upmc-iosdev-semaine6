//
//  AnnotationsModel.h
//  owned-iSouvenir
//
//  Created by Huy on 6/11/14.
//  Copyright (c) 2014 huy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Annotation.h"

@interface Annotations : NSObject

+ (instancetype)sharedAnnotations;

@property (nonatomic, readonly) int count;

- (void)addAnnotation:(Annotation *)annotation;

@end
