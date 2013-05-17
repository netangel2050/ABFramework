//
//  ABSelectViewTheme.m
//  ABFramework
//
//  Created by Alexander Blunck on 10/17/12.
//  Copyright (c) 2012 Ablfx. All rights reserved.
//

#import "ABSelectViewTheme.h"

@implementation ABSelectViewTheme

#pragma mark - Utility
+(id) themeWithTop:(NSString*)top middle:(NSString*)middle bottom:(NSString*)bottom
{
    return [[self alloc] initThemeTop:top middle:middle bottom:bottom];
}

+(id) themeWithTag:(ABSelectViewThemeTag)theme
{
    return [[self alloc] initWithTag:theme];
}



#pragma mark - Initializer
-(id) initThemeTop:(NSString*)top middle:(NSString*)middle bottom:(NSString*)bottom
{
    if (self = [super init]) {
        self.topRowImageName = top;
        self.middleRowImageName = middle;
        self.bottomRowImageName = bottom;
    }
    return self;
}

-(id) initWithTag:(ABSelectViewThemeTag)theme
{
    if (self = [super init])
    {
        
        NSString *baseName = nil;
        
        if (theme == ABSelectViewThemeTagDark)
        {
            baseName = @"ABSelectViewThemeDark";
        }
        else
        {
            NSLog(@"ABSelectViewTheme: ERROR -> INVALID THEME");
            return nil;
        }
        
        self.topRowImageName = [NSString stringWithFormat:@"ABFramework.bundle/ABSelectView/%@-top-cell", baseName];
        self.middleRowImageName = [NSString stringWithFormat:@"ABFramework.bundle/ABSelectView/%@-middle-cell", baseName];
        self.bottomRowImageName = [NSString stringWithFormat:@"ABFramework.bundle/ABSelectView/%@-bottom-cell", baseName];
    }
    return self;
}

@end