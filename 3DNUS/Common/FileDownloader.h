//
//  FileDownloader.h
//  3DNUS
//
//  Created by 郑先生 on 15/12/13.
//  Copyright © 2015年 郑先生. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileDownloader : NSObject

+ (void)startDownloadWithUrlStr:(NSString *)urlStr
                   downloadPath:(NSString *)downloadPath
                      onSuccess:(CommonStringBlock)success;

+ (void)startDownloadWithUrlStr:(NSString *)urlStr
                   saveFileName:(NSString *)fileName
                   downloadPath:(NSString *)downloadPath
                      onSuccess:(CommonStringBlock)success;

+ (void)startDownloadWithUrlArray:(NSArray *)urlStrs
                   saveFileNameArray:(NSArray *)fileNames
                   downloadPath:(NSString *)downloadPath
                      onSuccess:(CommonDicBlock)success;

@end
