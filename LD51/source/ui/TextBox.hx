package ui;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.AniBitmapText;
import ui.Portrait;
import util.Input;
import util.InputState;
import util.ui.UIBitmapText;
import util.ui.UIContainer;
import util.ui.UIImage;

/**
 * ...
 * @author aeveis
 */
class TextBox extends UIImage
{
	private var charBox:UIImage;
	private var textBox:UIContainer;
	private var text:AniBitmapText;
	private var textCam:FlxCamera;
	private var textZoomRatio:Float;
	private var xbutton:UIBitmapText;
	private var xbuttonY:Float;
	private var xbuttonTimer:Float = 0;

	public var hasMoreText:Bool = false;

	private var charIcon:Portrait;

	public function new(p_bgImage:FlxGraphicAsset, p_placement:UIPlacement, p_size:UISize, ?p_textZoom:Float)
	{
		super(p_bgImage, p_placement, p_size, UIPlacement.Left, UILayout.sides(3), UILayout.hori(1));
		scrollFactor.set(0, 0);

		charBox = new UIImage(null, UIPlacement.Left, UISize.Size(36, 36), UIPlacement.Center, null, UILayout.sides(1));
		textBox = new UIContainer(UIPlacement.Left, UISize.Size(width - height - 40, height - 12));

		if (p_textZoom == _null)
			p_textZoom = 1;
		textZoomRatio = FlxG.initialZoom / p_textZoom;
		textCam = new FlxCamera(0, 0, Math.floor(textBox.width * textZoomRatio), Math.floor(textBox.height * textZoomRatio), p_textZoom);
		textCam.bgColor = 0;

		nineSlice(UILayout.sides(2));
		charBox.nineSlice(UILayout.sides(2));

		charIcon = new Portrait();
		charBox.add(charIcon);

		var font:FlxBitmapFont = FlxBitmapFont.fromAngelCode(AssetPaths.getFile("Easyable_0"), AssetPaths.getFile("Easyable", AssetPaths.LOC_DATA, "fnt"));
		text = new AniBitmapText(font);
		text.cameras = [textCam];
		text.alignment = FlxTextAlign.LEFT;
		text.wordWrap = true;
		text.setTyping();

		xbutton = new UIBitmapText("[X]", 5);
		xbutton.setColor(0x56ddd7);

		add(charBox);
		add(textBox);
		add(xbutton);
		textBox.add(text);

		text.text = "";

		FlxG.cameras.add(textCam);

		refreshTextPlacement();
		xbuttonY = xbutton.y;

		Input.setSwitchGamepadCallback(updateGamepadButton);
		Input.setSwitchKeysCallback(updateKeyboardButton);
	}

	public function updateGamepadButton()
	{
		var input:InputState = Input.control.keys.get("select");
		xbutton.text = "[" + Input.getGamepadInputString(input.gamepadMapping[input.lastChangedGamepadIndex]) + "]";
		refresh(true);
		refreshTextPlacement();
	}

	public function updateKeyboardButton()
	{
		var input:InputState = Input.control.keys.get("select");
		// trace(input.lastChangedIndex);
		xbutton.text = "[" + Input.getInputString(input.keyMapping[input.lastChangedIndex]) + "]";
		refresh(true);
		refreshTextPlacement();
	}

	public function setPortraitBorderColor(p_color:FlxColor)
	{
		charBox.color = p_color;
	}

	public function setPortraitBorderImage(p_bgImage:FlxGraphicAsset, p_nineSlice:Box, ?p_margin:Box)
	{
		charBox.setBG(p_bgImage);
		charBox.nineSlice(p_nineSlice);
		if (p_margin != null)
			charBox.setMargin(p_margin);

		refreshChildren();
	}

	public function setPortrait(p_image:FlxGraphicAsset, p_animated:Bool = false, p_width:Int = 0, p_height:Int = 0)
	{
		charIcon.loadGraphic(p_image, p_animated, p_width, p_height);
	}

	public function addAnim(p_name:String, p_frames:Array<Int>, p_framerate:Float = 10)
	{
		charIcon.animation.add(p_name, p_frames, p_framerate, true);
	}

	public function playAnim(p_name:String)
	{
		charIcon.animation.play(p_name);
	}

	public function playText(?p_text:String, ?p_typeSound:String, ?p_typeRandomAmount:Int)
	{
		if (p_typeSound != null)
		{
			if (p_typeRandomAmount != null)
			{
				text.setTypingSound(p_typeSound, p_typeRandomAmount);
			}
			else
			{
				text.setTypingSound(p_typeSound);
			}
		}
		if (p_text == null)
		{
			restartTyping();
			return;
		}
		text.text = p_text;
		if (AniBitmapText.noTyping)
		{
			text.skipTyping();
		}
	}

	public override function close()
	{
		super.close();
		text.skipTyping();
	}

	public function skipTyping()
	{
		if (isDoneTyping && !hasMoreText)
		{
			visible = false;
		}
		text.skipTyping();
	}

	public function restartTyping()
	{
		text.restartTyping();
	}

	public function pauseTyping()
	{
		text.pauseTyping = true;
	}

	public function unpauseTyping()
	{
		text.pauseTyping = false;
	}

	public var isDoneTyping(get, null):Bool;

	function get_isDoneTyping():Bool
	{
		return !text.isTyping;
	}

	public function hideXButton()
	{
		xbutton.visible = false;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (isDoneTyping)
		{
			xbuttonTimer += elapsed * 15;
			xbutton.y = xbuttonY + Math.sin(xbuttonTimer);
		}
		else
		{
			xbutton.y = xbuttonY;
		}
	}

	override public function refreshChildren()
	{
		super.refreshChildren();
		refreshTextPlacement();

		xbuttonY = xbutton.y;
	}

	private function refreshTextPlacement()
	{
		textCam.x = Math.floor(textBox.x * textZoomRatio);
		textCam.y = Math.floor(textBox.y * textZoomRatio);
		text.x = 0;
		text.y = 0;
		text.fieldWidth = Math.floor(textBox.width * textZoomRatio);
	}
}
