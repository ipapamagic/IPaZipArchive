//
//  IPaZipArchiveReader.m
//  IPaZipArchive
//
//  Created by IPaPa on 12/12/19.
//  Copyright (c) 2012年 IPaPa. All rights reserved.
//

#import "IPaZipArchiveReader.h"
#include "minizip/unzip.h"

@implementation IPaZipArchiveReader
{
    unzFile		_unzFile;
    BOOL isEncrypted;
    uLong originalFileSize;
    uLong processFileSize;
}
-(void) dealloc
{
    [self unzipCloseFile];
}
-(IPaZipReaderRetCode) unzipOpenFile:(NSString*) zipFile
{
    _unzFile = unzOpen( (const char*)[zipFile UTF8String] );
    if( _unzFile )
    {
        unz_global_info  globalInfo = {0};
        if( unzGetGlobalInfo(_unzFile, &globalInfo )==UNZ_OK )
        {
            NSLog(@"%@",[NSString stringWithFormat:@"%d entries in the zip file",(int)globalInfo.number_entry] );
        }
        isEncrypted = NO;
        originalFileSize = 0;
        //check original data size and check is Encrypted
        int ret = unzGoToFirstFile( _unzFile );
        if (ret == UNZ_OK) {
            do {
                ret = unzOpenCurrentFile( _unzFile );
                if( ret!=UNZ_OK ) {
                    [self unzipCloseFile];
                    return IPaZipReaderRetCode_FailToReadZipFile;
                }
                unz_file_info	fileInfo ={0};
                ret = unzGetCurrentFileInfo(_unzFile, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
                if (ret!= UNZ_OK) {
                    [self unzipCloseFile];
                    return IPaZipReaderRetCode_FailToReadZipFile;
                }
                else if((fileInfo.flag & 1) == 1) {
                    isEncrypted = YES;
                }
                originalFileSize += fileInfo.uncompressed_size;
                unzCloseCurrentFile( _unzFile );
                ret = unzGoToNextFile( _unzFile );
            }while( ret==UNZ_OK && UNZ_OK!=UNZ_END_OF_LIST_OF_FILE );
            
            
        }
        
    }
    return (_unzFile!=NULL) ? IPaZipReaderRetCode_Success : IPaZipReaderRetCode_FailToReadZipFile;
}


-(IPaZipReaderRetCode) unzipFileTo:(NSString*) path overWrite:(BOOL) overwrite
{
    return [self unzipFileTo:path overWrite:overwrite withPassword:nil];
}
-(IPaZipReaderRetCode) unzipFileTo:(NSString*) path overWrite:(BOOL) overwrite withPassword:(NSString *)password
{
    
    processFileSize = 0;
    int ret = unzGoToFirstFile( _unzFile );
    unsigned char		buffer[4096] = {0};
    NSFileManager* fman = [NSFileManager defaultManager];
    if( ret!=UNZ_OK )
    {
        return IPaZipReaderRetCode_CanNotReachFile;
    }
    
    do{
        if( [password length]==0 )
            ret = unzOpenCurrentFile( _unzFile );
        else
            ret = unzOpenCurrentFilePassword( _unzFile, [password cStringUsingEncoding:NSASCIIStringEncoding] );
        if( ret!=UNZ_OK )
        {
            return IPaZipReaderRetCode_CanNotOpenFile;
        }
        // reading data and write to file
        int read ;
        unz_file_info	fileInfo ={0};
        ret = unzGetCurrentFileInfo(_unzFile, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
        if( ret!=UNZ_OK )
        {
            
            unzCloseCurrentFile( _unzFile );
            return IPaZipReaderRetCode_CanNotGetFileInfo;
            
        }
        
        //check if password is needed
        if ((fileInfo.flag & 1) == 1 && password == nil) {
            unzCloseCurrentFile( _unzFile );
            return IPaZipReaderRetCode_NeedPassword;
        }
        
        
        char* filename = (char*) malloc( fileInfo.size_filename +1 );
        unzGetCurrentFileInfo(_unzFile, &fileInfo, filename, fileInfo.size_filename + 1, NULL, 0, NULL, 0);
        filename[fileInfo.size_filename] = '\0';
        
        // check if it contains directory
        NSString * strPath = [NSString  stringWithCString:filename encoding:NSUTF8StringEncoding];
        
        
        //		NSString * strPath = [NSString  stringWithCString:filename];
        BOOL isDirectory = NO;
        if( filename[fileInfo.size_filename-1]=='/' || filename[fileInfo.size_filename-1]=='\\')
            isDirectory = YES;
        free( filename );
        if( [strPath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/\\"]].location!=NSNotFound )
        {// contains a
            strPath = [strPath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
        }
        NSString* fullPath = [path stringByAppendingPathComponent:strPath];
        
        if( isDirectory )
            [fman createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
        else
            [fman createDirectoryAtPath:[fullPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        if( [fman fileExistsAtPath:fullPath] && !isDirectory && !overwrite )
        {
            
            unzCloseCurrentFile( _unzFile );
            ret = unzGoToNextFile( _unzFile );
            continue;
        }
        FILE* fp = fopen( (const char*)[fullPath UTF8String], "wb");
        while( fp )
        {
            read=unzReadCurrentFile(_unzFile, buffer, 4096);
            if( read > 0 )
            {
                fwrite(buffer, read, 1, fp );
            }
            else if( read<0 )
            {
                return IPaZipReaderRetCode_FailToReadZipFile;
                break;
            }
            else
                break;
        }
        if( fp )
        {
            fclose( fp );
            // set the orignal datetime property
            NSDate* orgDate = nil;
            
            //{{ thanks to brad.eaton for the solution
            NSDateComponents *dc = [[NSDateComponents alloc] init];
            
            dc.second = fileInfo.tmu_date.tm_sec;
            dc.minute = fileInfo.tmu_date.tm_min;
            dc.hour = fileInfo.tmu_date.tm_hour;
            dc.day = fileInfo.tmu_date.tm_mday;
            dc.month = fileInfo.tmu_date.tm_mon+1;
            dc.year = fileInfo.tmu_date.tm_year;
            
            NSCalendar *gregorian = [[NSCalendar alloc]
                                     initWithCalendarIdentifier:NSGregorianCalendar];
            
            orgDate = [gregorian dateFromComponents:dc] ;
            //}}
            
            
            NSDictionary* attr = [NSDictionary dictionaryWithObject:orgDate forKey:NSFileModificationDate]; //[[NSFileManager defaultManager] fileAttributesAtPath:fullPath traverseLink:YES];
            if( attr )
            {
                //		[attr  setValue:orgDate forKey:NSFileCreationDate];
                if( ![[NSFileManager defaultManager] setAttributes:attr ofItemAtPath:fullPath error:nil] )
                {
                    // cann't set attributes
                    NSLog(@"Failed to set attributes");
                }
                
            }
            
            
            
        }
        
        //record current process file size
        processFileSize += fileInfo.uncompressed_size;
        
        unzCloseCurrentFile( _unzFile );
        ret = unzGoToNextFile( _unzFile );
    }while( ret==UNZ_OK && UNZ_OK!=UNZ_END_OF_LIST_OF_FILE );
    return IPaZipReaderRetCode_Success;
}
-(float)unzipProgress
{
    return (float) processFileSize / (float)originalFileSize;
}
-(BOOL)isEncrypted
{
    return isEncrypted;
}
-(IPaZipReaderRetCode) unzipCloseFile
{
    if( _unzFile )
    {
        int ret = unzClose( _unzFile );
        _unzFile = nil;
        if (ret != UNZ_OK)
        {
            return IPaZipReaderRetCode_CloseFail;
        }
    }
    return IPaZipReaderRetCode_Success;
}



@end
