package objs;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;
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
	AirDash;
	Crouch;
	Stun;
}

class Player extends FlxSprite
{
	public static var instance:Player;

	public var moveSpeed:Float = 380;
	public var groundBoost:Float = 60;
	public var airMoveSpeed:Float = 250;
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
	public var airDashStrength:Float = 300;
	public var airDashDiagonalStrength:Float;
	public var maxDashVelocity = 400;
	public var maxMoveVelocity = 120;

	public var elapsed:Float = 0;
	public var fsm:FSM;
	public var control:Bool = true;

	public var onGround:TimedBool;
	public var jumping:TimedBool;
	public var jumpCooldown:TimedBool;
	public var dashing:TimedBool;
	public var dashCooldown:TimedBool;
	public var delayedDash:Bool = false;
	public var stunned:TimedBool;

	public var dashLimited:Bool = true;
	public var dashUntethered:Bool = true;
	public var dashCount:Int = 0;
	public var normalDashTime:Float = 0.15;
	public var untetheredDashTime:Float = 0.2;

	public var followPoint:FlxPoint;
	public var followOffset:Float = 3;

	public function new(px:Float, py:Float)
	{
		super(px, py + 4);

		loadGraphic(AssetPaths.skyjay__png, true, 16, 16);

		width = height = 12;
		centerOffsets();
		offset.y += 2;

		setFacingFlip(FlxObject.RIGHT, false, false);
		setFacingFlip(FlxObject.LEFT, true, false);
		facing = FlxObject.LEFT;

		maxVelocity.x = maxVelocity.y = maxMoveVelocity;
		drag.x = drag.y = idleDrag;
		acceleration.y = gravity;

		onGround = new TimedBool(0.15);
		jumping = new TimedBool(0.2);
		jumpCooldown = new TimedBool(0.3);
		dashing = new TimedBool(normalDashTime);
		dashCooldown = new TimedBool(0.2);
		stunned = new TimedBool(0.25);
		airDashDiagonalStrength = Math.sqrt(airDashStrength * airDashStrength / 2.0);

		animation.add("idle", [0], 5, false);
		animation.add("crouch", [5], 12, false);
		animation.add("land", [5, 2], 12, false);
		animation.add("walk", [1, 2, 0], 10, true);
		animation.add("jump", [5, 1, 3, 3, 6, 6], 15, false);
		animation.add("flap", [3, 6], 7, false);
		animation.add("fall", [3, 4], 6, false);
		animation.add("glide", [8, 7, 8, 9], 6, true);
		animation.add("airDash", [10, 13, 13, 13, 12, 11, 3], 50, false);
		animation.add("airDashDiaUp", [10, 16, 16, 16, 15, 14, 3], 50, false);
		animation.add("airDashDiaDown", [10, 19, 19, 19, 18, 17, 3], 50, false);
		animation.add("stun", [20, 21, 20, 21], 8, false);
		fsm = new FSM();

		fsm.addState(MoveState.Idle, idleEnter, idleUpdate);
		fsm.addState(MoveState.Walk, walkEnter, walkUpdate, walkLeave);
		fsm.addState(MoveState.Fall, fallEnter, fallUpdate);
		fsm.addState(MoveState.Jump, jumpEnter, jumpUpdate);
		fsm.addState(MoveState.Flap, flapEnter, flapUpdate);
		fsm.addState(MoveState.Glide, glideEnter, glideUpdate, glideLeave);
		fsm.addState(MoveState.Land, landEnter, landUpdate);
		fsm.addState(MoveState.AirDash, airDashEnter, airDashUpdate, airDashLeave);
		fsm.addState(MoveState.Crouch, crouchEnter, crouchUpdate);
		fsm.addState(MoveState.Stun, stunEnter, stunUpdate);
		fsm.switchState(MoveState.Idle);

		// followPoint = FlxPoint.get();
		// followPoint.set(x, y);
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

		dashCooldown.update(elapsed);
		dashing.update(elapsed);
		if (!dashCooldown.soft)
		{
			onGround.hard = isTouching(FlxObject.FLOOR);
			onGround.update(elapsed);
		}
		jumping.update(elapsed);
		jumpCooldown.update(elapsed);
		stunned.update(elapsed);
		fsm.update();
		super.update(elapsed);

		/*switch (facing)
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
		}*/
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
		animation.play("land");
	}

	private function crouchEnter()
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
		acceleration.y = gravity;
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

