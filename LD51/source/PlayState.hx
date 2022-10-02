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
import flixel.system.debug.interaction.tools.Eraser;
import flixel.text.FlxText.FlxTextAlign;
import flixel.tile.FlxTilemap;
import flixel.util.FlxColor;
import global.G;
import global.TextConstants;
import objs.Checkpoint;
import objs.DustEmitter;
import objs.Feather;
import objs.Object;
import objs.Platform;
import objs.Player;
import util.Input;
import util.TiledLevel;
import util.ui.UIBitmapText;
import util.ui.UIContainer.UILayout;
import util.ui.UIContainer.UIPlacement;
import util.ui.UIContainer;

class PlayState extends FlxState
{
	public static var instance:PlayState;

	public var level:TiledLevel;
	public var tilemap:FlxTilemap;
	public var fadeComplete:Bool = false;
	public var followCam:FlxObject = null;

	public var player:Player;
	public var ui:UIContainer;
	public var timerUI:UIContainer;
	public var timerText:UIBitmapText;
	public var checkpointText:UIBitmapText;
	public var scoreUI:UIContainer;
	public var scoreText:UIBitmapText;
	public var dashUI:UIContainer;
	public var featherIcon:Feather;
	public var dashText:UIBitmapText;
	public var controlText:UIBitmapText;
	public var checkpoints:FlxTypedGroup<Checkpoint>;
	public var checkpointMap:Map<Int, Checkpoint>;
	public var feathers:FlxTypedGroup<Feather>;
	public var feathersMap:Map<Int, Array<Feather>>;
	public var platforms:FlxTypedGroup<Platform>;
	public var dustEmit:DustEmitter;

	public var timer:Float = 0;
	public var counting:Bool = false;

	public var onCheckpoint:Bool = false;
	public var raceStarted:Bool = false;
	public var goldLevel:Int;
	public var untetheredLevel:Int;
	public var totalTime:Float = 0;

	override public function create()
	{
		super.create();
		instance = this;
		cameras = [camera];
		FlxG.mouse.useSystemCursor = true;
		FlxG.camera.bgColor = 0xf9dca1;
		FlxG.camera.pixelPerfectRender = true;
		Input.control = new Input();
		Input.control.platformerSetup();

		checkpoints = new FlxTypedGroup<Checkpoint>();
		checkpointMap = new Map<Int, Checkpoint>();
		feathers = new FlxTypedGroup<Feather>();
		feathersMap = new Map<Int, Array<Feather>>();
		platforms = new FlxTypedGroup<Platform>();
		dustEmit = new DustEmitter();

		ui = new UIContainer(UIPlacement.Top, UISize.XFill(20));
		ui.scrollFactor.set(0, 0);

		timerUI = new UIContainer(UIPlacement.Center, UISize.Size(64, 16), UIPlacement.Center, UILayout.top(2));
		timerText = new UIBitmapText("0.0");
		timerText.setPadding(UILayout.horivert(2, 3), true);
		timerText.setColor(0x56ddd7);
		checkpointText = new UIBitmapText("Safe Zone");
		checkpointText.setPadding(UILayout.horivert(2, 3), true);
		checkpointText.setColor(0x59c316);
		timerUI.add(timerText);
		timerUI.add(new FlxSprite(0, 0, AssetPaths.timer__png));
		timerUI.add(checkpointText);
		ui.add(timerUI);

		scoreUI = new UIContainer(UIPlacement.Right, UISize.Size(64, 16), UIPlacement.Right, UILayout.top(2));
		scoreText = new UIBitmapText("0/0");
		scoreText.setPadding(UILayout.horivert(1, 3));
		scoreUI.add(scoreText);
		scoreUI.add(new FlxSprite(0, 0, AssetPaths.flag__png));
		ui.add(scoreUI);

		dashUI = new UIContainer(UIPlacement.Left, UISize.Size(48, 16), UIPlacement.Left, UILayout.top(2));
		dashText = new UIBitmapText("0");
		dashText.setPadding(UILayout.horivert(2, 3));
		dashText.setSizeToText();
		featherIcon = new Feather(0, 0, Feather.NORMAL);
		featherIcon.state = Object.NONE;
		controlText = new UIBitmapText("");
		controlText.setColor(0x56ddd7);
		controlText.setPadding(UILayout.horivert(2, 3));
		controlText.setSizeToText();
		dashUI.add(dashText);
		dashUI.add(featherIcon);
		dashUI.add(controlText);
		ui.add(dashUI);

		level = new TiledLevel(AssetPaths.level0__tmx);
		tilemap = level.loadTileMap("tiles");
		for (i in 0...(level.gid + 1))
		{
			tilemap.setTileProperties(i, FlxObject.NONE);
		}
		for (i in(level.gid + 1)...(level.gid + 15))
		{
			tilemap.setTileProperties(i, FlxObject.ANY);
		}
		level.loadObjects("entities", loadObj);
		FlxG.camera.setScrollBoundsRect(tilemap.x, tilemap.y, level.fullWidth, level.fullHeight);

		var bg = new FlxSprite(0, 0, AssetPaths.bg__png);
		bg.scrollFactor.set(0.2, 0.2);
		add(bg);
		add(tilemap);
		add(platforms);
		add(checkpoints);
		add(feathers);
		add(dustEmit);
		add(player);
		add(ui);

		/*followCam = new FlxObject();
			followCam.x = player.x;
			followCam.y = player.y; */
		FlxG.camera.follow(player, FlxCameraFollowStyle.PLATFORMER);

		// FlxG.sound.playMusic("unrest", 0);

		if (!G.startInput)
		{
			// FlxG.sound.music.pause();
		}
		G.level = -1;
		G.score = 0;
		G.maxLevel = G.maxScore = checkpoints.members.length;
		scoreText.text = G.score + "/" + G.maxScore;
		scoreText.setSizeToText();
		scoreUI.refreshChildren();
		fade(0.3, true, fadeOnComplete, 0xf9dca1);
	}

