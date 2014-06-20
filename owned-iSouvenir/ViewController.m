//
//  ViewController.m
//  owned-iSouvenir
//
//  Created by Huy on 6/10/14.
//  Copyright (c) 2014 huy. All rights reserved.
//

#import "ViewController.h"
#import "Masonry.h"
#import "MKMapView+RAC.h"
#import "ABPeoplePickerNavigationControllerDelegateHandler.h"
#import "Annotations.h"
#import "Annotation.h"

@interface ViewController ()

@property (nonatomic, weak) UIToolbar *toolbar;
@property (nonatomic, weak) UIBarButtonItem *contactButton;
@property (nonatomic, weak) UIBarButtonItem *dropPinButton;

@property (nonatomic, weak) MKMapView *mapView;
@property (nonatomic, weak) ABPeoplePickerNavigationController *peoplePicker;
@property (nonatomic, strong) ABPeoplePickerNavigationControllerDelegateHandler *peoplePickerHandler;

@property (nonatomic, strong) UIPopoverController *peoplePickerPopover;

@end

@implementation ViewController

+ (UIImage *)imageNamed:(NSString *)name
{
    UIImage *image = [UIImage imageNamed:name];
    return [UIImage imageWithCGImage:[image CGImage] scale:(image.scale * 50.0/24.0) orientation:image.imageOrientation];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /// Toolbar
    
    UIBarButtonItem *contactButton = [[UIBarButtonItem alloc] initWithImage:
                                      [ViewController imageNamed:@"line__0000s_0100_bookmarks.png"]
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:nil
                                                                     action:nil];
    _contactButton = contactButton;
    UIBarButtonItem *dropPinButton = [[UIBarButtonItem alloc] initWithImage:
                                      [ViewController imageNamed:@"line__0000s_0092_map.png"]
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:nil
                                                                     action:nil];
    _dropPinButton = dropPinButton;
    
    UIBarButtonItem *flexibleSpace =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *fixedSpace =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 10;
    
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    _toolbar = toolbar;
    self.toolbar.items = @[flexibleSpace,
                           dropPinButton,
                           fixedSpace,
                           contactButton,
                           flexibleSpace];
    [self.view addSubview:self.toolbar];
    
    /// MapView

    MKMapView *mapView = [[MKMapView alloc] init];
    _mapView = mapView;
    [self.view addSubview:mapView];
    
    if (![CLLocationManager locationServicesEnabled]) {
        _dropPinButton.enabled = NO;
    } else {
        self.mapView.showsUserLocation = YES;
    }
    
    // Turn off showsUserLocation when in background
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackgroundNotification:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForegroundNotification:)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];
    
    /// Set up the rest
    
    [self setupConstraints];
    [self setupRAC];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Constraints

- (void)setupConstraints
{
    UIView *superview = self.view;
    
    [self.toolbar mas_makeConstraints:^(MASConstraintMaker *make) {
        // Making use of the topLayoutGuide in iOS7+ ensures that room is made for the toolbar,
        // regardless of whether the controller's view's frame is full screen or not
        if ([self respondsToSelector:@selector(topLayoutGuide)]) {
            UIView *topLayoutGuide = (id)self.topLayoutGuide;
            make.top.equalTo(topLayoutGuide.mas_bottom);
        } else {
            make.top.equalTo(superview);
        }
        
        make.left.equalTo(superview);
        make.right.equalTo(superview);
    }];
    
    [self.mapView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.toolbar.mas_bottom);
        make.left.equalTo(superview);
        make.right.equalTo(superview);
        make.bottom.equalTo(superview);
    }];
}

#pragma mark - RAC

- (void)setupRAC
{
    @weakify(self);
    
    // React to drop-pin button
    self.dropPinButton.rac_action = [[RACSignal create:^(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        Annotation *annotation = [[Annotation alloc] init];
        annotation.coordinate = self.mapView.centerCoordinate;
        annotation.title = [NSString stringWithFormat:@"Lieu %d", [[Annotations sharedAnnotations] count]];
        
        [[Annotations sharedAnnotations] addAnnotation:annotation];
        [self.mapView addAnnotation:annotation];
        
        [subscriber sendCompleted];
    }] action];
    
    // React to MapView's first update of user location by panning and zooming in
    [[self.mapView.rac_didUpdateUserLocationSignal take:1] subscribeNext:^(RACTuple *tuple) {
        @strongify(self);
        MKUserLocation *userLocation = (MKUserLocation *)tuple[1];
        
        MKCoordinateSpan span = {.latitudeDelta = 0.035, .longitudeDelta = 0.035};
        MKCoordinateRegion region = {userLocation.location.coordinate, span};
        [self.mapView setRegion:region animated:YES];
    }];
    
    // React to select-contact button
    // NOTE: This code has to be after rac_didUpdateUserLocationSignal is used for some reason.
    self.contactButton.rac_action = [[RACSignal create:^(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
        self.peoplePicker = peoplePicker;
        NSArray *displayedProperties = [NSArray arrayWithObjects:
                              [NSNumber numberWithInt:kABPersonFirstNameProperty],
                              [NSNumber numberWithInt:kABPersonLastNameProperty],
                              nil];
        [self.peoplePicker setDisplayedProperties:displayedProperties];
        
        if (IS_IPAD) {
            self.peoplePickerPopover = [[UIPopoverController alloc] initWithContentViewController:self.peoplePicker];
            [self.peoplePickerPopover presentPopoverFromBarButtonItem:self.contactButton
                                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                                             animated:YES];
        } else {
            [self presentViewController:self.peoplePicker animated:YES completion:nil];
        }
        
        self.peoplePickerHandler = [[ABPeoplePickerNavigationControllerDelegateHandler alloc]
                                    initWithNavigationController:self.peoplePicker];
        
        [self.peoplePickerHandler.rac_selectedPerson subscribeNext:^(NSArray *personProperties) {
            // XXX Do I need @strongify(self) here?
            
            // For ipad mode, dismiss any popover
            if (self.peoplePickerPopover) {
                [self.peoplePickerPopover dismissPopoverAnimated:YES];
                self.peoplePickerPopover = nil;
            }
            
            NSMutableString *name = [[NSMutableString alloc] init];
        
            if ([personProperties count] > 0) {
                [name appendString:personProperties[0]];
            }
            if ([personProperties count] > 1) {
                if ([name length] > 0) {
                    [name appendString:@" "];
                }
                [name appendString:personProperties[1]];
            }
            NSArray *annotations = self.mapView.selectedAnnotations;
            if ([annotations count] > 0) {
                Annotation *annotation = (Annotation *)annotations[0];
                annotation.subtitle = name;
            }
        }];
        
        [subscriber sendCompleted];
    }] actionEnabledIf:self.mapView.rac_doesHaveAnnotationViewSelected];
    
}

#pragma mark - UIApplicationDidEnterBackgroundNotification

- (void)appDidEnterBackgroundNotification:(NSNotification *)notification
{
    // XXX I'm not sure this is necessary.  iOS seems to turn it off after a few seconds anyway.
    self.mapView.showsUserLocation = NO;
}
- (void)appWillEnterForegroundNotification:(NSNotification *)notification
{
    self.mapView.showsUserLocation = YES;
}

@end
