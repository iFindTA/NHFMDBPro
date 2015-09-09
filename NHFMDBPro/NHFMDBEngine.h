//
//  NHFMDBEngine.h
//  NHFMDBPro
//
//  Created by hu jiaju on 15/9/9.
//  Copyright (c) 2015年 hu jiaju. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NHFMDBEngine : NSObject

+ (NHFMDBEngine *)share;

#pragma mark -- 增删改查 示例 --

- (BOOL)saveInfo:(id)info;

- (BOOL)deleteInfo:(id)info;

- (BOOL)updateInfo:(id)info;

- (id)getInfo;
- (NSArray *)getInfos;

@end
