//
//  HelloWorldLayer.h
//  CatChuckr
//
//  Created by Antonelli Brian on 8/29/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

// HelloWorldLayer
@interface HelloWorldLayer : CCLayerColor
{
    NSMutableArray *targets;
    NSMutableArray *projectiles;
    CCLabelTTF *score;
    int currentScore;
}

-(void) addTarget;

-(void) spriteMoveFinished: (id) sender;

-(void) update: (ccTime) dt;

-(void) gameLogic: (ccTime) dt;

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
