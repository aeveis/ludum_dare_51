package objs;

import flixel.FlxG;
import flixel.FlxSprite;
import ui.TextTrigger;

/**
 * ...
 * @author aeveis
 */
class Feather extends Object
{
	public static inline var NORMAL:Int = 0;
	public static inline var GOLD:Int = 1;
	public static inline var UNTETHERED:Int = 2;

	public var featherState:Int = NORMAL;

	public function new(px:Float, py:Float, p_featherState:Int)
	{
		super(px, py);
		loadGraphic(AssetPaths.dashFeather__png, true, 16, 16);
		animation.add("normal", [0], 5, false);
		animation.add("gold", [1], 5, false);
		animation.add("untethered", [2], 5, false);

		setFeatherState(p_featherState);

		state = Object.BOUNCE;
		showState = Object.SHOWN;
	}

	public function setFeatherState(fstate:Int)
	{
		featherState = fstate;
		switch (featherState)
		{
			case NORMAL:
				animation.play("normal");
			case GOLD:
				animation.play("gold");
			case UNTETHERED:
				animation.play("untethered");
		}
	}

	public function collect()
	{
		state = Object.RISEFADE;
	}

	public function reactivate()
	{
		state = Object.BOUNCE;
		alpha = 1.0;
		visible = true;
		y = startY;
	}
}
