package util.ui;

import flixel.graphics.frames.FlxBitmapFont;
import flixel.system.FlxAssets.FlxShader;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import util.ui.UIContainer.UIPlacement;
import util.ui.UIContainer.UISize;

/**
 * Text class to handle specific text settings for UI
 * Uses set FlxBitmapText for now
 * @author aeveis
 */
class UIText extends UIContainer
{
	var textSprite:FlxText;

	public var heightOffset:Float = 0;

	public var text(default, set):String = "";

	private var typeTextShader:TypeTextShader;
	private var ratio:Float = 0;
	private var lines:Float = 0;
	private var isTypeText:Bool = false;
	private var isTyping:Bool = false;
	private var typeSpeed:Float = 16.0;

	function set_text(p_text:String):String
	{
		textSprite.text = p_text;
		lines = textSprite.textField.numLines;
		typeTextShader.lines.value = [lines];
		setSizeToText();
		return text = p_text;
	}

	public function new(?p_text:String, _typeText:Bool = false, p_heightOffset:Float = 0)
	{
		super(UIPlacement.Inherit, UISize.Fill, UIPlacement.Inherit);
		typeTextShader = new TypeTextShader();

		setFont();
		add(textSprite);
		if (p_text != null)
			text = p_text;

		textSprite.shader = typeTextShader;

		isTypeText = _typeText;
		if (isTypeText)
		{
			setTypeRatio(0);
		}

		heightOffset = p_heightOffset;
		setSizeToText();
	}

	public function setTypeRatio(p_ratio:Float)
	{
		ratio = p_ratio;
		typeTextShader.ratio.value = [ratio];
	}

	public function setColor(p_color:FlxColor)
	{
		textSprite.color = p_color;
	}

	public function setSizeToText()
	{
		size = UISize.Size(textSprite.width * textSprite.scale.x, (textSprite.height - heightOffset) * textSprite.scale.y);
		refresh(true);
	}

	public function setFont(?fontPath:String)
	{
		if (fontPath == null)
		{
			fontPath = AssetPaths.EasyableOutline__ttf;
		}
		textSprite = new FlxText();
		textSprite.setFormat(fontPath, 16);
	}

	public function startTyping(pixelPerSec:Float = 64.0)
	{
		isTypeText = true;
		setTypeRatio(0);
		typeSpeed = pixelPerSec / width;
		isTyping = true;
	}

	public function skipTyping()
	{
		isTyping = false;
		setTypeRatio(1.0);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!isTypeText)
			return;
		if (!isTyping)
			return;

		ratio += elapsed * typeSpeed;
		if (ratio >= 1.0)
		{
			ratio = 1.0;
		}
		typeTextShader.ratio.value = [ratio];
		if (ratio == 1.0)
		{
			isTyping = false;
		}
	}
}

class TypeTextShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		#ifdef GL_ES
			precision mediump float;
		#endif
		
		uniform float ratio;
		uniform float lines;
		
		void main()
		{
			vec2 uv = openfl_TextureCoordv;
			
			vec4 col = texture2D(bitmap, uv);

			float totalratio = ratio * lines;
			float yline = uv.y * lines;

			if(floor(yline) > totalratio)
			{
				col *= 0.0;
			}
			if(col.a > 0.0)
			{
				float lineratio = mod(totalratio, 1.0);
				if(uv.x > lineratio && ceil(yline+0.01) > totalratio)
				{
					float fade = 1.0 - smoothstep(lineratio - 0.1, lineratio, uv.x);
					col *= fade;
				}
				
			}
			gl_FragColor = col;
		}
	')
	public function new()
	{
		super();
	}
}
