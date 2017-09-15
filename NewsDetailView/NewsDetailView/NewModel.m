//
//  NewModel.m
//  NewsDetailView
//
//  Created by Justin on 2017/9/14.
//  Copyright © 2017年 jerei. All rights reserved.
//

#import "NewModel.h"
#import <MJExtension/MJExtension.h>
#import "Picture.h"

@implementation NewModel
+ (NSDictionary *)mj_objectClassInArray {
    
    return @{
             @"allphoto" : [Picture class]
             };
}

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    
    return @{
             @"nid" : @"id"
             };
}
@end
