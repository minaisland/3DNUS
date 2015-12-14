//
//  MainViewController.m
//  3DNUS
//
//  Created by 郑先生 on 15/12/13.
//  Copyright © 2015年 郑先生. All rights reserved.
//

#import "MainViewController.h"
#import "FCFileManager.h"
#import "FileDownloader.h"
#import "NSString+ESAdditions.h"

#define WORK_PATH [NSHomeDirectory() stringByAppendingPathComponent:@".3dnus"]
#define DESKTOP_PATH [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"]
#define RESOURCE_PATH [[NSBundle mainBundle] resourcePath]

static NSString *server = @"http://nus.cdn.c.shop.nintendowifi.net/ccs/download/";

@interface MainViewController ()

@property (weak) IBOutlet NSTextField *titleIDField;
@property (weak) IBOutlet NSTextField *versionField;
@property (unsafe_unretained) IBOutlet NSTextView *logTextView;
@property (nonatomic, assign) BOOL isDownloaded;
@property (nonatomic, copy) NSNumber *currentIndex;
@property (nonatomic, strong) NSArray *titleArray;
@property (weak) IBOutlet NSButton *packAsCIABtn;
@property (weak) IBOutlet NSButton *powerBtn;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleIDField.stringValue = @"9.2.0-20";
    self.versionField.stringValue = @"JPN";
    self.logTextView.font = [NSFont systemFontOfSize:14];
    self.currentIndex = @1;
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:self.powerBtn.title];
    NSRange strRange = {0,[str length]};
    [str addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:strRange];
    self.powerBtn.attributedTitle = str;
    
    [self addObserver:self forKeyPath:@"isDownloaded" options:NSKeyValueObservingOptionNew context:nil];
    
    if (![FCFileManager isDirectoryItemAtPath:WORK_PATH]) {
        if ([FCFileManager createDirectoriesForPath:WORK_PATH]) {
            NSLog(@"创建目录成功");
        }
    }
    NSString *ftmp = [WORK_PATH appendPathComponent:@"tmp"];
    [FCFileManager removeItemAtPath:ftmp];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"isDownloaded"]) {
        if (![change[@"new"] boolValue]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self verifyDown];
            });
        }
    }
}

- (void)parseTitlelist:(NSString *)titlelist
{
    self.titleArray = [titlelist splitWith:@"\n"];
    [self downConfigure:self.titleArray[[self.currentIndex integerValue]]];
}

- (void)verifyDown
{
    self.currentIndex = @(self.currentIndex.integerValue+1);
    if (self.currentIndex.integerValue < self.titleArray.count) {
        [self downConfigure:self.titleArray[[self.currentIndex integerValue]]];
    } else {
        [self log:@"\r\nDownloading firmware complete!"];
    }
}

- (void)downConfigure:(NSString *)select1
{
    self.isDownloaded = YES;
    NSArray *wantedfw = [[self.titleIDField.stringValue replace:@"." with:@""] splitWith:@"-"];
    if ([select1 containsString:self.versionField.stringValue]) {
        NSArray *csv = [select1 splitWith:@","];
        if (csv.count >=3) {
            NSString *title;
            NSString *version;
            NSString *firmwaresls = [[[[[[[[[[[csv[3]
                                               replace:@" Initial scan" with:@""]
                                              replace:@"(stage1)" with:@""]
                                             replace:@"(stage2)" with:@""]
                                            replace:@"(stage3)" with:@""]
                                           replace:@"(stage4)" with:@""]
                                          replace:@"(stage5)" with:@""]
                                         replace:@"(stage6)" with:@""]
                                        replace:@"stage7" with:@""]
                                       replace:@"EUR" with:@""]
                                      replace:@"USA" with:@""]
                                     replace:@"JPN" with:@""];
            NSArray *csvfirmtmp = [firmwaresls splitWith:@" "];
            NSMutableArray *csvfirm = [NSMutableArray array];
            for (NSString *csvtmp in csvfirmtmp) {
                NSString *csvtmptrim = [csvtmp trim];
                if (csvtmptrim.length > 0) {
                    [csvfirm addObject:csvtmptrim];
                }
            }
            NSArray *csvfu = [[csvfirm[0] replace:@"." with:@""] splitWith:@"-"];
            if ([wantedfw[1] integerValue]>=[csvfu[1] integerValue] &&
                [wantedfw[0] integerValue] >= [csvfu[0] integerValue]) {
                NSString *use = nil;
                for (NSString *temp in csvfirm) {
                    NSString *currentclean = temp;
                    NSArray *intcc = [[currentclean replace:@"." with:@""] splitWith:@"-"];
                    if (intcc.count < 2) continue;
                    NSScanner *scanner1 = [NSScanner scannerWithString:intcc[0]];
                    NSScanner *scanner2 = [NSScanner scannerWithString:intcc[1]];
                    int intcc1, intcc2;
                    [scanner1 scanInt:&intcc1];
                    [scanner2 scanInt:&intcc2];
                    if ([wantedfw[0] integerValue] < intcc1 &&
                        [wantedfw[1] integerValue] < intcc2) {
                        break;
                    }
                    use = currentclean;
                }
                //set download title
                title = csv[0];
                // find version number
                NSInteger verindex = [csvfirm indexOfObject:use];
                if ([csv[2] containsString:@" "]) {
                    NSArray *aver = [csv[2] splitWith:@" "];
                    version = [aver[verindex] replace:@"v" with:@""];
                } else {
                    version = [csv[2] replace:@"v" with:@""];
                }
                [self singledownload:title version:version];
            } else {
                self.isDownloaded = NO;
            }
        }
    } else {
        self.isDownloaded = NO;
    }
}

