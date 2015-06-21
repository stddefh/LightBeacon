//
//  LBAViewController.m
//  LightBeacon
//
//  Created by Jonathan Fox on 6/6/15.
//  Copyright (c) 2015 Jon Fox. All rights reserved.
//

#import "LBAViewController.h"
#import "LBALogManager.h"
#import "LBAColorConstants.h"
#import "LBARectangleView.h"
#import "LBASettingsTab.h"
#import "LBAPlusSign.h"
#import "LBAMinusSign.h"
#import <Gimbal/Gimbal.h>

#define LIGHT_ON_THRESHOLD @"Light_On_Threshold"
#define LIGHT_OFF_THRESHOLD @"Light_Off_Threshold"
#define USER_LIGHT_OFF_DELAY @"User_light_Off_Delay"

@interface LBAViewController () <GMBLPlaceManagerDelegate>
@property (nonatomic) GMBLPlaceManager *placeManager;
@property (nonatomic) NSMutableString *log;

@property (nonatomic) BOOL lightIsOn;
@property (nonatomic) BOOL delayTimerIsOn;
@property (nonatomic) UIColor *liteTintColor;
@property (nonatomic) UIColor *darkTintColor;
@property (nonatomic) UIColor *whiteTintColor;

// User configurable properties
@property (nonatomic) BOOL userLightOffTimerIsOn;
@property (nonatomic) NSInteger userOnThreshold;
@property (nonatomic) NSInteger userOffThreshold;
@property (nonatomic) int redColor;
@property (nonatomic) int greenColor;
@property (nonatomic) int blueColor;
@property (nonatomic) float alpha;

//UI Elements
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *darkTintColorElements;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *lightTintColorElements;
@property (weak, nonatomic) IBOutlet UISlider *redSlider;
@property (weak, nonatomic) IBOutlet UISlider *greenSlider;
@property (weak, nonatomic) IBOutlet UISlider *blueSlider;
@property (weak, nonatomic) IBOutlet UISlider *dimmerSlider;
@property (weak, nonatomic) IBOutlet UISwitch *lightSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *autoSwitch;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *favoritesButton;
@property (weak, nonatomic) IBOutlet LBARectangleView *dimBox;

//Labels
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *redLabel;
@property (weak, nonatomic) IBOutlet UILabel *greenLabel;
@property (weak, nonatomic) IBOutlet UILabel *blueLabel;


@end

@implementation LBAViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpConfigurations];
    [self setUpUserDefaults];
    [self setTintColors];
    [self changeBackgroundColor];
    [self setUpVerticalSlider];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:NO];
    self.log = [@""mutableCopy];
    
    for (UILabel *label in self.lightTintColorElements) {
        label.tintColor = self.liteTintColor;
    }
    for (UIView *view in self.darkTintColorElements) {
        view.tintColor = self.darkTintColor;
    }
    self.lightSwitch.onTintColor = self.darkTintColor;
    self.lightSwitch.tintColor = self.liteTintColor;
    self.lightSwitch.thumbTintColor = self.whiteTintColor;
    self.autoSwitch.onTintColor = self.darkTintColor;
    self.autoSwitch.tintColor = self.liteTintColor;
    self.autoSwitch.thumbTintColor = self.whiteTintColor;
    self.settingsButton.tintColor = self.liteTintColor;
    self.favoritesButton.tintColor = self.liteTintColor;
}


- (void)setUpConfigurations{
    self.lightIsOn = NO;
    self.delayTimerIsOn = NO;
    self.userLightOffTimerIsOn = NO;
    
    self.placeManager = [GMBLPlaceManager new];
    self.placeManager.delegate = self;
    [GMBLPlaceManager startMonitoring];
}


- (void)setTintColors{
    self.whiteTintColor = LIGHT_ON_WHITE_TINT_COLOR;
    if (self.lightIsOn) {
        self.liteTintColor = LIGHT_ON_LITE_TINT_COLOR;
        self.darkTintColor = LIGHT_ON_DARK_TINT_COLOR;
    }else{
        self.liteTintColor = LIGHT_OFF_LITE_TINT_COLOR;
        self.darkTintColor = LIGHT_OFF_DARK_TINT_COLOR;
    }
    if (!self.autoSwitch.on && self.lightSwitch.on) {
        self.autoSwitch.thumbTintColor = self.liteTintColor;
        self.autoSwitch.tintColor = self.darkTintColor;
    }else if (!self.autoSwitch.on && !self.lightSwitch.on){
        self.autoSwitch.thumbTintColor = self.whiteTintColor;
        self.autoSwitch.tintColor = self.liteTintColor;
    }
    if (self.autoSwitch.on & self.lightSwitch.on){
        self.autoSwitch.thumbTintColor = self.whiteTintColor;
        self.autoSwitch.tintColor = self.whiteTintColor;
        self.autoSwitch.onTintColor = LIGHT_OFF_DARK_TINT_COLOR;
    }
}

