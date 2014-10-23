//
//  AppDelegate.h
//  SimpleResignTool
//
//  Created by Ethanol on 2014/10/16.
//  Copyright (c) 2014年 EthanolWu. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ResignManager;


@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSTextField *SelectedIPATextField;
@property (weak) IBOutlet NSComboBox *CertificateComboBox;
@property (weak) IBOutlet NSTextField *ProvisioningProfileTextField;
@property (weak) IBOutlet NSTextField *IPAOutputPathTextField;
@property (weak) IBOutlet NSTextField *StatusTextField;
@property (weak) IBOutlet NSProgressIndicator *ResignProgressIndicator;
@property (weak) IBOutlet NSButton *DetailsBtn;


- (IBAction)onSelectIPABtnClick:(id)sender;
- (IBAction)onIPAOutputBtnClick:(id)sender;
- (IBAction)onCertificateComboBoxSelected:(id)sender;
- (IBAction)onSelectProvisioningProfileBtnClick:(id)sender;

- (IBAction)onDetailsBtnClick:(id)sender;

- (IBAction)onResignBtnClick:(id)sender;




@end