- (void)singledownload:(NSString *)title version:(NSString *)version
{
    [self log:@"\r\nDownloading %@ v%@...", title, version];
    NSString *downloadVersionDir = [DESKTOP_PATH appendPathComponent:self.titleIDField.stringValue];
    if ([FCFileManager isFileItemAtPath:[[downloadVersionDir appendPathComponent:title] appendPathExtension:@"cia"]]) {
        [self log:@"Done."];
        self.isDownloaded = NO;
        return;
    }
    if (![FCFileManager isDirectoryItemAtPath:downloadVersionDir]) {
        if ([FCFileManager createDirectoriesForPath:downloadVersionDir]) {
            NSLog(@"create dir: %@", downloadVersionDir);
        }
    }
    NSString *ftmp = [WORK_PATH appendPathComponent:@"tmp"];
    NSString *downloadtmp = [NSString stringWithFormat:@"%@%@/tmd.%@", server, title, version];
    NSString *downloadcetk = [NSString stringWithFormat:@"%@%@/cetk", server, title];
    
    if (![FCFileManager isDirectoryItemAtPath:ftmp]) {
        if ([FCFileManager createDirectoriesForPath:ftmp]) {
            NSLog(@"create dir: %@", ftmp);
        }
    }
    
    [FileDownloader startDownloadWithUrlArray:@[downloadtmp, downloadcetk] saveFileNameArray:@[@"tmd", @"cetk"] downloadPath:ftmp onSuccess:^(NSDictionary *data) {
        NSLog(@"%@", data[downloadtmp]);
        NSData *tmd = nil;
        Byte *bytes;
        @try {
            tmd = [FCFileManager readFileAtPathAsData:data[downloadtmp]];
            bytes = (Byte *)[tmd bytes];
        }
        @catch (NSException *exception) {
            [self singledownload:title version:version];
            return ;
        }
        NSString *contentcounter = @"1";
        if (tmd.length > 519) {
            contentcounter = [NSString stringWithFormat:@"%x",bytes[519]&0xff];
        } else {
            NSLog(@"fail tmd download");
        }
        [self log:@"Title has %@ contents", contentcounter];
        
        NSMutableArray *cids = [NSMutableArray array];
        for (int i=1; i<=contentcounter.integerValue; i++) {
            int contentoffset = 2820 + (48 * (i - 1));
            NSMutableString *contentid = [NSMutableString string];
            for (int j=contentoffset; j<=contentoffset+3; j++) {
                NSString *cid = [NSString stringWithFormat:@"%02x",bytes[j]&0xff];
                [contentid appendString:cid];
            }
            NSLog(@"contentid: %@", contentid);
            [cids addObject:[[server appendPathComponent:title] appendPathComponent:contentid]];
        }
        [FileDownloader startDownloadWithUrlArray:cids downloadPath:ftmp onSuccess:^(NSDictionary *pathToFile) {
            [self log:@"Downloading complete"];
            if (self.packAsCIABtn.state == 1) {
                [self log:@"Packing as .cia ..."];
                NSTask *task = [[NSTask alloc] init];
                task.launchPath = [RESOURCE_PATH appendPathComponent:@"make_cdn_cia"];
                task.arguments = @[ftmp, [[downloadVersionDir appendPathComponent:title] appendPathExtension:@"cia"]];
                [task launch];
                [task waitUntilExit];
                [self log:@"Done."];
                
                [FCFileManager removeItemAtPath:ftmp];
            } else {
                [FCFileManager moveItemAtPath:ftmp toPath:[downloadVersionDir appendPathComponent:title]];
            }
            
            
            self.isDownloaded = NO;
        } onFail:^(NSDictionary *pathToFile) {
            [self log:@"TitleID: %@, CotentId: %@ is Not Found", title, cids];
            
            self.isDownloaded = NO;
        }];
    }];
}

- (void)log:(NSString *)log, ...
{
    NSString *str = @"";
    if (log) {
        va_list args;
        va_start(args, log);
        str = [[NSString alloc] initWithFormat:log arguments:args];
        va_end(args);
    }
    [self.logTextView insertText:[str append:@"\r\n"]];
}

- (IBAction)downloadPress:(NSButton *)sender
{
    if (self.titleIDField.stringValue.length == 0 || self.versionField.stringValue.length == 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Warning!!!";
        alert.informativeText = @"Please enter a titleid/firmware and version/region";
        [alert runModal];
    } else {
        [FileDownloader startDownloadWithUrlStr:@"http://yls8.mtheall.com/ninupdates/titlelist.php?sys=ctr&csv=1" saveFileName:@"titlelist.csv" downloadPath:WORK_PATH onSuccess:^(NSString *pathToFile) {
            NSError *err;
            NSString *titlelist = [FCFileManager readFileAtPath:pathToFile error:&err];
            if (err) {
                NSLog(@"error: %@", err);
            } else {
                [self log:@"Download titlelist.csv success."];
                [self parseTitlelist:titlelist];
            }
        }];
    }
}

@end