- (void)setUpVerticalSlider{
    CGAffineTransform trans = CGAffineTransformMakeRotation(-M_PI * 0.5);
    self.dimmerSlider.transform = trans;
}


- (NSMutableString *)log{
    if (!_log) {
        _log = [@"" mutableCopy];
    }
    return _log;
}

-(int)redColor{
    if (!_redColor) {
        _redColor = [self.redLabel.text intValue];
    }
    return _redColor;
}

-(int)greenColor{
    if (!_greenColor) {
        _greenColor = [self.greenLabel.text intValue];
    }
    return _greenColor;
}

-(int)blueColor{
    if (!_blueColor) {
        _blueColor = [self.blueLabel.text intValue];
    }
    return _blueColor;
}

-(float)alpha{
    if (!_alpha) {
        _alpha = self.dimmerSlider.value;
    }
    return _alpha;
}

- (void)setUpUserDefaults{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (defaults == nil){
        defaults = [NSUserDefaults standardUserDefaults];
    }
    if (![defaults objectForKey:LIGHT_ON_THRESHOLD]){
        NSDictionary *lightDefaults = @{LIGHT_ON_THRESHOLD:@-80, LIGHT_OFF_THRESHOLD:@-90};
        [defaults registerDefaults:lightDefaults];
    };
    
    self.userOnThreshold = [[defaults objectForKey:LIGHT_ON_THRESHOLD] integerValue];
    self.userOffThreshold = [[defaults objectForKey:LIGHT_OFF_THRESHOLD] integerValue];
}


#pragma mark - GMBL PLACE MANAGER DELEGATE METHODS
- (void)placeManager:(GMBLPlaceManager *)manager didBeginVisit:(GMBLVisit *)visit{
    NSString * visitLog = [LBALogManager createDeveloperLogsWithVisit:visit andEvent:@"Begin"];
    [self updateLogWithString:visitLog];
}


- (void)placeManager:(GMBLPlaceManager *)manager didEndVisit:(GMBLVisit *)visit{
    NSString * visitLog = [LBALogManager createDeveloperLogsWithVisit:visit andEvent:@"End"];
    [self updateLogWithString:visitLog];
}


- (void)placeManager:(GMBLPlaceManager *)manager didReceiveBeaconSighting:(GMBLBeaconSighting *)sighting forVisits:(NSArray *)visits{
    NSString * sightingLog = [LBALogManager createDeveloperLogsWithSighting:sighting];
    [self updateLogWithString:sightingLog];
    self.distanceLabel.text = [NSString stringWithFormat:@"%ld", (long)sighting.RSSI];
    if (!self.lightIsOn && !self.delayTimerIsOn) {
        if (sighting.RSSI > self.userOnThreshold){
            [self startDelay];
            self.lightSwitch.on = YES;
            [self changeBackgroundColor];
            [self setTintColors];
        }
    }
    if (self.lightIsOn && !self.delayTimerIsOn && !self.userLightOffTimerIsOn) {
        if (sighting.RSSI < self.userOffThreshold){
            [self startUserLightOffTimer];
            self.lightSwitch.on = NO;
            [self setTintColors];
        }
    }
}

#pragma mark - ACTIONS

- (IBAction)lightSwitch:(UISwitch *)sender {
    if (sender.on) {
        self.lightIsOn = YES;
    }else{
        self.lightIsOn = NO;
        self.autoSwitch.on = NO;
        [GMBLPlaceManager stopMonitoring];
    }
    [self setTintColors];
    [self changeBackgroundColor];
}

- (IBAction)autoSwitch:(UISwitch *)sender {
    if (sender.on) {
        [GMBLPlaceManager startMonitoring];
        [self setTintColors];
    }else{
        [GMBLPlaceManager stopMonitoring];
        [self setTintColors];
    }
}

- (IBAction)redSliderMoved:(UISlider *)sender {
    int value = sender.value;
    self.redLabel.text = [NSString stringWithFormat:@"%d",value];
    [self updateUserBackgroundColorWithRedColor:value green:0 blue:0 alpha:0];
}

- (IBAction)greenSliderMoved:(UISlider *)sender {
    int value = sender.value;
    self.greenLabel.text = [NSString stringWithFormat:@"%d",value];
    [self updateUserBackgroundColorWithRedColor:0 green:value blue:0 alpha:0];
}

