//
//  MyClass.m
//  DynamicLyrics
//
//  Created by Martian on 11-11-2.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "MyClass.h"

@implementation MyClass

- (void)sendEvent:(NSEvent *)theEvent
{
	CGPoint mouseLoc=NSPointToCGPoint([theEvent locationInWindow]);
	switch ([theEvent type]) {
		case NSLeftMouseDown: {
			[self setIgnoresMouseEvents:TRUE];
			CGEnableEventStateCombining(TRUE);
			CGSetLocalEventsFilterDuringSupressionState(kCGEventFilterMaskPermitAllEvents,kCGEventSupressionStateSupressionInterval);
			CGSetLocalEventsFilterDuringSupressionState(kCGEventFilterMaskPermitAllEvents,kCGEventSupressionStateRemoteMouseDrag);	
			CGPostMouseEvent(mouseLoc, FALSE, 1,TRUE);
			break;
		}
		default:
			[super sendEvent:theEvent];
	}
}


@end
