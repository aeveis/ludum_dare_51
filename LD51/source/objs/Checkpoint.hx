package objs;

import flixel.FlxG;
import flixel.FlxSprite;

/**
 * ...
 * @author aeveis
 */
class Checkpoint extends FlxSprite
{
	public static inline var IDLE:Int = 0;
	public static inline var SUCCESS:Int = 1;
	public static inline var FAIL:Int = 2;

	public var state:Int = IDLE;
	public var level:Int = -1;

	public function new(px:Float, py:Float)
	{
		super(px, py);
		loadGraphic(AssetPaths.checkpoint__png, true, 16, 16);

		animation.add("idle", [0], 5, false);
		animation.add("success", [1], 5, false);
		animation.add("fail", [2], 5, false);

		animation.play("idle");
	}

	public function switchState(p_state:Int)
	{
		state = p_state;
		switch (state)
		{
			case IDLE:
				animation.play("idle");
			case SUCCESS:
				animation.play("success");
			case FAIL:
				animation.play("fail");
		}
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
