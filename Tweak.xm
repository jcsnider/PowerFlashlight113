#import "AVFlashlight.h"
#import <AudioToolbox/AudioServices.h>
@interface SpringBoard : NSObject
-(BOOL)_handlePhysicalButtonEvent:(id)arg1 ;
-(void)_simulateHomeButtonPress;
-(void)_simulateLockButtonPress;
@end

@interface AVSystemController

+ (id)sharedAVSystemController;

- (BOOL)getActiveCategoryVolume:(float*)volume andName:(id*)name;
- (BOOL)setActiveCategoryVolumeTo:(float)to;

@end

BOOL pressed = NO;
NSTimer *pressedTimer;
static AVFlashlight *_sharedFlashlight;

%hook AVFlashlight

-(id)init {
if (!_sharedFlashlight) {
_sharedFlashlight = %orig;
}

return _sharedFlashlight;
}

%end

%hook SpringBoard

	-(_Bool)_handlePhysicalButtonEvent:(UIPressesEvent *)arg1 
	{

		int type = arg1.allPresses.allObjects[0].type; 
		int force = arg1.allPresses.allObjects[0].force;

        // type = 101 -> Home button
        // type = 104 -> Power button

        // force = 0 -> button released
        // force = 1 -> button pressed
		
		if(type == 104 && force == 1) //Power PRESSED
		{
            pressed = YES;
            pressedTimer = [[NSTimer scheduledTimerWithTimeInterval:.6 target:self selector:@selector(toggleFlashlight) userInfo:nil repeats:NO] retain];
		}

        if(type == 104 && force == 0) //Power RELEASED
        {
            if (pressedTimer != nil) {
                [pressedTimer invalidate];
                pressedTimer = nil;
            }
            pressed = NO;
        }

		return %orig;
	}

    %new
    - (void)toggleFlashlight
    {
        if (pressed) {
            if (_sharedFlashlight.flashlightLevel > 0) {
                [_sharedFlashlight setFlashlightLevel: 0.0 withError:nil]
            }
            else {
                [_sharedFlashlight setFlashlightLevel:1.0 withError:nil];
            }
            AudioServicesPlaySystemSoundWithCompletion(kSystemSoundID_Vibrate, ^{
                AudioServicesDisposeSystemSoundID(kSystemSoundID_Vibrate);
            });
            pressed = NO;
        }
    }
%end



	

