//
//  NHDBEngine.h
//  NHFMDBPro
//
//  Created by hu jiaju on 16/2/17.
//  Copyright © 2016年 hu jiaju. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NHDBEngine : NSObject

+ (NHDBEngine *)share;

#pragma mark -- 增删改查 示例 --

- (BOOL)saveInfo:(id)info;

- (BOOL)deleteInfo:(id)info;

- (BOOL)updateInfo:(id)info;

- (id)getInfo;
- (NSArray *)getInfos;

@end
