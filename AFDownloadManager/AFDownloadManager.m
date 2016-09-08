//
//  AFDownloadManager.m
//  AFDownloadManager
//
//  Created by ton252 on 06.09.16.
//  Copyright © 2016 ton252. All rights reserved.
//

#import "AFDownloadManager.h"

@interface AFDownloadManager()

@property(strong, atomic) NSMutableSet *filesInProgress;
@property(strong, atomic) NSMutableSet *filesSuccess;
@property(strong, atomic) NSMutableSet *filesFailure;

@end

@implementation AFDownloadManager

- (instancetype) init {
    self = [super init];
    
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.HTTPMaximumConnectionsPerHost = 4;
        
        self.sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:config];
        self.progress = [[NSProgress alloc] init];
        self.operationQueue = [[NSOperationQueue alloc] init];
        
        self.filesInProgress = [[NSMutableSet alloc] init];
        self.filesSuccess = [[NSMutableSet alloc] init];
        self.filesFailure =[[NSMutableSet alloc] init];

        self.operationQueue.maxConcurrentOperationCount = 1;
    }
    
    return self;
}

- (void) addDownloadFiles:(NSArray<AFDownloadFile*> *) files {
    @synchronized (self) {
        [self checkFilesForDuplicateURLs:files];
        [self.filesInProgress addObjectsFromArray:files];
        NSMutableArray *operations = [[NSMutableArray alloc] init];
        for (AFDownloadFile *file in files) {
            NSArray *fileOperation = [self operationsForFile:file];
            [operations addObjectsFromArray:fileOperation];
        }
        [self.operationQueue addOperations:operations waitUntilFinished:NO];
    }
}

- (BOOL) checkFilesForDuplicateURLs:(NSArray<AFDownloadFile *> *) files{
    
    BOOL existDuplicate = NO;
    
    for (int i = 0; i < files.count; i++) {
        AFDownloadFile *file1 = files[i];
        
        for (int j = 0; j < files.count; j++){
            if (i != j) {
                AFDownloadFile *file2 = files[j];
                if([file1.directURL isEqualToString:file2.directURL]) {
                    NSLog(@"Warning! Duplicate direct url: %@",file1.directURL);
                    existDuplicate = YES;
                }
                if([file1.inDirectURL isEqualToString:file2.inDirectURL]) {
                    NSLog(@"Warning! Duplicate inDirect url: %@",file1.directURL);
                    existDuplicate = YES;
                }
            }
        }
    }
    
    return existDuplicate;
}

- (NSArray *)operationsForFile:(AFDownloadFile *) file {
    
    if (!file.directURL) {
        AFHTTPSessionOperation *directLinkOperation = [self directLinkOperation:file];
        AFHTTPSessionOperation *headerOperation = [self headerOperation:file];
        AFURLSessionOperation *downloadOperation = [self downloadOperation:file];
        [downloadOperation addDependency:headerOperation];
        [headerOperation addDependency:directLinkOperation];
        return @[directLinkOperation,headerOperation,downloadOperation];
    } else{
        AFHTTPSessionOperation *headerOperation = [self headerOperation:file];
        AFURLSessionOperation *downloadOperation = [self downloadOperation:file];
        [downloadOperation addDependency:headerOperation];
        return @[headerOperation,downloadOperation];
    }
 
    return nil;
}