	public function loadObj(pobj:TiledObject, px:Float, py:Float)
	{
		var pname:String = pobj.name;

		switch (pname)
		{
			case "player":
				player = new Player(px, py);
			case "checkpoint":
				var level = pobj.properties.contains("level") ? Std.parseInt(pobj.properties.get("level")) : -1;
				if (level == -1)
				{
					trace("checkpoint's level not set");
				}
				var checkpoint:Checkpoint = new Checkpoint(px, py);
				checkpoint.level = level;
				checkpointMap.set(level, checkpoint);
				checkpoints.add(checkpoint);
			case "feather":
				var level = pobj.properties.contains("level") ? Std.parseInt(pobj.properties.get("level")) : -1;
				if (level == -1)
				{
					trace("checkpoint's level not set");
				}
				var type:String = pobj.properties.contains("type") ? pobj.properties.get("type") : "normal";
				var fstate:Int = Feather.NORMAL;
				switch (type)
				{
					case "gold":
						fstate = Feather.GOLD;
						goldLevel = level;
					case "untethered":
						fstate = Feather.UNTETHERED;
						untetheredLevel = level;
					default:
				}
				var feather:Feather = new Feather(px, py, fstate);
				var array:Array<Feather> = feathersMap.get(level);
				if (array == null)
				{
					array = new Array<Feather>();
				}
				array.push(feather);
				feathersMap.set(level, array);
				feathers.add(feather);
			case "platform":
				platforms.add(new Platform(px, py));
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
		if (!fadeComplete)
			return;
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
			// super.update(elapsed);

			return;
		}

		// followCam.x = (followCam.x * 9 + player.followPoint.x) / 10;
		// followCam.y = player.followPoint.y;

		FlxG.collide(tilemap, player);
		FlxG.collide(platforms, player, checkPlatform);
		onCheckpoint = FlxG.overlap(checkpoints, player, reachCheckpoint);
		if (!onCheckpoint && raceStarted)
		{
			counting = true;
			checkpointText.text = "";
			checkpointText.setSizeToText();
			timerUI.refreshChildren();
		}
		FlxG.overlap(feathers, player, collectFeather);

		super.update(elapsed);

		if (counting)
		{
			timer += elapsed;
			timerText.text = Math.floor(timer) + "." + Math.floor(timer * 10) % 10;
			if (timer > 10)
			{
				timerText.setColor(FlxColor.RED);
			}
			else
			{
				timerText.setColor(FlxColor.WHITE);
			}
			timerText.setSizeToText();
			timerUI.refreshChildren();
		}

		if (FlxG.keys.justPressed.RBRACKET)
		{
			G.level++;
			setToLevel(cast Math.min(G.maxLevel, G.level));
		}
		if (FlxG.keys.justPressed.LBRACKET)
		{
			G.level--;
			setToLevel(cast Math.max(0, G.level));
		}
		if (Input.control.keys.get("restart").justPressed)
		{
			if (G.level <= G.maxLevel)
			{
				setToLevel(G.level);
			}
			else
			{
				restart();
			}
		}
		if (Input.control.keys.get("restart").justPressed && FlxG.keys.pressed.SHIFT)
		{
			restart();
		}
	}

