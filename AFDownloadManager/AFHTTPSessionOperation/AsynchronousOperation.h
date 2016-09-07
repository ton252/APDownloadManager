//
//  AsynchronousOperation.h
//

#import <Foundation/Foundation.h>

@interface AsynchronousOperation : NSOperation

/// Complete the asynchronous operation.
///
/// This also triggers the necessary KVO to support asynchronous operations.

@property(assign, nonatomic) BOOL cancelDependentOperations;
- (void)completeOperation;

@end
