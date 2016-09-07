//
//  AFDownloadManager.h
//  AFDownloadManager
//
//  Created by ton252 on 06.09.16.
//  Copyright © 2016 ton252. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFHTTPSessionManager.h>
#import "AFHTTPSessionOperation.h"
#import "AFURLSessionOperation.h"
#import "AFDownloadFile.h"

@class AFHTTPSessionOperation,AFURLSessionOperation;
@protocol AFDownloadManagerDelegate;

@interface AFDownloadManager : NSObject

@property(strong, nonatomic) AFHTTPSessionManager *sessionManager;
@property(strong, nonatomic) NSOperationQueue *operationQueue;
@property(strong, nonatomic) NSProgress *progress;
@property(weak, nonatomic) id<AFDownloadManagerDelegate> delegate;

- (void) addDownloadFiles:(NSArray<AFDownloadFile*> *) files;
- (void) cancelDownloadFiles;

@end

@protocol AFDownloadManagerDelegate <NSObject>

@optional
- (void)completeLoadDirectLinkOfFile:(AFDownloadFile *)file operation:(AFHTTPSessionOperation*) operation error:(NSError *)error;
- (void)completeLoadHeaderOfFile:(AFDownloadFile *)file operation:(AFHTTPSessionOperation*) operation error:(NSError *)error;
- (void)completeLoadFile:(AFDownloadFile *) file operation:(AFURLSessionOperation*) operation error:(NSError *) error;
- (void)completeLoadFiles:(NSArray<AFDownloadFile*> *)successFiles failureFiles:(NSArray<AFDownloadFile*> *)failureFiles;

@end
