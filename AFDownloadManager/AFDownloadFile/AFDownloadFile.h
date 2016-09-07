//
//  AFDownloadFile.h
//  AFDownloadManager
//
//  Created by ton252 on 06.09.16.
//  Copyright © 2016 ton252. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSString* (^AFDirectLinkBlock)(NSURLSessionDataTask *, id);

@interface AFDownloadFile : NSObject

@property(strong,nonatomic) NSString *name;
@property(strong,nonatomic) NSString *path;
@property(strong,nonatomic) NSString *directURL;
@property(strong,nonatomic) NSString *inDirectURL;
@property(assign,nonatomic) long long size;
@property(strong,nonatomic) id associatedObject;

@property(nonatomic, copy) AFDirectLinkBlock directLinkHandler;

+ (NSArray<AFDownloadFile*> *) filesWithURLs:(NSArray<NSString*> *) URLs;

@end

@interface NSData (MD5Hash)
- (NSString *)MD5Hash;
@end