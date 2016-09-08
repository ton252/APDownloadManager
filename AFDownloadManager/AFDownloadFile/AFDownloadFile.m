//
//  AFDownloadFile.m
//  AFDownloadManager
//
//  Created by ton252 on 06.09.16.
//  Copyright © 2016 ton252. All rights reserved.
//

#import "AFDownloadFile.h"
#import <CommonCrypto/CommonDigest.h>

@implementation AFDownloadFile

+ (AFDownloadFile *) fileWithURL:(NSString *) URL {
    
    AFDownloadFile *file = [[AFDownloadFile alloc] init];
    NSString *name = [URL lastPathComponent];
    NSString *mainPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [mainPath stringByAppendingPathComponent:name];
    file.directURL = URL;
    file.name = name;
    file.path = filePath;
    
    return file;
}

+ (NSArray<AFDownloadFile*> *) filesWithURLs:(NSArray<NSString*> *) URLs {
    
    NSMutableArray *files = [[NSMutableArray alloc] init];
    for (NSString *url in URLs) {
        AFDownloadFile *file = [AFDownloadFile fileWithURL:url];
        [files addObject:file];
    }
    
    return [NSArray arrayWithArray:files];
}

@end

@implementation NSData (MD5Hash)

- (NSString *)MD5Hash;
{
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(self.bytes, (CC_LONG)self.length, md5Buffer);
    
    // Convert unsigned char buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

@end
