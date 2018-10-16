//
//  main.m
//  carify
//
//  Created by Wilson Styres on 10/16/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

void insertFilenameIntoDictionaryForSize(NSString *filepath, NSMutableDictionary *dictionary, NSString *size, NSString *idiom, NSString *scale, NSString *output);
void createOutputDirectory(NSString *outputDirPath);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString *assetsFolderPath = @"/Users/wstyres/CarifyTests/Assets/";//argv[1];
        NSString *outputFolderPath = @"/Users/wstyres/CarifyTests/Assets.xcassets/";//argv[1]; + Assets.xcassets
        NSLog(@"Analyzing Assets folder at %@", assetsFolderPath);
        
        createOutputDirectory(outputFolderPath);
        
        NSError *dirError;
        NSArray *dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:assetsFolderPath error:&dirError]; //List of image sets to compile
        
        if (dirError != nil) {
            NSLog(@"Erorr while reading directories: %@", dirError.localizedDescription);
        }
        
        for (NSString *directory in dirs) {
            if (![directory isEqualToString:@".DS_Store"]) {
                NSError *imagesError;
                NSString *imageSetPath = [assetsFolderPath stringByAppendingPathComponent:directory];
                NSArray *images = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:imageSetPath error:&imagesError]; //List of images in each set
                
                if (dirError != nil) {
                    NSLog(@"Error while reading directories: %@", dirError.localizedDescription);
                }
                
                if ([directory isEqualToString:@"AppIcon"]) { //We're making an AppIcon image set
                    NSError *createError;
                    NSString *outputPath = [outputFolderPath stringByAppendingPathComponent:@"AppIcon.appiconset"];
                    [[NSFileManager defaultManager] createDirectoryAtPath:outputPath withIntermediateDirectories:true attributes:nil error:&createError];
                    
                    if (createError != nil) {
                        NSLog(@"Error while creating path %@", createError.localizedDescription);
                    }//Create AppIcon.appiconset
                    
                    NSString *jsonString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AppIcon" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil];
                    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                    NSMutableDictionary *jsonOutput = [[NSJSONSerialization JSONObjectWithData:data options:0 error:nil] mutableCopy];
                    
                    for (NSString *imageFilename in images) {
                        NSString *imagePath = [imageSetPath stringByAppendingPathComponent:imageFilename];
                        NSArray * imageReps = [NSBitmapImageRep imageRepsWithContentsOfFile:imagePath];
                        
                        NSInteger imageSize = 0; //if they're actually app icons, they should be the same dimensions
                        
                        for (NSImageRep * imageRep in imageReps) {
                            if ([imageRep pixelsWide] > imageSize) imageSize = [imageRep pixelsWide];
                            if ([imageRep pixelsHigh] > imageSize) imageSize = [imageRep pixelsHigh];
                        }

                        switch (imageSize) {
                            case 40: { //20x20@2x and 40x40@1x
                                insertFilenameIntoDictionaryForSize(imagePath, jsonOutput, @"20x20", @"iphone", @"2x", outputPath);
                                insertFilenameIntoDictionaryForSize(imagePath, jsonOutput, @"20x20", @"ipad", @"2x", outputPath);
                                insertFilenameIntoDictionaryForSize(imagePath, jsonOutput, @"40x40", @"ipad", @"1x", outputPath);
                                break;
                            }
                            case 60: { //20x20@3x
                                insertFilenameIntoDictionaryForSize(imagePath, jsonOutput, @"20x20", @"iphone", @"3x", outputPath);
                                break;
                            }
                            case 58: { //29x29@2x
                                insertFilenameIntoDictionaryForSize(imagePath, jsonOutput, @"29x29", @"iphone", @"2x", outputPath);
                                insertFilenameIntoDictionaryForSize(imagePath, jsonOutput, @"29x29", @"ipad", @"2x", outputPath);
                                break;
                            }
                            case 87: { //29x29@3x
                                insertFilenameIntoDictionaryForSize(imagePath, jsonOutput, @"29x29", @"iphone", @"3x", outputPath);
                                break;
                            }
                            case 80: { //40x40@2x
                                insertFilenameIntoDictionaryForSize(imagePath, jsonOutput, @"40x40", @"iphone", @"2x", outputPath);
                                insertFilenameIntoDictionaryForSize(imagePath, jsonOutput, @"40x40", @"ipad", @"2x", outputPath);
                                break;
                            }
                            case 120: { //40x40@3x and 60x60@2x
                                insertFilenameIntoDictionaryForSize(imagePath, jsonOutput, @"40x40", @"iphone", @"3x", outputPath);
                                insertFilenameIntoDictionaryForSize(imagePath, jsonOutput, @"60x60", @"iphone", @"2x", outputPath);
                                break;
                            }
                            case 180: {
                                insertFilenameIntoDictionaryForSize(imagePath, jsonOutput, @"60x60", @"iphone", @"3x", outputPath);
                                break;
                            }
                            case 20: { //20x20@1x
                                insertFilenameIntoDictionaryForSize(imagePath, jsonOutput, @"20x20", @"ipad", @"1x", outputPath);
                                break;
                            }
                            case 29: { //29x29@1x
                                insertFilenameIntoDictionaryForSize(imagePath, jsonOutput, @"29x29", @"ipad", @"1x", outputPath);
                                break;
                            }
                            case 76: { //76x76@1x
                                insertFilenameIntoDictionaryForSize(imagePath, jsonOutput, @"76x76", @"ipad", @"1x", outputPath);
                                break;
                            }
                            case 152: { //152x152@1x
                                insertFilenameIntoDictionaryForSize(imagePath, jsonOutput, @"76x76", @"ipad", @"2x", outputPath);
                                break;
                            }
                            case 167: {
                                insertFilenameIntoDictionaryForSize(imagePath, jsonOutput, @"83.5x83.5", @"ipad", @"2x", outputPath);
                                break;
                            }
                            case 1024: {
                                insertFilenameIntoDictionaryForSize(imagePath, jsonOutput, @"1024x1024", @"ios-marketing", @"1x", outputPath);
                                break;
                            }
                        }
                    }
                    
                    NSError *outputError;
                    NSError *writeError;
                    NSData *outputData = [NSJSONSerialization dataWithJSONObject:jsonOutput options:0 error:&outputError];
                    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
                    [outputString writeToFile:[outputPath stringByAppendingPathComponent:@"Contents.json"] atomically:true encoding:NSUTF8StringEncoding error:&writeError];
                    
                    if (outputError != nil) {
                        NSLog(@"Error turning NSDictionary into JSON: %@", outputError);
                    }
                    
                    if (writeError != nil) {
                        NSLog(@"Error writing json to file: %@", writeError);
                    }
                    
                }
                else if ([directory isEqualToString:@"LaunchImage"]) {
                    printf("Launch images not currently supported");
                }
                else {
                    
                }
            }
        }
    }
    return 0;
}

