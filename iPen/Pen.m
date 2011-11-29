//
//  Pen.m
//  Pen
//
//  Created by Roy Winata on 11/23/11.
//  Copyright (c) 2011 PTGDI. All rights reserved.
//

#import "Pen.h"
#include <sys/types.h>  
#include <sys/sysctl.h> 

#define PROTOCOL_STRING @"com.yifangdigital.myprotocol"

@implementation Pen

@synthesize delegate = _delegate;

- (EAAccessory *)getAccessoryForProtocol:(NSString *)protocol {
    EAAccessory *accessory = nil;
    
    NSArray *accessories = [[EAAccessoryManager sharedAccessoryManager] connectedAccessories];
    
    for (EAAccessory *accessoryCandidate in accessories) {
        if ([accessoryCandidate.protocolStrings containsObject:protocol]) {
            accessory = accessoryCandidate;
            break;
        }
    }
    
    return accessory;
}


- (void)openInputStream:(EASession *)session {
    NSInputStream *inputStream = [session inputStream];
    
    [inputStream setDelegate:self];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];
}


- (void)closeInputStream:(EASession *)session
{
    NSInputStream *inputStream = [session inputStream];
    
    [inputStream close];
    [inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream setDelegate:nil];
}


- (void)registerForNotifications {
    EAAccessoryManager *accessoryManager = [EAAccessoryManager sharedAccessoryManager];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessoryDidConnect:) name:EAAccessoryDidConnectNotification object:accessoryManager];
    
    [accessoryManager registerForLocalNotifications];
}


- (void)unregisterForNotification {
    [[EAAccessoryManager sharedAccessoryManager] unregisterForLocalNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (NSString *)getPlatformName {
	size_t size;  
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);  
	char *machine = malloc(size);  
    
	sysctlbyname("hw.machine", machine, &size, NULL, 0);  
	NSString *platformName = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];  
	free(machine);
    
	return platformName;
}


- (BOOL)isPlatform:(NSString *)platformName {
    NSRange range = [_platformName rangeOfString:platformName];
    return (range.location != NSNotFound);
}


- (void)setAutoLock:(BOOL)isAutoLock {
    UIApplication *thisApp = [UIApplication sharedApplication];
    thisApp.idleTimerDisabled = !isAutoLock;	
}


- (BOOL)connectAccessory:(EAAccessory *)accessory {
    BOOL isSuccessful = NO;
    
    _isPenDown = NO;
    _accessory = accessory;
    _accessory.delegate = self;
    _session = [[EASession alloc] initWithAccessory:_accessory forProtocol:PROTOCOL_STRING];
    
    if (_session) {
        [self openInputStream:_session];
        [self setAutoLock:NO];
        isSuccessful = YES;
    }
    
    return isSuccessful;
}


- (BOOL)connectAccessory {
    BOOL isSuccessful = NO;

    _accessory = [self getAccessoryForProtocol:PROTOCOL_STRING];
    if (_accessory) {
        isSuccessful = [self connectAccessory:_accessory];
    }
    
    return isSuccessful;
}


- (id)init {
    if ((self = [super init])) {
        [self registerForNotifications];

        _isPenDown = NO;
        _isLefHanded = NO;
        _platformName = [self getPlatformName];
        [_platformName retain];
        _interfaceOrientation = UIInterfaceOrientationPortrait;
    }
    
    return self;
}


- (void)setLeftHanded:(BOOL)isLeftHanded {
    _isLefHanded = isLeftHanded;
}


- (void)setInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    _interfaceOrientation = interfaceOrientation;
}