	public function checkPlatform(pf:Platform, p:Player)
	{
		if (player.dashing.soft && player.dashUntethered)
		{
			pf.breakPlatform();
			dustEmit.x = pf.x;
			dustEmit.y = pf.y;
			dustEmit.cloudPoof();
		}
	}

	public function setToLevel(level:Int)
	{
		var checkpoint:Checkpoint = checkpointMap.get(level);
		if (checkpoint == null)
			return;
		// followCam.x = player.followPoint.x = player.x = checkpoint.x;
		// followCam.y = player.followPoint.y = player.y = checkpoint.y - 1;
		player.x = checkpoint.x;
		player.y = checkpoint.y - 1;

		player.dashCount = 0;
		if (level > untetheredLevel)
		{
			setFeatherState(Feather.UNTETHERED);
		}
		else if (level > goldLevel)
		{
			setFeatherState(Feather.GOLD);
		}
		else
		{
			setFeatherState(Feather.NORMAL);
		}
		player.update(FlxG.elapsed);

		timer = 0;

		for (i in 0...(level + 1))
		{
			var array:Array<Feather> = feathersMap.get(i);
			if (array == null)
				continue;
			for (f in array)
			{
				f.reactivate();
			}
		}
		for (i in(level + 1)...(G.maxLevel + 1))
		{
			var cp:Checkpoint = checkpointMap.get(i);
			if (cp == null)
				continue;

			cp.switchState(Checkpoint.IDLE);
		}

		if (G.score > level)
		{
			G.score = level;
			scoreText.text = G.score + "/" + G.maxScore;
			scoreText.setSizeToText();
			scoreUI.refreshChildren();
		}
	}

	public function reachCheckpoint(cp:Checkpoint, p:Player)
	{
		if (cp.state == Checkpoint.IDLE)
		{
			raceStarted = true;
			if (timer >= 10.1)
			{
				cp.switchState(Checkpoint.FAIL);
			}
			else
			{
				cp.switchState(Checkpoint.SUCCESS);
				G.score++;
				scoreText.text = G.score + "/" + G.maxScore;
				scoreText.setSizeToText();
				scoreUI.refreshChildren();
				timerText.setColor(0x59c316);
				totalTime += timer;
			}
			G.level = cp.level;
			timer = 0;
		}
		if (checkpointText.text != "Safe Zone")
		{
			checkpointText.text = "Safe Zone";
			checkpointText.setSizeToText();
			timerUI.refreshChildren();
			counting = false;
		}
	}

	public function collectFeather(f:Feather, p:Player)
	{
		if (f.state == Object.BOUNCE)
		{
			f.collect();
			switch (f.featherState)
			{
				case Feather.GOLD:
					player.dashLimited = false;
					featherIcon.setFeatherState(f.featherState);
					dashText.text = "#";
					dashText.setSizeToText();
					dashUI.refreshChildren();
				case Feather.UNTETHERED:
					player.dashLimited = false;
					player.dashUntethered = true;
					featherIcon.setFeatherState(f.featherState);
					dashText.text = "??";
					dashText.setSizeToText();
					dashUI.refreshChildren();
				default:
					player.dashCount++;
					updateDashCount();
			}
		}
	}

	public function setFeatherState(featherState:Int)
	{
		featherIcon.setFeatherState(featherState);
		switch (featherState)
		{
			case Feather.GOLD:
				player.dashLimited = false;
				player.dashUntethered = false;
				dashText.text = "#";
				dashText.setSizeToText();
				dashUI.refreshChildren();
			case Feather.UNTETHERED:
				player.dashLimited = false;
				player.dashUntethered = true;
				dashText.text = "??";
				dashText.setSizeToText();
				dashUI.refreshChildren();
			default:
				player.dashLimited = true;
				player.dashUntethered = false;
				updateDashCount();
		}
	}

	public function updateDashCount()
	{
		dashText.text = player.dashCount + "";
		dashText.setSizeToText();
		if (player.dashCount > 0)
		{
			controlText.text = "[X]";
		}
		else
		{
			controlText.text = "";
		}
		controlText.setSizeToText();
		dashUI.refreshChildren();
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
