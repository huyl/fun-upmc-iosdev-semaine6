//
//  AnnotationsModel.m
//  owned-iSouvenir
//
//  Created by Huy on 6/11/14.
//  Copyright (c) 2014 huy. All rights reserved.
//

#import "Annotations.h"
#import "Annotation.h"

@interface Annotations ()
@property (nonatomic, strong) NSMutableArray *annotations;
@end

@implementation Annotations

+ (instancetype)sharedAnnotations {
    static Annotations *_sharedAnnotations = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedAnnotations = [[Annotations alloc] init];
    });
    
    return _sharedAnnotations;
}

- (id)init
{
    self = [super init];
    if (self) {
        _annotations = [[NSMutableArray alloc] init];
    }

    return self;
}

- (int)count
{
    return [self.annotations count];
}

- (void)addAnnotation:(Annotation *)annotation
{
    [self.annotations addObject:annotation];
}


@end
