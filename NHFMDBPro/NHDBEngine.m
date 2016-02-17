//
//  NHDBEngine.m
//  NHFMDBPro
//
//  Created by hu jiaju on 16/2/17.
//  Copyright © 2016年 hu jiaju. All rights reserved.
//

/*
 *线程安全使用示例
 */

#import "NHDBEngine.h"
#import <FMDB/FMDB.h>

static NSString *NHDBCipherKey = @"nanhujiaju";
static NSString *NHDBNAME = @"securityInfo.DB";
static NSString *NHSQLS   = @"NH_SQLS";

@interface NHDBEngine ()

@property (nonatomic, strong, nullable)FMDatabaseQueue *dbQueue;

@end

static NHDBEngine *instance = nil;

@implementation NHDBEngine

+ (NHDBEngine *)share {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone:zone];
    });
    
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        [self createFMDB];
    }
    return self;
}

- (NSString *)filePath:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true);
    NSString *filePath = [[paths firstObject] stringByAppendingPathComponent:fileName];
    return filePath;
}

- (FMDatabaseQueue *)dbQueue {
    if (!_dbQueue) {
        NSString *dbpath = [self filePath:NHDBNAME];
        ///创建数据库及线程队列
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbpath];
    }
    return _dbQueue;
}

- (BOOL)createFMDB {
    
    __block BOOL ret = false;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        [db setKey:NHDBCipherKey];
        NSString *sqlFile = [[NSBundle mainBundle] pathForResource:NHSQLS ofType:@"txt"];
        if (!sqlFile) {
            return ;
        }
        NSString *sqls = [NSString stringWithContentsOfFile:sqlFile encoding:NSUTF8StringEncoding error:nil];
        NSArray *sqlArr = [sqls componentsSeparatedByString:@"|"];
        for (NSString *sql in sqlArr) {
            [db executeUpdate:sql];
        }
        
        ret = true;
    }];
    
    return ret;
}

#pragma mark -- Commen Method --

- (BOOL)saveInfo:(id)info {
    __block BOOL ret = false;
    
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *querySql = @"INSERT OR REPLACE INTO t_info_table (infoid, info, time) VALUES(?, ?, ?)";
        NSNumber *infoid = [info objectForKey:@"infoid"];
        NSString *info_ = [info objectForKey:@"info"];
        NSDate *time = [info objectForKey:@"time"];
        NSMutableArray *params = [NSMutableArray array];
        [params addObject:infoid];
        [params addObject:info_];
        [params addObject:time];
        ///执行SQL语句
        [db setKey:NHDBCipherKey];
        ret = [db executeUpdate:querySql withArgumentsInArray:params];
        NSLog(@"ret:%zd---插入数据",ret);
    }];
    
    return ret;
}

- (BOOL)deleteInfo:(id)info {
    
    __block BOOL ret = false;
    
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSNumber *infoid = [info objectForKey:@"infoid"];
        ///执行SQL语句
        [db setKey:NHDBCipherKey];
        ret = [db executeUpdate:@"DELETE FROM t_info_table WHERE infoid = ?",infoid,nil];
        NSLog(@"ret:%zd---删除数据",ret);
    }];
    
    return ret;
}

- (BOOL)updateInfo:(id)info {
    
    __block BOOL ret = false;
    
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSNumber *infoid = [info objectForKey:@"infoid"];
        NSString *info_ = [info objectForKey:@"info"];
        NSDate *time = [info objectForKey:@"time"];
        ///执行SQL语句
        [db setKey:NHDBCipherKey];
        ret = [db executeUpdate:@"UPDATE t_info_table SET info = ? AND time = ? WHERE infoid = ? ", info_, time, infoid, nil];
        NSLog(@"ret:%zd---更新数据",ret);
    }];
    
    return ret;
}

- (id)getInfo{
    
    __block NSMutableDictionary *tmpInfo = nil;
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        ///处理事情
        [db setKey:NHDBCipherKey];
        FMResultSet *retSets = [db executeQuery:@"SELECT * FROM t_info_table LIMIT 1",nil];
        while ([retSets next]) {
            NSString *infoid = [retSets stringForColumn:@"infoid"];
            NSString *info = [retSets stringForColumn:@"info"];
            NSString *time = [retSets stringForColumn:@"time"];
            NSDictionary *tmp = [NSDictionary dictionaryWithObjectsAndKeys:infoid,@"infoid",info,@"info",time,@"time", nil];
            tmpInfo = [NSMutableDictionary dictionaryWithDictionary:tmp];
        }
    }];
    
    return tmpInfo;
}
- (NSArray *)getInfos{
    
    __block NSMutableArray *tmpArray = [NSMutableArray array];
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        ///处理事情
        [db setKey:NHDBCipherKey];
        FMResultSet *retSets = [db executeQuery:@"SELECT * FROM t_info_table",nil];
        while ([retSets next]) {
            NSString *infoid = [retSets stringForColumn:@"infoid"];
            NSString *info = [retSets stringForColumn:@"info"];
            NSString *time = [retSets stringForColumn:@"time"];
            NSDictionary *tmp = [NSDictionary dictionaryWithObjectsAndKeys:infoid,@"infoid",info,@"info",time,@"time", nil];
            [tmpArray addObject:tmp];
        }
    }];
    
    return [tmpArray copy];
}

@end
