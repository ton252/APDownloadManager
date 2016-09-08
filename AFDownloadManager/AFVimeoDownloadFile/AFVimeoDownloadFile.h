//
//  AFVimeoDownloadFile.h
//  ExempleProject
//
//  Created by ton252 on 08.09.16.
//  Copyright © 2016 ton252. All rights reserved.
//

#import "AFDownloadFile.h"

@interface AFVimeoDownloadFile : AFDownloadFile

+ (instancetype) fileWithURL:(NSString *) URL;
- (BOOL) setExtentionToPath;

@end
