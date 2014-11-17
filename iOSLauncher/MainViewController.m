//
//  MainViewController.m
//  iOSLauncher
//
//  Created by Sergio Lopez on 11/7/14.
//  Copyright (c) 2014 Flexible Software Solutions S.L. All rights reserved.
//

#import "MainViewController.h"
#import "DesktopTableViewCell.h"
#import "Toast+UIView.h"
#import "Reachability.h"
#import "flexConstants.h"
#import "io_interface.h"
#import "spice.h"
#import "draw.h"
#import "globals.h"

MainViewController *mainViewController;

@interface MainViewController ()

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        mainViewController = self;
    }
    return self;
}

//The EAGL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder
{
    if ((self = [super initWithCoder:coder]))
    {
        mainViewController = self;
        return self;
    }
    
    return nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _tblMenu.dataSource = self;
    _tblMenu.delegate = self;
    _tblMenu.hidden = true;
    
    longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.view addGestureRecognizer:longPressRecognizer];
    
    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapRecognizer];
    
    doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapRecognizer.numberOfTapsRequired = 1;
    doubleTapRecognizer.numberOfTouchesRequired = 2;
    [self.view addGestureRecognizer:doubleTapRecognizer];
    
    pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [self.view addGestureRecognizer:pinchRecognizer];
    
    panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.view addGestureRecognizer:panRecognizer];
    
    doublePanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoublePan:)];
    doublePanRecognizer.minimumNumberOfTouches = 2;
    doublePanRecognizer.maximumNumberOfTouches = 2;
    [self.view addGestureRecognizer:doublePanRecognizer];
    
    keybView = [[KeyboardView alloc] init];
    [self.view addSubview:keybView];
    
    _lblMessage.layer.cornerRadius = 8;
    
    connDesiredState = CONNECTED;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)closeConnection
{
    NSLog(@"closeConnection\n");
    [self clearCredentials];
    connDesiredState = DISCONNECTED;
    engine_spice_disconnect();
}

- (void)changeResolution
{
    NSLog(@"changeResolution\n");
}

- (void)sendKeyCombination:(int) keyCombo
{
    NSLog(@"sendKeyCombination: %d\n", keyCombo);
    Boolean ctrl = false;
    Boolean alt = false;
    Boolean shift = false;
    int keycode = 0;
    
    switch (keyCombo) {
        case 0:
            //name = @"ctrl+c";
            ctrl = true;
            keycode = 0x2e;
            break;
        case 1:
            //name = @"ctrl+x";
            ctrl = true;
            keycode = 0x2d;
            break;
        case 2:
            //name = @"ctrl+v";
            ctrl = true;
            keycode = 0x2f;
            break;
        case 3:
            //name = @"ctrl+z";
            ctrl = true;
            keycode = 0x2c;
            break;
        case 4:
            //name = @"alt+f4";
            alt = true;
            keycode = 0x3e;
            break;
        case 5:
            //name = @"ctrl+alt+del";
            ctrl = true;
            alt = true;
            keycode = 0x53;
            break;
        case 6:
            //name = @"ctrl+shift+esc";
            ctrl = true;
            shift = true;
            keycode = 0x01;
            break;
        case 7:
            //name = @"ctrl+alt+f1";
            ctrl = true;
            alt = true;
            keycode = 0x5b;
            break;
        case 8:
            //name = @"ctrl+alt+f2";
            ctrl = true;
            alt = true;
            keycode = 0x5c;
            break;
        case 9:
            //name = @"ctrl+alt+f6";
            ctrl = true;
            alt = true;
            keycode = 0x60;
            break;
        case 10:
            //name = @"ctrl+alt+f7";
            ctrl = true;
            alt = true;
            keycode = 0x61;
            break;
    }
    
    if (keycode) {
        if (ctrl) {
            engine_spice_keyboard_event(0x1d, 1);
        }
        
        if (alt) {
            engine_spice_keyboard_event(0x38, 1);
        }
        
        if (shift) {
            engine_spice_keyboard_event(0x2a, 1);
        }
        
        engine_spice_keyboard_event(keycode, 1);
        engine_spice_keyboard_event(keycode, 0);
        
        if (shift) {
            engine_spice_keyboard_event(0x2a, 0);
        }

        if (alt) {
            engine_spice_keyboard_event(0x38, 0);
        }
        
        if (ctrl) {
            engine_spice_keyboard_event(0x1d, 0);
        }
    }
}

