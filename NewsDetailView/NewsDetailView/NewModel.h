//
//  NewModel.h
//  NewsDetailView
//
//  Created by Justin on 2017/9/14.
//  Copyright © 2017年 jerei. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Picture;
@interface NewModel : NSObject
/** 顶贴数 */
@property (nonatomic, copy) NSString *top;
/** 踩帖数 */
@property (nonatomic, copy) NSString *down;
/** 文章标题 */
@property (nonatomic, copy) NSString *title;
/** 发布时间戳 */
@property (nonatomic, copy) NSString *newstime;
/** 文章内容 */
@property (nonatomic, copy) NSString *newstext;
/** 文章url */
@property (nonatomic, copy) NSString *titleurl;
/** 文章id */
@property (nonatomic, copy) NSString *nid;
/** 当前子分类id */
@property (nonatomic, copy) NSString *classid;
/** 评论数量 */
@property (nonatomic, copy) NSString *plnum;
/** 是否收藏 1收藏  0未收藏 */
@property (nonatomic, copy) NSString *havefava;
/** 文章简介 */
@property (nonatomic, copy) NSString *smalltext;
/** 标题图片 */
@property (nonatomic, copy) NSString *titlepic;
/** 信息来源 - 如果没有则返回空字符串，所以可以直接强拆 */
@property (nonatomic, copy) NSString *befrom;
/** 所有图片 */
@property (nonatomic, strong) NSArray *allphoto;
@end
