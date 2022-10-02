package objs;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;

/**
 * ...
 * @author aeveis
 */
class Platform extends FlxSprite
{
	public function new(px:Float, py:Float)
	{
		super(px, py);
		loadGraphic(AssetPaths.platform__png);
		solid = true;
		immovable = true;
		allowCollisions = FlxObject.UP;
	}

	public function breakPlatform()
	{
		visible = false;
		solid = false;
	}
}
