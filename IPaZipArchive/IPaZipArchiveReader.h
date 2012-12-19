//
//  IPaZipArchiveReader.h
//  IPaZipArchive
//
//  Created by IPaPa on 12/12/19.
//  Copyright (c) 2012年 IPaPa. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum {
    IPaZipReaderErrorCode_CanNotReachFile,
    IPaZipReaderErrorCode_CanNotOpenFile,
    IPaZipReaderErrorCode_CanNotGetFileInfo,
    IPaZipReaderErrorCode_NeedPassword,
    IPaZipReaderErrorCode_FailToReadZipFile,
}IPaZipReaderErrorCode;

@protocol IPaZipArchiveReaderDelegate;
@interface IPaZipArchiveReader : NSObject
@property (nonatomic,weak) id<IPaZipArchiveReaderDelegate> delegate;
@property (nonatomic,readonly) CGFloat unzipProgress;
-(BOOL) UnzipOpenFile:(NSString*) zipFile;
-(BOOL) UnzipFileTo:(NSString*) path overWrite:(BOOL) overwrite;
-(BOOL) UnzipFileTo:(NSString*) path overWrite:(BOOL) overwrite withPassword:(NSString *)password;
-(BOOL) UnzipCloseFile;

-(BOOL) UnzipIsEncrypted;

@end

@protocol IPaZipArchiveReaderDelegate <NSObject>
@optional
-(void)onIPaZipArchiveReader:(IPaZipArchiveReader*)reader errorOccur:(IPaZipReaderErrorCode)errorCode;
-(void)onIPaZipArchiveReader:(IPaZipArchiveReader *)reader willProcessFile:(NSString*)fileName;
-(void)onIPaZipArchiveReader:(IPaZipArchiveReader *)reader didProcessFile:(NSString*)fileName;
@end