#pragma mark UITableView methods delegate and source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    } else {
        return 11;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *simpleTableIdentifier = @"CellDesktop";
    
    DesktopTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    NSString *key;
    NSString *name;
    
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                key = @"close";
                name = @"Cerrar sesión";
                break;
        }
    } else {
        key = @"keyCombo";
        switch (indexPath.row) {
            case 0:
                name = @"CTRL+C";
                break;
            case 1:
                name = @"CTRL+X";
                break;
            case 2:
                name = @"CTRL+V";
                break;
            case 3:
                name = @"CTRL+Z";
                break;
            case 4:
                name = @"ALT+F4";
                break;
            case 5:
                name = @"CTRL+ALT+DEL";
                break;
            case 6:
                name = @"CTRL+ALT+ESC";
                break;
            case 7:
                name = @"CTRL+ALT+F1";
                break;
            case 8:
                name = @"CTRL+ALT+F2";
                break;
            case 9:
                name = @"CTRL+ALT+F6";
                break;
            case 10:
                name = @"CTRL+ALT+F7";
                break;
        }
    }
    
    cell.lblKey.text=key;
    cell.lblName.text=name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"didSelectRowAtIndexPath %d",indexPath.row);
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                [self closeConnection];
                break;
            case 1:
                [self changeResolution];
                break;
        }
    } else {
        [self sendKeyCombination:indexPath.row];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self hideMenu];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"General";
    } else {
        return @"Enviar combinación de teclas";
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 40;
}

//-(void) adjustHeightWithNumberRows:(int)numberOfRows{
//    if(numberOfRows>=9){
//        NSLog(@"reloadDataForTable muchas filas %d",numberOfRows);
//        numberOfRows=8;
//        
//    }
//    CGRect tblResultFrame = _tblMenu.frame;
//    tblResultFrame.size.height = 44+(numberOfRows)*44;
//    
//    _tblMenu.frame = tblResultFrame;
//    [_tblMenu reloadData];
//}

#pragma mark -
#pragma mark Touch-handling methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchedBegan\n");
    [self hideMenu];
    //[mainView hideKeyboard];
    //NSMutableSet *currentTouches = [[event touchesForView:self] mutableCopy];
    //[currentTouches minusSet:touches];
    
    if (dragging) {
        NSLog(@"touchedBegan dragging\n");
        
        io_event_t io_event;
        
        io_event.type = IO_EVENT_ENDED;
        io_event.position[0] = lastMovementPosition.x * global_state.content_scale;
        io_event.position[1] = lastMovementPosition.y * global_state.content_scale;
        io_event.button = 1;
        
        IO_PushEvent(&io_event);
        
        io_event.type = IO_EVENT_BEGAN;
        io_event.position[0] = lastMovementPosition.x * global_state.content_scale;
        io_event.position[1] = lastMovementPosition.y * global_state.content_scale;
        io_event.button = 3;
        
        IO_PushEvent(&io_event);
        
        io_event.type = IO_EVENT_ENDED;
        io_event.position[0] = lastMovementPosition.x * global_state.content_scale;
        io_event.position[1] = lastMovementPosition.y * global_state.content_scale;
        io_event.button = 3;
        
        IO_PushEvent(&io_event);
    } else {
        if ([[event touchesForView:self.view] count] > 1) {
            NSLog(@"Double touch\n");
            io_event_t io_event;
            
            io_event.type = IO_EVENT_MOVED;
            io_event.position[0] = lastMovementPosition.x * global_state.content_scale;
            io_event.position[1] = lastMovementPosition.y * global_state.content_scale;
            io_event.button = 1;
            
            IO_PushEvent(&io_event);
            
            io_event.type = IO_EVENT_BEGAN;
            io_event.position[0] = lastMovementPosition.x * global_state.content_scale;
            io_event.position[1] = lastMovementPosition.y * global_state.content_scale;
            io_event.button = 3;
            
            IO_PushEvent(&io_event);
            
            io_event.type = IO_EVENT_ENDED;
            io_event.position[0] = lastMovementPosition.x * global_state.content_scale;
            io_event.position[1] = lastMovementPosition.y * global_state.content_scale;
            io_event.button = 3;
            
            IO_PushEvent(&io_event);
        } else {
            NSLog(@"Single touch\n");
            CGPoint center = [[[event allTouches] anyObject] locationInView:self.view];
            lastMovementPosition.x = center.x;
            lastMovementPosition.y = center.y;
        }
    }
	// New touches are not yet included in the current touches for the view
	//lastMovementPosition = [[touches anyObject] locationInView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
    NSLog(@"touchesMoved\n");
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	//NSMutableSet *remainingTouches = [[event touchesForView:self] mutableCopy];
    //[remainingTouches minusSet:touches];
    if (!dragging) {
        return;
    }
    
    //	lastMovementPosition = [[touches anyObject] locationInView:self];
    //
    //    io_event_t io_event;
    //
    //    io_event.type = IO_EVENT_MOVED;
    //    io_event.position[0] = lastMovementPosition.x * global_state.content_scale;
    //    io_event.position[1] = lastMovementPosition.y * global_state.content_scale;
    //    io_event.button = 1;
    //    IO_PushEvent(&io_event);
    
    //    io_event.type = IO_EVENT_BEGAN;
    //    io_event.position[0] = lastMovementPosition.x * global_state.content_scale;
    //    io_event.position[1] = lastMovementPosition.y * global_state.content_scale;
    //    io_event.button = 1;
    //    IO_PushEvent(&io_event);
    
    //    io_event.type = IO_EVENT_ENDED;
    //    io_event.position[0] = lastMovementPosition.x * global_state.content_scale;
    //    io_event.position[1] = lastMovementPosition.y * global_state.content_scale;
    //    io_event.button = 1;
    //    IO_PushEvent(&io_event);
    //
    //    dragging = false;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Handle touches canceled the same as as a touches ended event
    [self.view touchesEnded:touches withEvent:event];
}

