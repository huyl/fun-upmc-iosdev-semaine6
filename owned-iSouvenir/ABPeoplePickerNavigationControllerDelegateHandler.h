//
//  ABPeoplePickerNavigationControllerDelegateHandler.h
//  owned-iSouvenir
//
//  Created by Huy on 6/11/14.
//  Copyright (c) 2014 huy. All rights reserved.
//

@interface ABPeoplePickerNavigationControllerDelegateHandler : NSObject

- (instancetype)initWithNavigationController:(ABPeoplePickerNavigationController *)peoplePicker;

- (RACSignal *)rac_selectedPerson;

@end
