//
//  ViewController.m
//  BackgroundMusic
//
//  Created by Mac on 2016/10/26.
//  Copyright © 2016年 Mac. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
@property (strong, nonatomic) AVAudioPlayer *player;
@property (assign, nonatomic) BOOL isPlaying;

@property (strong, nonatomic) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@end

@implementation ViewController

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_timer && [_timer isValid]) {
        [_timer invalidate];
        _timer = nil;
    }
    NSLog(@"dealloc");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //
    self.isPlaying = NO;
    
    //
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapWindow:)];
    [self.view addGestureRecognizer:tap];
    
    //
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    //对中断的响应,比如打电话等
    [center addObserver:self selector:@selector(interruptNote:) name:AVAudioSessionInterruptionNotification object:nil];
    //对线路改变的响应
    [center addObserver:self selector:@selector(routeChangeNote:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)tapWindow:(UIView *)view {
    if (self.isPlaying) {
        [self pause];
    } else {
        [self play];
    }
}

/*
    Note:
        1: 只有在播放时才会收到通知;
        2: 当收到通知时，音频会话已经被终止，且AVAudioPlayer实例处于暂停状态;
        3: 当前正在播放时，然后进入后台继续播放，然后进入酷我音乐进行播放音乐，则此时只会触发AVAudioSessionInterruptionTypeBegan，正好将当前的音乐停止掉, 而不是线路改变通知。
 */
- (void)interruptNote:(NSNotification *)note {

    NSDictionary *userInfo = note.userInfo;
    AVAudioSessionInterruptionType interruptType = [userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    switch (interruptType) {
        case AVAudioSessionInterruptionTypeBegan: //中断开始
        {
            //由Note可知: 这里主要是更新状态
            NSLog(@"began");
            
            [self stop];
        }
            break;
        case AVAudioSessionInterruptionTypeEnded: //中断结束
        {
            //这时userInfo里面会包含一个AVAudioSessionInterruptionOptions来表明音频会话是否已经重新激活以及是否可以再次播放.
            NSLog(@"ended");
            
            AVAudioSessionInterruptionOptions options = [userInfo[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
            if (options == AVAudioSessionInterruptionOptionShouldResume) {
                [self play];
            }
            
        }
            break;
        default:
            break;
    }
}

/*
    iOS设备上添加或移除音频输入，输出路线时，会发生线路的改变。有多重原因会导致线路的变化，比如用户插入耳机或断开USB麦克风。当这些事件发生时，音频会根据情况改变输入或输出的线路，同时AVAudioSession会广播一个描述该变化的通知给所有相关的侦听器。
 */

- (void)routeChangeNote:(NSNotification *)note {
    NSDictionary *userInfo = note.userInfo;
    /*
     
     AVAudioSessionRouteChangeReasonUnknown = 0,
     AVAudioSessionRouteChangeReasonNewDeviceAvailable = 1,
     AVAudioSessionRouteChangeReasonOldDeviceUnavailable = 2,
     AVAudioSessionRouteChangeReasonCategoryChange = 3,
     AVAudioSessionRouteChangeReasonOverride = 4,
     AVAudioSessionRouteChangeReasonWakeFromSleep = 6,
     AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory = 7,
     AVAudioSessionRouteChangeReasonRouteConfigurationChange
     
     
     正常为扬声器(Speaker)这个不算是新旧Device，也就是如果原来是Speaker，现在插入Headphones,则算为：AVAudioSessionRouteChangeReasonNewDeviceAvailable; 原来为Headphones,现在为Speaker则算为：AVAudioSessionRouteChangeReasonOldDeviceUnavailable,而不是：先发送通知AVAudioSessionRouteChangeReasonOldDeviceUnavailable，紧接着发送：AVAudioSessionRouteChangeReasonNewDeviceAvailable;
     
     */
    AVAudioSessionRouteChangeReason reason = [userInfo[AVAudioSessionRouteChangeReasonKey] unsignedIntegerValue];
    switch (reason) {
        case AVAudioSessionRouteChangeReasonUnknown:
        {
            NSLog(@"AVAudioSessionRouteChangeReasonUnknown");
        }
            break;
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
        {
            NSLog(@"AVAudioSessionRouteChangeReasonNewDeviceAvailable");
        }
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        {
            NSLog(@"AVAudioSessionRouteChangeReasonOldDeviceUnavailable");
            AVAudioSessionRouteDescription *previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey];
            AVAudioSessionPortDescription *previousOutput =  previousRoute.outputs.firstObject;
            NSString *previousPortType = previousOutput.portType;
            
            AVAudioSessionRouteDescription *currentRoute = [AVAudioSession sharedInstance].currentRoute;
            AVAudioSessionPortDescription *currentOutput = currentRoute.outputs.firstObject;
            NSString *currentPortType = currentOutput.portType;
            
            if ([previousPortType isEqualToString:AVAudioSessionPortHeadphones]) {
                /*
                 //input port types
                    AVAudioSessionPortLineIn
                    AVAudioSessionPortBuiltInMic
                    AVAudioSessionPortHeadsetMic
                 
                 //output port types
                    AVAudioSessionPortLineOut
                    AVAudioSessionPortHeadphones
                    AVAudioSessionPortBluetoothA2DP
                    AVAudioSessionPortBuiltInReceiver
                    AVAudioSessionPortBuiltInSpeaker
                    AVAudioSessionPortHDMI
                    AVAudioSessionPortAirPlay
                    AVAudioSessionPortBluetoothLE
                 
                 //port types that refer to either input or output
                    AVAudioSessionPortBluetoothHFP
                    AVAudioSessionPortUSBAudio
                    AVAudioSessionPortCarAudio
                 */
                
                NSLog(@"previousPortType: %@, currentPortType: %@", previousPortType, currentPortType);
                [self pause];
            }
        }
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
        {
            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
        }
            break;
        case AVAudioSessionRouteChangeReasonOverride:
        {
            NSLog(@"AVAudioSessionRouteChangeReasonOverride");
        }
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
        {
            NSLog(@"AVAudioSessionRouteChangeReasonWakeFromSleep");
        }
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
        {
            NSLog(@"AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory");
        }
            break;
        case AVAudioSessionRouteChangeReasonRouteConfigurationChange:
        {
            NSLog(@"AVAudioSessionRouteChangeReasonRouteConfigurationChange");
        }
            break;
            
        default:
            break;
    }
}

- (void)play {
    if (!self.isPlaying) {
        self.isPlaying = YES;
        [self.player play];
        [self.timer setFireDate:[NSDate distantPast]];
        NSLog(@"play currentTime: %f", self.player.currentTime);
    }
}

- (void)pause {
    if (self.isPlaying) {
        self.isPlaying = NO;
        [self.player pause];
        [self.timer setFireDate:[NSDate distantFuture]];
    }
}

- (void)stop {
    self.isPlaying = NO;
    [self.player stop];
    [self.timer setFireDate:[NSDate distantFuture]];
    NSLog(@"stop currentTime: %f", self.player.currentTime);
}

- (void)progressUpdate:(NSTimer *)timer {
    self.progressSlider.value = self.progressSlider.maximumValue * self.player.currentTime / self.player.duration;
}

- (AVAudioPlayer *)player {
    if (!_player) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"drums" ofType:@"caf"];
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:path] error:nil];
        _player.numberOfLoops = -1;
        [_player prepareToPlay];
    }
    return _player;
}

- (NSTimer *)timer {
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.01f target:self selector:@selector(progressUpdate:) userInfo:nil repeats:YES];
        [_timer setFireDate:[NSDate distantFuture]];
    }
    return _timer;
}

@end