-(void)handleTap:(UIPanGestureRecognizer *)sender {
    CGPoint center = [sender locationInView:self.view];
    NSLog(@"handleTap: %f %f\n", center.x, center.y);
    
    if (dragging) {
        return;
    }
    
    int taps = 1;
    int i;
    
    if (lastTapDate != nil) {
        double time_since_tap = [lastTapDate timeIntervalSinceNow] * -1000.0;
        
        //NSLog(@"tapTimestamp: %f\n", tapTimestamp);
        NSLog(@"lastTapTimestap: %f\n", lastTapTimestamp);
        if (time_since_tap < 300) {
            taps = 2;
        }
    }
    
    lastTapDate = [NSDate date];
    
    //lastTapTimestamp = tapTimestamp;
    
    for (i = 0; i < taps; i++) {
        io_event_t io_event;
        
        io_event.type = IO_EVENT_MOVED;
        io_event.position[0] = center.x * global_state.content_scale;
        io_event.position[1] = center.y * global_state.content_scale;
        //io_event.position[1] = center.y * global_state.content_scale;
        io_event.button = 1;
        IO_PushEvent(&io_event);
        
        io_event.type = IO_EVENT_BEGAN;
        io_event.position[0] = center.x * global_state.content_scale;
        io_event.position[1] = center.y * global_state.content_scale;
        //io_event.position[1] = center.y * global_state.content_scale;
        io_event.button = 1;
        IO_PushEvent(&io_event);
        
        io_event.type = IO_EVENT_ENDED;
        io_event.position[0] = center.x * global_state.content_scale;
        io_event.position[1] = center.y * global_state.content_scale;
        //io_event.position[1] = center.y * global_state.content_scale;
        io_event.button = 1;
        IO_PushEvent(&io_event);
    }
}

-(void)handleDoubleTap:(UIPanGestureRecognizer *)sender {
    int i;
    CGPoint center = [sender locationInView:self.view];
    NSLog(@"handleDoubleTap: %f %f\n", center.x, center.y);
    
    if (dragging) {
        return;
    }
    
    for (i = 0; i < 1; i++) {
        io_event_t io_event;
        
        io_event.type = IO_EVENT_MOVED;
        io_event.position[0] = center.x * global_state.content_scale;
        io_event.position[1] = center.y * global_state.content_scale;
        io_event.button = 3;
        IO_PushEvent(&io_event);
        
        io_event.type = IO_EVENT_BEGAN;
        io_event.position[0] = center.x * global_state.content_scale;
        io_event.position[1] = center.y * global_state.content_scale;
        io_event.button = 3;
        IO_PushEvent(&io_event);
        
        io_event.type = IO_EVENT_ENDED;
        io_event.position[0] = center.x * global_state.content_scale;
        io_event.position[1] = center.y * global_state.content_scale;
        io_event.button = 3;
        IO_PushEvent(&io_event);
    }
}

