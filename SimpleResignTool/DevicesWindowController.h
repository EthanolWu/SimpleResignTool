//
//  DevicesWindowController.h
//  SimpleResignTool
//
//  Created by Ethanol on 2014/10/22.
//  Copyright (c) 2014年 EthanolWu. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DevicesWindowController : NSWindowController

- (IBAction)onSearchFieldEdited:(id)sender;

@property (strong) IBOutlet NSSearchField *DeviceSearchField;
@property (strong) IBOutlet NSTextField *AppIDTextField;
@property (strong) IBOutlet NSTextField *ExpirationDateTextField;
@property (strong) IBOutlet NSTextField *ProvisionedDevicesTextField;

@end
