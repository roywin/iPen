//
//  Pen.h
//  Pen
//
//  Created by Roy Winata on 11/23/11.
//  Copyright (c) 2011 PTGDI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>

@protocol PenDelegate;

@interface Pen : NSObject <NSStreamDelegate, EAAccessoryDelegate> {
    id<PenDelegate> _delegate;
    EAAccessory *_accessory;
    EASession *_session;
    
    BOOL _isLefHanded;
    BOOL _isPenDown;
    CGPoint _prevPoint;
    
    
    NSString *_platformName;
    UIInterfaceOrientation _interfaceOrientation;
}

@property (nonatomic, assign) id<PenDelegate> delegate;

- (id)init;
- (BOOL)connectAccessory;
- (void)setInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)setLeftHanded:(BOOL)isLeftHanded;

@end

@protocol PenDelegate <NSObject>
-(void)penTouchBegan:(CGPoint)point;
-(void)penTouchMoved:(CGPoint)point prevPoint:(CGPoint)prevPoint;
-(void)penTouchEnded:(CGPoint)point prevPoint:(CGPoint)prevPoint;
-(void)penTouchCancelled:(CGPoint)prevPoint;
-(void)penHovered:(CGPoint)point;
-(void)penHidden:(CGPoint)prevPoint;
-(void)penConnected;
-(void)penDisconnected;

@end

