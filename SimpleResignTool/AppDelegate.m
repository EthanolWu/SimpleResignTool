//
//  AppDelegate.m
//  SimpleResignTool
//
//  Created by Ethanol on 2014/10/16.
//  Copyright (c) 2014年 EthanolWu. All rights reserved.
//

#import "AppDelegate.h"
#import "ResignManager.h"
#import "DevicesWindowController.h"





@interface AppDelegate ()
{
    ResignManager* mResignManager;
}

@property (weak) IBOutlet NSWindow *window;
@property (strong) DevicesWindowController *devicesWindowController;

@end

@implementation AppDelegate



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    mResignManager = [ResignManager sharedInstance];//[[ResignManager alloc] init];
    
    [self updateCertificatesUI];
    
    [self.CertificateComboBox selectItemAtIndex:0];
    [mResignManager setSelectedCertificate:self.CertificateComboBox.stringValue];
    

//    NSLog(@"%@", [outputIPAUrl absoluteString]);
    
    NSArray * paths = NSSearchPathForDirectoriesInDomains (NSDesktopDirectory, NSUserDomainMask, YES);
    NSString * desktopPath = [paths objectAtIndex:0];
    
    
    [mResignManager setIPAOutputPath:desktopPath];
    [self.IPAOutputPathTextField setStringValue:desktopPath];
    
    

    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress) name:@"UpdateProgress" object:nil];
    
    

}





- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application

}




- (IBAction)onSelectIPABtnClick:(id)sender
{
//    [mSelectedIPAs removeAllObjects];
    
    [mResignManager.SelectedIPAs removeAllObjects];
    
    NSOpenPanel *panel;
    NSArray* fileTypes = [[NSArray alloc] initWithObjects:@"ipa", @"IPA", nil];
    panel = [NSOpenPanel openPanel];
    [panel setFloatingPanel:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:YES];
    [panel setAllowsMultipleSelection:YES];
    [panel setAllowedFileTypes:fileTypes];
    NSInteger i = [panel runModal];
    if(i == NSOKButton)
    {
        for(NSURL* url in [panel URLs])
        {
//            NSLog(@"%@", url.path);
        
            BOOL isDir = NO;
            [[NSFileManager defaultManager] fileExistsAtPath: url.path isDirectory: &isDir];
            
//            NSLog(@"isDir=%d", isDir);
            
            
            if(isDir)
            {
                NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:url.path error:nil];
                NSArray *ipaFiles = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.ipa'"]];
                
                for(NSString* ipaPath in ipaFiles)
                {
                    NSString* ipaFullPath = [url.path stringByAppendingPathComponent:ipaPath];
                    
                    [mResignManager.SelectedIPAs addObject:ipaFullPath];
                    
//                    NSLog(@"%@",ipaFullPath);
                    
                    
                    
                    
                    
                    
                    
                }
            }
            else
            {
                [mResignManager.SelectedIPAs addObject:url.path];
            }
        }
        
        
        NSString* strIPAs = @"";
        for(NSString* ipaPath in mResignManager.SelectedIPAs)
        {
            if([strIPAs length] > 0)
                strIPAs = [NSString stringWithFormat:@"%@, %@", strIPAs, [ipaPath lastPathComponent] ];
            else
                strIPAs = [ipaPath lastPathComponent];
            
        
        }
        NSLog(@"%@", strIPAs);
        
        [self.SelectedIPATextField setStringValue:strIPAs];
//        NSLog(@"%@", mSelectedIPAs);
    }
    
}

- (IBAction)onCertificateComboBoxSelected:(id)sender
{
    [mResignManager setSelectedCertificate:self.CertificateComboBox.stringValue];
    
    
}




- (IBAction)onIPAOutputBtnClick:(id)sender
{
    NSOpenPanel *panel;
    panel = [NSOpenPanel openPanel];
    [panel setFloatingPanel:YES];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    [panel setAllowsMultipleSelection:NO];

    NSInteger i = [panel runModal];
    if(i == NSOKButton)
    {
        NSLog(@"%@",[[panel URLs] lastObject]);
        
        NSURL* fileURL = [[panel URLs] lastObject];

        [mResignManager setIPAOutputPath:[fileURL path]];
        [self.IPAOutputPathTextField setStringValue:[fileURL path]];
        
        
        //        NSLog(@"%@", mProvisioningProfilePath);
    }
}




- (IBAction)onSelectProvisioningProfileBtnClick:(id)sender
{
    NSOpenPanel *panel;
    NSArray* fileTypes = [[NSArray alloc] initWithObjects:@"mobileprovision", nil];
    
    panel = [NSOpenPanel openPanel];
    [panel setFloatingPanel:YES];
    [panel setCanChooseDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setAllowsMultipleSelection:NO];
    [panel setAllowedFileTypes:fileTypes];
    
  
    NSInteger i = [panel runModal];
    if(i == NSOKButton)
    {

        NSLog(@"%@",[[panel URLs] lastObject]);
        
        NSURL* fileURL = [[panel URLs] lastObject];
        mResignManager.ProvisioningProfilePath = [NSString stringWithString:fileURL.path];
        
//        NSLog(@"%@", mProvisioningProfilePath);
        
        [self.ProvisioningProfileTextField setStringValue:[NSString stringWithString:fileURL.path]];
    
        
        
        
        [mResignManager parseMobileProvision:fileURL];
        [self.DetailsBtn setEnabled:YES];
    }
}

- (IBAction)onResignBtnClick:(id)sender
{
    [self.ResignProgressIndicator setMinValue:0.0 ];
    [self.ResignProgressIndicator setMaxValue:(double)[mResignManager SelectedIPAs].count ];
    [self.ResignProgressIndicator setDoubleValue:0.0];
    [self.ResignProgressIndicator setUsesThreadedAnimation:YES];
    [self.ResignProgressIndicator displayIfNeeded];
    [mResignManager StartResign];
    
}

- (IBAction)onDetailsBtnClick:(id)sender
{
    self.devicesWindowController = [[DevicesWindowController alloc] initWithWindowNibName:@"DevicesWindowController"];
    [self.devicesWindowController showWindow:self];
    
}




- (void)updateCertificatesUI
{
    [self.CertificateComboBox removeAllItems];
    [self.CertificateComboBox addItemsWithObjectValues:mResignManager.Certificates];
}


- (void)updateProgress
{
    int progress = [mResignManager Progress];
    
    
    [self.StatusTextField setStringValue: [NSString stringWithFormat:@"Resigning IPAs (%d/%d)", progress+1, (int)[mResignManager SelectedIPAs].count]];

    [self.ResignProgressIndicator setDoubleValue:(double)(progress+1)];
    [self.ResignProgressIndicator displayIfNeeded];
    
    if( progress+1 == [mResignManager SelectedIPAs].count)
    {
    
        [self.StatusTextField setStringValue: [NSString stringWithFormat:@"Resigning IPAs (%d/%d)  Completed!", progress+1, (int)[mResignManager SelectedIPAs].count]];
    }
    
    
}


// close app when there is no any windows
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}



@end
