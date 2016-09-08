//
//  ViewController.m
//  ExempleProject
//
//  Created by ton252 on 07.09.16.
//  Copyright © 2016 ton252. All rights reserved.
//

#import "ViewController.h"
#import "AFDownloadManager.h"
#import "AFVimeoDownloadFile.h"

@interface ViewController () <AFDownloadManagerDelegate>
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressView;
@property (strong, nonatomic) AFDownloadManager *downloadManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.downloadManager = [[AFDownloadManager alloc] init];
    self.downloadManager.delegate = self;
    
    NSString *mainPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSLog(@"Cache folder: %@",mainPath);
    [self.downloadManager addObserver:self forKeyPath:@"progress" options:0 context:nil];
}

- (IBAction)loadFilesFromList:(id)sender {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *path = [mainBundle pathForResource: @"urls" ofType: @"plist"];
    NSArray *URLs = [[NSArray alloc] initWithContentsOfFile:path];
    NSSet *set = [NSSet setWithArray:URLs]; // if there is duplicates in URLs
    NSArray *files = [AFDownloadFile filesWithURLs:set.allObjects];
    [self.downloadManager addDownloadFiles:files];
}

- (IBAction)loadVimeoFiles:(id)sender {
    AFVimeoDownloadFile *file1 = [AFVimeoDownloadFile fileWithURL:@"https://vimeo.com/181560988"];
    AFVimeoDownloadFile *file2 = [AFVimeoDownloadFile fileWithURL:@"https://vimeo.com/180979975"];
    [self.downloadManager addDownloadFiles:@[file1,file2]];
}

- (IBAction)cancelDownloads:(id)sender {
    [self.downloadManager cancelDownloadFiles];
}

#pragma mark Delegate methods

- (void)completeLoadDirectLinkOfFile:(AFDownloadFile *)file operation:(AFHTTPSessionOperation*) operation error:(NSError *)error {
    //NSLog(@"Direct_Link| name: %@  error: %zd",file.name,error.code);
    AFVimeoDownloadFile *vimeoFile = (AFVimeoDownloadFile *)file;
    [vimeoFile setExtentionToPath];
}
- (void)completeLoadHeaderOfFile:(AFDownloadFile *)file operation:(AFHTTPSessionOperation*) operation error:(NSError *)error {
    //NSLog(@"Header     | name: %@  error: %zd",file.name,error.code);
}
- (void)completeLoadFile:(AFDownloadFile *) file operation:(AFURLSessionOperation*) operation error:(NSError *) error {
    //NSLog(@"Downloaded | name: %@  error: %zd",file.name,error.code);
}
- (void)completeLoadFiles:(NSArray<AFDownloadFile*> *)successFiles failureFiles:(NSArray<AFDownloadFile*> *)failureFiles {
    NSLog(@"Success:%zd Failure:%zd",successFiles.count,failureFiles.count);
}

#pragma mark Observe methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"progress"]){
        AFDownloadManager *downloadManager = (AFDownloadManager *)object;
        NSProgress *downloadProgress = downloadManager.progress;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.downloadProgressView.progress = downloadProgress.fractionCompleted;
        });

    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc {
    [self.downloadManager removeObserver:self forKeyPath:@"progress"];
}

@end
