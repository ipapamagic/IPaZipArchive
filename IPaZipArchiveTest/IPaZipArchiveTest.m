//
//  IPaZipArchiveTest.m
//  IPaZipArchiveTest
//
//  Created by IPaPa on 12/12/19.
//  Copyright (c) 2012年 IPaPa. All rights reserved.
//

#import "IPaZipArchiveTest.h"
#import "IPaZipArchiveWriter.h"
#import "IPaZipArchiveReader.h"
@interface IPaZipArchiveTest() <IPaZipArchiveReaderDelegate>
@end
@implementation IPaZipArchiveTest
{
    NSString *testFilePath1;
    NSString *testFilePath2;
    IPaZipArchiveWriter *writer;
    IPaZipArchiveReader *reader;
}
- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
   
    NSString *documentsDir= [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:documentsDir]) {
        [[NSFileManager defaultManager] removeItemAtPath:documentsDir error:nil];
    }
    
    [[NSFileManager defaultManager] createDirectoryAtPath:documentsDir withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSString *filePath= [documentsDir stringByAppendingPathComponent:@"test.zip"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    testFilePath1 = @"abc.txt";
    
    NSString *testFile = [documentsDir stringByAppendingPathComponent:testFilePath1];
    if (![[NSFileManager defaultManager] fileExistsAtPath:testFile]) {
        NSString *testFileContent = @"test1234";
        NSData* testData = [testFileContent dataUsingEncoding:NSUTF8StringEncoding];
        [testData writeToFile:testFile atomically:YES];
    }
    testFilePath2 = @"x/y/z/abc.txt";
    testFile = [documentsDir stringByAppendingPathComponent:testFilePath2];
    if (![[NSFileManager defaultManager] fileExistsAtPath:testFile]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[testFile stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSString *testFileContent = @"test1234";
        NSData* testData = [testFileContent dataUsingEncoding:NSUTF8StringEncoding];
        [testData writeToFile:testFile atomically:YES];
    }
    
    
    writer = [[IPaZipArchiveWriter alloc] init];
    reader = [[IPaZipArchiveReader alloc] init];
    reader.delegate = self;
}

- (void)tearDown
{
    // Tear-down code here.
    testFilePath1 = nil;
    testFilePath2 = nil;
    writer = nil;
    reader = nil;
    NSString *documentsDir= [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    [[NSFileManager defaultManager] removeItemAtPath:documentsDir error:nil];
    [super tearDown];
}

- (void)testExample
{
    
    NSString *documentsDir= [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    NSString *testPassword = @"test1234";
    
    NSString *filePath= [documentsDir stringByAppendingPathComponent:@"test.zip"];
    NSString *testFile1 = [documentsDir stringByAppendingPathComponent:testFilePath1];
    [writer CreateZipFile:filePath Password:testPassword];
    [writer addFileToZip:testFile1 newname:testFilePath1];
    
    NSString *testFile2 = [documentsDir stringByAppendingPathComponent:testFilePath2];
    [writer addFileToZip:testFile2 newname:testFilePath2];
    [writer CloseZipFile];
    
    
    [reader UnzipOpenFile:filePath];
    
    [reader UnzipFileTo:[filePath stringByDeletingPathExtension] overWrite:YES withPassword:testPassword];
    
    [reader UnzipCloseFile];
    
    
    NSString *unzipDocument = [documentsDir stringByAppendingPathComponent:@"test"];
    
    testFile1 = [unzipDocument stringByAppendingPathComponent:testFilePath1];
    testFile2 = [unzipDocument stringByAppendingPathComponent:testFilePath2];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:testFile1])
    {
        STFail(@"Unit tests Fail unzip test file 1 not exist!");
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:testFile2])
    {
        STFail(@"Unit tests Fail unzip test file 2 not exist!");
    }
    
    NSData *content = [NSData dataWithContentsOfFile:testFile1];
    NSString *testFileContent = @"test1234";
    NSString *fileContent = [[NSString alloc] initWithData:content encoding:NSUTF8StringEncoding];
    
    if (![fileContent isEqualToString:testFileContent]) {
        STFail(@"Unit tests Fail unzip test file 1 Content Not match");
    }
    content = [NSData dataWithContentsOfFile:testFile2];
    
    fileContent = [[NSString alloc] initWithData:content encoding:NSUTF8StringEncoding];
    
    if (![fileContent isEqualToString:testFileContent]) {
        STFail(@"Unit tests Fail unzip test file 2 Content Not match");
    }
    
   

}

#pragma mark - IPaZipArchiveReaderDelegate
-(void)onIPaZipArchiveReader:(IPaZipArchiveReader *)_reader didProcessFile:(NSString*)fileName
{
    NSLog(@"Unit Test print progress:%f",_reader.unzipProgress);
}
@end
