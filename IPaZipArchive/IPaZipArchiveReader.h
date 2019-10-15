//
//  IPaZipArchiveReader.h
//  IPaZipArchive
//
//  Created by IPaPa on 12/12/19.
//  Copyright (c) 2012年 IPaPa. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, IPaZipReaderRetCode) {
    IPaZipReaderRetCode_Success,
    IPaZipReaderRetCode_CloseFail,
    IPaZipReaderRetCode_CanNotReachFile,
    IPaZipReaderRetCode_CanNotOpenFile,
    IPaZipReaderRetCode_CanNotGetFileInfo,
    IPaZipReaderRetCode_NeedPassword,
    IPaZipReaderRetCode_FailToReadZipFile,
};

@protocol IPaZipArchiveReaderDelegate;
@interface IPaZipArchiveReader : NSObject
@property (nonatomic,readonly) float unzipProgress;
@property (nonatomic,readonly) BOOL isEncrypted;
-(IPaZipReaderRetCode) unzipOpenFile:(NSString*) zipFile;
-(IPaZipReaderRetCode) unzipFileTo:(NSString*) path overWrite:(BOOL) overwrite;
-(IPaZipReaderRetCode) unzipFileTo:(NSString*) path overWrite:(BOOL) overwrite withPassword:(NSString *)password;
-(IPaZipReaderRetCode) unzipCloseFile;


@end

