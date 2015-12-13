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

#define WORK_PATH [NSHomeDirectory() stringByAppendingPathComponent:@".3dnus"]
#define DESKTOP_PATH [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"]

@interface MainViewController ()

@property (weak) IBOutlet NSTextField *titleIDField;
@property (weak) IBOutlet NSTextField *versionField;
@property (unsafe_unretained) IBOutlet NSTextView *logTextView;


@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (![FCFileManager isDirectoryItemAtPath:WORK_PATH]) {
        if ([FCFileManager createDirectoriesForPath:WORK_PATH]) {
            NSLog(@"创建目录成功");
        }
    }
}

- (IBAction)downloadPress:(NSButton *)sender
{
    [FileDownloader startDownloadWithUrlStr:@"http://yls8.mtheall.com/ninupdates/titlelist.php?sys=ctr&csv=1" saveFileName:@"titlelist.csv" downloadPath:WORK_PATH onSuccess:^(NSString *pathToFile) {
        NSError *err;
        NSString *titlelist = [FCFileManager readFileAtPath:pathToFile error:&err];
        if (err) {
            NSLog(@"error: %@", err);
        } else {
            [self.logTextView insertText:@"download titlelist.csv success.\n"];
        }
    }];
}

@end
