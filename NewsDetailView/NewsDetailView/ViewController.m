//
//  ViewController.m
//  NewsDetailView
//
//  Created by Justin on 2017/9/14.
//  Copyright © 2017年 jerei. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking.h>
#import <MJExtension.h>
#import <YYImageCache.h>
#import <YYWebImageManager.h>
#import <YYDiskCache.h>
#import <CommonCrypto/CommonDigest.h>
#import "WebViewJavascriptBridge.h"
#import "NewModel.h"
#import "Picture.h"

#define margin 20

@interface ViewController () <UIWebViewDelegate, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableview;
@property (nonatomic, strong) UIWebView *webview;
/** 管理者 */
@property (nonatomic, strong) AFHTTPSessionManager *manager;
/** 模型 */
@property (nonatomic, strong) NewModel *model;
/** 交互管理者 */
@property (nonatomic, strong) WebViewJavascriptBridge *bridge;
@end

@implementation ViewController

#pragma mark - 懒加载

- (AFHTTPSessionManager *)manager {
    if (!_manager) {
        _manager = [AFHTTPSessionManager manager];
        _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    }
    return _manager;
}

- (UIWebView *)webview {
    if (!_webview) {
        _webview = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        _webview.delegate = self;
        _webview.scrollView.scrollEnabled = NO;
    }
    return _webview;
}

- (UITableView *)tableview {
    if (!_tableview) {
        _tableview = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) style:UITableViewStylePlain];
        _tableview.delegate = self;
        _tableview.dataSource = self;
        _tableview.tableHeaderView = self.webview;
    }
    return _tableview;
}

#pragma mark - 初始化

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configUI];
    
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:self.webview webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"objc received message from JS %@", data);
        responseCallback(@"Response for message from Objc");
    }];
    
    [self loadData];
    
}

#pragma mark - 页面布局
- (void)configUI {
    
//    [self.view addSubview:self.webview];
    [self.view addSubview:self.tableview];
}

- (void)autolayoutWebview {
    NSString *result = [self.webview stringByEvaluatingJavaScriptFromString:@"getHtmlHeight();"];
    self.webview.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, result.floatValue + 20);
    self.tableview.tableHeaderView = self.webview;
}

#pragma mark - 数据处理
- (void)loadData {
    
    /*   加载本地 json 数据  如果接口出现问题请使用
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Data.json" ofType:nil];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    self.model = [NewModel mj_objectWithKeyValues:dict[@"data"]];
    [self composeContentWithModel:self.model];
     */
    
    [self.manager.tasks makeObjectsPerformSelector:@selector(cancel)];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"classid"] = @"1";
    params[@"id"] = @"2887";
    
    __weak typeof(self) weakSelf = self;
    
    [self.manager GET:@"http://www.6ag.cn/e/api/getNewsContent.php" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        weakSelf.model = [NewModel mj_objectWithKeyValues:responseObject[@"data"]];
        [self composeContentWithModel:weakSelf.model];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@", error.description);
    }];
    
}

/** 拼接文章内容 */
- (void)composeContentWithModel:(NewModel *)model {
    
    NSString *html = [NSString stringWithFormat:@"<div class=\"title\">%@</div><div class=\"time\">%@&nbsp;&nbsp;&nbsp;&nbsp;</div>", model.title, model.befrom];
    
    NSString *tempNewstext = model.newstext;
    
    if (model.allphoto.count > 0) {
        for (Picture *picture in model.allphoto.objectEnumerator) {
            
            NSRange range = [tempNewstext rangeOfString:picture.ref];
            if (range.location == NSNotFound || range.length == 0) {
                continue;
            }
            
            NSNumber *widthPixel = picture.pixel[@"width"];
            NSNumber *heightPixel = picture.pixel[@"height"];
            
            // 判断图片是否超过屏幕宽度
            NSInteger screenWith = [UIScreen mainScreen].bounds.size.width - 2 * margin;
            CGFloat picture_width = widthPixel.floatValue;
            CGFloat picture_height = heightPixel.floatValue;
            
            if (widthPixel.integerValue > screenWith) { //超过屏幕宽度重新计算
                CGFloat rate = (CGFloat)screenWith / widthPixel.integerValue;
                picture_width = widthPixel.integerValue * rate;
                picture_height = heightPixel.integerValue * rate;
                
            }
            
            // 加载中的占位图
            NSString *loading = [[NSBundle mainBundle] pathForResource:@"www/images/loading.jpg" ofType:nil];
            
            // 图片URL
            NSString *imgUrl = picture.url;
            
            // img标签
            NSString *imgTag = [NSString stringWithFormat:@"<img src='%@' id='%@' width='%f' height='%f'/>", loading, imgUrl, picture_width, picture_height];
            
            tempNewstext = [tempNewstext stringByReplacingOccurrencesOfString:picture.ref withString:imgTag options:NSCaseInsensitiveSearch range:range];
        }
        
        html = [NSString stringWithFormat:@"<div id=\"content\">%@</div>", tempNewstext];
        
//        NSLog(@"html - %@", html);
        
        // 从本地加载网页模板，替换新闻主页
        NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"www/html/article.html" ofType:nil];
        NSString *template = [NSString stringWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:nil];
        
        html = [template stringByReplacingOccurrencesOfString:@"<p>mainnews</p>" withString:html options:NSCaseInsensitiveSearch range:[template rangeOfString:@"<p>mainnews</p>"]];
        
        NSURL *baseURL = [NSURL fileURLWithPath:templatePath];
        
        [self.webview loadHTMLString:html baseURL:baseURL];
    }
}

