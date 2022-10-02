package objs;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import util.FSM;
import util.MultiEmitter;
import util.MultiSprite.SpriteProperty;

/**
 * ...
 * @author aeveis
 */
class DustEmitter extends MultiEmitter
{
	public static var instance:DustEmitter;

	public var isSmoke:Bool = true;
	public var useAccelY:Bool = false;
	public var accelY:Float = 0;

	public var isCloudEmit:Bool = false;

	public function new()
	{
		super(250);

		loadGraphic(AssetPaths.dust__png, true, 8, 8);
		animation.add("0_right", [0], 10, false);
		animation.add("1_right", [1], 10, false);
		animation.add("2_right", [2], 10, false);
		animation.add("3_right", [3], 10, false);
		animation.add("4_right", [4], 10, false);
		animation.add("5_right", [5], 10, false);
		animation.add("6_right", [6], 10, false);
		animation.add("7_right", [7], 10, false);
		animation.add("8_right", [8], 10, false);
		animation.add("0_left", [9], 10, false);
		animation.add("1_left", [10], 10, false);
		animation.add("2_left", [11], 10, false);
		animation.add("3_left", [12], 10, false);
		animation.add("4_left", [13], 10, false);
		animation.add("5_left", [14], 10, false);
		animation.add("6_left", [15], 10, false);
		animation.add("7_left", [16], 10, false);
		animation.add("8_left", [17], 10, false);
		animation.play("0_right");
		width = 8;
		height = 8;

		minLifespan = 0.5;
		maxLifespan = 1;

		color = 0xff000000;

		instance = this;
	}

	public function floorPoof()
	{
		minVelX = -1.0;
		maxVelX = 1.0;
		minVelY = -1.0;
		maxVelY = -1.0;

		if (FlxG.random.bool(15))
		{
			emitParticle(x, y);
		}
		if (isCloudEmit)
		{
			cloudPoof();
		}
	}

	public function backPoof()
	{
		minVelX = -1.0;
		maxVelX = 1.0;
		minVelY = -1.0;
		maxVelY = -1.0;

		if (FlxG.random.bool(3))
		{
			emitParticle(x, y);
		}
		if (isCloudEmit)
		{
			cloudPoof();
		}
	}

	public function constantPoof()
	{
		minVelX = -10;
		maxVelX = 10;
		minVelY = -10;
		maxVelY = -10;

		if (FlxG.random.bool(5))
		{
			emitParticle(x, y);
		}

		if (isCloudEmit)
		{
			cloudPoof();
		}
	}

	public function rightPoof()
	{
		minVelX = 0.5;
		maxVelX = 3.0;
		minVelY = -1.0;
		maxVelY = 1.0;
		for (i in 0...2)
		{
			emitParticle(x, y);
		}
	}

	public function leftPoof()
	{
		minVelX = -3.0;
		maxVelX = -0.5;
		minVelY = -1.0;
		maxVelY = 1.0;
		for (i in 0...2)
		{
			emitParticle(x, y);
		}
	}

	public function upPoof()
	{
		minVelY = 0.5;
		maxVelY = 3.0;
		minVelX = -1.0;
		maxVelX = 1.0;
		for (i in 0...2)
		{
			emitParticle(x, y);
		}
	}

	public function downPoof()
	{
		minVelY = -3.0;
		maxVelY = -0.5;
		minVelX = -1.0;
		maxVelX = 1.0;
		for (i in 0...2)
		{
			emitParticle(x, y);
		}
	}

	public function dashPoof(angle:Float, dist:Float)
	{
		minVelX = -10 * Math.cos(angle);
		maxVelX = -30 * Math.cos(angle);
		minVelY = -30;
		maxVelY = -40 * Math.sin(angle);
		for (i in 0...Math.floor(dist))
		{
			emitParticle(x + i * Math.cos(angle), y + i * Math.sin(angle));
		}
		minVelX = -10 * Math.cos(angle);
		maxVelX = -50 * Math.cos(angle);
		minVelY = -10 * Math.sin(angle);
		maxVelY = -50 * Math.sin(angle);
		for (i in 0...20)
		{
			emitParticle(x - i, y - FlxG.random.float(0, 10));
		}
	}

	public function dashEndPoof()
	{
		minVelX = -50;
		maxVelX = 50;
		minVelY = -10;
		maxVelY = -2;

		for (i in 0...12)
		{
			emitParticle(x, y);
			emitParticle(x, y - 2);
		}
	}

