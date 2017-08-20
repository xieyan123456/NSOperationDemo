
//
//  FDImageDownloadOperation.m
//  自定义NSOperationDemo
//
//  Created by xieyan on 2017/8/19.
//  Copyright © 2017年 Fruitday. All rights reserved.
//

#import "FDImageDownloadOperation.h"

@interface FDImageDownloadOperation ()

@property (nonatomic, copy) void(^complete)(UIImage *image, NSString *imageUrl, NSIndexPath *index);
@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, strong) NSIndexPath *curIndexPath;

@end

@implementation FDImageDownloadOperation

+ (instancetype)operationWithImageUrl:(NSString *)imageUrl indexPath:(NSIndexPath *)indexPath complete:(void(^)(UIImage *image, NSString *imageUrl, NSIndexPath *index))complete{
    FDImageDownloadOperation *downloadOperation = [[self alloc]init];
    downloadOperation.imageUrl = imageUrl;
    downloadOperation.complete = complete;
    downloadOperation.curIndexPath = indexPath;
    return downloadOperation;
}

- (void)start{//这方法在异步执行，无法访问主线程的释放池,所以创建一个释放池
    @autoreleasepool {
        if (self.isCancelled) return;
        NSURL *imageUrl = [NSURL URLWithString:self.imageUrl];
        // 下载图片
        NSData *data = [NSData dataWithContentsOfURL:imageUrl];
        UIImage *image = [UIImage imageWithData:data];         
        if (self.isCancelled) return;
        
        // 回到主线程刷新UI
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (self.complete) {
                self.complete(image,self.imageUrl,self.curIndexPath);
            }
        }];
    }
}

@end
