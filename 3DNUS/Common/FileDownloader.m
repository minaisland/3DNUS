//
//  FileDownloader.m
//  3DNUS
//
//  Created by 郑先生 on 15/12/13.
//  Copyright © 2015年 郑先生. All rights reserved.
//

#import "FileDownloader.h"
#import "TCBlobDownload.h"

@interface FileDownloader () <TCBlobDownloaderDelegate>

@property (nonatomic, strong) TCBlobDownloadManager *manager;
@property (nonatomic, strong) NSCache *blockCache;
@property (nonatomic, strong) NSMutableArray *array;

@end

@implementation FileDownloader

+ (FileDownloader *)sharedInstance
{
    static FileDownloader *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FileDownloader alloc] init];
    });
    return sharedInstance;
}

+ (void)startDownloadWithUrlStr:(NSString *)urlStr
                downloadPath:(NSString *)downloadPath
                   onSuccess:(CommonStringBlock)success
{
    [self startDownloadWithUrlStr:urlStr saveFileName:nil downloadPath:downloadPath onSuccess:success];
}

+ (void)startDownloadWithUrlStr:(NSString *)urlStr
                    saveFileName:(NSString *)fileName
                downloadPath:(NSString *)downloadPath
                   onSuccess:(CommonStringBlock)success
{
    NSURL *url = [NSURL URLWithString:urlStr];
    if (success) {
        [[self sharedInstance].blockCache setObject:success forKey:url];
    }
    TCBlobDownloader *downloadTask = [[TCBlobDownloader alloc] initWithURL:url downloadPath:downloadPath delegate:[self sharedInstance]];
    if (fileName) {
        downloadTask.fileName = fileName;
    }
    [[self sharedInstance].manager startDownload:downloadTask];
}

+ (void)startDownloadWithUrlArray:(NSArray *)urlStrs
                saveFileNameArray:(NSArray *)fileNames
                     downloadPath:(NSString *)downloadPath
                        onSuccess:(CommonDicBlock)success
{
    NSMutableDictionary *mutResultDict = [NSMutableDictionary dictionary];
    
    dispatch_group_t group = dispatch_group_create();
    for (int i=0; i<urlStrs.count; i++) {
        dispatch_group_enter(group);
        NSString *urlStr = urlStrs[i];
        __block typeof(urlStr) blockUrlStr = urlStr;
        [self startDownloadWithUrlStr:urlStr saveFileName:fileNames[i] downloadPath:downloadPath onSuccess:^(NSString *pathToFile) {
            [mutResultDict setObject:pathToFile forKey:blockUrlStr];
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (success) {
            success(mutResultDict);
        }
    });
}

- (void)download:(TCBlobDownloader *)blobDownload didStopWithError:(NSError *)error
{
    
}

- (void)download:(TCBlobDownloader *)blobDownload didFinishWithSuccess:(BOOL)downloadFinished atPath:(NSString *)pathToFile
{
    CommonStringBlock block = [self.blockCache objectForKey:blobDownload.downloadURL];
    if (block) {
        [self.blockCache removeObjectForKey:blobDownload.downloadURL];
        block(pathToFile);
    }
}

- (TCBlobDownloadManager *)manager
{
    return [TCBlobDownloadManager sharedInstance];
}

- (NSCache *)blockCache
{
    if (!_blockCache) {
        _blockCache = [[NSCache alloc] init];
    }
    return _blockCache;
}

@end
