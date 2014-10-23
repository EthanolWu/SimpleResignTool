//
//  DevicesWindowController.m
//  SimpleResignTool
//
//  Created by Ethanol on 2014/10/22.
//  Copyright (c) 2014年 EthanolWu. All rights reserved.
//

#import "DevicesWindowController.h"
#import "ResignManager.h"


@interface DevicesWindowController () <NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet NSTableView *DevicesTableView;
    NSMutableArray* deviceArray;
}

@end

@implementation DevicesWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    deviceArray = [[NSMutableArray alloc] init];
    
    DevicesTableView.delegate = self;
    DevicesTableView.dataSource = self;
 
    self.AppIDTextField.stringValue = [ResignManager sharedInstance].ProvisioningProfileAppID;
    self.ExpirationDateTextField.stringValue = [ResignManager sharedInstance].ProvisioningProfileExpirationDate;
    
    [self reloadDeviceData];
}

- (void)reloadDeviceData
{
    [deviceArray removeAllObjects];
    
    for(NSString* device in [ResignManager sharedInstance].ProvisionedDevices)
    {
        if( [self.DeviceSearchField.stringValue length] > 0)
        {
        
            if ([device rangeOfString:self.DeviceSearchField.stringValue].location != NSNotFound)
            {
                [deviceArray addObject:device];
            }
        }
        else
        {
            [deviceArray addObject:device];
        }
    }

    if( [deviceArray count] == [[ResignManager sharedInstance].ProvisionedDevices count])
        self.ProvisionedDevicesTextField.stringValue = [NSString stringWithFormat:@"%lu devices", (unsigned long)[deviceArray count]];
    else
        self.ProvisionedDevicesTextField.stringValue = [NSString stringWithFormat:@"%lu of %lu devices", (unsigned long)[deviceArray count], (unsigned long)[[ResignManager sharedInstance].ProvisionedDevices count]];
    
    [DevicesTableView reloadData];
}


- (IBAction)onSearchFieldEdited:(id)sender
{
    [self reloadDeviceData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [deviceArray count];
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    NSTableCellView *result = [tableView makeViewWithIdentifier:@"deviceCell" owner:self];
    result.textField.stringValue = [deviceArray objectAtIndex:row];

    return result;
}


@end