-(void)handleLongPress:(UIPanGestureRecognizer *)sender {
    NSLog(@"handleLongPress\n");
    CGPoint center = [sender locationInView:self.view];
    io_event_t io_event;
    
    if (!dragging) {
        dragging = true;
        
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        
        io_event.type = IO_EVENT_MOVED;
        io_event.position[0] = center.x * global_state.content_scale;
        io_event.position[1] = center.y * global_state.content_scale;
        io_event.button = 1;
        IO_PushEvent(&io_event);
        
        io_event.type = IO_EVENT_BEGAN;
        io_event.position[0] = center.x * global_state.content_scale;
        io_event.position[1] = center.y * global_state.content_scale;
        io_event.button = 1;
        IO_PushEvent(&io_event);
        
        lastMovementPosition.x = center.x * global_state.content_scale;
        lastMovementPosition.y = center.y * global_state.content_scale;
    } else {
        io_event.type = IO_EVENT_MOVED;
        io_event.position[0] = center.x * global_state.content_scale;
        io_event.position[1] = center.y * global_state.content_scale;
        io_event.button = 1;
        IO_PushEvent(&io_event);
        
        lastMovementPosition.x = center.x * global_state.content_scale;
        lastMovementPosition.y = center.y * global_state.content_scale;
    }
    //
    //    io_event.type = IO_EVENT_ENDED;
    //    io_event.position[0] = center.x * global_state.content_scale;
    //    io_event.position[1] = center.y * global_state.content_scale;
    //    io_event.button = 3;
    //    IO_PushEvent(&io_event);
    
    if ([sender state] == UIGestureRecognizerStateEnded) {
        NSLog(@"longPress ended\n");
        dragging = false;
        io_event.type = IO_EVENT_ENDED;
        io_event.position[0] = center.x * global_state.content_scale;
        io_event.position[1] = center.y * global_state.content_scale;
        io_event.button = 4; /* Special case for indicating long press */
        IO_PushEvent(&io_event);
    }
}

-(void)handlePan:(UIPanGestureRecognizer *)sender {
    NSLog(@"handlePan\n");
    
    if (dragging) {
        return;
    }
    
    if (global_state.zoom == 0) {
        global_state.zoom_offset_x = 0.0;
        global_state.zoom_offset_y = 0.0;
        panTarget.x = -1;
        panTarget.y = -1;
    } else {
        CGPoint pan_center = [sender locationInView:self.view];
        float offset;
        float pan_offset_x;
        float pan_offset_y;
        
        NSLog(@"handlePan: %f %f\n", pan_center.x, pan_center.y);
        
        if (panTarget.x == -1) {
            panTarget.x = pan_center.x;
            panTarget.y = pan_center.y;
        } else {
            pan_offset_x = panTarget.x - pan_center.x;
            //            if (pan_offset_x > 0) {
            //                if (panDirection == -1) {
            //                    panDirection = 1;
            //                    panTarget.x = pan_center.x;
            //                    return;
            //                }
            //                panDirection = 1;
            //            } else {
            //                if (panDirection == 1) {
            //                    panDirection = -1;
            //                    panTarget.x = pan_center.x;
            //                    return;
            //                }
            //                panDirection = -1;
            //            }
            pan_offset_y = panTarget.y - pan_center.y;
        }
        
        if (fabs(pan_offset_x) > 10) {
            if (pan_offset_x < 0) {
                offset = global_state.zoom_offset_x - 0.04;
                if (fabs(offset) <= global_state.zoom) {
                    global_state.zoom_offset_x = offset;
                } else {
                    if (offset < 0) {
                        global_state.zoom_offset_x = global_state.zoom * -1;
                    } else {
                        global_state.zoom_offset_x = global_state.zoom;
                    }
                }
            } else {
                offset = global_state.zoom_offset_x + 0.04;
                if (fabs(offset) <= global_state.zoom) {
                    global_state.zoom_offset_x = offset;
                } else {
                    if (offset < 0) {
                        global_state.zoom_offset_x = global_state.zoom * -1;
                    } else {
                        global_state.zoom_offset_x = global_state.zoom;
                    }
                }
            }
            panTarget.x = pan_center.x;
        }
        
        if (fabs(pan_offset_y) > 10) {
            if (pan_offset_y > 0) {
                offset = global_state.zoom_offset_y - 0.04;
                if (fabs(offset) <= global_state.zoom) {
                    global_state.zoom_offset_y = offset;
                } else {
                    if (offset < 0) {
                        global_state.zoom_offset_y = global_state.zoom * -1;
                    } else {
                        global_state.zoom_offset_y = global_state.zoom;
                    }
                }
            } else {
                offset = global_state.zoom_offset_y + 0.04;
                if (fabs(offset) <= global_state.zoom) {
                    global_state.zoom_offset_y = offset;
                } else {
                    if (offset < 0) {
                        global_state.zoom_offset_y = global_state.zoom * -1;
                    } else {
                        global_state.zoom_offset_y = global_state.zoom;
                    }
                }
            }
            panTarget.y = pan_center.y;
        }
    }
    
    if ([sender state] == UIGestureRecognizerStateEnded) {
        panTarget.x = -1;
        panTarget.y = -1;
    }
}

