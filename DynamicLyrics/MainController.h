//
//  MainController.h
//  DynamicLyrics
//
//  Created by Zheng Zhu on 11-8-5.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MainController : NSObject{
    NSStatusItem *_statusItem;
    NSOperationQueue *_queue;
    NSMutableString *LastSongTitle;
    NSMutableString *LastSongArtist;
    NSMutableArray *lyrics;
    int CurrentLyric;
    NSMutableString *_lastLyrics;
    NSMutableString *_lyricsContent;

    IBOutlet NSMenu *menu;
    IBOutlet NSPanel *searchPanel;
    IBOutlet NSPanel *aboutMePanel;
    IBOutlet NSTextField *searchPanel_Text_Artist;
    IBOutlet NSTextField *searchPanel_Text_Title;
    IBOutlet NSArrayController *array_controller;
    IBOutlet NSComboBox *comboBox_Server;
    IBOutlet NSTableView *tableView;
    
    NSWindow *window;
}
-(void) Anylize:(NSString*)s;
NSInteger qSortCompare(id num1, id num2, void *context);
//@property (nonatomic,retain) IBOutlet NSPanel *searchPanel;
@property (assign) IBOutlet NSWindow *lyricsWindow;

-(IBAction)menuClicked:(id)sender; 
-(IBAction)startSearch:(id)sender;
-(IBAction)onPanelClosed:(id)sender;
-(IBAction)aboutMe:(id)sender;
-(IBAction)haltApp:(id)sender;
-(IBAction)copyCurrentLyrics:(id)sender;
-(IBAction)copyLRC:(id)sender;
-(IBAction)copyAllLyrics:(id)sender;
-(IBAction)donate:(id)sender;
-(IBAction)open4321La:(id)sender;
@end