	private function stunEnter()
	{
		velocity.x = velocity.y = 0;
		followOffset = 3;
		stunned.trigger();
		animation.play("stun");
	}

	private function airDashEnter()
	{
		drag.x = drag.y = airDrag;
		followOffset = 2;
		acceleration.y = 1;
		maxVelocity.x = maxVelocity.y = maxDashVelocity;
		angle = 0;
		dashCooldown.trigger();
		dashing.trigger();

		/*trace("delayed left: " + Input.control.left.justPressedDelayed + " right: " + Input.control.right.justPressedDelayed + " up: "
				+ Input.control.up.justPressedDelayed + " down: " + Input.control.down.justPressedDelayed);
			trace("justpressed left: " + Input.control.left.justPressed + " right: " + Input.control.right.justPressed + " up: " + Input.control.up.justPressed
				+ " down: " + Input.control.down.justPressed);
			trace("pressed left: " + Input.control.left.pressed + " right: " + Input.control.right.pressed + " up: " + Input.control.up.pressed
				+ " down: " + Input.control.down.pressed); */

		delayedDash = !Input.control.anyJustPressed;

		var diagonal:Bool = Input.control.anyLeftRight;
		if (Input.control.left.justPressedDelayed)
		{
			facing = FlxObject.LEFT;
		}
		if (Input.control.right.justPressedDelayed)
		{
			facing = FlxObject.RIGHT;
		}

		if (Input.control.up.pressed || Input.control.up.justPressedDelayed)
		{
			if (facing == FlxObject.LEFT && diagonal)
			{
				velocity.x = -airDashDiagonalStrength;
				velocity.y = -airDashDiagonalStrength;
				animation.play("airDashDiaUp");
				return;
			}
			if (facing == FlxObject.RIGHT && diagonal)
			{
				velocity.x = airDashDiagonalStrength;
				velocity.y = -airDashDiagonalStrength;
				animation.play("airDashDiaUp");
				return;
			}
			if (facing == FlxObject.LEFT)
			{
				angle = 90;
			}
			else
			{
				angle = -90;
			}
			velocity.x = 0;
			velocity.y = -airDashStrength;
			animation.play("airDash");
			return;
		}
		if (Input.control.down.pressed || Input.control.down.justPressedDelayed)
		{
			if (facing == FlxObject.LEFT && diagonal)
			{
				velocity.x = -airDashDiagonalStrength;
				velocity.y = airDashDiagonalStrength;
				animation.play("airDashDiaDown");
				return;
			}
			if (facing == FlxObject.RIGHT && diagonal)
			{
				velocity.x = airDashDiagonalStrength;
				velocity.y = airDashDiagonalStrength;
				animation.play("airDashDiaDown");
				return;
			}

			if (facing == FlxObject.LEFT)
			{
				angle = -90;
			}
			else
			{
				angle = 90;
			}
			velocity.x = 0;
			velocity.y = airDashStrength;
			animation.play("airDash");
			return;
		}
		if (facing == FlxObject.LEFT)
		{
			velocity.x = -airDashStrength;
			velocity.y = 0;
			animation.play("airDash");
			return;
		}
		if (facing == FlxObject.RIGHT)
		{
			velocity.x = airDashStrength;
			velocity.y = 0;
			animation.play("airDash");
			return;
		}
	}

	private function airDashLeave()
	{
		acceleration.y = gravity;
		maxVelocity.x = maxVelocity.y = maxMoveVelocity;
		angle = 0;
	}