- (AFHTTPSessionOperation *) directLinkOperation:(AFDownloadFile *) file {
    __weak __typeof__(self) weakSelf = self;
    __block AFHTTPSessionOperation *operation =
    [AFHTTPSessionOperation operationWithManager:self.sessionManager
                                      HTTPMethod:@"GET"
                                       URLString:file.inDirectURL
                                      parameters:nil
                                  uploadProgress:nil
                                downloadProgress:nil
                                         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                                              __strong typeof(self)strongSelf = weakSelf;
                                             file.directURL = file.directLinkHandler(task,responseObject);
                                             if ([strongSelf.delegate respondsToSelector:@selector(completeLoadDirectLinkOfFile:operation:error:)]){
                                                 [strongSelf.delegate completeLoadDirectLinkOfFile:file operation:operation error:nil];
                                             }
                                         } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
                                             __strong typeof(self)strongSelf = weakSelf;
                                             if ([strongSelf.delegate respondsToSelector:@selector(completeLoadDirectLinkOfFile:operation:error:)]){
                                                 [strongSelf.delegate completeLoadDirectLinkOfFile:file operation:operation error:error];
                                             }
                                             [operation cancel];
                                         }];
    operation.cancelDependentOperations = YES;
    operation.queuePriority = NSOperationQueuePriorityHigh;
    return operation;
}

- (AFHTTPSessionOperation *) headerOperation:(AFDownloadFile *) file {
    __weak __typeof__(self) weakSelf = self;
    __block int64_t expectedContentLength = 0;
    AFHTTPSessionOperation *operation =
    [AFHTTPSessionOperation operationWithManager:self.sessionManager
                                      HTTPMethod:@"HEAD"
                                       URLString:file.directURL
                                      parameters:nil
                                  uploadProgress:nil
                                downloadProgress:nil
                                         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                                             __strong typeof(self)strongSelf = weakSelf;
                                             expectedContentLength = task.response.expectedContentLength;
                                             if (expectedContentLength < 1) {
                                                 if([task.response isKindOfClass:[NSHTTPURLResponse class]]){
                                                     NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
                                                     NSNumber *tmpNum = [response.allHeaderFields objectForKey:@"Content-Length"];
                                                     expectedContentLength = (tmpNum) ? tmpNum.integerValue : 0;
                                                 }
                                             }
                                             
                                             [strongSelf setProgressTotalUnitCount:strongSelf.progress.totalUnitCount + expectedContentLength];
                                             file.size = expectedContentLength;
                                             if ([strongSelf.delegate respondsToSelector:@selector(completeLoadHeaderOfFile:operation:error:)]){
                                                 [strongSelf.delegate completeLoadHeaderOfFile:file operation:operation error:nil];
                                             }
                                         } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
                                             __strong typeof(self)strongSelf = weakSelf;
                                             [strongSelf setProgressTotalUnitCount:strongSelf.progress.totalUnitCount - expectedContentLength];
                                             if ([strongSelf.delegate respondsToSelector:@selector(completeLoadHeaderOfFile:operation:error:)]){
                                                 [strongSelf.delegate completeLoadHeaderOfFile:file operation:operation error:error];
                                             }
                                            [operation cancel];
                                         }];
    operation.cancelDependentOperations = YES;
    operation.queuePriority = NSOperationQueuePriorityNormal;
    return operation;
}

- (AFURLSessionOperation *) downloadOperation:(AFDownloadFile *) file {
    
    __weak __typeof__(self) weakSelf = self;
    __block int64_t previousCompletedUnitCount = 0;
    NSURL *fileURL = [NSURL URLWithString:file.directURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:fileURL];
    
    __block AFURLSessionOperation *operation =
    [AFURLSessionOperation downloadOperationWithManager:self.sessionManager
                                                request:request
                                               progress:^(NSProgress * _Nonnull downloadProgress) {
                                                   __strong typeof(self)strongSelf = weakSelf;
                                                   int64_t receivedBytes = downloadProgress.completedUnitCount - previousCompletedUnitCount;
                                                   if (receivedBytes < 0){
                                                       receivedBytes = downloadProgress.completedUnitCount;
                                                   }
                                                   [strongSelf setProgressCompletedUnitCount:(strongSelf.progress.completedUnitCount + receivedBytes)];
                                                   previousCompletedUnitCount = downloadProgress.completedUnitCount;
                                               } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                    __strong typeof(self)strongSelf = weakSelf;
                                                   NSURL *filePath = [NSURL fileURLWithPath:file.path];
                                                   [[NSFileManager defaultManager] removeItemAtPath:file.path error:nil];
                                                   [strongSelf createDirectory:filePath error:nil];
                                                   return filePath;
                                               } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                        __strong typeof(self)strongSelf = weakSelf;
                                                        [strongSelf completeLoadFile:file operation:operation prevUnionCount:previousCompletedUnitCount error:error];
                                                        [strongSelf finishLoadingFiles];
                                                        [operation cancel];
                                               }];

    operation.cancelDependentOperations = YES;
    operation.queuePriority = NSOperationQueuePriorityLow;
    
    return operation;
}