-(void)handleDoublePan:(UIPanGestureRecognizer *)sender {
    NSLog(@"handleDoublePan\n");
    
    if (dragging) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGPoint pan_center = [sender locationInView:self.view];
        int button;
        
        CGPoint gestureVelocity = [sender velocityInView:self.view];
        NSLog(@"gestureVelocity.x = %f\n", gestureVelocity.x);
        NSLog(@"gestureVelocity.y = %f\n", gestureVelocity.y);
        
//        if (doublePanVelocity == -1) {
//            doublePanEvents = 0;
//            if (fabs(gestureVelocity.y) < 100) {
                doublePanVelocity = 400;
//            } else if (fabs(gestureVelocity.y) > 200) {
//                doublePanVelocity = 50;
//            } else {
//                doublePanVelocity = 100;
//            }
//        } else {
            doublePanEvents += (int) fabs(gestureVelocity.y);
//        }
        
        NSLog(@"doublePanVelocity = %d\n", doublePanVelocity);
        NSLog(@"doublePanVelocity = %d\n", doublePanEvents);
        
        if (gestureVelocity.y != 0.0 && doublePanEvents > doublePanVelocity) {
            doublePanEvents = 0;
            doublePanVelocity = -1;
            if (gestureVelocity.y < 0.0) {
                button = 5;
            } else {
                button = 4;
            }
            
            io_event_t io_event;
            
            io_event.type = IO_EVENT_MOVED;
            io_event.position[0] = pan_center.x * global_state.content_scale;
            io_event.position[1] = pan_center.y * global_state.content_scale;
            io_event.button = button;
            IO_PushEvent(&io_event);
            
            io_event.type = IO_EVENT_BEGAN;
            io_event.position[0] = pan_center.x * global_state.content_scale;
            io_event.position[1] = pan_center.y * global_state.content_scale;
            io_event.button = button;
            IO_PushEvent(&io_event);
            
            io_event.type = IO_EVENT_ENDED;
            io_event.position[0] = pan_center.x * global_state.content_scale;
            io_event.position[1] = pan_center.y * global_state.content_scale;
            io_event.button = button;
            IO_PushEvent(&io_event);
        }
        
        if ([sender state] == UIGestureRecognizerStateEnded) {
            doublePanVelocity = -1;
        }
    });
}

