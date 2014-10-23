//
//  ResignManager.h
//  SimpleResignTool
//
//  Created by Ethanol on 2014/10/17.
//  Copyright (c) 2014年 EthanolWu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ResignManager : NSObject



@property (strong, nonatomic) NSMutableArray* Certificates;
@property (strong, nonatomic) NSMutableArray* SelectedIPAs;
@property (strong, nonatomic) NSString* SelectedCertificate;
@property (strong, nonatomic) NSString* ProvisioningProfilePath;
@property (strong, nonatomic) NSString* ProvisioningProfileAppID;
@property (strong, nonatomic) NSString* ProvisioningProfileExpirationDate;

@property (strong, nonatomic) NSString* IPAOutputPath;
@property (assign, nonatomic) int Progress;

@property (strong, nonatomic) NSMutableArray* ProvisionedDevices;


+ (instancetype)sharedInstance;

- (void)StartResign;
- (void)parseMobileProvision:(NSURL*)url;

@end
