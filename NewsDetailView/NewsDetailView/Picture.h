//
//  Picture.h
//  NewsDetailView
//
//  Created by Justin on 2017/9/14.
//  Copyright © 2017年 jerei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Picture : NSObject
/** 图片占位字符 */
@property (nonatomic, copy) NSString *ref;
/** 图片描述 */
@property (nonatomic, copy) NSString *caption;
/** 图片url */
@property (nonatomic, copy) NSString *url;
/** 宽高 */
@property (nonatomic, strong) NSDictionary *pixel;
@end