- (IBAction)blueSliderMoved:(UISlider *)sender {
    int value = sender.value;
    self.blueLabel.text = [NSString stringWithFormat:@"%d",value];
    [self updateUserBackgroundColorWithRedColor:0 green:0 blue:value alpha:0];
}
- (IBAction)dimmerValueChanged:(UISlider *)sender {
    [self updateUserBackgroundColorWithRedColor:0 green:0 blue:0 alpha:sender.value];
}

- (IBAction)redMinusButton:(UIButton *)sender {
   [self adjustRedValueWithOperator:@"-"];
}

- (IBAction)redPlusButton:(UIButton *)sender {
    [self adjustRedValueWithOperator:@"+"];
}

- (IBAction)greenMinusButton:(UIButton *)sender {
    [self adjustGreenValueWithOperator:@"-"];
}

- (IBAction)greenPlusButton:(UIButton *)sender {
    [self adjustGreenValueWithOperator:@"+"];
}

- (IBAction)blueMinusButton:(UIButton *)sender {
    [self adjustBlueValueWithOperator:@"-"];
}

- (IBAction)bluePlusButton:(UIButton *)sender {
    [self adjustBlueValueWithOperator:@"+"];
}

#pragma mark - HELPERS
- (void)updateLogWithString:(NSString *)log{
    [self.log insertString:log atIndex:0];
    NSLog(@"%@", log);
}

-(void)updateUserBackgroundColorWithRedColor:(int)red green:(int)green blue:(int)blue alpha:(float)alpha{
    if (self.lightIsOn) {
        if (red > 0) {
            self.redColor = red;
        }
        if (green > 0) {
            self.greenColor = green;
        }
        if (blue > 0) {
            self.blueColor = blue;
        }
        if (alpha > 0.0) {
            self.alpha = alpha;
        }
        self.view.backgroundColor = [UIColor colorWithRed:self.redColor / 255.0 green:self.greenColor / 255.0 blue:self.blueColor / 255.0 alpha:self.alpha];
    }
}


- (void)startDelay{
    self.delayTimerIsOn = YES;
    NSTimer *timer = [NSTimer timerWithTimeInterval:10 target:self selector:@selector(lightSwitchOn) userInfo:nil repeats:NO];
    [timer fire];
}


- (void)startUserLightOffTimer{
    self.userLightOffTimerIsOn = YES;
    NSTimer *timer = [NSTimer timerWithTimeInterval:20 target:self selector:@selector(turnOffUserLightOffTimer) userInfo:nil repeats:NO];
    [timer fire];
}


- (void)lightSwitchOn{
    self.lightIsOn = YES;
    self.delayTimerIsOn = NO;
}


- (void)turnOffUserLightOffTimer{
    self.lightIsOn = NO;
    self.userLightOffTimerIsOn = NO;
    [self changeBackgroundColor];
}

- (void)changeBackgroundColor{
    [UIView animateWithDuration:1.0 animations:^{
        int red = [self.redLabel.text intValue] / 255.0;
        int green = [self.greenLabel.text intValue] / 255.0;
        int blue = [self.blueLabel.text intValue] / 255.0;
        float alpha = self.alpha;
        self.view.backgroundColor = self.lightIsOn ? [UIColor colorWithRed:red green:green blue:blue alpha:alpha] : [UIColor colorWithRed:0.098f green:0.098f blue:0.098f alpha:1.0f];
    }];
}

-(void)adjustRedValueWithOperator:(NSString *)operator{
    int redValue = [self.redLabel.text intValue];
    redValue = [operator isEqualToString:@"+"] ? (redValue += 1) : (redValue -= 1);
    self.redSlider.value = redValue;
    self.redLabel.text = [NSString stringWithFormat:@"%d",redValue];
    [self updateUserBackgroundColorWithRedColor:redValue green:0 blue:0 alpha:0];
}

-(void)adjustGreenValueWithOperator:(NSString *)operator{
    int greenValue = [self.greenLabel.text intValue];
    greenValue = [operator isEqualToString:@"+"] ? (greenValue += 1) : (greenValue -= 1);
    self.greenSlider.value = greenValue;
    self.greenLabel.text = [NSString stringWithFormat:@"%d",greenValue];
    [self updateUserBackgroundColorWithRedColor:0 green:greenValue blue:0 alpha:0];
}

-(void)adjustBlueValueWithOperator:(NSString *)operator{
    int blueValue = [self.blueLabel.text intValue];
    blueValue = [operator isEqualToString:@"+"] ? (blueValue += 1) : (blueValue -= 1);
    self.blueSlider.value = blueValue;
    self.blueLabel.text = [NSString stringWithFormat:@"%d",blueValue];
    [self updateUserBackgroundColorWithRedColor:0 green:0 blue:blueValue alpha:0];
}


@end