-(void)handlePinch:(UIPinchGestureRecognizer *)pinchGestureRecognizer {
    NSLog(@"PinchGesture scale: %f", pinchGestureRecognizer.scale);
    NSLog(@"PinchGesture velocity: %f", pinchGestureRecognizer.velocity);
    
    if (dragging) {
        return;
    }
    
    float velocity = fabs(pinchGestureRecognizer.velocity) / 500;
    
    if (isnan(velocity)) {
        return;
    }
    
    if (pinchGestureRecognizer.scale > 1) {
        global_state.zoom += velocity;
        if (global_state.zoom > 0.30) {
            global_state.zoom = 0.30;
        }
    } else {
        global_state.zoom -= velocity * 4;
        if (global_state.zoom < 0.0) {
            global_state.zoom = 0.0;
        }
    }
    
    if (global_state.zoom == 0) {
        global_state.zoom_offset_x = 0.0;
        global_state.zoom_offset_y = 0.0;
        pinchTarget.x = -1;
        pinchTarget.y = -1;
        pinchDirection.x = 0;
        pinchDirection.y = 0;
    } else {
        CGPoint pinch_center = [pinchGestureRecognizer locationInView:self.view];
        CGPoint screen_center;
        float offset;
        
        if (pinchTarget.x == -1) {
            pinchTarget.x = pinch_center.x;
            pinchTarget.y = pinch_center.y;
        }
        
        screen_center.x = global_state.width / 4 + (global_state.width * global_state.zoom_offset_x);
        screen_center.y = global_state.height / 4 + (global_state.height * global_state.zoom_offset_y);
        
        NSLog(@"PinchGesture: %f %f\n", pinch_center.x, pinch_center.y);
        NSLog(@"PinchTarget: %f %f\n", screen_center.x, screen_center.y);
        
        if (pinchTarget.x >= 0) {
            if (pinchTarget.x < screen_center.x) {
                if (pinchDirection.x == 0) {
                    pinchDirection.x = -1;
                } else if (pinchDirection.x == -1) {
                    offset = global_state.zoom_offset_x - 0.01;
                    if (fabs(offset) <= global_state.zoom) {
                        global_state.zoom_offset_x = offset;
                    }
                }
            } else {
                if (pinchDirection.x == 0) {
                    pinchDirection.x = 1;
                } else if (pinchDirection.x == 1) {
                    offset = global_state.zoom_offset_x + 0.01;
                    if (fabs(offset) <= global_state.zoom) {
                        global_state.zoom_offset_x = offset;
                    }
                }
            }
        }
        
        if (pinchTarget.y >= 0) {
            if (pinchTarget.y > screen_center.y) {
                if (pinchDirection.y == 0) {
                    pinchDirection.y = -1;
                } else if (pinchDirection.y == -1) {
                    offset = global_state.zoom_offset_y - 0.01;
                    if (fabs(offset) <= global_state.zoom) {
                        global_state.zoom_offset_y = offset;
                    }
                }
            } else {
                if (pinchDirection.y == 0) {
                    pinchDirection.y = 1;
                } else if (pinchDirection.y == -1) {
                    offset = global_state.zoom_offset_y + 0.01;
                    if (fabs(offset) <= global_state.zoom) {
                        global_state.zoom_offset_y = offset;
                    }
                }
            }
        }
    }
    
    //    if ([pinchGestureRecognizer state] == UIGestureRecognizerStateEnded) {
    //        pinchTarget.x = -1;
    //        pinchTarget.y = -1;
    //    }
    
    
    NSLog(@"Zoom=%f\n", global_state.zoom);
}

-(void)showHideKeyboard
{
    if (keybVisible) {
        [self hideKeyboard];
    } else {
        [self showKeyboard];
    }
}

-(void)showKeyboard
{
    if (!keybVisible) {
        [keybView becomeFirstResponder];
        keybVisible = true;
        if (global_state.width > global_state.height) {
            engine_set_keyboard_offset(0.2);
        }
        engine_set_keyboard_opacity(1.0);
    }
}

-(void)hideKeyboard
{
    if (keybVisible) {
        [keybView resignFirstResponder];
        keybVisible = false;
        engine_set_keyboard_offset(0.0);
        engine_set_keyboard_opacity(0.2);
    }
}

-(void)showMenu
{
    if (_tblMenu.hidden) {
        if (keybVisible) {
            [self hideKeyboard];
        }
        tapRecognizer.enabled = false;
        longPressRecognizer.enabled = false;
        pinchRecognizer.enabled = false;
        panRecognizer.enabled = false;
        _tblMenu.hidden = false;
        [_tblMenu becomeFirstResponder];
        engine_set_main_opacity(0.5);
    }
}

-(void)hideMenu
{
    if (!_tblMenu.hidden) {
        tapRecognizer.enabled = true;
        longPressRecognizer.enabled = true;
        pinchRecognizer.enabled = true;
        panRecognizer.enabled = true;
        _tblMenu.hidden = true;
        engine_set_main_opacity(1.0);
    }
}

-(void)showLabel:(NSString *)text
{
    _lblMessage.text = text;
    _lblMessage.hidden = false;
}