- (void) completeLoadFile:(AFDownloadFile *) file operation:(AFURLSessionOperation *) operation prevUnionCount:(int64_t) previousCompletedUnitCount error:(NSError *)error {
    
    NSError *checkError = [self checkResponseForErrors:operation.task.response];
    
    if (!error && !checkError) {
       [self changeFileStatus:file success:YES];
    }else {
        if(!error) error = checkError;
        [self setProgressCompletedUnitCount:(self.progress.completedUnitCount - operation.task.response.expectedContentLength)];
        [self setProgressTotalUnitCount:self.progress.totalUnitCount - previousCompletedUnitCount];
        [self changeFileStatus:file success:NO];
    }

    if ([self.delegate respondsToSelector:@selector(completeLoadFile:operation:error:)]){
        [self.delegate completeLoadFile:file operation:operation error:error];
    }
}

- (void) finishLoadingFiles {
    if (self.filesInProgress.count == 0) {
        if ([self.delegate respondsToSelector:@selector(completeLoadFiles:failureFiles:)]){
            NSArray *successFiles = [self.filesSuccess.allObjects copy];
            NSArray *failureFiles = [self.filesFailure.allObjects copy];
            [self.delegate completeLoadFiles:successFiles failureFiles:failureFiles];
        }
        [self.filesSuccess removeAllObjects];
        [self.filesFailure removeAllObjects];
    }

}

- (NSError *)checkResponseForErrors:(NSURLResponse *) response{
    
    NSError *MIMETypeError = nil;
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if([httpResponse.MIMEType containsString:@"text"] && httpResponse.statusCode == 200)
        MIMETypeError = [[NSError alloc] initWithDomain:@"AFNetworkingErrorDomain" code:-1016 userInfo:nil];
    
    return MIMETypeError;
}


- (void) changeFileStatus:(AFDownloadFile *) file success:(BOOL) success {
    @synchronized (self) {
        if (success){
            [self.filesSuccess addObject:file];
        } else {
            [self.filesFailure addObject:file];
        }
        [self.filesInProgress removeObject:file];
    }
}

- (BOOL) createDirectory:(NSURL *) directoryPath error:(NSError **)error {
    
    NSString *directory = [[directoryPath path] stringByDeletingLastPathComponent];
    if ([[NSFileManager defaultManager] fileExistsAtPath:directory]){
        return YES;
    }
    
    return [[NSFileManager defaultManager] createDirectoryAtPath:directory
                                     withIntermediateDirectories:YES
                                                      attributes:nil
                                                           error:error];
}

- (void) setProgressTotalUnitCount:(int64_t) totalUnitCount {
    if (self.progress.totalUnitCount != totalUnitCount){
        [self willChangeValueForKey:@"progress"];
        self.progress.totalUnitCount = totalUnitCount;
        [self didChangeValueForKey:@"progress"];
    }
}

- (void) setProgressCompletedUnitCount:(int64_t) completedUnitCount {
    if (self.progress.completedUnitCount != completedUnitCount) {
        [self willChangeValueForKey:@"progress"];
        self.progress.completedUnitCount = completedUnitCount;
        [self didChangeValueForKey:@"progress"];
    }
}

- (void) cancelDownloadFiles {
    [self.operationQueue cancelAllOperations];
}

@end