	private function idleUpdate()
	{
		if (Input.control.pressedBothX || Input.control.pressedBothY)
		{
			return;
		}
		if (canDash())
		{
			/*if (onGround.soft && Input.control.down.pressed)
				{
					fsm.switchState(MoveState.Crouch);
					return;
			}*/
			fsm.switchState(MoveState.AirDash);
			onGround.hard = false;
			return;
		}
		if (onGround.soft)
		{
			if (Input.control.down.justPressed)
			{
				fsm.switchState(MoveState.Crouch);
				return;
			}
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

	private function crouchUpdate()
	{
		if (canDash())
		{
			/*if (onGround.soft && Input.control.down.pressed)
				{
					fsm.switchState(MoveState.Crouch);
					return;
			}*/
			fsm.switchState(MoveState.AirDash);
			onGround.hard = false;
			return;
		}
		if (Input.control.pressedBothX || Input.control.pressedBothY)
		{
			return;
		}
		else if (Input.control.left.pressed)
		{
			facing = FlxObject.LEFT;
		}
		else if (Input.control.right.pressed)
		{
			facing = FlxObject.RIGHT;
		}

		if (onGround.soft)
		{
			if (!Input.control.down.pressed)
			{
				fsm.switchState(MoveState.Idle);
				return;
			}
			if (Input.control.up.justPressed)
			{
				fsm.switchState(MoveState.Jump);
				return;
			}
			return;
		}

		fsm.switchState(MoveState.Fall);
	}

	private function walkUpdate()
	{
		if (canDash())
		{
			/*if (onGround.soft && Input.control.down.pressed)
				{
					fsm.switchState(MoveState.Crouch);
					return;
			}*/
			fsm.switchState(MoveState.AirDash);
			onGround.hard = false;
			return;
		}
		if (onGround.soft)
		{
			move(moveSpeed);
			if (Input.control.down.justPressed)
			{
				fsm.switchState(MoveState.Crouch);
				return;
			}
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

		if (canDash())
		{
			fsm.switchState(MoveState.AirDash);
		}
		else if (Input.control.up.justPressed && !jumpCooldown.soft)
		{
			fsm.switchState(MoveState.Flap);
		}
		else if (Input.control.up.pressed || Input.control.keys.get("select").pressed)
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
		if (canDash())
		{
			fsm.switchState(MoveState.AirDash);
			onGround.hard = false;
			return;
		}
		move(moveSpeed);
		if (onGround.soft)
		{
			if (Input.control.down.pressed)
			{
				fsm.switchState(MoveState.Crouch);
				return;
			}
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
		if (canDash())
		{
			fsm.switchState(MoveState.AirDash);
			onGround.hard = false;
			return;
		}
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
			else if (Input.control.up.pressed || Input.control.keys.get("select").pressed)
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
		if (canDash())
		{
			fsm.switchState(MoveState.AirDash);
			onGround.hard = false;
			return;
		}
		if (onGround.hard)
		{
			fsm.switchState(MoveState.Land);
			return;
		}
		if (!jumping.soft)
		{
			if (canDash())
			{
				fsm.switchState(MoveState.AirDash);
			}
			else if (Input.control.up.justPressed && !jumpCooldown.soft)
			{
				fsm.switchState(MoveState.Flap);
				return;
			}
			else if (Input.control.up.pressed || Input.control.keys.get("select").pressed)
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
		if (onGround.hard)
		{
			fsm.switchState(MoveState.Land);
			return;
		}
		if (canDash())
		{
			fsm.switchState(MoveState.AirDash);
		}
		else if (Input.control.up.justPressed && !jumpCooldown.soft)
		{
			fsm.switchState(MoveState.Flap);
			return;
		}
		if (!Input.control.up.pressed && !Input.control.keys.get("select").pressed)
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

	private function airDashUpdate()
	{
		if (onGround.hard)
		{
			fsm.switchState(MoveState.Land);
			return;
		}

		if (!dashUntethered && isTouching(FlxObject.WALL | FlxObject.CEILING))
		{
			fsm.switchState(MoveState.Stun);
			return;
		}

		if (Input.control.anyJustPressed && (Input.control.keys.get("select").justPressedDelayed || dashUntethered))
		{
			fsm.switchState(MoveState.AirDash);
		}

		if (isTouching(FlxObject.FLOOR) && velocity.y > 10.0)
		{
			animation.stop();
			onGround.hard = true;
			fsm.switchState(MoveState.Land);
			return;
		}
		if (!dashing.soft && animation.finished)
		{
			if (Input.control.keys.get("select").pressed)
			{
				fsm.switchState(MoveState.Glide);
				return;
			}
			fsm.switchState(MoveState.Fall);
		}
	}

	private function stunUpdate()
	{
		if (!stunned.soft)
		{
			if (onGround.hard)
			{
				fsm.switchState(MoveState.Land);
				return;
			}
			fsm.switchState(MoveState.Fall);
		}
	}

	private function canDash()
	{
		if (dashUntethered)
		{
			dashing.setDelay(untetheredDashTime);
		}
		else
		{
			dashing.setDelay(normalDashTime);
		}

		var attemptDash:Bool = (Input.control.keys.get("select").justPressed && !dashCooldown.soft);
		if (attemptDash && dashLimited)
		{
			if (dashCount <= 0)
				return false;

			dashCount--;
			PlayState.instance.updateDashCount();
		}
		return attemptDash;
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
		}
		else if (Input.control.right.pressed)
		{
			velocity.x += elapsed * p_move_speed;
			facing = FlxObject.RIGHT;
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
