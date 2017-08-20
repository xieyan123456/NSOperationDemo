//
//  FDImageDownloadOperation.h
//  自定义NSOperationDemo
//
//  Created by xieyan on 2017/8/19.
//  Copyright © 2017年 Fruitday. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FDImageDownloadOperation : NSOperation

+ (instancetype)operationWithImageUrl:(NSString *)imageUrl indexPath:(NSIndexPath *)indexPath complete:(void(^)(UIImage *image, NSString *imageUrl, NSIndexPath *index))complete;

@end
