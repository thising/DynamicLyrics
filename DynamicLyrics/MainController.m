//
//  MainController.m
//  DynamicLyrics
//
//  Created by Zheng Zhu on 11-8-5.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "MainController.h"
#import "iTunes.h"
#import "QianQianLyrics.h"
#import "RegexKitLite.h"
#import "RequestSender.h"
#import "KeyValue_SearchLyrics.h"
@implementation MainController

//@synthesize lyricsWindow;


- (id)init
{
    self = [super init];
    if (self) {
        _queue = [[NSOperationQueue alloc] init]; 
        _lyricsContent = [[NSMutableString alloc]init];
        [_queue setMaxConcurrentOperationCount:1];
        lyrics = [[NSMutableArray alloc]init];
        LastSongTitle = [[NSMutableString alloc] init];
        LastSongArtist = [[NSMutableString alloc] init];
        _lastLyrics = [[NSMutableString alloc]init];
    }
    
    return self;
}

-(void)dealloc
{
    [_queue release];
    [lyrics release];
    [LastSongTitle release];
    [LastSongArtist release];
    [_lastLyrics release];
    [_lyricsContent release];
}

-(void)awakeFromNib
{
    _statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [_statusItem setTitle:@"⋯⋯Loading DynamicLyrics⋯⋯Waiting for iTunes⋯⋯"];
    [_statusItem setHighlightMode:YES];
    
    

    [_statusItem setMenu:menu];

    [NSThread detachNewThreadSelector:@selector(monitoringThread) toTarget:self withObject:nil];
    [NSThread detachNewThreadSelector:@selector(checkUpdate) toTarget:self withObject:nil];
        
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    
    if ([userDefaults integerForKey:@"LyricsServer"] != 0  && [userDefaults integerForKey:@"LyricsServer"] != 1)
        [userDefaults setInteger:0 forKey:@"LyricsServer"];
    [comboBox_Server selectItemAtIndex:[userDefaults integerForKey:@"LyricsServer"]];
    
    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(tableViewDoubleClick:)];
    
#if 0
	[lyricsWindow setHasShadow:NO];
	[lyricsWindow setBackgroundColor:[NSColor colorWithCalibratedWhite:0 alpha:0.3]];
	[lyricsWindow setLevel:NSDockWindowLevel];
	[lyricsWindow setOpaque:NO];
	[lyricsWindow setAcceptsMouseMovedEvents:NO];
	[lyricsWindow center];
	[lyricsWindow orderFront:self];
#endif

}

#pragma Mark -
#pragma Mark InterfaceSupporter
-(IBAction)menuClicked:(id)sender
{
    if(![searchPanel isVisible]) 
    {
        [searchPanel setLevel:NSFloatingWindowLevel];
        [searchPanel makeKeyAndOrderFront:sender]; 
        [searchPanel_Text_Artist setStringValue:LastSongArtist];
        [searchPanel_Text_Title setStringValue:LastSongTitle];
    }
}

-(IBAction)onPanelClosed:(id)sender
{ 
    [searchPanel orderOut:sender]; 
}

-(IBAction)startSearch:(id)sender
{
    [array_controller removeObjects:[array_controller arrangedObjects]];
    if ([[searchPanel_Text_Title stringValue] isEqualToString:@""])
        return;
        
    [QianQianLyrics getLyricsListByTitle:[searchPanel_Text_Title stringValue] getLyricsListByArtist:[searchPanel_Text_Artist stringValue] AddToArrayController:array_controller Server:[comboBox_Server indexOfSelectedItem]];
}
-(IBAction)aboutMe:(id)sender
{
    if(![aboutMePanel isVisible]) 
    {
        [aboutMePanel setLevel:NSFloatingWindowLevel];
        [aboutMePanel makeKeyAndOrderFront:sender]; 
    }
}
-(IBAction)haltApp:(id)sender
{
    exit(0);
}
-(IBAction)copyCurrentLyrics:(id)sender
{
    if (CurrentLyric > [lyrics count] - 1) 
    {
        return;
    }
    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject: NSStringPboardType] owner:nil];
    [[NSPasteboard generalPasteboard] setString: [NSString stringWithString:[[lyrics objectAtIndex:CurrentLyric] objectForKey:@"Content"]] forType: NSStringPboardType];
}
- (void)tableViewDoubleClick:(id)sender
{
    KeyValue_SearchLyrics *key_value = [[array_controller selectedObjects] objectAtIndex:0];
    NSString *lrc = [QianQianLyrics getLyricsByTitle:[key_value LyricsTitle] getLyricsByArtist:[key_value LyricsArtist] getLyricsByID:[key_value ID]];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults]; 
    [userDefaults setValue:[NSString stringWithString:lrc] forKey:[NSString stringWithFormat:@"%@%@",LastSongArtist,LastSongTitle]];
    [self Anylize:lrc];
    [searchPanel orderOut:sender]; 
    
    
}

