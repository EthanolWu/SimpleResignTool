//
//  ResignManager.m
//  SimpleResignTool
//
//  Created by Ethanol on 2014/10/17.
//  Copyright (c) 2014年 EthanolWu. All rights reserved.
//

#import "ResignManager.h"
#import <Security/Security.h>


@implementation ResignManager

@synthesize SelectedIPAs=mSelectedIPAs;
@synthesize SelectedCertificate=mSelectedCertificate;
@synthesize Certificates=mCertificates;
@synthesize ProvisioningProfilePath=mProvisioningProfilePath;

@synthesize ProvisioningProfileAppID=mProvisioningProfileAppID;
@synthesize ProvisioningProfileExpirationDate=mProvisioningProfileExpirationDate;

@synthesize IPAOutputPath=mIPAOutputPath;
@synthesize ProvisionedDevices=mProvisionedDevices;



+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id) init {
    self = [super init];
    if (self != nil) {
        // initializations go here.
        
        mCertificates = [[NSMutableArray alloc] init];
        mSelectedIPAs = [[NSMutableArray alloc] init];
        mProvisionedDevices = [[NSMutableArray alloc] init];
        
        mProvisioningProfileAppID = @"";
        mProvisioningProfileExpirationDate = @"";
        
        
        [self getCertificatesFromKeychain];
    }
    return self;
}


- (NSString*)getTeamCertificateID
{
    NSString *parten = @"\\((\\w*)\\)";

    NSError* error = NULL;
    
    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:parten options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSArray* match = [reg matchesInString:mSelectedCertificate options:NSMatchingReportCompletion range:NSMakeRange(0, [mSelectedCertificate length])];
    
    
    for (NSTextCheckingResult *mat in match) {
        NSRange matchRange = [mat rangeAtIndex:1];
        return [mSelectedCertificate substringWithRange:matchRange];
    }
    
    return @"";
}




