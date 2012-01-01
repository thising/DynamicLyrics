//
//  KeyValue_SearchLyrics.m
//  DynamicLyrics
//
//  Created by Zheng Zhu on 11-8-12.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "KeyValue_SearchLyrics.h"

@implementation KeyValue_SearchLyrics


@synthesize ID;
@synthesize LyricsTitle;
@synthesize LyricsArtist;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(id)initWithID:(NSString *)nID initWithTitle:(NSString *)nLyricsTitle initWithArtist:(NSString *)nLyricsArtist
{
    self.ID = nID;
    self.LyricsArtist = nLyricsArtist;
    self.LyricsTitle = nLyricsTitle;
    return self;
}

@end
