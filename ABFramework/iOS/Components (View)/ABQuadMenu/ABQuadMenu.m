//
//  ABQuadMenu.m
//  ABFramework
//
//  Created by Alexander Blunck on 5/14/13.
//  Copyright (c) 2013 Ablfx. All rights reserved.
//

#import "ABQuadMenu.h"

#define ABQUADMENU_ANIMATION_DURATION 0.4f

#pragma mark - ABQuadMenuItem
@interface ABQuadMenuItem ()
@property (nonatomic, copy) NSString *iconName;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) ABBlockVoid actionBlock;
@end

@implementation ABQuadMenuItem

+(id) itemWithIconName:(NSString*)iconName title:(NSString*)title action:(ABBlockVoid)actionBlock
{
    return [[self alloc] initWithIconName:iconName title:title action:actionBlock];
}

-(id) initWithIconName:(NSString*)iconName title:(NSString*)title action:(ABBlockVoid)actionBlock
{
    self = [super init];
    if (self)
    {
        self.iconName = iconName;
        self.title = title;
        self.actionBlock = [actionBlock copy];
    }
    return self;
}

@end



#pragma mark - ABQuadMenu
@interface ABQuadMenu ()
{
    NSArray *_items;
    NSMutableArray *_viewArray;
    UIView *_backgroundView;
    ABPrimitiveArray *_intialRegions;
    ABPrimitiveArray *_finalRegions;
}
@end

@implementation ABQuadMenu

#pragma mark - Utility
+(id) showMenuWithItems:(NSArray*)items
{
    return [[self alloc] initWithItems:items andShow:YES];
}



#pragma mark - Initializer
-(id) initWithItems:(NSArray*)items
{
    return [self initWithItems:items andShow:NO];
}

-(id) initWithItems:(NSArray*)items andShow:(BOOL)show
{
    self = [super init];
    if (self)
    {
        if (items.count != 3)
        {
            NSLog(@"ABQuadMenu: ERROR -> You need to supply exactly 3 ABQuadMenuItem 's.");
            return nil;
        }
        
        //Add "close" item
        ABQuadMenuItem *closeItem = [ABQuadMenuItem itemWithIconName:@"circled-cross" title:@"Close" action:nil];
        
        _items = [items arrayByAddingObject:closeItem];
        
        //Allocation
        _viewArray = [NSMutableArray new];
        
        //Config
        self.theme = ABQuadMenuThemeLight;
        
        if (show)
        {
            [self show];
        }
    }
    return self;
}



#pragma mark - LifeCycle
-(void) willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview == (id)[NSNull null] || newSuperview == nil)
    {
        return;
    }
    
    //Frame (full screen)
    self.frame = [[UIScreen mainScreen] bounds];
    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    self.frame = CGRectOffsetSizeHeight(self.frame, -statusBarSize.height);
    self.frame = CGRectChangingOriginY(self.frame, statusBarSize.height);
    
    //Compute screen regions for placing elements later
    CGSize quarterScreenSize = CGSizeMake(self.width/2, self.height/2);
    CGRect topLeft = cgr(0, 0, quarterScreenSize.width, quarterScreenSize.height);
    CGRect topRight = cgr(quarterScreenSize.width, 0, quarterScreenSize.width, quarterScreenSize.height);
    CGRect bottomLeft = cgr(0, quarterScreenSize.height, quarterScreenSize.width, quarterScreenSize.height);
    CGRect bottomRight = cgr(quarterScreenSize.width, quarterScreenSize.height, quarterScreenSize.width, quarterScreenSize.height);
    CGRect topLeftI = CGRectOffsetOrigin(topLeft, -topLeft.size.width, -topLeft.size.height);
    CGRect topRightI = CGRectOffsetOrigin(topRight, topRight.size.width, -topRight.size.height);
    CGRect bottomLeftI = CGRectOffsetOrigin(bottomLeft, -bottomLeft.size.width, bottomLeft.size.height);
    CGRect bottomRightI = CGRectOffsetOrigin(bottomRight, bottomRight.size.width, bottomRight.size.height);
    _intialRegions = [ABPrimitiveArray arrayWithRects:topLeftI, topRightI, bottomLeftI, bottomRightI, CGRectNull];
    _finalRegions = [ABPrimitiveArray arrayWithRects:topLeft, topRight, bottomLeft, bottomRight, CGRectNull];
    
    //Background
    _backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    _backgroundView.backgroundColor = [self themeBackgroundColor];
    _backgroundView.alpha = 0.0f;
    [self addSubview:_backgroundView];
    
    //Seperators
    ABSeperator *verticalSep = [ABSeperator seperatorWithType:ABSeperatorTypeEtchedVertical
                                                       length:self.bounds.size.height
                                                          top:[self themeTopSeperaterColor]
                                                       bottom:[self themeBottomSeperaterColor]];
    verticalSep.frame = CGRectCenteredWithCGRect(verticalSep.frame, self.bounds);
    [_backgroundView addSubview:verticalSep];
    
    ABSeperator *horizontalSep = [ABSeperator seperatorWithType:ABSeperatorTypeEtchedHorizontal
                                                         length:self.bounds.size.width
                                                            top:[self themeTopSeperaterColor]
                                                         bottom:[self themeBottomSeperaterColor]];
    horizontalSep.frame = CGRectCenteredWithCGRect(horizontalSep.frame, self.bounds);
    [_backgroundView addSubview:horizontalSep];
    
    //layout items
    [self layoutItems];
    
    //Animate in
    [self animateIn:YES completion:nil];
}



