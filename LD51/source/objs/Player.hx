package objs;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import global.G;
import util.FSM;
import util.Input;
import util.TimedBool;

enum MoveState
{
	Idle;
	Walk;
	Fall;
	Jump;
	Flap;
	Glide;
	Land;
}

class Player extends FlxSprite
{
	public static var instance:Player;

	public var moveSpeed:Float = 350;
	public var groundBoost:Float = 60;
	public var airMoveSpeed:Float = 200;
	public var airBoost:Float = 50;
	public var jumpStrength:Float = 120;
	public var jumpVariable:Float = 5;
	public var flapStrength:Float = 200;
	public var flapVariable:Float = 20;
	public var gravity:Float = 400;
	public var glideGravity:Float = 50;
	public var idleDrag:Float = 600;
	public var airDrag:Float = 150;
	public var moveDrag:Float = 250;

	public var elapsed:Float = 0;
	public var fsm:FSM;
	public var control:Bool = true;

	public var onGround:TimedBool;
	public var jumping:TimedBool;
	public var jumpCooldown:TimedBool;

	public var followPoint:FlxPoint;
	public var followOffset:Float = 3;

	public function new(px:Float, py:Float)
	{
		super(px, py);

		loadGraphic(AssetPaths.skyjay__png, true, 16, 16);

		setFacingFlip(FlxObject.RIGHT, false, false);
		setFacingFlip(FlxObject.LEFT, true, false);

		maxVelocity.x = 120;
		maxVelocity.y = 180;
		drag.x = idleDrag;
		drag.y = idleDrag;
		acceleration.y = gravity;

		onGround = new TimedBool(0.15);
		jumping = new TimedBool(0.2);
		jumpCooldown = new TimedBool(0.3);

		animation.add("idle", [0], 5, false);
		animation.add("crouch", [5, 2], 12, false);
		animation.add("walk", [1, 2, 0], 10, true);
		animation.add("jump", [5, 1, 3, 3, 6, 6], 15, false);
		animation.add("flap", [3, 6], 7, false);
		animation.add("fall", [3, 4], 6, false);
		animation.add("glide", [8, 7, 8, 9], 6, true);
		fsm = new FSM();

		fsm.addState(MoveState.Idle, idleEnter, idleUpdate);
		fsm.addState(MoveState.Walk, walkEnter, walkUpdate, walkLeave);
		fsm.addState(MoveState.Fall, fallEnter, fallUpdate);
		fsm.addState(MoveState.Jump, jumpEnter, jumpUpdate);
		fsm.addState(MoveState.Flap, flapEnter, flapUpdate);
		fsm.addState(MoveState.Glide, glideEnter, glideUpdate, glideLeave);
		fsm.addState(MoveState.Land, landEnter, landUpdate);
		fsm.switchState(MoveState.Idle);

		followPoint = FlxPoint.get();
		followPoint.set(x, y);
		instance = this;
	}

	override public function update(elapsed:Float):Void
	{
		if (!control)
		{
			return;
		}

		this.elapsed = elapsed;

		// DustEmitter.instance.x = x + width / 2;
		// DustEmitter.instance.y = y + height / 2;
		// DustEmitter.instance.constantPoof();

		onGround.hard = isTouching(FlxObject.FLOOR);
		onGround.update(elapsed);
		jumping.update(elapsed);
		jumpCooldown.update(elapsed);
		fsm.update();
		super.update(elapsed);

		switch (facing)
		{
			case FlxObject.LEFT:
				followPoint.x -= elapsed * moveSpeed;
				if (followPoint.x < x - FlxG.height / followOffset)
				{
					followPoint.x = x - FlxG.height / followOffset;
				}
				followPoint.y = y;
			case FlxObject.RIGHT:
				followPoint.x += elapsed * moveSpeed;
				if (followPoint.x > x + FlxG.height / followOffset)
				{
					followPoint.x = x + FlxG.height / followOffset;
				}
				followPoint.y = y;
			default:
		}
	}

	private function idleEnter()
	{
		drag.x = drag.y = idleDrag;

		followOffset = 3;
		animation.play("idle");
	}

	private function landEnter()
	{
		drag.x = drag.y = moveDrag;
		jumping.reset();
		jumpCooldown.reset();
		followOffset = 3;
		animation.play("crouch");
	}

	private function walkEnter()
	{
		drag.x = drag.y = moveDrag;
		followOffset = 2;
		animation.play("walk");
	}

	private function walkLeave()
	{
		animation.stop();
	}

	private function fallEnter()
	{
		drag.x = drag.y = airDrag;
		followOffset = 2;
	}

	private function jumpEnter()
	{
		drag.x = drag.y = airDrag;
		followOffset = 2;
		animation.play("jump");
		jump(jumpStrength, jumpVariable);
	}

	private function flapEnter()
	{
		drag.x = drag.y = airDrag;
		followOffset = 2;
		animation.play("flap");
		jump(flapStrength, flapVariable);
	}

	private function glideEnter()
	{
		drag.x = drag.y = airDrag;
		followOffset = 2;
		acceleration.y = glideGravity;
	}