#pragma Mark -
#pragma Mark BackgroundWorker

-(void)checkUpdate
{
    //http://api.4321.la/analytics-maclyrics.php
    NSString* result = [RequestSender sendRequest:@"http://api.4321.la/analytics-maclyrics.php?ver=20111029"];
    
    if ([result isEqualToString:@"Update"])
    {
        NSRunAlertPanel(@"软件发布新版本", @"软件检测到已经您当前的版本已经过期，新版本已经发布，单击确定进入官方网站下载新版！", @"确定", nil, nil);
        NSURL *url = [NSURL URLWithString:@"http://www.4321.la"];
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}


//监视以及获取iTunes播放信息线程
-(void) monitoringThread
{
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    while (![iTunes isRunning])
    {
        [[iTunes currentTrack] name];
        sleep(1);
    }
    unsigned long currentPlayerPosition = 0;
    unsigned long PlayerPosition = 0;    
    while (true) {

        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; 

        currentPlayerPosition += 100;
        usleep(150000); //1000微秒 = 1毫秒 //精确度10毫秒
        
        PlayerPosition = [iTunes playerPosition];
        if ((currentPlayerPosition / 1000) != PlayerPosition)
            currentPlayerPosition = PlayerPosition * 1000;
        
        NSMutableDictionary *dict;
        dict = [NSMutableDictionary dictionary];
        
        while (![iTunes isRunning] || ![[iTunes currentTrack] name])
        {
            //[_statusItem setTitle:@"  "];
            //exit(0); 
            sleep(1);
            //sleep(1); [pool release]; continue; 
        }

            
        [dict setObject:[[iTunes currentTrack] name] forKey:@"title"];
        [dict setObject:[[iTunes currentTrack] artist] forKey:@"artist"];
        [dict setObject:[NSString stringWithFormat:@"%lu",currentPlayerPosition] forKey:@"currentPlayerPosition"];
        [self performSelectorOnMainThread:@selector(threadCallBack:) withObject:dict waitUntilDone:YES];
        dict = nil;
        
        [pool release];

        

    }

}


-(long) ToTime:(NSString*)s
{
    NSString *RegEx = [NSString stringWithString:@"^(\\d+):(\\d+)(\\.(\\d+))?$"];
    NSArray *matchArray = NULL;
    matchArray = [s arrayOfCaptureComponentsMatchedByRegex:RegEx options:RKLCaseless range:NSMakeRange(0UL, [s length]) error:NULL];
    if (matchArray)
    {
        NSArray *tempArray = [matchArray objectAtIndex:0];
        NSString *ms = [NSString stringWithString:[tempArray objectAtIndex:4]];
        if ([ms length] == 1) [ms stringByAppendingString:@"00"];
        if ([ms length] == 2) [ms stringByAppendingString:@"0"];
        NSString *_tmp1 = [NSString stringWithString:[tempArray objectAtIndex:1]];
        NSString *_tmp2 = [NSString stringWithString:[tempArray objectAtIndex:2]];
        unsigned long ans = ([_tmp1 intValue]) * 60 * 1000 + ([_tmp2 intValue]) * 1000 + [ms intValue];
        return ans;
    }
    else
    {
        return 0;
    }
    
}

-(void) Anylize:(NSString*)s
{
    [_lyricsContent setString:s];
    NSString *RegEx = [NSString stringWithString:@"^((\\[\\d+:\\d+\\.\\d+\\])+)(.*?)$"]; //正则表达式
    [lyrics removeAllObjects];
    
    NSArray *matchArray = NULL;
    matchArray = [s arrayOfCaptureComponentsMatchedByRegex:RegEx options:RKLMultiline | RKLCaseless range:NSMakeRange(0UL, [s length]) error:NULL];
    
    for(int i=0; i<[matchArray count]; i++)
    {
        NSArray *tempArray = [matchArray objectAtIndex:i];
        NSString *a = [NSString stringWithString:[tempArray objectAtIndex:1]];
        NSString *b = [NSString stringWithString:[tempArray objectAtIndex:3]];
        //分割多个时间标签
        NSArray *ACount = [a componentsSeparatedByString:@"]"];
        for (int j=0; j<[ACount count]-1; j++)
        {
            //新建一个字典
            NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
            NSString *Time = [ACount objectAtIndex:j];
            Time = [Time stringByReplacingOccurrencesOfString:@"[" withString:@""];

            [tempDict setObject:[NSNumber numberWithLong:[self ToTime:Time]] forKey:@"Time"];
            [tempDict setObject:b forKey:@"Content"];
            [lyrics addObject:tempDict];
        }
    }
    
    NSSortDescriptor * sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"Time" ascending:YES] autorelease];
    [lyrics sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    //NSLog(@"%@",lyrics);
    
}


