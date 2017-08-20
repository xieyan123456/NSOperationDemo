//
//  ViewController.m
//  自定义NSOperationDemo
//
//  Created by stone on 2017/8/19.
//  Copyright © 2017年 Fruitday. All rights reserved.
//

#import "ViewController.h"
#import "FDImageDownloadOperation.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *imageTableView;

/** 所有的图片url数据 */
@property (nonatomic, strong) NSArray *imageUrls;

/** 所有下载操作的队列 */
@property (nonatomic, strong) NSOperationQueue *queue;

/** 所有的下载操作,url是key，operation对象是value */
@property (nonatomic, strong) NSMutableDictionary *operations;

/** 图片内存缓存 */
@property (nonatomic, strong) NSMutableDictionary *images;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //在百度随机找的图片链接,因为含http链接，所以要在info.plist配置App Transport Security Settings
    self.imageUrls = @[@"http://mpic.tiankong.com/ecc/3e3/ecc3e349338dbe58603cf270d9cd7c9c/640.jpg?x-oss-process=image/resize,m_lfit,h_600,w_600/watermark,image_cXVhbmppbmcucG5n,t_90,g_ne,x_5,y_5",
                       @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1503200381356&di=e9586ecb77d2696dd0aab1e681581d25&imgtype=0&src=http%3A%2F%2Fpic28.nipic.com%2F20130424%2F11588775_115415688157_2.jpg",
                       @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1503200399281&di=2c7ea45f43707d4d32c8b9095cc4e074&imgtype=0&src=http%3A%2F%2Fimg01.taopic.com%2F141115%2F240422-1411151JK469.jpg",
                       @"http://img05.tooopen.com/images/20150602/tooopen_sy_128223296629.jpg",
                       @"http://gonglve.baidu.com/gonglve/api/getcontent?doc_id=8c6e828090c69ec3d4bb755d&type=pic&src=115_0_1080_810.jpg",
                       @"http://dl.bizhi.sogou.com/images/2012/04/04/294895.jpg",
                       @"http://pic37.nipic.com/20140110/2531170_181315835000_2.jpg",
                       @"http://img01.taopic.com/150715/240497-150G50J13264.jpg",
                       @"http://pic1.cxtuku.com/00/12/67/b266f16b2ac2.jpg",
                       @"http://www.liuxue86.com/uploadfile/2015/0906/20150906043546913.jpg",
                       @"http://pic.58pic.com/58pic/14/91/48/58Q58PICM3d_1024.jpg",
                       @"http://img07.tooopen.com/images/20170413/tooopen_sy_205717792263.jpg"];
    
    //初始化
    self.queue = [[NSOperationQueue alloc]init];
    self.operations = [NSMutableDictionary dictionary];
    self.images = [NSMutableDictionary dictionary];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    //当收到内存警告,取消下载操作，并清空操作和内存缓存
    [self.queue cancelAllOperations];
    [self.operations removeAllObjects];
    [self.images removeAllObjects];
}

#pragma mark - UIScrollViewDelegate
/**
 *  当开始拖拽时调用
 */
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    // 暂停下载操作
    [self.queue setSuspended:YES];
}

/**
 *  当停止拖拽时调用
 */
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    // 恢复下载操作
    [self.queue setSuspended:NO];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.imageUrls.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"imageIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    NSString *imageUrl = self.imageUrls[indexPath.row];
    UIImage *image = self.images[imageUrl];
    if (image) {// 内存中有
        cell.imageView.image = image;
    } else { // 从沙盒中找，找不到下载
        // 获得caches的路径, 拼接文件路径
        NSString *filePath =  [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[imageUrl lastPathComponent]];
        // 从沙盒中取出图片
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        if (data) { // 沙盒中有
            cell.imageView.image  = [UIImage imageWithData:data];
        } else { // 沙盒中没有
            // 显示占位图片
            cell.imageView.image  = [UIImage imageNamed:@"placeholder"];
            // 开始下载图片
            [self downloadImage:imageUrl indexPath:indexPath];
        }
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 300;
}

#pragma mark - Private Method
/**
 *  图片下载
 *
 *  @param imageUrl 图片的url
 */
- (void)downloadImage:(NSString *)imageUrl indexPath:(NSIndexPath *)indexPath
{
    
    // 根据当前图片url取出对应的下载操作
    FDImageDownloadOperation *operation = self.operations[imageUrl];
    if (operation) return;
    
    __weak typeof(self) weakSelf = self;
    // 创建下载图片的操作
    operation = [FDImageDownloadOperation operationWithImageUrl:imageUrl indexPath:indexPath complete:^(UIImage *image, NSString *imageUrl, NSIndexPath *indexPath) {
        // 存放在内存中
        if (image) {
            weakSelf.images[imageUrl] = image;
            // 将图片存入沙盒中
            NSData *data = UIImagePNGRepresentation(image);
            NSString *filePath =  [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[imageUrl lastPathComponent]];
            [data writeToFile:filePath atomically:YES];
        }
        // 不管下载成功还是失败，都移除下载操作，保证下载失败可以重新下载
        [weakSelf.operations removeObjectForKey:imageUrl];
        // 刷新对应的cell
        [weakSelf.imageTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }];
    
    // 添加操作到队列中
    [self.queue addOperation:operation];
    
    // 添加到字典中 (防止重复加入队列中)
    self.operations[imageUrl] = operation;
}
@end
