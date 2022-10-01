package;

import flixel.FlxCamera.FlxCameraFollowStyle;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.editors.tiled.TiledObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;
import global.G;
import global.TextConstants;
import util.Input;
import util.TiledLevel;
import util.ui.UIContainer.UILayout;
import util.ui.UIContainer.UIPlacement;

class PlayState extends FlxState
{
	public static var instance:PlayState;

	public var level:TiledLevel;
	public var tilemap:FlxTilemap;
	public var fadeComplete:Bool = false;
	public var followCam:FlxObject = null;

	override public function create()
	{
		super.create();
		instance = this;
		cameras = [camera];
		FlxG.mouse.useSystemCursor = true;
		FlxG.camera.bgColor = 0xffffff;
		FlxG.camera.pixelPerfectRender = true;
		Input.control = new Input();
		Input.control.platformerSetup();

		level = new TiledLevel(AssetPaths.level0__tmx);
		tilemap = level.loadTileMap("tiles", "tiles");
		for (i in 0...1)
		{
			tilemap.setTileProperties(i, FlxObject.NONE);
		}
		for (i in 1...15)
		{
			tilemap.setTileProperties(i, FlxObject.ANY);
		}
		level.loadObjects("entities", loadObj);
		FlxG.camera.setScrollBoundsRect(tilemap.x, tilemap.y, level.fullWidth, level.fullHeight);

		add(tilemap);

		/*followCam = new FlxObject();
			followCam.x = player.x;
			followCam.y = player.y;
			FlxG.camera.follow(followCam, FlxCameraFollowStyle.PLATFORMER);
		 */

		// FlxG.sound.playMusic("unrest", 0);

		if (!G.startInput)
		{
			// FlxG.sound.music.pause();
		}

		fade(0.3, true, fadeOnComplete);
	}

	public function loadObj(pobj:TiledObject, px:Float, py:Float)
	{
		var pname:String = pobj.name;

		switch (pname)
		{
			case "player":
			// player = new Player(px, py);
			default:
				/*var obj:Object = new Object(px, py, pname);
					obj.state = Object.NONE;
					objs.add(obj);

					var textArray:Array<String> = Reflect.getProperty(TextConstants, pname);
					if (textArray == null)
					{
						return;
					}
					obj.textTrigger = addTextTrigger(px, py, pobj.width, pobj.height, pname, textArray);
					obj.textTrigger.setActive(false); */
		}
	}

	override public function update(elapsed:Float)
	{
		Input.control.update(elapsed);
		super.update(elapsed);
		if (!G.startInput)
		{
			if (Input.control.any || Input.control.keys.get("select").pressed)
			{
				G.startInput = true;
				// FlxG.sound.music.fadeIn(1, 0, 1);
				if (Input.control.keys.get("select").justPressed)
				{
					// G.playSound("confirm");
				}
			}
			/*if (!FlxG.overlap(textTriggers, player, checkText))
				{
					textbox.hasMoreText = false;
					if (Input.control.keys.get("select").justPressed)
					{
						textbox.skipTyping();
					}
			}*/
			super.update(elapsed);

			return;
		}

		if (Input.control.keys.get("restart").justPressed)
		{
			G.level = 0;
			restart();
		}
	}

	public function fade(pDuration:Float, pFadeIn:Bool = false, ?pCallback:Void->Void, ?Color:Int)
	{
		if (Color == null)
		{
			Color = 0xffffffff;
		}
		FlxG.camera.fade(Color, pDuration, pFadeIn, pCallback);
	}

	public function restart(fadeTime:Float = 0.1):Void
	{
		fade(fadeTime, false, refreshState);
		fadeComplete = false;
		if (FlxG.sound.music != null)
		{
			// FlxG.sound.music.fadeOut(.3);
		}
	}

	public function fadeOnComplete():Void
	{
		fadeComplete = true;
	}

	public function refreshState():Void
	{
		G.startInput = false;
		FlxG.switchState(new PlayState());
	}
}
