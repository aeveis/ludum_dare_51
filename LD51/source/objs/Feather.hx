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
	public function new(px:Float, py:Float)
	{
		super(px, py, "dashFeather");
		state = Object.BOUNCE;
		showState = Object.SHOWN;
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
