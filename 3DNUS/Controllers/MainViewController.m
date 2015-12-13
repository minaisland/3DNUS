//
//  MainViewController.m
//  3DNUS
//
//  Created by 郑先生 on 15/12/13.
//  Copyright © 2015年 郑先生. All rights reserved.
//

#import "MainViewController.h"
#import "FCFileManager.h"
#import "TCBlobDownload.h"

#define WORK_PATH [NSHomeDirectory() stringByAppendingPathComponent:@".3dnus"]
#define DESKTOP_PATH [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"]

@interface MainViewController () <TCBlobDownloaderDelegate>

@property (nonatomic, copy) NSString *pathToFile;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (![FCFileManager isDirectoryItemAtPath:WORK_PATH]) {
        if ([FCFileManager createDirectoriesForPath:WORK_PATH]) {
            NSLog(@"创建目录成功");
        }
    } else {
        NSURL *url = [NSURL URLWithString:@"http://yls8.mtheall.com/ninupdates/titlelist.php?sys=ctr&csv=1"];
        TCBlobDownloader *downloadTask = [[TCBlobDownloader alloc] initWithURL:url downloadPath:WORK_PATH delegate:self];
        downloadTask.fileName = @"titlelist.csv";
        [[TCBlobDownloadManager sharedInstance] startDownload:downloadTask];
    }
    
}

- (void)download:(TCBlobDownloader *)blobDownload didFinishWithSuccess:(BOOL)downloadFinished atPath:(NSString *)pathToFile
{
    NSError *err;
    NSString *titlelist = [FCFileManager readFileAtPath:pathToFile error:&err];
    if (err) {
        NSLog(@"error: %@", err);
    } else {
        NSLog(@"%@", titlelist);
    }
}

@end
