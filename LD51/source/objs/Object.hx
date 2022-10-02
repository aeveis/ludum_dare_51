package objs;

import flixel.FlxG;
import flixel.FlxSprite;
import ui.TextTrigger;

/**
 * ...
 * @author aeveis
 */
class Object extends FlxSprite
{
	private var timer:Float = 0;

	public static inline var NONE:Int = 0;
	public static inline var BOUNCE:Int = 1;
	public static inline var RISEFADE:Int = 2;
	public static inline var HIDE:Int = 3;

	public var state:Int = 0;
	public var sineAmount:Float = 1;
	public var sineSpeed:Float = 6;

	public var startY:Float = 0;

	public var name:String = "";

	public var showTime:Float = 1.0;
	public var showCounter:Float = 0;

	public static inline var FADE:Int = 0;
	public static inline var SHOWN:Int = 1;

	public var showState:Int = SHOWN;
	public var textTrigger:TextTrigger;

	public function new(px:Float, py:Float, pname:String = "")
	{
		super(px, py);
		startY = py;
		if (pname != "")
		{
			name = pname;
			loadGraphic(AssetPaths.getFile(pname));
		}
		// solid = true;
		timer = FlxG.random.float(0, 5);
	}

	public function show()
	{
		if (showState == SHOWN)
		{
			return;
		}

		showCounter += FlxG.elapsed;

		if (showCounter >= showTime)
		{
			showCounter = showTime;
			showState = SHOWN;
			state = BOUNCE;
			if (textTrigger != null)
			{
				textTrigger.setActive(true);
			}
		}
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		switch (state)
		{
			case BOUNCE:
				timer += elapsed * sineSpeed;
				y = startY + sineAmount * Math.sin(timer);
			case RISEFADE:
				y -= elapsed * 30;
				alpha -= elapsed * 5;
				if (alpha <= 0)
				{
					visible = false;
					alpha = 1;
					y = startY;
					state = HIDE;
				}
			default:
		}
		switch (state)
		{
			case FADE:
				if (showCounter > 0)
				{
					showCounter -= elapsed * 0.3;
					if (showCounter < 0)
					{
						showCounter = 0;
					}
				}
			case SHOWN:
			default:
		}
	}
}
