/*
 ShiftIt: Resize windows with Hotkeys
 Copyright (C) 2010  Aravind
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 */

#import "SimpleWindowResizerAppDelegate.h"

@implementation SimpleWindowResizerAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    if (!AXAPIEnabled()){
        if ([self isOsxVersion10_9Plus]) {
            // In OSX 10.9+, the setting is in: System Preferences -> Security & Privacy -> Privacy -> Accessibility
            [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Security.prefPane"];
        } else {
            // In earlier versions of OSX, it is in: System Preferences -> Accessibility -> "Enable access for assistive devices"
            [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/UniversalAccessPref.prefPane"];
        }
    }
}

- (BOOL)isOsxVersion10_9Plus {
    return (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_9);
}

-(id)init{
	if(self == [super init]){
		_pref = [[Preferences alloc] init];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.shiftItshowMenu" options:0 context:self];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.shiftItstartLogin" options:0 context:self];
	}
	return self;
}
- (void) awakeFromNib{
	[self updateMenuBarIcon];
	[self registerForLogin];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if([keyPath compare:@"values.shiftItshowMenu"] == NSOrderedSame){
		[self updateMenuBarIcon];
	}else if ([keyPath compare:@"values.shiftItstartLogin"]== NSOrderedSame) {
		[self registerForLogin];
	} 

}

-(void)updateMenuBarIcon{
	BOOL showIconInMenuBar = [[NSUserDefaults standardUserDefaults] boolForKey:@"shiftItshowMenu"];
	NSStatusBar * temp = [NSStatusBar systemStatusBar];
	if(showIconInMenuBar){
		if(!statusItem){
			statusItem = [[temp statusItemWithLength:NSSquareStatusItemLength] retain];

			NSImage *image = [NSImage imageNamed:@"icon.png"];
			[statusItem setImage:image];
			[statusItem setHighlightMode:YES];
			[statusItem setMenu:statusMenu];
		}
	}else {
/*		[temp removeStatusItem:statusItem];
		[statusItem autorelease];
		statusItem = nil;
*/	}
}

-(void)registerForLogin{
	BOOL login = [[NSUserDefaults standardUserDefaults] boolForKey:@"shiftItstartLogin"];
    if(login){
        NSString * appPath = [[NSBundle mainBundle] bundlePath];
        
        // This will retrieve the path for the application
        // For example, /Applications/test.app
        CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:appPath]; 
        
        // Create a reference to the shared file list.
        // We are adding it to the current user only.
        // If we want to add it all users, use
        // kLSSharedFileListGlobalLoginItems instead of
        //kLSSharedFileListSessionLoginItems
        LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,kLSSharedFileListSessionLoginItems, NULL);
        if (loginItems) {
            //Insert an item to the list.
            LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,kLSSharedFileListItemLast, NULL, NULL,url, NULL, NULL);
            if (item){
                CFRelease(item);
            }
        }	
        CFRelease(loginItems);
    }else {
        NSString * appPath = [[NSBundle mainBundle] bundlePath];
        
        // This will retrieve the path for the application
        // For example, /Applications/test.app
        CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:appPath]; 
        
        // Create a reference to the shared file list.
        LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                                kLSSharedFileListSessionLoginItems, NULL);
        
        if (loginItems) {
            UInt32 seedValue;
            //Retrieve the list of Login Items and cast them to
            // a NSArray so that it will be easier to iterate.
            NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
            int i = 0;
            for(i ; i< [loginItemsArray count]; i++){
                LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)[loginItemsArray
                                                                            objectAtIndex:i];
                //Resolve the item with URL
                if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr) {
                    NSString * urlPath = [(NSURL*)url path];
                    if ([urlPath compare:appPath] == NSOrderedSame){
                        LSSharedFileListItemRemove(loginItems,itemRef);
                    }
                }
            }
            [loginItemsArray release];
        }
    }
    
    
}

-(IBAction)showPreferences:(id)sender{
    if (!prefController) {
        prefController = [[PrefWindowController alloc]init];
    }
    [prefController showPreferences:sender];
    [NSApp activateIgnoringOtherApps:YES];
}

@end