- (CGPoint)iPenToUIConvertX:(int16_t)x y:(int16_t)y {
    CGFloat lengthFactor = 0;
    NSInteger offsetX = 0;
    NSInteger offsetY = 0;
    NSInteger deviceWidth = 0;
    NSInteger deviceHeight = 0;
    CGFloat resultX, tempResultX;
    CGFloat resultY, tempResultY;
    
    if ([self isPlatform:@"iPad"]) {
        lengthFactor = 9.31543f;
        offsetX = 3577;
        offsetY = -1161;
        deviceWidth = 768;
        deviceHeight = 1024;
    }
    else if ([self isPlatform:@"iPhone"]) {
        lengthFactor = 7.525f;
        offsetX = 1206;
        offsetY = -1013;
        deviceWidth = 320;
        deviceHeight = 480;
    }
    else if ([self isPlatform:@"iPod"]) {
        lengthFactor = 7.525f;
        offsetX = 1206;
        offsetY = -938;
        deviceWidth = 320;
        deviceHeight = 480;
    }
    
    tempResultX = (x + offsetX)/lengthFactor;
    tempResultY = (y + offsetY)/lengthFactor;
    
    switch (_interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            resultX = deviceWidth - tempResultX;
            resultY = deviceHeight - tempResultY;
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            resultX = deviceHeight - tempResultY;
            resultY = tempResultX;
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            resultX = tempResultY;
            resultY = deviceWidth - tempResultX;
            break;
            
        default:
            resultX = tempResultX;
            resultY = tempResultY;
            break;
    }
    
    if (_isLefHanded) {
        resultX += 20.0f;
        resultY -= 10.0f;
    }
    else {
        resultX -= 20.0f;
        resultY -= 10.0f;
    }
    
    return CGPointMake(resultX, resultY);
}


- (CGFloat)distanceBetweenPoint:(CGPoint)first andPoint:(CGPoint)second {
    CGFloat deltaX = second.x - first.x;
    CGFloat deltaY = second.y - first.y;
    
    return sqrt(deltaX*deltaX + deltaY*deltaY);
}


- (void)readData {
    const CGFloat kMinDistance = 2.0f;
    const uint8_t kPenDown = 0x81;
    const uint8_t kPenUp = 0x88;
    
    NSUInteger kBufferSize = 6;
    uint8_t buffer[kBufferSize];
    int16_t x, y;
    CGPoint point;
    
    while ([[_session inputStream] hasBytesAvailable])
    {
        NSInteger bytesRead = [[_session inputStream] read:buffer maxLength:kBufferSize];
        
        if (bytesRead == kBufferSize) {
            
            x = (int16_t)buffer[2] | ((int16_t)buffer[3]<<8);
            y = (int16_t)buffer[4] | ((int16_t)buffer[5]<<8);
            point = [self iPenToUIConvertX:x y:y];
            
            if (buffer[1] == kPenDown) {
                if (_isPenDown) { // touch moved
                    CGPoint prevPoint = _prevPoint; 
                    
                    CGFloat distance = [self distanceBetweenPoint:prevPoint andPoint:point];
                    
                    if (distance >= kMinDistance) {
                        _prevPoint = point;
                        [_delegate penTouchMoved:point prevPoint:prevPoint];
                    }
                }
                else { // touch began
                    _isPenDown = YES;
                    _prevPoint = point;
                    [_delegate penTouchBegan:point];
                }
            }
            else if (buffer[1] == kPenUp) {
                if (_isPenDown) { // touch ended
                    _isPenDown = NO;
                    CGPoint prevPoint = _prevPoint; 
                    _prevPoint = point;
                    [_delegate penTouchEnded:point prevPoint:prevPoint];
                }
                else { // hover
                    CGPoint prevPoint = _prevPoint; 
                    
                    CGFloat distance = [self distanceBetweenPoint:prevPoint andPoint:point];
                    
                    if (distance >= kMinDistance) {
                        _prevPoint = point;
                        [_delegate penHovered:point];
                    }
                }
            }
            else {
                if (_isPenDown) { // touch canceled
                    _isPenDown = NO;
                    [_delegate penTouchCancelled:_prevPoint];
                }
                else {
                    [_delegate penHidden:_prevPoint];
                }
            }
        }
    }
}


- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable:
            [self readData];
            break;
            
        default:
            break;
    }
}


- (void)accessoryDidConnect:(NSNotification *)notification {
    if (_accessory)
        return;
    
    EAAccessory *accessory = [[notification userInfo] objectForKey:EAAccessoryKey];
    
    if ([accessory.protocolStrings containsObject:PROTOCOL_STRING]) {
        if ([self connectAccessory:accessory]) {
            [_delegate penConnected];
        }
    }
}


- (void)accessoryDidDisconnect:(NSNotification *)notification {
    _accessory = nil;
    
    if (_session) {
        [self closeInputStream:_session];
        [_session release];
        _session = nil;
    }
    
    [self setAutoLock:YES];
    [_delegate penDisconnected];
}


- (void)dealloc {
    [self unregisterForNotification];
    [_platformName release];
    
    if (_session) {
        [self closeInputStream:_session];
        [_session release];
    }
    
    [super dealloc];
}



@end
