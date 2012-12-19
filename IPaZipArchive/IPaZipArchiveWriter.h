//
//  IPaZipArchiveWriter.h
//  IPaZipArchive
//
//  Created by IPaPa on 12/12/19.
//  Copyright (c) 2012年 IPaPa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IPaZipArchiveWriter : NSObject
-(BOOL) CreateZipFile:(NSString*) zipFile;
-(BOOL) CreateZipFile:(NSString*) zipFile Password:(NSString*) password;
-(BOOL) addFileToZip:(NSString*) file newname:(NSString*) newname;
-(BOOL) CloseZipFile;

@end