-(void) showSmoothTitle:(NSString *)title
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    for (float alpha = 0.3; alpha < 1.01; alpha+=0.02)
    {
        NSAutoreleasePool *Pool = [[NSAutoreleasePool alloc] init];
        NSColor *color = [NSColor colorWithCalibratedWhite:0 alpha:alpha];
        
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        [d setObject:color forKey:NSForegroundColorAttributeName];
        [d setObject:[NSFont fontWithName: @"Helvetica" size: 15] forKey:NSFontAttributeName];
        
        NSAttributedString *shadowTitle = [[NSAttributedString alloc] initWithString:title attributes:d];
        
        [_statusItem setAttributedTitle:shadowTitle];
        
        usleep(5000);
        [shadowTitle release];
        [Pool release];
    }
    [pool release];
}

-(void) hideSmoothTitle:(NSDictionary *)dict
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSNumber *sleepTime = [dict objectForKey:@"Time"];
    long sT = ([sleepTime longValue] - 800)*1000;
    if (sT < 0) return;
    usleep((unsigned int)sT);
    for (float alpha = 0.7; alpha > 0; alpha-=0.02)
    {
        NSAutoreleasePool *Pool = [[NSAutoreleasePool alloc] init];
        NSColor *color = [NSColor colorWithCalibratedWhite:0 alpha:alpha];
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        [d setObject:color forKey:NSForegroundColorAttributeName];
        [d setObject:[NSFont fontWithName: @"Helvetica" size: 15] forKey:NSFontAttributeName];
        
        NSAttributedString *shadowTitle = [[NSAttributedString alloc] initWithString:[dict objectForKey:@"Title"] attributes:d];
        
        [_statusItem setAttributedTitle:shadowTitle];
        usleep(5000);
        [shadowTitle release];
        [Pool release];
    }
    [_statusItem setTitle:@""];
    [pool release];
}