- (void)StartResign
{
    NSString* teamID = [self getTeamCertificateID];
    
    for(int i = 0 ; i < [mSelectedIPAs count]; i++)
    {
        self.Progress = i;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateProgress" object:nil];
        
        NSString* ipaPath = [mSelectedIPAs objectAtIndex:i];
        
        NSLog(@"Resign: %@", [ipaPath lastPathComponent]);
        NSLog(@"%@",[ipaPath stringByDeletingLastPathComponent]);
        
        
        NSString* outputIPAFilePath = [[NSString stringWithFormat:@"%@_RESIGN_%@", [[ipaPath lastPathComponent] stringByDeletingPathExtension], teamID] stringByAppendingPathExtension:@"ipa"];
        
        
        outputIPAFilePath = [mIPAOutputPath stringByAppendingPathComponent:outputIPAFilePath];
        
        [self unzipIPA:ipaPath];
        [self removeSignature];
        [self replaceProvisionProfile];
        [self signWithNewCertificate];
        [self generateResignedIPA:outputIPAFilePath];
        
        NSLog(@"Resign complete: %@", outputIPAFilePath);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateProgress" object:nil ];
}




-(void)getCertificatesFromKeychain
{
    // create query
    CFMutableDictionaryRef query = CFDictionaryCreateMutable(kCFAllocatorDefault, 3, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionaryAddValue(query, kSecReturnAttributes, kCFBooleanTrue);
    CFDictionaryAddValue(query, kSecMatchLimit, kSecMatchLimitAll);
    CFDictionaryAddValue(query, kSecClass, kSecClassCertificate);
    
    // get search results
    CFArrayRef result = nil;
    OSStatus status = SecItemCopyMatching(query, (CFTypeRef*)&result);
    assert(status == 0);
    
    CFIndex arrayCount = CFArrayGetCount(result);
    
    for(int i=0; i < arrayCount; i++)
    {
        CFDictionaryRef dict = CFArrayGetValueAtIndex(result, i);
        
        CFStringRef acct = CFDictionaryGetValue(dict, kSecAttrLabel);
        NSString* certificate = (__bridge NSString*)acct;
        
        if([certificate hasPrefix:@"iPhone Distribution:"] && [certificate hasSuffix:@")"])
        {
            [mCertificates addObject:certificate];
        }
    }
}

- (void)unzipIPA:(NSString*)originalIPAFilePath
{
    NSString* tempIPAFolderName = @"Payload";
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    BOOL isDir = NO;
    BOOL bIsIPAFolderExist = [fileManager fileExistsAtPath:tempIPAFolderName isDirectory:&isDir];
    if(bIsIPAFolderExist && isDir)
    {
        [fileManager removeItemAtPath:tempIPAFolderName error:nil];
    }
    
    

    
    
//    NSPipe *pipe = [NSPipe pipe];
//    NSFileHandle *file = pipe.fileHandleForReading;
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/unzip";
    task.arguments = @[@"-q", originalIPAFilePath];   //(NSString*)[mSelectedIPAs lastObject]];
//    task.standardOutput = pipe;
    
    [task launch];
    [task waitUntilExit];
//    NSData *data = [file readDataToEndOfFile];
//    [file closeFile];
//    
//    NSString *grepOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
//    NSLog (@"returned:\n%@", grepOutput);
}


- (void)removeSignature
{

    NSTask *task = [[NSTask alloc] init];

    task.launchPath = @"/bin/sh";
    task.arguments = @[@"-c", @"rm -rfv Payload/*.app/_CodeSignature"];//, @"Payload/*.app/CodeResources"];
    
    [task launch];
    [task waitUntilExit];
}

- (void)replaceProvisionProfile
{
    NSTask *task = [[NSTask alloc] init];

    NSURL* url = [NSURL URLWithString:mProvisioningProfilePath];

    
    task.launchPath = @"/bin/sh";
    task.arguments = @[@"-c", [NSString stringWithFormat:@"cp %s Payload/*.app/embedded.mobileprovision", url.fileSystemRepresentation]];
    
    [task launch];
    [task waitUntilExit];
}

- (void)signWithNewCertificate
{
    NSTask *task = [[NSTask alloc] init];
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *entitlementsTemplatePath= [bundle pathForResource:@"EntitlementsTemplate" ofType:@"plist"];
 
    
    
    

    NSString *newEntitlementsContent =[NSString stringWithFormat:[NSString stringWithContentsOfFile:entitlementsTemplatePath
                                               encoding:NSUTF8StringEncoding
                                                  error:nil],  mProvisioningProfileAppID ];
    
    
    
    NSLog(@"en=%@", newEntitlementsContent);
    
    
    NSString *entitlementsPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Entitlements.plist"];
    
    NSError *error;
    [newEntitlementsContent writeToFile:entitlementsPath
                             atomically:YES
                               encoding:NSUTF8StringEncoding
                                  error:&error];

    task.launchPath = @"/bin/sh";
    task.arguments = @[@"-c", [NSString stringWithFormat:@"/usr/bin/codesign -f -s \"%@\" --resource-rules Payload/*.app/ResourceRules.plist --entitlements \"%@\" Payload/*.app", mSelectedCertificate, entitlementsPath]];
    
    [task launch];
    [task waitUntilExit];
}

- (void)generateResignedIPA:(NSString*)outputIPAFilePath
{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/sh";
    task.arguments = @[@"-c", [NSString stringWithFormat:@"zip -qr \"%@\" Payload", outputIPAFilePath]];
    
    NSLog(@"%@",  [NSString stringWithFormat:@"zip -qr %@ Payload", outputIPAFilePath] );
    
    [task launch];
    [task waitUntilExit];
}



-(NSString*)getExpirationDate:(NSString*)sourceStr
{
    NSString *parten = @"ExpirationDate</key>\\s+<date>(.+)</date>";
    
    NSError* error = nil;
    
    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:parten options:NSRegularExpressionCaseInsensitive error:&error];
    
    
    NSString *text = [NSString stringWithContentsOfFile:mProvisioningProfilePath
                                               encoding:NSASCIIStringEncoding
                                                  error:&error];
    
    NSArray* match = [reg matchesInString:text options:NSMatchingReportCompletion range:NSMakeRange(0, [text length])];
    
    for (NSTextCheckingResult *mat in match)
    {
        if([mat numberOfRanges] > 1)
        {
            NSRange groupRange= [mat rangeAtIndex:1];
            return [text substringWithRange:groupRange];
            
        }
        
    }
    
    return @"";
}

-(NSString*)getAppID:(NSString*)sourceStr
{
    NSString *parten = @"application-identifier</key>\\s+<string>(.+)</string>";
    
    NSError* error = nil;
    
    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:parten options:NSRegularExpressionCaseInsensitive error:&error];
    
    
    NSString *text = [NSString stringWithContentsOfFile:mProvisioningProfilePath
                                               encoding:NSASCIIStringEncoding
                                                  error:&error];
    
    NSArray* match = [reg matchesInString:text options:NSMatchingReportCompletion range:NSMakeRange(0, [text length])];
    

    
    for (NSTextCheckingResult *mat in match)
    {
        if([mat numberOfRanges] > 1)
        {
            NSRange groupRange= [mat rangeAtIndex:1];
            return [text substringWithRange:groupRange];

        }
    }
    
    return @"";
}


-(NSMutableArray*)getProvisionedDevices:(NSString*)sourceStr
{
    
    NSString *parten = @"<string>([0-9A-Fa-f]{40,40})</string>";
    
    NSError* error = nil;
    
    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:parten options:NSRegularExpressionCaseInsensitive error:&error];
    
    
    NSString *text = [NSString stringWithContentsOfFile:mProvisioningProfilePath
                                               encoding:NSASCIIStringEncoding
                                                  error:&error];
    
    NSArray* match = [reg matchesInString:text options:NSMatchingReportCompletion range:NSMakeRange(0, [text length])];
    
    NSMutableArray* devices = [[NSMutableArray alloc] init];
    
    for (NSTextCheckingResult *mat in match)
    {
        if([mat numberOfRanges] > 1)
        {
            NSRange groupRange= [mat rangeAtIndex:1];
            NSString* deviceID = [text substringWithRange:groupRange];
            
            [devices addObject:deviceID];
        }
    }
    
    return devices;
}


- (void)parseMobileProvision:(NSURL*)url
{
    NSError* error = nil;
    NSString *text = [NSString stringWithContentsOfFile:mProvisioningProfilePath
                                               encoding:NSASCIIStringEncoding
                                                  error:&error];
    
    mProvisioningProfileAppID = [self getAppID:text];
    mProvisioningProfileExpirationDate = [self getExpirationDate:text];
    
    self.ProvisionedDevices = [[self getProvisionedDevices:text] copy];
}






@end
