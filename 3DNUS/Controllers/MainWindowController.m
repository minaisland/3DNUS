//
//  MainWindowController.m
//  3DNUS
//
//  Created by 郑先生 on 15/12/13.
//  Copyright © 2015年 郑先生. All rights reserved.
//

#import "MainWindowController.h"

@interface MainWindowController () <NSWindowDelegate>

@end

@implementation MainWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.window.title = @"3DNUS";
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (BOOL)windowShouldClose:(id)sender
{
    exit(0);
    return YES;
}

@end
