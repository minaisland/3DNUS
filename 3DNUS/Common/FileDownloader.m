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
@property (nonatomic, strong) NSCache *successBlocks;
@property (nonatomic, strong) NSCache *failBlocks;
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
                   downloadPath:(NSString *)downloadPath
                      onSuccess:(CommonStringBlock)success
                         onFail:(CommonStringBlock)fail
{
    [self startDownloadWithUrlStr:urlStr saveFileName:nil downloadPath:downloadPath onSuccess:success onFail:fail];
}

+ (void)startDownloadWithUrlStr:(NSString *)urlStr
                    saveFileName:(NSString *)fileName
                downloadPath:(NSString *)downloadPath
                   onSuccess:(CommonStringBlock)success
{
    [self startDownloadWithUrlStr:urlStr saveFileName:fileName downloadPath:downloadPath onSuccess:success onFail:nil];
}

+ (void)startDownloadWithUrlStr:(NSString *)urlStr
                   saveFileName:(NSString *)fileName
                   downloadPath:(NSString *)downloadPath
                      onSuccess:(CommonStringBlock)success
                         onFail:(CommonStringBlock)fail
{
    NSURL *url = [NSURL URLWithString:urlStr];
    if (success) {
        [[self sharedInstance].successBlocks setObject:success forKey:url];
    }
    if (fail) {
        [[self sharedInstance].failBlocks setObject:fail forKey:url];
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
        } onFail:^(NSString *pathToFile) {
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (success) {
            success(mutResultDict);
        }
    });
}

+ (void)startDownloadWithUrlArray:(NSArray *)urlStrs
                     downloadPath:(NSString *)downloadPath
                        onSuccess:(CommonDicBlock)success
                           onFail:(CommonDicBlock)fail
{
    [self startDownloadWithUrlArray:urlStrs saveFileNameArray:nil downloadPath:downloadPath onSuccess:success onFail:fail];
}

+ (void)startDownloadWithUrlArray:(NSArray *)urlStrs
                saveFileNameArray:(NSArray *)fileNames
                     downloadPath:(NSString *)downloadPath
                        onSuccess:(CommonDicBlock)success
                           onFail:(CommonDicBlock)fail
{
    NSMutableDictionary *mutResultDict = [NSMutableDictionary dictionary];
    
    dispatch_group_t group = dispatch_group_create();
    for (int i=0; i<urlStrs.count; i++) {
        dispatch_group_enter(group);
        NSString *urlStr = urlStrs[i];
        __block typeof(urlStr) blockUrlStr = urlStr;
        NSString *fileName = nil;
        if (i < fileNames.count) {
            fileName = fileNames[i];
        }
        [self startDownloadWithUrlStr:urlStr saveFileName:fileName downloadPath:downloadPath onSuccess:^(NSString *pathToFile) {
            [mutResultDict setObject:pathToFile forKey:blockUrlStr];
            dispatch_group_leave(group);
        } onFail:^(NSString *pathToFile) {
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (mutResultDict.count > 0 && success) {
            success(mutResultDict);
        } else if (fail) {
            fail(mutResultDict);
        }
    });
}

#pragma mark - TCBlobDownloader Delegate

- (void)download:(TCBlobDownloader *)blobDownload didStopWithError:(NSError *)error
{
    NSNumber *statusCode = error.userInfo[TCBlobDownloadErrorHTTPStatusKey];
    if (statusCode.integerValue <= 400 || statusCode.integerValue >= 500) {
        
        TCBlobDownloader *downloadTask = [[TCBlobDownloader alloc] initWithURL:blobDownload.downloadURL
                                                                  downloadPath:blobDownload.pathToDownloadDirectory delegate:self];
        if (blobDownload.fileName) {
            downloadTask.fileName = blobDownload.fileName;
        }
        [self.manager startDownload:downloadTask];
    }
    CommonStringBlock block = [self.failBlocks objectForKey:blobDownload.downloadURL];
    if (block) {
        [self.failBlocks removeObjectForKey:blobDownload.downloadURL];
        block(blobDownload.pathToFile);
    }
}

- (void)download:(TCBlobDownloader *)blobDownload didFinishWithSuccess:(BOOL)downloadFinished atPath:(NSString *)pathToFile
{
    CommonStringBlock block = [self.successBlocks objectForKey:blobDownload.downloadURL];
    if (block) {
        [self.successBlocks removeObjectForKey:blobDownload.downloadURL];
        block(pathToFile);
    }
}

- (TCBlobDownloadManager *)manager
{
    return [TCBlobDownloadManager sharedInstance];
}

- (NSCache *)failBlocks
{
    if (!_failBlocks) {
        _failBlocks = [[NSCache alloc] init];
    }
    return _failBlocks;
}

- (NSCache *)successBlocks
{
    if (!_successBlocks) {
        _successBlocks = [[NSCache alloc] init];
    }
    return _successBlocks;
}

@end
