//
//  AFVimeoDownloadFile.m
//  ExempleProject
//
//  Created by ton252 on 08.09.16.
//  Copyright © 2016 ton252. All rights reserved.
//

#import "AFVimeoDownloadFile.h"

@implementation AFVimeoDownloadFile

- (instancetype) initWithURL:(NSString *) URL {
    
    if (self) {
        NSString *name = [AFVimeoDownloadFile videoID:URL];
        self.inDirectURL = [AFVimeoDownloadFile vimeoDirectLink:name];
        self.name = name;
        self.path = [[AFVimeoDownloadFile defaultFileFolder] stringByAppendingPathComponent:name];
        self.directLinkHandler = [AFVimeoDownloadFile vimeoDirectLinkBlock];
    }
    
    return self;
}

+ (instancetype) fileWithURL:(NSString *) URL {
    return [[AFVimeoDownloadFile alloc] initWithURL:URL];
}

+ (NSString *) vimeoDirectLink:(NSString *) videoID {
    
    NSString *mainURL = @"https://player.vimeo.com/video";
    NSString *config = @"config";
    
    return [[mainURL stringByAppendingPathComponent:videoID] stringByAppendingPathComponent:config];
}

+ (NSString *) videoID:(NSString *) URL {
    return [[URL componentsSeparatedByString:@"/"] lastObject];
}

+ (AFDirectLinkBlock)vimeoDirectLinkBlock {
    AFDirectLinkBlock block = ^NSString *(NSURLSessionDataTask *task, id responseObject){
        NSArray *progressive = [[[responseObject objectForKey:@"request"] objectForKey:@"files"] objectForKey:@"progressive"];
        NSString *videoURL = [[progressive firstObject] objectForKey:@"url"];
        return videoURL;
    };
    return block;
}

- (BOOL) setExtentionToPath {
    
    if (self.directURL) {
        NSString *extention = [self.directURL pathExtension];
        extention = [[extention componentsSeparatedByString:@"?"] firstObject];
        
        if (extention && ![extention isEqualToString:@""]) {
            self.path = [self.path stringByAppendingPathExtension:extention];
            return YES;
        }
        
    }
    
    return NO;
}

@end
