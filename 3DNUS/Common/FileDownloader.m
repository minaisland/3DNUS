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
    [[self sharedInstance].blockCache setObject:success forKey:url];
    TCBlobDownloader *downloadTask = [[TCBlobDownloader alloc] initWithURL:url downloadPath:downloadPath delegate:[self sharedInstance]];
    if (fileName) {
        downloadTask.fileName = fileName;
    }
    [[self sharedInstance].manager startDownload:downloadTask];
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
