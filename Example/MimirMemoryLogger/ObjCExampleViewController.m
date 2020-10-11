//
//  ObjCExampleViewController.m
//  MimirMemoryLogger_Example
//
//  Created by Amer Eid on 10/12/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

#import "ObjCExampleViewController.h"
#import <MimirMemoryLogger/MimirMemoryLogger-Swift.h>

@interface ObjCExampleViewController ()

@end

@implementation ObjCExampleViewController

- (IBAction)takeMemorySnapshotTapped:(id)sender {
    [MimirMemoryLogger saveCurrentSnapshotToFileWithCompletion:^(NSURL * _Nullable url) {
        if (!url) {
            return;
        }
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Success" message:[NSString stringWithFormat:@"Memory snapshot taken successfully, location: %@\nLook at console for more details", url.absoluteString] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        NSLog(@"Latest memory snapshot location: %@", url.absoluteString);
    }];
}

- (IBAction)getAllMemorySnapshotsTapped:(id)sender {
    NSArray<NSURL*>* urls = [MimirMemoryLogger getSavedSnapshots];
    if (urls && urls.count > 0) {
        NSLog(@"URLS of all saved snapshots: %@", urls);
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Success" message:[NSString stringWithFormat:@"Memory snapshots fetched, locations: %@\nLook at console for more details", urls] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"No saved snapshots found - Press the button above to take a memory snapshot first" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