-(void)hideLabel
{
    _lblMessage.hidden = true;
}

-(void)clearCredentials
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kFlexKeyLauncherUser];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kFlexKeyLauncherPassword];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kFlexKeyLauncherDesktop];
}

-(void)waitForNetwork
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showLabel:NSLocalizedString(@"wait_for_network", nil)];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (1) {
            sleep(5);
            
            Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
            NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
            
            if (networkStatus != NotReachable || connDesiredState != CONNECTED) {
                [self connectionChange:DISCONNECTED];
                return;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showLabel:NSLocalizedString(@"reconnection_failed", nil)];
            [self clearCredentials];
            sleep(3);
            global_state.guest_height = 0;
            global_state.guest_width = 0;
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    });
}

-(void)connectionChange:(int)state
{
    if (state == DISCONNECTED) {
        if (connDesiredState == DISCONNECTED) {
            /* User asked us to close this session */
            global_state.guest_height = 0;
            global_state.guest_width = 0;
            [self clearCredentials];
            [self dismissViewControllerAnimated:YES completion:nil];
            return;
        }
        
        [self hideKeyboard];
        [self hideMenu];
        engine_set_keyboard_opacity(0.2);
        engine_set_main_opacity(0.5);
        
        Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
        NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
        
        if (networkStatus == NotReachable) {
            [self waitForNetwork];
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showLabel:NSLocalizedString(@"reconnection", nil)];
        });
        
        //engine_spice_disconnect();
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //int i;
            //for (i = 0; i < 3; i++) {
            while (1) {
                sleep(1);
                NSLog(@"Reconnecting to %@:%@ with password \"%@\"", self.ip, self.port, self.pass);
                
                reconnectionState = R_NONE;
                [self launcherConnect:nil];
                
                while (reconnectionState != R_SPICE) {
                    sleep(1);
                    if (reconnectionState == R_LAUNCHER_WAIT) {
                        sleep(3);
                        reconnectionState = R_NONE;
                        [self launcherConnect:nil];
                    } else if (reconnectionState == R_FAILED) {
                        if (connDesiredState != CONNECTED) {
                            return;
                        }
                        NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
                        
                        if (networkStatus == NotReachable) {
                            [self waitForNetwork];
                            return;
                        } else {
                            /* Break loop to reach error bellow. */
                            break;
                        }
                    }
                }
                
                if (reconnectionState == R_SPICE) {
                    if (engine_spice_connect() == 0) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self hideLabel];
                            engine_set_main_opacity(1.0);
                            engine_set_keyboard_opacity(0.2);
                        });
                        return;
                    }
                    
                    if (connDesiredState != CONNECTED) {
                        return;
                    }
                    
                    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
                    
                    if (networkStatus == NotReachable) {
                        [self waitForNetwork];
                        return;
                    }
                } else {
                    /* Launcher connection failed, break loop. */
                    break;
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showLabel:NSLocalizedString(@"reconnection_failed", nil)];
                [self clearCredentials];
                sleep(3);
                global_state.guest_height = 0;
                global_state.guest_width = 0;
                [self dismissViewControllerAnimated:YES completion:nil];
            });
        });
    }
}

void native_show_keyboard()
{
    [mainViewController showHideKeyboard];
}

void native_show_menu()
{
    [mainViewController showMenu];
}

void native_connection_change(int state)
{
    [mainViewController connectionChange:state];
}

void native_resolution_change(int changing) {
    if (changing) {
        engine_set_main_opacity(0.5);
        [mainViewController showLabel:@"Solicitando ajuste de resolución" ];
    } else {
        engine_set_main_opacity(1.0);
        [mainViewController hideLabel];
    }
}

#pragma mark -
#pragma mark Fetch loads from url
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    NSLog(@"willCacheResponse");
    return nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    NSLog(@"didReceiveResponse");
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    int statusCode = [httpResponse statusCode];
    
    if (statusCode != 200){
        NSLog(@"no es 200  ");
        
        reconnectionState = R_FAILED;
        
        NSLog(@"statusCode %d  ",statusCode);
        [connection cancel];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"didReceiveData");
    
    if (serverAnswer == nil) {
        serverAnswer = [[NSMutableData alloc] init];
    }
    
    [serverAnswer appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError");

    serverAnswer = nil;
    connection = nil;
    reconnectionState = R_FAILED;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSLog(@"willSendRequestForAuthenticationChallenge");
    NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];
    NSURLCredential *credential = [NSURLCredential credentialForTrust:[protectionSpace serverTrust]];
    [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
}