	public function shieldEffect(radius:Float)
	{
		var pangle:Float = FlxG.random.float(0, 6.28);
		radius *= 0.8;
		minVelX = -5;
		maxVelX = 5;
		minVelY = -5;
		maxVelY = 5;
		if (FlxG.random.bool(40))
		{
			emitParticle(x + radius * Math.cos(pangle), y + radius * Math.sin(pangle));
		}
	}

	public function shieldHit(radius:Float)
	{
		radius *= 0.95;
		minVelX = -15;
		maxVelX = 15;
		minVelY = -50;
		maxVelY = 15;
		color = 0x00c9ff;
		isSmoke = false;
		for (i in 0...30)
		{
			var pangle:Float = FlxG.random.float(0, 6.28);
			emitParticle(x + radius * Math.cos(pangle), y + radius * Math.sin(pangle));
		}
		isSmoke = true;
		color = FlxColor.WHITE;
	}

	public function moteEffect()
	{
		minVelX = -20;
		maxVelX = 20;
		minVelY = -30;
		maxVelY = 5;
		color = 0x2bf2ff;
		randomInSize = false;
		isSmoke = false;
		if (FlxG.random.bool(40))
		{
			emitParticle(x, y);
		}
		randomInSize = true;
		isSmoke = true;
		color = FlxColor.WHITE;
	}

	public function cryEffect()
	{
		minVelX = -10;
		maxVelX = 10;
		minVelY = 0;
		maxVelY = 10;
		color = 0x00ffd9;
		accelY = 2;
		useAccelY = true;
		randomInSize = false;
		isSmoke = false;
		if (FlxG.random.bool(10))
		{
			emitParticle(x, y);
		}
		minVelX = -20;
		maxVelX = 20;
		minVelY = -10;
		maxVelY = -20;
		if (FlxG.random.bool(2))
		{
			emitParticle(x, y);
		}
		isSmoke = true;
		randomInSize = true;
		useAccelY = false;
		color = FlxColor.WHITE;
	}

	public function poof()
	{
		minVelX = -45;
		maxVelX = 45;
		minVelY = -45;
		maxVelY = 45;
		for (i in 0...10)
		{
			emitParticle(x, y);
		}
	}

	public function largePoof()
	{
		width = 32;
		height = 32;
		minVelX = -65;
		maxVelX = 65;
		minVelY = -65;
		maxVelY = 65;
		for (i in 0...20)
		{
			emitParticle(x, y);
		}
		width = 8;
		height = 8;
	}

	public function fireflyPoof()
	{
		minVelX = -55;
		maxVelX = 55;
		minVelY = -55;
		maxVelY = 55;
		isSmoke = false;
		for (i in 0...30)
		{
			if (i < 10)
				color = 0xd5ff37;
			else if (i < 20)
				color = 0x7dee45;
			else
				color = 0xb26a36;
			emitParticle(x, y);
		}
		color = FlxColor.WHITE;
		isSmoke = true;
	}

	public function smallPoof()
	{
		minVelX = -55;
		maxVelX = 55;
		minVelY = -55;
		maxVelY = 55;
		for (i in 0...10)
		{
			emitParticle(x, y);
		}
	}

	public function tinyPoof()
	{
		minVelX = -55;
		maxVelX = 55;
		minVelY = -55;
		maxVelY = 55;
		minLifespan = 0.25;
		maxLifespan = 0.35;
		for (i in 0...3)
		{
			emitParticle(x, y);
		}
		minLifespan = 0.5;
		maxLifespan = 1;
	}

	public function cloudPoof()
	{
		minVelX = -30;
		maxVelX = 30;
		minVelY = -30;
		maxVelY = -30;

		color = 0xfffacc;
		isSmoke = false;
		if (FlxG.random.bool(10))
		{
			emitParticle(x, y);
		}

		color = FlxColor.WHITE;
		isSmoke = true;
	}

	override function initParticle(sp:SpriteProperty)
	{
		super.initParticle(sp);
		if (useAccelY)
		{
			sp.accelY = accelY;
		}
	}

	override function spriteUpdate(sp:SpriteProperty, elapsed:Float)
	{
		super.spriteUpdate(sp, elapsed);

		sp.velocityX += FlxG.random.float(-1, 1);
		sp.velocityY += FlxG.random.float(-1, 1);
		var frameNum:Int = Math.floor(ratio * 9);
		if (frameNum == 9)
		{
			frameNum = 8;
		}
		if (sp.velocityX > 0)
		{
			sp.anim = frameNum + "_right";
		}
		else
		{
			sp.anim = frameNum + "_left";
		}
	}
}
