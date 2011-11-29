//
//  ViewController.h
//  iPen
//
//  Created by Roy Winata on 11/20/11.
//  Copyright (c) 2011 PTGDI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Pen.h"


@interface ViewController : UIViewController <PenDelegate> {
    UITextView *_text;
    
    Pen *_pen;
}

@property (retain, nonatomic) IBOutlet UITextView *text;


@end
