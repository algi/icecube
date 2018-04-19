//
//  MBMavenService.m
//  IceCube
//
//  Created by Marian Bouček on 17.04.18.
//  Copyright © 2018 Marian Bouček. All rights reserved.
//

#import "MBServiceProvider.h"

#import "MBTaskRunnerDocument.h"

#import <os/log.h>

@implementation MBServiceProvider

- (void) runMavenWithFile:(NSPasteboard *)pasteboard
                 userData:(NSString *)userData
                    error:(NSString * __autoreleasing *)error
{
    NSDocumentController *documentController = [NSDocumentController sharedDocumentController];

    NSError *documentError;
    MBTaskRunnerDocument *document = [documentController openUntitledDocumentAndDisplay:YES error:&documentError];
    if (!document) {
        os_log_error(OS_LOG_DEFAULT, "Unable to create new document from path. Reason: %@", documentError);
        *error = [documentError localizedDescription];
        return;
    }

    NSString *selectedFileName = [[pasteboard propertyListForType:NSFilenamesPboardType] firstObject];
    NSString *directoryPath = [selectedFileName stringByDeletingLastPathComponent];

    document.workingDirectory = [NSURL fileURLWithPath:directoryPath isDirectory:YES];
}

@end