#pragma mark -
#pragma mark Process load data

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self launcherConnect:connection];
    [connection cancel];
}

-(void)launcherConnect:(NSURLConnection *) connection
{
    if (reconnectionState == R_NONE) {
        NSLog(@"R_NONE");
        
        NSString* launcherUser = [[NSUserDefaults standardUserDefaults] stringForKey:kFlexKeyLauncherUser];
        if(!launcherUser || launcherUser.length==0){
            reconnectionState = R_FAILED;
            return;
        }
        NSString* launcherPassword = [[NSUserDefaults standardUserDefaults] stringForKey:kFlexKeyLauncherPassword];
        if(!launcherPassword || launcherPassword.length==0){
            reconnectionState = R_FAILED;
            return;
        }
        NSString* launcherDesktop = [[NSUserDefaults standardUserDefaults] stringForKey:kFlexKeyLauncherDesktop];
        if(!launcherDesktop || launcherDesktop.length==0){
            launcherDesktop = @"";
        }
        NSString* launcherDevID = [[NSUserDefaults standardUserDefaults] stringForKey:kFlexKeyLauncherDevID];
        if(!launcherDevID || launcherDevID.length==0){
            reconnectionState = R_FAILED;
            return;
        }
        NSString* serverIP = [[NSUserDefaults standardUserDefaults] stringForKey:kFlexKeyServerIP];
        if(!serverIP || serverIP.length==0){
            reconnectionState = R_FAILED;
            return;
        }
        NSString* serverPort = [[NSUserDefaults standardUserDefaults] stringForKey:kFlexKeyServerPort];
        if(!serverPort || serverPort.length==0){
            reconnectionState = R_FAILED;
            return;
        }
        
        NSString* serverProto =nil;
        serverProto = @"https";
        
        NSString *strUrlDesktop = [NSString stringWithFormat:@"%@://%@:%@/vdi/desktop", serverProto,serverIP,serverPort];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:strUrlDesktop]];
        [request setHTTPMethod:@"POST"];
        
        NSString *body = [NSString stringWithFormat:
                          @"{\"hwaddress\": \"%@\", \"username\": \"%@\", \"password\": \"%@\", \"desktop\": \"%@\"}", launcherDevID, launcherUser, launcherPassword, launcherDesktop];
        
        NSLog(@"body %@",body);
        
        NSData *postData = [body dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        [request setHTTPBody:postData];
        [request setValue:[NSString stringWithFormat:@"%d", body.length] forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        reconnectionState = R_LAUNCHER;
        NSURLConnection *connectionDesktop =[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        NSLog(@"antes de connectionDesktop start");
        
        [connectionDesktop scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [connectionDesktop start];
    } else if (reconnectionState == R_LAUNCHER) {
        NSDictionary *responseDesktopDict = [NSJSONSerialization JSONObjectWithData:serverAnswer options:kNilOptions error:nil];
        serverAnswer = nil;
        
        NSLog(@"response todo  %@",responseDesktopDict);
        NSString *status=[responseDesktopDict objectForKey:@"status"];
        NSString *message=[responseDesktopDict objectForKey:@"message"];
        NSLog(@"status  %@",status);
        NSLog(@"message %@", message);
        
        if([status isEqualToString:@"OK"]){
            self.ip=[responseDesktopDict objectForKey:@"spice_address"];
            self.pass=[responseDesktopDict objectForKey:@"spice_password"];
            self.port=[responseDesktopDict objectForKey:@"spice_port"];
            
            NSString *wsport;
            if (self.enableWebSockets) {
                wsport = @"443";
            } else {
                wsport = @"-1";
            }
            
            engine_spice_set_connection_data([self.ip UTF8String],
                                             [self.port UTF8String],
                                             [wsport UTF8String],
                                             [self.pass UTF8String]);
            
            reconnectionState = R_SPICE;
        } else if ([status isEqualToString:@"Pending"]) {
            NSLog(@"status Pending");
            reconnectionState = R_LAUNCHER_WAIT;
        } else {
            NSLog(@"status NOK");
            reconnectionState = R_FAILED;
        }
    }
    
    NSLog(@"despues de todo=%d", reconnectionState);
}

@end
