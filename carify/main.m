//
//  main.m
//  carify
//
//  Created by Wilson Styres on 10/16/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

void createAssetsCarInDirectory(NSString *resourcesDirectory, NSString *xcassetsPath);
void createAppIconSet(NSString *directory, NSString *assetsFolderPath, NSString *outputFolderPath);
void createBasicImageSet(NSString *directory, NSString *assetsFolderPath, NSString *outputFolderPath);
void insertFilenameIntoDictionaryForSize(NSString *filepath, NSMutableDictionary *dictionary, NSString *size, NSString *idiom, NSString *scale, NSString *output);
void createOutputDirectory(NSString *outputDirPath);

int main(int argc, const char * argv[]) { //Assets input, Resources folder output
    @autoreleasepool {
        if (argc < 3) {
            printf("Usage: ./carify <Assets folder input> <Resources folder output\n");
        }
        else {
            NSString *assetsFolderPath = [NSString stringWithUTF8String:argv[1]];
            NSString *resourcesFolderPath = [NSString stringWithUTF8String:argv[2]];
            NSString *outputFolderPath = [resourcesFolderPath stringByAppendingString:@"/Assets.xcassets/"];
            
            createOutputDirectory(outputFolderPath);
            
            NSError *dirError;
            NSArray *dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:assetsFolderPath error:&dirError]; //List of image sets to compile
            
            if (dirError != nil) {
                NSLog(@"Error while reading directories: %@", dirError.localizedDescription);
            }
            
            for (NSString *directory in dirs) {
                if (![directory isEqualToString:@".DS_Store"]) {
                    if ([directory isEqualToString:@"AppIcon"]) { //We're making an AppIcon image set
                        createAppIconSet(directory, assetsFolderPath, outputFolderPath);
                    }
                    else if ([directory isEqualToString:@"LaunchImage"]) {
                        printf("Launch images not currently supported");
                    }
                    else {
                        createBasicImageSet(directory, assetsFolderPath, outputFolderPath);
                    }
                }
            }
            
            createAssetsCarInDirectory(resourcesFolderPath, outputFolderPath);
        }
    }
    return 0;
}

void createAssetsCarInDirectory(NSString *resourcesDirectory, NSString *xcassetsPath) {
    NSTask *createCarTask = [[NSTask alloc] init];
    [createCarTask setLaunchPath:@"/Applications/Xcode.app/Contents/Developer/usr/bin/actool"];
    NSArray *carArgs = [[NSArray alloc] initWithObjects: xcassetsPath, @"--compile", resourcesDirectory, @"--platform", @"iphoneos", @"--minimum-deployment-target", @"8.0", @"--app-icon", @"AppIcon", @"--output-partial-info-plist", [resourcesDirectory stringByAppendingPathComponent:@"tmp.plist"], nil];
    [createCarTask setArguments:carArgs];
    
    [createCarTask launch];
    [createCarTask waitUntilExit];
    
    [[NSFileManager defaultManager] removeItemAtPath:xcassetsPath error:nil];
    
    NSDictionary *tmpPlistDict = [NSDictionary dictionaryWithContentsOfFile:[resourcesDirectory stringByAppendingPathComponent:@"tmp.plist"]];
    NSMutableDictionary *infoPlistDict = [NSMutableDictionary dictionaryWithContentsOfFile:[resourcesDirectory stringByAppendingPathComponent:@"Info.plist"]];
    
    [infoPlistDict addEntriesFromDictionary:tmpPlistDict];
    [infoPlistDict writeToFile:[resourcesDirectory stringByAppendingPathComponent:@"Info.plist"] atomically:true];
    
    [[NSFileManager defaultManager] removeItemAtPath:[resourcesDirectory stringByAppendingPathComponent:@"/tmp.plist"] error:nil];
}