#pragma mark - Layout
-(void) layoutItems
{
    [_intialRegions enumerateRectsUsingBlock:^(CGRect rect, NSUInteger idx) {
        
        ABQuadMenuItem *item = [_items safeObjectAtIndex:idx];
        
        //Containment view
        ABView *view = [[ABView alloc] initWithFrame:rect];
        view.userData = @{@"item": item};
        view.selectRecursively = YES;
        [view setTarget:self selector:@selector(itemSelected:)];
        [_viewArray addObject:view];
        
        UIColor *color = [self themeIconColor];
        UIColor *selectedColor = [self themeSelectedIconColor];
        
        //Close item
        if (idx == 3)
        {
            color = [self themeCloseIconColor];
            selectedColor = [self themeSelectedCloseIconColor];
        }
        
        //Icon
        ABEntypoView *icon = [ABEntypoView viewWithIconName:item.iconName size:64.0f];
        icon.frame = CGRectCenteredWithCGRect(icon.frame, view.bounds);
        icon.frame = CGRectOffsetOriginY(icon.frame, -25);
        icon.color = color;
        icon.selectedColor = selectedColor;
        icon.shadow = ABShadowTypeLetterpress;
        icon.shadowColor = [UIColor whiteColor];
        [view addSubview:icon];
        
        //Label
        ABLabel *label = [ABLabel new];
        label.trimAutomatically = YES;
        label.centeredHorizontally = YES;
        label.fontName = ABFRAMEWORK_FONT_DEFAULT_REGULAR;
        label.textSize = 20.0f;
        label.textColor = [self themeTitleColor];
        label.text = item.title;
        label.frame = CGRectCenteredWithCGRect(label.frame, view.bounds);
        label.frame = CGRectOffsetOriginY(label.frame, 25);
        [view addSubview:label];
        
        [self addSubview:[_viewArray lastObject]];
    }];

}



#pragma mark - Show / Hide
-(void) show
{
    [[UIView topView] addSubview:self];
}

-(void) hide
{
    [self animateIn:NO completion:^{
        [self removeFromSuperview];
    }];
}



#pragma mark - Animation
-(void) animateIn:(BOOL)animateIn completion:(ABBlockVoid)block
{
    ABPrimitiveArray *toRegions = (animateIn) ? _finalRegions : _intialRegions;
    
    [UIView animateWithDuration:ABQUADMENU_ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        //
        _backgroundView.alpha = (animateIn) ? 1.0f : 0.0f;
        
        for (UIView *view in _viewArray)
        {
            view.frame = [toRegions rectAtIndex:[_viewArray indexOfObject:view]];
        }
    } completion:^(BOOL finished) {
        //
        if (block) {
            block();
        }
    }];
}



#pragma mark - Selection
-(void) itemSelected:(ABView*)view
{
    ABQuadMenuItem *item = [view.userData safeObjectForKey:@"item"];
    
    //Execute action block
    if (item && item.actionBlock)
    {
        item.actionBlock();
    }
    
    //Hide
    [self hide];
}



#pragma mark - Theme
-(UIColor*) themeBackgroundColor
{
    //ABQuadMenuThemeLight
    if (self.theme == ABQuadMenuThemeLight)
    {
        return [UIColor colorWithHexString:@"#eeeeee"];
    }
    
    return nil;
}

-(UIColor*) themeTitleColor
{
    //ABQuadMenuThemeLight
    if (self.theme == ABQuadMenuThemeLight)
    {
        return [UIColor colorWithHexString:@"#82807a"];
    }
    
    return nil;
}

-(UIColor*) themeIconColor
{
    //ABQuadMenuThemeLight
    if (self.theme == ABQuadMenuThemeLight)
    {
        return [UIColor colorWithHexString:@"#dedcd6"];
    }
    
    return nil;
}

-(UIColor*) themeSelectedIconColor
{
    //ABQuadMenuThemeLight
    if (self.theme == ABQuadMenuThemeLight)
    {
        return [UIColor colorWithWhite:0.722 alpha:1.000];
    }
    
    return nil;
}

-(UIColor*) themeCloseIconColor
{
    //ABQuadMenuThemeLight
    if (self.theme == ABQuadMenuThemeLight)
    {
        return [UIColor colorWithHexString:@"#f64d4d"];
    }
    
    return nil;
}

-(UIColor*) themeSelectedCloseIconColor
{
    //ABQuadMenuThemeLight
    if (self.theme == ABQuadMenuThemeLight)
    {
        return [UIColor colorWithHexString:@"#c23d3d"];
    }
    
    return nil;
}

-(UIColor*) themeTopSeperaterColor
{
    //ABQuadMenuThemeLight
    if (self.theme == ABQuadMenuThemeLight)
    {
        return [UIColor colorWithHexString:@"#d6d5d1"];
    }
    
    return nil;
}

-(UIColor*) themeBottomSeperaterColor
{
    //ABQuadMenuThemeLight
    if (self.theme == ABQuadMenuThemeLight)
    {
        return [UIColor colorWithHexString:@"#ffffff"];
    }
    
    return nil;
}

@end