//
//  NHFMDBEngine.m
//  NHFMDBPro
//
//  Created by hu jiaju on 15/9/9.
//  Copyright (c) 2015年 hu jiaju. All rights reserved.
//

/*
 *非线程安全使用示例
 */

#import "NHFMDBEngine.h"
#import <FMDB.h>
#import <sqlite3.h>

static NSString *NHDBNAME = @"NHINFO.DB";
static NSString *NHSQLS   = @"NH_SQLS";

@interface NHFMDBEngine ()

@property (nonatomic, strong)FMDatabase *DB;

@end

static NHFMDBEngine *instance = nil;

@implementation NHFMDBEngine

+ (NHFMDBEngine *)share {
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

- (BOOL)createFMDB {
    
    BOOL ret = false;
    NSString *dbpath = [self filePath:NHDBNAME];
    _DB = [FMDatabase databaseWithPath:dbpath];
    if (_DB != nil) {
        ///想使用数据库 必须首先打开数据库
        ret = [_DB open];
        if (!ret) {
            NSLog(@"failed to open db !");
            return ret;
        }
        NSLog(@"success to create db at path:%@!",dbpath);
        [_DB setShouldCacheStatements:true];
        [_DB beginTransaction];
        NSString *sqlFile = [[NSBundle mainBundle] pathForResource:NHSQLS ofType:@"txt"];
        if (!sqlFile) {
            return false;
        }
        NSString *sqls = [NSString stringWithContentsOfFile:sqlFile encoding:NSUTF8StringEncoding error:nil];
        NSArray *sqlArr = [sqls componentsSeparatedByString:@"|"];
        for (NSString *sql in sqlArr) {
            [_DB executeUpdate:sql];
        }
        [_DB commit];///提交事务
        [_DB close];///使用完毕记得关闭数据库
    }
    
    ///无加密数据库迁移
    if(![_DB goodConnection]){ //无效连接
        [_DB close];
        [self upgradeDatabase:dbpath];
    }
    return ret;
}

- (BOOL)openDB {
    BOOL ret = _DB == nil;
    if (ret) {
        NSLog(@"DB is nil , goto create db now !");
        ret = [self createFMDB];
        if (!ret) {
            NSLog(@"failed to create db again !");
            return ret;
        }
    }
    /// open the db
    ret = [_DB open];
    if (!ret) {
        NSLog(@"failed to open db !");
        return ret;
    }
    return ret;
}

- (BOOL)closeDB {
    BOOL ret = _DB == nil;
    if (ret) {
        NSLog(@"DB is nil, don't need to close !");
        return !ret;
    }
    ret = [_DB inTransaction];
    if (ret) {
        [_DB commit];
    }
    ret = [_DB close];
    return ret;
}

#pragma mark -- Commen Method --

- (BOOL)saveInfo:(id)info {
    BOOL ret = [self openDB];
    if (!ret) {
        NSLog(@"failed to open DB in function :%s",__FUNCTION__);
        return ret;
    }
    [_DB setShouldCacheStatements:true];
    ///到这一步数据库已经成功打开 可针对大数据开启事务模式
    [_DB beginTransaction];
    ///处理事情
    NSString *querySql = @"INSERT OR REPLACE INTO t_info_table (infoid, info, time) VALUES(?, ?, ?)";
    NSMutableArray *params = [NSMutableArray array];
    [params addObject:@"infoid"];
    [params addObject:@"info"];
    [params addObject:@"time"];
    ///执行SQL语句
    ret = [_DB executeUpdate:querySql withArgumentsInArray:params];
    ///关闭数据库
    [self closeDB];
    return ret;
}

- (BOOL)deleteInfo:(id)info {
    BOOL ret = [self openDB];
    if (!ret) {
        NSLog(@"failed to open DB in function :%s",__FUNCTION__);
        return ret;
    }
    [_DB setShouldCacheStatements:true];
    ///到这一步数据库已经成功打开 可针对大数据开启事务模式
    [_DB beginTransaction];
    ///处理事情
    ret = [_DB executeUpdate:@"DELETE FROM t_info_table WHERE infoid = ? AND info = ?",@"infoid",@"info",nil];
    ///关闭数据库
    [self closeDB];
    return ret;
}

- (BOOL)updateInfo:(id)info {
    BOOL ret = [self openDB];
    if (!ret) {
        NSLog(@"failed to open DB in function :%s",__FUNCTION__);
        return ret;
    }
    [_DB setShouldCacheStatements:true];
    ///到这一步数据库已经成功打开 可针对大数据开启事务模式
    [_DB beginTransaction];
    ///处理事情
    ret = [_DB executeUpdate:@"UPDATE t_info_table SET info = ? WHERE infoid = ?",@"info",@"infoid",nil];
    ///关闭数据库
    [self closeDB];
    return ret;
}

- (id)getInfo{
    BOOL ret = [self openDB];
    if (!ret) {
        NSLog(@"failed to open DB in function :%s",__FUNCTION__);
        return nil;
    }
    [_DB setShouldCacheStatements:true];
    ///到这一步数据库已经成功打开 可针对大数据开启事务模式
    [_DB beginTransaction];
    ///处理事情
    FMResultSet *retSets = [_DB executeQuery:@"SELECT * FROM t_info_table WHERE infoid = ? LIMIT 1",@"infoid",nil];
    NSMutableDictionary *infos ;
    while ([retSets next]) {
        NSString *infoid = [retSets stringForColumn:@"infoid"];
        NSString *info = [retSets stringForColumn:@"info"];
        NSString *time = [retSets stringForColumn:@"time"];
        NSDictionary *tmp = [NSDictionary dictionaryWithObjectsAndKeys:infoid,@"infoid",info,@"info",time,@"time", nil];
        infos = [NSMutableDictionary dictionaryWithDictionary:tmp];
    }
    ///关闭数据库
    [self closeDB];
    return infos;
}
- (NSArray *)getInfos{
    BOOL ret = [self openDB];
    if (!ret) {
        NSLog(@"failed to open DB in function :%s",__FUNCTION__);
        return nil;
    }
    [_DB setShouldCacheStatements:true];
    ///到这一步数据库已经成功打开 可针对大数据开启事务模式
    [_DB beginTransaction];
    ///处理事情
    FMResultSet *retSets = [_DB executeQuery:@"SELECT * FROM t_info_table WHERE infoid = ?",@"infoid",nil];
    NSMutableArray *infos = [NSMutableArray array];
    while ([retSets next]) {
        NSString *infoid = [retSets stringForColumn:@"infoid"];
        NSString *info = [retSets stringForColumn:@"info"];
        NSString *time = [retSets stringForColumn:@"time"];
        NSDictionary *tmp = [NSDictionary dictionaryWithObjectsAndKeys:infoid,@"infoid",info,@"info",time,@"time", nil];
        [infos addObject:tmp];
    }
    ///关闭数据库
    [self closeDB];
    return infos;
}

#pragma mark == 数据库迁移==

- (void)upgradeDatabase:(NSString *)path{
    NSString *tmppath = [self changeDatabasePath:path];
    if(tmppath){
        const char* sqlQ = [[NSString stringWithFormat:@"ATTACH DATABASE '%@' AS encrypted KEY '%@'",path,@"123456"] UTF8String];
        
        sqlite3 *unencrypted_DB;
        if (sqlite3_open([tmppath UTF8String], &unencrypted_DB) == SQLITE_OK) {
            
            // Attach empty encrypted database to unencrypted database
            int status = sqlite3_exec(unencrypted_DB, sqlQ, NULL, NULL, NULL);
            
            // export database
            status = sqlite3_exec(unencrypted_DB, "SELECT sqlcipher_export('encrypted');", NULL, NULL, NULL);
            
            // Detach encrypted database
            status = sqlite3_exec(unencrypted_DB, "DETACH DATABASE encrypted;", NULL, NULL, NULL);
            
            status = sqlite3_close(unencrypted_DB);
            
            //delete tmp database
            [self removeDatabasePath:tmppath];
        }
        else {
            sqlite3_close(unencrypted_DB);
            NSAssert1(NO, @"Failed to open database with message ‘%s‘.", sqlite3_errmsg(unencrypted_DB));
        }
    }
}

- (NSString *)changeDatabasePath:(NSString *)path{
    NSError * err = NULL;
    NSFileManager * fm = [[NSFileManager alloc] init];
    NSString *tmppath = [path stringByReplacingOccurrencesOfString:@"sqlite" withString:@"tem"];
    BOOL result = [fm moveItemAtPath:path toPath:tmppath error:&err];
    if(!result){
        NSLog(@"Error: %@", err);
        return nil;
    }else{
        return tmppath;
    }
}

-(void)removeDatabasePath:(NSString *)path
{
    NSError * err = NULL;
    NSFileManager * fm = [[NSFileManager alloc] init];
    BOOL result = [fm removeItemAtPath:path error:&err];
    if(!result){
        NSLog(@"Error: %@", err);
    }
}


@end
