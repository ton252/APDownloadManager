//
//  AsynchronousOperation.m
//

#import "AsynchronousOperation.h"

@interface AsynchronousOperation ()

@property (nonatomic, getter = isFinished, readwrite)  BOOL finished;
@property (nonatomic, getter = isExecuting, readwrite) BOOL executing;

@end

@implementation AsynchronousOperation

@synthesize finished  = _finished;
@synthesize executing = _executing;
@synthesize cancelled = _cancelled;

- (id)init {
    self = [super init];
    if (self) {
        _finished  = NO;
        _executing = NO;
        _cancelled = NO;
    }
    return self;
}

- (void)start {
    
    if ([self isCancelled]) {
        self.finished = YES;
        return;
    }

    self.executing = YES;

    [self main];
}

- (void) cancelNextOperations {
    if (self.cancelDependentOperations) {
        for (NSOperation *operation in self.dependencies) {
            if ([operation isCancelled]){
                [self cancel];
                return;
            }
        }
    }
}

- (void)main {
    NSAssert(![self isMemberOfClass:[AsynchronousOperation class]], @"AsynchronousOperation is abstract class that must be subclassed");
    NSAssert(false, @"AsynchronousOperation subclasses must override `main`.");
}
             
- (void)completeOperation {
    self.executing = NO;
    self.finished  = YES;
}

#pragma mark - NSOperation methods

- (BOOL)isAsynchronous {
    return YES;
}

- (BOOL)isExecuting {
    @synchronized(self) {
        return _executing;
    }
}

- (BOOL)isFinished {
    @synchronized(self) {
        return _finished && !_cancelled;
    }
}

- (void)setExecuting:(BOOL)executing {
    if (_executing != executing) {
        [self willChangeValueForKey:@"isExecuting"];
        @synchronized(self) {
            _executing = executing;
        }
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)setFinished:(BOOL)finished {
    if (_finished != finished) {
        [self willChangeValueForKey:@"isFinished"];
        @synchronized(self) {
            _finished = finished;
        }
        [self didChangeValueForKey:@"isFinished"];
    }
}

- (void)cancel {
    [super cancel];
    [self cancelNextOperations];
    _finished = YES;
}


@end