	private function glideLeave()
	{
		acceleration.y = gravity;
		animation.stop();
	}

	private function idleUpdate()
	{
		if (Input.control.pressedBothX || Input.control.pressedBothY)
		{
			return;
		}

		if (onGround.soft)
		{
			if (Input.control.anyLeftRight)
			{
				fsm.switchState(MoveState.Walk);
			}
			if (Input.control.up.justPressed)
			{
				fsm.switchState(MoveState.Jump);
			}
			return;
		}

		fsm.switchState(MoveState.Fall);
	}

	private function walkUpdate()
	{
		if (onGround.soft)
		{
			move(moveSpeed);
			if (Input.control.up.justPressed)
			{
				fsm.switchState(MoveState.Jump);
			}
			if (!Input.control.anyLeftRight)
			{
				fsm.switchState(MoveState.Idle);
			}
			return;
		}

		fsm.switchState(MoveState.Fall);
	}

	private function fallUpdate()
	{
		if (onGround.soft)
		{
			fsm.switchState(MoveState.Land);
			return;
		}

		if (Input.control.up.justPressed && !jumpCooldown.soft)
		{
			fsm.switchState(MoveState.Flap);
		}
		else if (Input.control.up.pressed)
		{
			fsm.switchState(MoveState.Glide);
		}
		if (animation.finished)
		{
			animation.play("fall");
		}
		move(airMoveSpeed);
	}

	private function landUpdate()
	{
		move(moveSpeed);
		if (onGround.soft)
		{
			if (Input.control.up.justPressed)
			{
				fsm.switchState(MoveState.Jump);
			}
			if (animation.finished)
				fsm.switchState(MoveState.Idle);
			return;
		}

		fsm.switchState(MoveState.Fall);
	}

	private function jumpUpdate()
	{
		if (onGround.hard)
		{
			fsm.switchState(MoveState.Land);
			return;
		}
		if (!jumping.soft)
		{
			if (Input.control.up.justPressed && !jumpCooldown.soft)
			{
				fsm.switchState(MoveState.Flap);
				return;
			}
			else if (Input.control.up.pressed)
			{
				fsm.switchState(MoveState.Glide);
				return;
			}
			if (animation.finished)
				fsm.switchState(MoveState.Fall);
		}
		jump(jumpStrength, jumpVariable);
		move(airMoveSpeed);
	}

	private function flapUpdate()
	{
		if (onGround.soft)
		{
			fsm.switchState(MoveState.Land);
			return;
		}
		if (!jumping.soft)
		{
			if (Input.control.up.justPressed && !jumpCooldown.soft)
			{
				fsm.switchState(MoveState.Flap);
				return;
			}
			else if (Input.control.up.pressed)
			{
				fsm.switchState(MoveState.Glide);
				return;
			}
			fsm.switchState(MoveState.Fall);
		}
		jump(flapStrength, flapVariable);
		move(airMoveSpeed);
	}

	private function glideUpdate()
	{
		if (onGround.soft)
		{
			fsm.switchState(MoveState.Land);
			return;
		}
		if (Input.control.up.justPressed && !jumpCooldown.soft)
		{
			fsm.switchState(MoveState.Flap);
			return;
		}
		if (!Input.control.up.pressed)
		{
			fsm.switchState(MoveState.Fall);
			return;
		}
		if (animation.finished)
		{
			animation.play("glide");
		}
		move(airMoveSpeed);
	}

	private function move(p_move_speed:Float)
	{
		if (onGround.soft)
		{
			if (Input.control.left.justPressedDelayed && velocity.x > -10)
			{
				velocity.x -= groundBoost;
			}
			if (Input.control.right.justPressedDelayed && velocity.x < 10)
			{
				velocity.x += groundBoost;
			}
		}
		if (Input.control.pressedBothX) {}
		else if (Input.control.left.pressed)
		{
			velocity.x -= elapsed * p_move_speed;
			facing = FlxObject.LEFT;
			setFacingFlip(FlxObject.DOWN, true, false);
			setFacingFlip(FlxObject.UP, true, false);
		}
		else if (Input.control.right.pressed)
		{
			velocity.x += elapsed * p_move_speed;
			facing = FlxObject.RIGHT;
			setFacingFlip(FlxObject.DOWN, false, false);
			setFacingFlip(FlxObject.UP, false, false);
		}
	}

	private function jump(p_jump_strength:Float, p_jump_variable:Float)
	{
		if (Input.control.up.justPressed && !jumping.soft)
		{
			velocity.y -= p_jump_strength;
			if (velocity.y < -jumpStrength)
			{
				velocity.y = -jumpStrength;
			}
			jumping.trigger();
			jumpCooldown.trigger();
			if (Input.control.left.justPressedDelayed)
			{
				velocity.x -= airBoost;
			}
			else if (Input.control.right.justPressedDelayed)
			{
				velocity.x += airBoost;
			}
		}
		else if (Input.control.up.pressed && jumping.soft)
		{
			velocity.y -= elapsed * p_jump_variable;
		}

		if (Input.control.down.pressed)
		{
			// velocity.y += elapsed * p_move_speed;
		}
	}
}
