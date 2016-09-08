//
//  ViewController.m
//  ExempleProject
//
//  Created by ton252 on 07.09.16.
//  Copyright © 2016 ton252. All rights reserved.
//

#import "ViewController.h"
#import "AFDownloadManager.h"

@interface ViewController () <AFDownloadManagerDelegate>
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressView;
@property (strong, nonatomic) AFDownloadManager *downloadManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.downloadManager = [[AFDownloadManager alloc] init];
    self.downloadManager.delegate = self;
    [self.downloadManager addObserver:self forKeyPath:@"progress" options:0 context:nil];
    
    NSString *mainPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSLog(@"Cache folder: %@",mainPath);
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *path = [mainBundle pathForResource: @"urls" ofType: @"plist"];
    NSArray *URLs = [[NSArray alloc] initWithContentsOfFile:path];
    NSSet *set = [NSSet setWithArray:URLs]; // if there is duplicates in URLs
    NSArray *files = [AFDownloadFile filesWithURLs:set.allObjects];
    [self.downloadManager addDownloadFiles:files];
    
//    AFDownloadFile *file = [[AFDownloadFile alloc] init];
//    file.inDirectURL = @"https://player.vimeo.com/video/181757098/config";
//    file.path = [mainPath stringByAppendingString:@"video181757098.mp4"];
//    AFDirectLinkBlock block = ^NSString *(NSURLSessionDataTask *task, id responseObject){
//        NSArray *progressive = [[[responseObject objectForKey:@"request"] objectForKey:@"files"] objectForKey:@"progressive"];
//        NSString *videoURL = [[progressive firstObject] objectForKey:@"url"];
//        return videoURL;
//    };
//    [file setDirectLinkHandler:block];
//    [self.downloadManager addDownloadFiles:@[file]];
}

- (IBAction)cancelDownloads:(id)sender {
    [self.downloadManager cancelDownloadFiles];
}

#pragma mark Delegate methods

- (void)completeLoadDirectLinkOfFile:(AFDownloadFile *)file operation:(AFHTTPSessionOperation*) operation error:(NSError *)error {
    NSLog(@"Direct_Link| name: %@  error: %zd",file.name,error.code);
}
- (void)completeLoadHeaderOfFile:(AFDownloadFile *)file operation:(AFHTTPSessionOperation*) operation error:(NSError *)error {
    NSLog(@"Header     | name: %@  error: %zd",file.name,error.code);
}
- (void)completeLoadFile:(AFDownloadFile *) file operation:(AFURLSessionOperation*) operation error:(NSError *) error {
    NSLog(@"Downloaded | name: %@  error: %zd",file.name,error.code);
}
- (void)completeLoadFiles:(NSArray<AFDownloadFile*> *)successFiles failureFiles:(NSArray<AFDownloadFile*> *)failureFiles {
    
    NSLog(@"Success:%zd Failure:%zd",successFiles.count,failureFiles.count);
}

#pragma mark Observe methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"progress"]){
        AFDownloadManager *downloadManager = (AFDownloadManager *)object;
        NSProgress *downloadProgress = downloadManager.progress;

        if (downloadProgress.totalUnitCount == 0) {
            self.downloadProgressView.progress = 0;
        } else{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.downloadProgressView.progress = (Float64)downloadProgress.completedUnitCount/(Float64)downloadProgress.totalUnitCount;
            });

        }
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