/** 加载图片 */
- (void)getImageFromDownloaderOrDiskByImageUrlArray:(NSArray *)imageArray {
    
    // **********   以下图片缓存与获取图片路径可以用 SDWebImage  此处用的 YYKit 框架 自己选择
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 循环加载图片
        for (Picture *picture in imageArray) {
            // 图片url
            NSString *imageString = picture.url;
            
            // 判断本地磁盘是否已经缓存
            YYImageCache *mgr = [YYImageCache sharedCache];
            if ([mgr containsImageForKey:imageString withType:YYImageCacheTypeDisk]) {
                NSString *imagePath = [NSString stringWithFormat:@"%@/data/%@", [mgr diskCache].path, [self getmd5WithString:imageString]];
//                NSLog(@"%@", [NSString stringWithFormat:@"replaceimage%@~%@", imageString, imagePath]);
                [self.bridge send:[NSString stringWithFormat:@"replaceimage%@~%@", imageString, imagePath]];
                NSLog(@"缓存存在");
            } else {
                
                YYWebImageManager *webManager = [[YYWebImageManager alloc] initWithCache:mgr queue:[[NSOperationQueue alloc] init]];
                
                [webManager requestImageWithURL:[NSURL URLWithString:imageString] options:YYWebImageOptionUseNSURLCache progress:nil transform:^UIImage * _Nullable(UIImage * _Nonnull image, NSURL * _Nonnull url) {
                    return image;
                } completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //这样做其实已经修改了YYWebImage的磁盘缓存策略。默认YYWebImage缓存文件时超过20kb的文件才会存储为文件，所以需要在 YYDiskCache.m的171行修改
                        NSString *imagePath = [NSString stringWithFormat:@"%@/data/%@", [mgr diskCache].path, [self getmd5WithString:imageString]];
                        NSLog(@"%@", imagePath);
                        [self.bridge send:[NSString stringWithFormat:@"replaceimage%@~%@", imageString, imagePath]];
                        NSLog(@"缓存完成");
                    });
                }];
            }
        }
        
    });
}

// MD5加密（图片缓存命名方式使用了MD5加密，这里为了找到对应图片名字）
- (NSString*)getmd5WithString:(NSString *)string {
    const char* original_str=[string UTF8String];
    unsigned char digist[CC_MD5_DIGEST_LENGTH]; //CC_MD5_DIGEST_LENGTH = 16
    CC_MD5(original_str, (uint)strlen(original_str), digist);
    NSMutableString* outPutStr = [NSMutableString stringWithCapacity:10];
    for(int  i =0; i<CC_MD5_DIGEST_LENGTH;i++){
        [outPutStr appendFormat:@"%02x", digist[i]];//小写x表示输出的是小写MD5，大写X表示输出的是大写MD5
    }
    return [outPutStr lowercaseString];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mycell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"mycell"];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%zd", indexPath.row];
    return cell;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self autolayoutWebview];
    [self getImageFromDownloaderOrDiskByImageUrlArray:self.model.allphoto];
}
@end
