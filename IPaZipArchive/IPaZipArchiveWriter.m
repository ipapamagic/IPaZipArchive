//
//  IPaZipArchiveWriter.m
//  IPaZipArchive
//
//  Created by IPaPa on 12/12/19.
//  Copyright (c) 2012年 IPaPa. All rights reserved.
//

#import "IPaZipArchiveWriter.h"
#include "minizip/zip.h"
@implementation IPaZipArchiveWriter
{
    zipFile	_zipFile;
    NSString *zipPassword;
}

-(void) dealloc
{
	[self CloseZipFile];
}

-(BOOL) CreateZipFile:(NSString*) zipFile
{
	_zipFile = zipOpen( (const char*)[zipFile UTF8String], 0 );
	if( !_zipFile )
		return NO;
	return YES;
}

-(BOOL) CreateZipFile:(NSString*) zipFile Password:(NSString*) password
{
	zipPassword = [password copy];
	return [self CreateZipFile:zipFile];
}

-(BOOL) addFileToZip:(NSString*) file newname:(NSString*) newname;
{
	if( !_zipFile )
		return NO;
    //	tm_zip filetime;
	time_t current;
	time( &current );
	
	zip_fileinfo zipInfo = {0};
    //	zipInfo.dosDate = (unsigned long) current;
	
    NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:nil];
    
    //	NSDictionary* attr = [[NSFileManager defaultManager] fileAttributesAtPath:file traverseLink:YES];
	if( attr )
	{
		NSDate* fileDate = (NSDate*)[attr objectForKey:NSFileModificationDate];
		if( fileDate )
		{
			// some application does use dosDate, but tmz_date instead
            //	zipInfo.dosDate = [fileDate timeIntervalSinceDate:[self Date1980] ];
			NSCalendar* currCalendar = [NSCalendar currentCalendar];
			uint flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit |
            NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit ;
			NSDateComponents* dc = [currCalendar components:flags fromDate:fileDate];
			zipInfo.tmz_date.tm_sec = [dc second];
			zipInfo.tmz_date.tm_min = [dc minute];
			zipInfo.tmz_date.tm_hour = [dc hour];
			zipInfo.tmz_date.tm_mday = [dc day];
			zipInfo.tmz_date.tm_mon = [dc month] - 1;
			zipInfo.tmz_date.tm_year = [dc year];
		}
	}
	
	int ret ;
	NSData* data = nil;
	if( [zipPassword length] == 0 )
	{
		ret = zipOpenNewFileInZip( _zipFile,
								  (const char*) [newname UTF8String],
								  &zipInfo,
								  NULL,0,
								  NULL,0,
								  NULL,//comment
								  Z_DEFLATED,
								  Z_DEFAULT_COMPRESSION );
	}
	else
	{
		data = [ NSData dataWithContentsOfFile:file];
		uLong crcValue = crc32( 0L,NULL, 0L );
		crcValue = crc32( crcValue, (const Bytef*)[data bytes], [data length] );
		ret = zipOpenNewFileInZip3( _zipFile,
                                   (const char*) [newname UTF8String],
                                   &zipInfo,
                                   NULL,0,
                                   NULL,0,
                                   NULL,//comment
                                   Z_DEFLATED,
                                   Z_DEFAULT_COMPRESSION,
                                   0,
                                   15,
                                   8,
                                   Z_DEFAULT_STRATEGY,
                                   [zipPassword cStringUsingEncoding:NSASCIIStringEncoding],
                                   crcValue );
	}
	if( ret!=Z_OK )
	{
		return NO;
	}
	if( data==nil )
	{
		data = [ NSData dataWithContentsOfFile:file];
	}
	unsigned int dataLen = [data length];
	ret = zipWriteInFileInZip( _zipFile, (const void*)[data bytes], dataLen);
	if( ret!=Z_OK )
	{
		return NO;
	}
	ret = zipCloseFileInZip( _zipFile );
	if( ret!=Z_OK )
		return NO;
	return YES;
}

-(BOOL) CloseZipFile
{
	zipPassword = nil;
	if( _zipFile==NULL )
		return NO;
	BOOL ret =  zipClose( _zipFile,NULL )==Z_OK?YES:NO;
	_zipFile = NULL;
	return ret;
}

@end