void createAppIconSet(NSString *directory, NSString *assetsFolderPath, NSString *outputFolderPath) {
    NSError *imagesError;
    NSString *imageSetPath = [assetsFolderPath stringByAppendingPathComponent:directory];
    NSArray *images = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:imageSetPath error:&imagesError]; //List of images in each set
    
    if (imagesError != nil) {
        NSLog(@"Error while reading directories: %@", imagesError.localizedDescription);
    }
    
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

void createBasicImageSet(NSString *directory, NSString *assetsFolderPath, NSString *outputFolderPath) {
    NSError *imagesError;
    NSString *imageSetPath = [assetsFolderPath stringByAppendingPathComponent:directory];
    NSArray *images = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:imageSetPath error:&imagesError]; //List of images in each set
    
    if (imagesError != nil) {
        NSLog(@"Error while reading directories: %@", imagesError.localizedDescription);
    }
    
    NSError *createError;
    NSString *outputPath = [outputFolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.imageset", directory]];
    [[NSFileManager defaultManager] createDirectoryAtPath:outputPath withIntermediateDirectories:true attributes:nil error:&createError];
    
    if (createError != nil) {
        NSLog(@"Error while creating path %@", createError.localizedDescription);
    } //Create image set
    
    NSString *jsonString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Universal" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil];
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *jsonOutput = [[NSJSONSerialization JSONObjectWithData:data options:0 error:nil] mutableCopy];
    
    for (NSString *imageFilename in images) {
        if ([imageFilename isEqualToString:@".DS_Store"]) {
            continue;
        }
        
        NSString *imagePath = [imageSetPath stringByAppendingPathComponent:imageFilename];
        NSArray *components = [imageFilename componentsSeparatedByString:@"@"];
        if ([components count] > 1) {
            NSString *scale = components[1];
            NSArray *secondComp = [scale componentsSeparatedByString:@"."];
            scale = secondComp[0];
            
            NSArray *images = (NSArray *)jsonOutput[@"images"];
            NSMutableArray *newArray = [images mutableCopy];
            
            if ([scale isEqualToString:@"1x"]) {
                NSMutableDictionary *scaleDict = [newArray[0] mutableCopy];
                [scaleDict setObject:imageFilename forKey:@"filename"];
                newArray[0] = scaleDict;
            }
            else if ([scale isEqualToString:@"2x"]) {
                NSMutableDictionary *scaleDict = [newArray[1] mutableCopy];
                [scaleDict setObject:imageFilename forKey:@"filename"];
                newArray[1] = scaleDict;
            }
            else if ([scale isEqualToString:@"3x"])  {
                NSMutableDictionary *scaleDict = [newArray[2] mutableCopy];
                [scaleDict setObject:imageFilename forKey:@"filename"];
                newArray[2] = scaleDict;
            }
            else {
                printf("Improper scale for file %s", [imageFilename UTF8String]);
            }

            [jsonOutput setObject:newArray forKey:@"images"];
            
            NSError *copyError;
            [[NSFileManager defaultManager] copyItemAtPath:imagePath toPath:[outputPath stringByAppendingPathComponent:[imagePath lastPathComponent]] error:&copyError]; //Copy icon to directory
            if (copyError != nil) {
                NSLog(@"Error while copying icon %@\n", copyError.localizedDescription);
            }
        }
        else { //Assume 1x
            NSArray *images = (NSArray *)jsonOutput[@"images"];
            NSMutableArray *newArray = [images mutableCopy];
            
            NSMutableDictionary *scaleDict = [newArray[0] mutableCopy];
            [scaleDict setObject:imageFilename forKey:@"filename"];
            newArray[0] = scaleDict;
            
            [jsonOutput setObject:newArray forKey:@"images"];
            
            NSError *copyError;
            [[NSFileManager defaultManager] copyItemAtPath:imagePath toPath:[outputPath stringByAppendingPathComponent:[imagePath lastPathComponent]] error:&copyError]; //Copy icon to directory
            if (copyError != nil) {
                NSLog(@"Error while copying icon %@\n", copyError.localizedDescription);
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