void insertFilenameIntoDictionaryForSize(NSString *filepath, NSMutableDictionary *dictionary, NSString *size, NSString *idiom, NSString *scale, NSString *output) { //Doing this for futureproofing with future sizes
    NSArray *images = (NSArray *)dictionary[@"images"];
    NSMutableArray *newArray = [images mutableCopy];
    
    int i = 0;
    for (NSDictionary *dict in images) {
        NSMutableDictionary *newDict = [dict mutableCopy];
        if ([dict[@"size"] isEqualToString:size] && [dict[@"idiom"] isEqualToString:idiom] && [dict[@"scale"] isEqualToString:scale]) {
            [newDict setObject:[filepath lastPathComponent] forKey:@"filename"];
            newArray[i] = newDict;
        }
        i++;
    }
    
    [dictionary setObject:newArray forKey:@"images"];
    
    NSError *copyError;
    [[NSFileManager defaultManager] copyItemAtPath:filepath toPath:[output stringByAppendingPathComponent:[filepath lastPathComponent]] error:&copyError]; //Copy icon to directory
    if (copyError != nil) {
        NSLog(@"Error while copying icon %@", copyError.localizedDescription);
    }
}

void createOutputDirectory(NSString *outputDirPath) {
    NSError *createError;
    [[NSFileManager defaultManager] createDirectoryAtPath:outputDirPath withIntermediateDirectories:true attributes:nil error:&createError];
    
    if (createError != nil) {
        NSLog(@"Error while creating path %@", createError.localizedDescription);
    }
    
    NSString *contents = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Contents" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil];
    NSError *writeError;
    [contents writeToFile:[outputDirPath stringByAppendingString:@"Contents.json"] atomically:true encoding:NSUTF8StringEncoding error:&writeError];
    
    if (writeError != nil) {
        NSLog(@"Error while writing contents.json %@", writeError.localizedDescription);
    }
}
