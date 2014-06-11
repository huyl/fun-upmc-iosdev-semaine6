//
//  MKMapView+RAC.h
//  owned-iSouvenir
//
//  Created by Huy on 6/10/14.
//  Copyright (c) 2014 huy. All rights reserved.
//

@interface MKMapView (RAC)

- (RACSignal *)rac_didUpdateUserLocationSignal;
- (RACSignal *)rac_doesHaveAnnotationViewSelected;

@end