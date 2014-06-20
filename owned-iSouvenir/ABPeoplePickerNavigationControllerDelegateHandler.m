//
//  ABPeoplePickerNavigationControllerDelegateHandler.m
//  owned-iSouvenir
//
//  Created by Huy on 6/11/14.
//  Copyright (c) 2014 huy. All rights reserved.
//
// This class is notable because it converts delegate calls into a signal.  Can't use
// `rac_signalForSelector` because it can't handle return values.
//

#import <objc/runtime.h>
#import "ABPeoplePickerNavigationControllerDelegateHandler.h"

@interface ABPeoplePickerNavigationControllerDelegateHandler ()<ABPeoplePickerNavigationControllerDelegate>

@property (nonatomic, weak) ABPeoplePickerNavigationController *peoplePicker;
@property (nonatomic, strong) RACSubject *selectedPersonSubject;


@end

@implementation ABPeoplePickerNavigationControllerDelegateHandler

- (instancetype)initWithNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
{
    self = [self init];
    if (self) {
        _peoplePicker = peoplePicker;
    }
    return self;
}

#pragma mark - ABPeoplePickerNavigationControllerDelegate

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    if (self.selectedPersonSubject) {
        NSMutableArray *properties = [[NSMutableArray alloc] init];
        NSString *first = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
        NSString *last = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
        if (first) {
            [properties addObject:first];
        }
        if (last) {
            [properties addObject:last];
        }
        [self.selectedPersonSubject sendNext:properties];
    }
    
    [self.peoplePicker dismissViewControllerAnimated:YES completion:nil];
    
    // Don't display person details view
    return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
    return [self peoplePickerNavigationController:peoplePicker shouldContinueAfterSelectingPerson:person];
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [self.peoplePicker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - RAC

- (RACSignal *)rac_selectedPerson
{
    if (!self.selectedPersonSubject) {
        self.selectedPersonSubject = [RACSubject subject];
    }
    
    // Must reset delegate after setting the signals to workaround Cocoa's cache
    // See https://github.com/ReactiveCocoa/ReactiveCocoa/issues/1187
    self.peoplePicker.peoplePickerDelegate = self;
    
    return self.selectedPersonSubject;
}

@end