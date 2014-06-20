//
//  MKMapView+RAC.m
//  owned-iSouvenir
//
//  Created by Huy on 6/10/14.
//  Copyright (c) 2014 huy. All rights reserved.
//

#import <objc/runtime.h>
#import "MKMapView+RAC.h"


@interface MKMapView ()<MKMapViewDelegate>
@end

@implementation MKMapView (RAC)

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    // Don't display a pin for the user location
    if (annotation == [mapView userLocation]) {
        return nil;
    }
    
    MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"anno"];
    pin.animatesDrop = YES;
    pin.pinColor = MKPinAnnotationColorGreen;
    pin.canShowCallout = YES;
    return pin;
}

- (RACSignal *)rac_didUpdateUserLocationSignal
{
    RACSignal *signal = objc_getAssociatedObject(self, _cmd);
    if (signal != nil) return signal;
    
    signal = [self rac_signalForSelector:@selector(mapView:didUpdateUserLocation:)
                            fromProtocol:@protocol(MKMapViewDelegate)];
    objc_setAssociatedObject(self, _cmd, signal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // Must reset delegate after setting the signals to workaround Cocoa's cache
    self.delegate = self;
    
    return signal;
}

- (RACSignal *)rac_doesHaveAnnotationViewSelected
{
    RACSignal *signal = objc_getAssociatedObject(self, _cmd);
    if (signal != nil) return signal;
    
    RACSignal *selectSignal = [self rac_signalForSelector:@selector(mapView:didSelectAnnotationView:)
                                             fromProtocol:@protocol(MKMapViewDelegate)];
    RACSignal *deselectSignal = [self rac_signalForSelector:@selector(mapView:didDeselectAnnotationView:)
                                               fromProtocol:@protocol(MKMapViewDelegate)];
    
    @weakify(self);
    // NOTE: we have to start signal with some value or an action will default to enabled
    signal = [[[RACSignal merge:@[selectSignal, deselectSignal]] startWith:nil] map:^(RACTuple *tuple) {
        @strongify(self);
        return @([self.selectedAnnotations count] > 0);
    }];
    
    objc_setAssociatedObject(self, _cmd, signal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // Must reset delegate after setting the signals to workaround Cocoa's cache
    // See https://github.com/ReactiveCocoa/ReactiveCocoa/issues/1187
    self.delegate = self;
    
    return signal;
}

@end