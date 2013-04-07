//
//  MBStatusPanel.m
//  IceCube
//
//  Created by Marian Bouček on 04.03.13.
//  Copyright (c) 2013 Marian Bouček. All rights reserved.
//

#import "MBStatusPanel.h"

@interface MBStatusPanel ()

@property NSGradient *gradient;

@end

@implementation MBStatusPanel

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		self.gradient = [[NSGradient alloc] initWithColorsAndLocations:
								[NSColor colorWithCalibratedRed:0.96f green:0.96f blue:0.96f alpha:1.00f], 0.0f,
								[NSColor colorWithCalibratedRed:0.84f green:0.84f blue:0.84f alpha:1.00f], 1.0f,
								nil];
    }
    
    return self;
}

// Zdroj: http://stackoverflow.com/questions/11971866/rounded-corner-gradient-background-of-window-in-cocoa
- (void)drawRect:(NSRect)dirtyRect
{
	[NSGraphicsContext saveGraphicsState];
	
    float cornerRadius = 10;
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:cornerRadius yRadius:cornerRadius];
	
    [path setClip];
	
    // [gradient drawInRect:self.bounds angle:270];
	[self.gradient drawInBezierPath:path angle:270];
	
    [NSGraphicsContext restoreGraphicsState];
}

@end
