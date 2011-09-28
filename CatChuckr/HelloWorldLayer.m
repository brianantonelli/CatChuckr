//
//  HelloWorldLayer.m
//  CatChuckr
//
//  Created by Antonelli Brian on 8/29/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"
#import "SimpleAudioEngine.h"

// HelloWorldLayer implementation
@implementation HelloWorldLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
    CCSprite *bg = [CCSprite spriteWithFile:@"space.png"];
    [bg setPosition:ccp(240, 160)];
    [layer addChild:bg z:0];

	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super initWithColor:ccc4(255,255,255,255)])) {
		self.isTouchEnabled = YES;
        
        projectiles = [[NSMutableArray alloc] init];
        targets = [[NSMutableArray alloc] init];

		CGSize winSize = [[CCDirector sharedDirector] winSize];
        
        CCSprite *player = [CCSprite spriteWithFile:@"Player.png" rect:CGRectMake(0, 0, 27, 40)];
        player.position = ccp(player.contentSize.width/2, winSize.height/2);
        [self addChild:player z:1];
        
        score = [CCLabelTTF labelWithString:@"Score: 0" fontName:@"Marker Felt" fontSize:16];
        score.color = ccc3(220,220,220);
        score.position = ccp(winSize.width - 50, winSize.height - 10);
        [self addChild:score z:1];
        
        [self schedule:@selector(gameLogic:) interval:1.0];
        [self schedule:@selector(update:)];
	}
	return self;
}

-(void) gameLogic: (ccTime) dt
{
    [self addTarget];
}

-(void) update: (ccTime) dt
{
    NSMutableArray *projectilesToRemove = [[NSMutableArray alloc] init];
    for(CCSprite *projectile in projectiles){
        CGRect projectileRect = CGRectMake(
                                           projectile.position.x - (projectile.contentSize.width/2),
                                           projectile.position.y - (projectile.contentSize.height/2),
                                           projectile.contentSize.width,
                                           projectile.contentSize.height);
        
        NSMutableArray *targetsToRemove = [[NSMutableArray alloc] init];
        for(CCSprite *target in targets){
            CGRect targetRect = CGRectMake(
                                           target.position.x - (target.contentSize.width/2), 
                                           target.position.y - (target.contentSize.height/2), 
                                           target.contentSize.width,
                                           target.contentSize.height);
            
            if(CGRectIntersectsRect(projectileRect, targetRect)){
                [targetsToRemove addObject:target];
            }
        }
        
        for(CCSprite *target in targetsToRemove){
            [targets removeObject:target];
            [self removeChild:target cleanup:YES];
            [[SimpleAudioEngine sharedEngine] playEffect:@"boom.wav"];
            [score setString:[NSString stringWithFormat:@"Score: %d", currentScore++]];
        }
        
        if([targetsToRemove count] > 0){
            [projectilesToRemove addObject:projectile];
        }
        
        [targetsToRemove release];
    }
    
    for(CCSprite *projectile in projectilesToRemove){
        [projectiles removeObject:projectile];
        [self removeChild:projectile cleanup:YES];
    }
    
    [projectilesToRemove release];
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Grab a touch's location
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:[touch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    
    // Set its initial location
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CCSprite *projectile = [CCSprite spriteWithFile:@"Cat.png" rect:CGRectMake(0, 0, 30, 20)];
    projectile.position = ccp(20, winSize.height/2);
    
    // Offset location to projectile
    int offsetX = location.x - projectile.position.x;
    int offsetY = location.y - projectile.position.y;
    
    // Abort if shooting down or backwards
    if(offsetX <=0 ) return;
    
    [self addChild:projectile];
    
    // Figure out where to shoot to
    int realX = winSize.width + (projectile.contentSize.width/2);
    float ratio = (float) offsetY / (float) offsetX;
    int realY = (realX * ratio) + projectile.position.y;
    CGPoint realDest = ccp(realX, realY);
    
    // Determine shot length
    int offRealX = realX - projectile.position.x;
    int offRealY = realY - projectile.position.y;
    float length = sqrtf((offRealX * offRealX) + (offRealY + offRealY));
    float velocity = 480/1; // 480 pixels = 1 second
    float realMoveDuration = length/velocity;
    
    // Project the projectile!
    [projectile runAction:[CCSequence actions:
                            [CCMoveTo actionWithDuration:realMoveDuration position:realDest],
                            [CCCallFuncN actionWithTarget:self selector:@selector(spriteMoveFinished:)],
                            nil]];
    
    projectile.tag = 2;
    [projectiles addObject:projectile];
    
    [[SimpleAudioEngine sharedEngine] playEffect:@"meow.wav"];
}

-(void) addTarget
{
    CCSprite *target = [CCSprite spriteWithFile:@"Homeless.png" rect:CGRectMake(0, 0, 27, 40)];
    
    // Where to spawn
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    int minY = target.contentSize.height/2;
    int maxY = winSize.height - target.contentSize.height/2;
    int rangeY = maxY - minY;
    int actualY = (arc4random() % rangeY) + minY;
    
    // Create target off screen with a random y
    target.position = ccp(winSize.width + (target.contentSize.width/2), actualY);
    [self addChild:target];
    
    // Speed?
    int minDuration = 2.0;
    int maxDuration = 4.0;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;
    
    // Create actions
    id actionMove = [CCMoveTo actionWithDuration:actualDuration position:ccp(-target.contentSize.width/2, actualY)];
    id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(spriteMoveFinished:)];
    
    [target runAction:[CCSequence actions:actionMove, actionMoveDone, nil]];
    
    target.tag = 1;
    [targets addObject:target];
}
                          
-(void) spriteMoveFinished: (id) sender
{
    CCSprite *sprite = (CCSprite*) sender;
    
    if(sprite.tag == 1){
        [targets removeObject:sprite];
    }
    else{
        [projectiles removeObject:sprite];
    }
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
    
    [targets release], targets = nil;
    [projectiles release], projectiles = nil;
    [score release], score = nil;
}
@end
