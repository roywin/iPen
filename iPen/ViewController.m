//
//  ViewController.m
//  iPen
//
//  Created by Roy Winata on 11/20/11.
//  Copyright (c) 2011 PTGDI. All rights reserved.
//

#import "ViewController.h"

#define INPUT_BUFFER_SIZE 6

@implementation ViewController
@synthesize text = _text;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle




- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _pen = [[Pen alloc] init];
    _pen.delegate = self;
    [_pen setLeftHanded:NO];
    if ([_pen connectAccessory]) {
        _text.text = @"Pen connected";
    }
    else {
        _text.text = @"Please connect your pen to this device";
    }
}


- (void)viewDidUnload
{
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.text = nil;
    [_pen release];

    [super viewDidUnload];
}


- (void)penTouchBegan:(CGPoint)point {
    _text.text = [NSString stringWithFormat:@"Touch began\nX: %f\nY: %f", point.x, point.y];    
}


- (void)penTouchMoved:(CGPoint)point prevPoint:(CGPoint)prevPoint {
    _text.text = [NSString stringWithFormat:@"Touch moved\nX: %f\nY: %f", point.x, point.y];        
}


- (void)penTouchEnded:(CGPoint)point prevPoint:(CGPoint)prevPoint {
    _text.text = [NSString stringWithFormat:@"Touch ended\nX: %f\nY: %f", point.x, point.y];        
}


- (void)penHovered:(CGPoint)point {
    _text.text = [NSString stringWithFormat:@"Hovered\nX: %f\nY: %f", point.x, point.y];        
}


- (void)penHidden:(CGPoint)prevPoint {
    _text.text = @"Pen hidden";    
}


- (void)penTouchCancelled:(CGPoint)prevPoint {
    _text.text = @"Touch canceled";
}


- (void)penConnected {
    _text.text = @"Pen connected";
}


- (void)penDisconnected {
    _text.text = @"Pen disconnected";
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [_pen setInterfaceOrientation:toInterfaceOrientation];
}


- (void)dealloc {
    [super dealloc];
}
@end