-(void) threadCallBack:(NSMutableDictionary*)tmpArray
{        
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *_title = [tmpArray objectForKey:@"title"];
    NSString *_artist = [tmpArray objectForKey:@"artist"];
    NSString *_currentPlayerPosition = [NSString stringWithString:[tmpArray objectForKey:@"currentPlayerPosition"]];
    
    unsigned long currentPlayerPosition = (long)[_currentPlayerPosition longLongValue];
    
    
    if (![LastSongTitle isEqualToString: _title])
    {
        [ _statusItem setTitle:[NSString stringWithFormat:@"正在播放：%@ - %@  加载歌词中……",_title,_artist]];;
        [LastSongTitle setString: _title];
        [LastSongArtist setString:_artist];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *lrc;
        if ([userDefaults valueForKey:[NSString stringWithFormat:@"%@%@",_artist,_title]])
        {                  
            lrc = [NSString stringWithString:[userDefaults valueForKey:[NSString stringWithFormat:@"%@%@",_artist,_title]]];
            if ([lrc isEqualToString:@"NULL"] || [lrc isEqualToString:@""] || !lrc)
            {
                lrc = [QianQianLyrics getLyricsByTitle:LastSongTitle getLyricsByArtist:_artist];
                [userDefaults setValue:[NSString stringWithString:lrc] forKey:[NSString stringWithFormat:@"%@%@",_artist,_title]];
            }
        }
        else
        {
            //搜索歌词
            lrc = [QianQianLyrics getLyricsByTitle:LastSongTitle getLyricsByArtist:_artist];
            [userDefaults setValue:[NSString stringWithString:lrc] forKey:[NSString stringWithFormat:@"%@%@",_artist,_title]];
        }
        
        [self Anylize:lrc]; //分析歌词
        CurrentLyric = 0;
    }
    long Total = [lyrics count];
    if (Total > 0)
    {
    NSNumber *tempNumber;
    @try {
            
        if (CurrentLyric < Total - 1) //如果已经是最后一句歌词了，不执行向后搜索
        {
            tempNumber = [[lyrics objectAtIndex:CurrentLyric + 1] objectForKey:@"Time"]; 
            //tempNumber 当前歌词的下一句歌词的时间
            while ([tempNumber longValue] < currentPlayerPosition && CurrentLyric < Total - 1) 
            {
                CurrentLyric += 1;
                if (CurrentLyric == Total - 1) break; //如果已经是最后一句歌词 不再比较 退出
                tempNumber = [[lyrics objectAtIndex:CurrentLyric + 1] objectForKey:@"Time"];
            }
        }
            
        tempNumber = [[lyrics objectAtIndex:CurrentLyric] objectForKey:@"Time"];  //当前歌词的时间
        if (CurrentLyric > 0) //如果已经是第一句歌词了，不执行向前搜索
        {
            while ([tempNumber longValue] > currentPlayerPosition && CurrentLyric > 1) 
            {
                CurrentLyric -= 1;
                tempNumber = [[lyrics objectAtIndex:CurrentLyric] objectForKey:@"Time"];
            }
        }
        
        NSString* lyric = [[NSString alloc]initWithFormat:@"%@",[NSString stringWithString:[[lyrics objectAtIndex:CurrentLyric] objectForKey:@"Content"]]];
        if (![_lastLyrics isEqualToString:lyric])
        {
            [_lastLyrics setString:lyric];
            NSInvocationOperation *operation = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(showSmoothTitle:) object:lyric];
             [_queue cancelAllOperations];
             [_queue addOperation:operation];
             [operation release];
            
            if (CurrentLyric < Total - 1)
            {
                //如果不是最后一句歌词，设置渐变隐藏
                NSNumber *sleepTime = [NSNumber numberWithLong:[[[lyrics objectAtIndex:CurrentLyric + 1] objectForKey:@"Time"] longValue] - [[[lyrics objectAtIndex:CurrentLyric] objectForKey:@"Time"] longValue]];
                NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:lyric,@"Title",sleepTime,@"Time", nil];
                operation = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(hideSmoothTitle:) object:dict];
                [_queue addOperation:operation];
                [operation release];
            }
            
        }
        [lyric release];
    }
    @catch (NSException *exception) {
    }
    }
    else
    {
        NSString* title = @"未找到歌词！";
        [_statusItem setTitle:title];

    }
    [pool release];
}

-(IBAction)copyLRC:(id)sender
{        
    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject: NSStringPboardType] owner:nil];
    [[NSPasteboard generalPasteboard] setString: _lyricsContent forType: NSStringPboardType];

}

-(IBAction)copyAllLyrics:(id)sender
{
    NSMutableString *s = [[NSMutableString alloc] init];
    [s setString:@""];
    for (int i = 0; i < [lyrics count]; i++) {
        [s setString:[s stringByAppendingString:[NSString stringWithFormat:@"%@\n",[[lyrics objectAtIndex:i] objectForKey:@"Content"]]]];
        //[s setString:[s stringByAppendingString:]];
    }
    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject: NSStringPboardType] owner:nil];
    [[NSPasteboard generalPasteboard] setString: s forType: NSStringPboardType];
    [s release];
    
}

-(IBAction)donate:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"http://donate.4321.la"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

-(IBAction)open4321La:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"http://www.4321.la"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
