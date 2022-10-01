package ui;
import flash.geom.Rectangle;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.graphics.frames.FlxFrame;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.util.FlxColor;
using flixel.util.FlxColorTransformUtil;

/**
 * Modified FlxBitmapText to allow for certain tags and text animation
 * Color Tag: <color=#aarrggbb></color>
 * @author aeveis
 */
class AniBitmapText extends FlxBitmapText
{
	
	private var colorTags:Array<ColorTag>;
	private var colorTagIndex:Int = 0;
	private var animTags:Array<AnimTag>;
	private var animTagIndex:Int = 0;
	private var count:Float = 0;
	private var rect:Rectangle;
	
	private var inAnimTag:Bool = false;
	private var animated:Bool = false;
	private var colored:Bool = false;
	private var parseAnimated:Bool = false;
	private var parseColored:Bool = false;
	
	private var typingCounter:Array<TypingProperty>;
	private var typingIndex:Int = 0;
	//is typing enabled?
	public var typing:Bool = true;
	private var typingCount:Float;
	private var typingLetterDelay:Float = 0.03;
	private var typingFadeInTime:Float = 0.1;
	private var typingYOffset:Float = 0;
	private var doneTypingIndex = 0;
	public var isTyping:Bool = false;
	public var typeSoundName:String = null;
	public var typeSoundCount:Int = 0;
	public var pauseTyping:Bool = false;
	
	static public var noAnimation:Bool = false;
	static public var noTyping:Bool = false;
	
	public function new(?font:FlxBitmapFont) 
	{
		super(font);
		autoSize = false;
		wordWrap = true;
		colorTags = new Array<ColorTag>();
		animTags = new Array<AnimTag>();
		typingCounter = new Array<TypingProperty>();
		rect = new Rectangle();
		//useTextColor = true;
	}
	public function setTyping(nextLetterDelay:Float = 0.01, letterFadeInTme:Float = 0.05, yOffsetIn:Float = 1)
	{
		typingLetterDelay = nextLetterDelay;
		typingFadeInTime = letterFadeInTme;
		typingYOffset = yOffsetIn;
		typing = true;
	}
	public function setTypingSound(soundName:String, soundRandomCount:Int = 0)
	{
		typeSoundName = soundName;
		typeSoundCount = soundRandomCount;
	}
	
	public function skipTyping()
	{
		isTyping = false;
	}
	
	public function restartTyping()
	{
		typingCount = 0;
		typingIndex = 0;
		doneTypingIndex = 0;
		isTyping = true;
		for (tprop in typingCounter)
		{
			tprop.alpha = 0;
			tprop.yoffset = typingYOffset;
		}
	}
	override public function update(elapsed:Float)
	{
		if (animated || isTyping)
		{
			pendingTextBitmapChange = true;
		}
		
		super.update(elapsed);
		count += elapsed;
		
		if (noTyping)
		{
			return;
		}
		if (typing && isTyping && !pauseTyping)
		{
			typingCount += elapsed;
			if (typingCount >= typingLetterDelay)
			{
				if (typeSoundName != null && typingIndex%2==0)
				{
					FlxG.sound.play(typeSoundName + FlxG.random.int(0, typeSoundCount), 0.2);
				}
				typingCount = 0;
				typingIndex++;
				if (typingIndex >= typingCounter.length)
				{
					typingIndex = typingCounter.length - 1;
					if (typingCounter[typingIndex].alpha >= 1)
					{
						isTyping = false;
					}
				}
			}
			for (i in doneTypingIndex...typingIndex + 1)
			{
				typingCounter[i].alpha += elapsed / typingFadeInTime;
				typingCounter[i].yoffset = typingYOffset * (1 - typingCounter[i].alpha);
				if (typingCounter[i].alpha >= 1)
				{
					typingCounter[i].alpha = 1;
					typingCounter[i].yoffset = 0;
					doneTypingIndex = i;
				}
			}
		}
	}
	override public function draw():Void 
	{
		if (text == null)
		{
			return;
		}
		
		if (FlxG.renderBlit)
		{
			checkPendingChanges(false);
			super.draw();
		}
		else
		{
			checkPendingChanges(true);
			
			var textLength:Int = Std.int(textDrawData.length / 3);
			var borderLength:Int = Std.int(borderDrawData.length / 3);
			
			var dataPos:Int;
			
			var cr:Float = color.redFloat;
			var cg:Float = color.greenFloat;
			var cb:Float = color.blueFloat;
			
			var borderRed:Float = borderColor.redFloat * cr;
			var borderGreen:Float = borderColor.greenFloat * cg;
			var borderBlue:Float = borderColor.blueFloat * cb;
			var bAlpha:Float = borderColor.alphaFloat * alpha;
			
			var textRed:Float = cr;
			var textGreen:Float = cg;
			var textBlue:Float = cb;
			var tAlpha:Float = alpha;
			
			if (useTextColor)
			{
				textRed *= textColor.redFloat;
				textGreen *= textColor.greenFloat;
				textBlue *= textColor.blueFloat;
				tAlpha *= textColor.alphaFloat;
			}
			
			var bgRed:Float = cr;
			var bgGreen:Float = cg;
			var bgBlue:Float = cb;
			var bgAlpha:Float = alpha;
			
			if (background)
			{
				bgRed *= backgroundColor.redFloat;
				bgGreen *= backgroundColor.greenFloat;
				bgBlue *= backgroundColor.blueFloat;
				bgAlpha *= backgroundColor.alphaFloat;
			}
			
			var drawItem;
			var currFrame:FlxFrame = null;
			var currTileX:Float = 0;
			var currTileY:Float = 0;
			var sx:Float = scale.x * _facingHorizontalMult;
			var sy:Float = scale.y * _facingVerticalMult;
			
			var ox:Float = origin.x;
			var oy:Float = origin.y;
			
			if (_facingHorizontalMult != 1)
			{
				ox = frameWidth - ox;
			}
			if (_facingVerticalMult != 1)
			{
				oy = frameHeight - oy;
			}
			
			for (camera in cameras)
			{
				if (!camera.visible || !camera.exists || !isOnScreen(camera))
				{
					continue;
				}
				
				getScreenPosition(_point, camera).subtractPoint(offset);
				
				if (isPixelPerfectRender(camera))
				{
					_point.floor();
				}
				
				updateTrig();
				
				if (background)
				{
					// backround tile transformations
					currFrame = FlxG.bitmap.whitePixel;
					_matrix.identity();
					_matrix.scale(0.1 * frameWidth, 0.1 * frameHeight);
					_matrix.translate(-ox, -oy);
					_matrix.scale(sx, sy);
					
					if (angle != 0)
					{
						_matrix.rotateWithTrig(_cosAngle, _sinAngle);
					}
					
					_matrix.translate(_point.x + ox, _point.y + oy);
					_colorParams.setMultipliers(bgRed, bgGreen, bgBlue, bgAlpha);
					camera.drawPixels(currFrame, null, _matrix, _colorParams, blend, antialiasing);
				}
				
				var hasColorOffsets:Bool = (colorTransform != null && colorTransform.hasRGBAOffsets());
				
				drawItem = camera.startQuadBatch(font.parent, true, hasColorOffsets, blend, antialiasing, shader);
				
				for (j in 0...borderLength)
				{
					dataPos = j * 3;
					
					currFrame = font.getCharFrame(Std.int(borderDrawData[dataPos]));
					
					currTileX = borderDrawData[dataPos + 1];
					currTileY = borderDrawData[dataPos + 2];
					
					currFrame.prepareMatrix(_matrix);
					_matrix.translate(currTileX - ox, currTileY - oy);
					_matrix.scale(sx, sy);
					if (angle != 0)
					{
						_matrix.rotateWithTrig(_cosAngle, _sinAngle);
					}
					
					_matrix.translate(_point.x + ox, _point.y + oy);
					_colorParams.setMultipliers(borderRed, borderGreen, borderBlue, bAlpha);
					drawItem.addQuad(currFrame, _matrix, _colorParams);
				}
				
				colorTagIndex = 0;
				animTagIndex = 0;
				var p_textRed:Float = textRed;
				var p_textGreen:Float = textGreen;
				var p_textBlue:Float = textBlue;
				var p_tAlpha:Float = tAlpha;
				var p_fadeAlpha:Float = 1;
				var p_fadeYOffset:Float = 0;
				inAnimTag = false;
				parseColored = colored;
				parseAnimated = animated;
				
				for (j in 0...textLength)
				{
					dataPos = j * 3;
					
					currFrame = font.getCharFrame(Std.int(textDrawData[dataPos]));
					
					currTileX = textDrawData[dataPos + 1];
					currTileY = textDrawData[dataPos + 2];
					
					currFrame.prepareMatrix(_matrix);
					
					if (isTyping)
					{
						p_fadeAlpha = typingCounter[j].alpha;
						p_fadeYOffset = typingCounter[j].yoffset;
					}
					
					
					if (!noAnimation)
					{
						
						if (parseAnimated && animTags[animTagIndex].end == j)
						{
							animTagIndex++;
							if (animTagIndex >= animTags.length)
							{
								parseAnimated = false;
							}
							inAnimTag = false;
						}
						if (parseAnimated && animTags[animTagIndex].start == j)
						{
							inAnimTag = true;
						}
						
						if (inAnimTag)
						{
							_matrix.translate(currTileX - ox, currTileY - oy + 
								animTags[animTagIndex].amount * Math.sin(
								count * animTags[animTagIndex].speed + 
								j * animTags[animTagIndex].freq) + 
								animTags[animTagIndex].amount - p_fadeYOffset + typingYOffset);
						}
						else
						{
							_matrix.translate(currTileX - ox, currTileY - oy - p_fadeYOffset + typingYOffset);
						}
					
					}
					else
					{
						_matrix.translate(currTileX - ox, currTileY - oy - p_fadeYOffset + typingYOffset);
					}
					
					_matrix.scale(sx, sy);
					if (angle != 0)
					{
						_matrix.rotateWithTrig(_cosAngle, _sinAngle);
					}
					
					_matrix.translate(_point.x + ox, _point.y + oy);
					
					if (parseColored && colorTags[colorTagIndex].end == j)
					{
						colorTagIndex++;
						if (colorTagIndex >= colorTags.length)
						{
							parseColored = false;
						}
						textRed = p_textRed;
						textGreen = p_textGreen;
						textBlue = p_textBlue;
						tAlpha = p_tAlpha;
					}
					if (parseColored && colorTags[colorTagIndex].start == j)
					{
						textRed *= colorTags[colorTagIndex].color.redFloat;
						textGreen *= colorTags[colorTagIndex].color.greenFloat;
						textBlue *= colorTags[colorTagIndex].color.blueFloat;
						tAlpha *= colorTags[colorTagIndex].color.alphaFloat;
					}
					
					_colorParams.setMultipliers(textRed, textGreen, textBlue, tAlpha * p_fadeAlpha);
					drawItem.addQuad(currFrame, _matrix, _colorParams);
					
				}
				
				#if FLX_DEBUG
				FlxBasic.visibleCount++;
				#end
			}
			
			#if FLX_DEBUG
			if (FlxG.debugger.drawDebug)
			{
				drawDebug();
			}
			#end
		}
	}
	

	/**
	 * Internal method for updating helper data for text rendering
	 * overriden for blit coloring
	 */
	override private function updateTextBitmap(useTiles:Bool = false):Void 
	{
		colorTagIndex = 0;
		animTagIndex = 0;
		inAnimTag = false;
		parseColored = colored;
		parseAnimated = animated;
		_colorParams.setMultipliers(1, 1, 1, 1);
		super.updateTextBitmap(useTiles);
	}
	
	/**
	 * extend for blit coloring
	 * @param	lineIndex
	 * @param	startX
	 * @param	startY
	 */
	override private function blitLine(lineIndex:Int, startX:Int, startY:Int):Void
	{
		var charFrame:FlxFrame;
		var charCode:Int;
		var curX:Float = startX;
		var curY:Int = startY;
		
		var line:String = _lines[lineIndex];
		var spaceWidth:Int = font.spaceWidth;
		var lineLength:Int = line.length;
		var textWidth:Int = this.textWidth;
		
		if (alignment == FlxTextAlign.JUSTIFY)
		{
			var numSpaces:Int = 0;
			
			for (i in 0...lineLength)
			{
				charCode = line.charCodeAt(i);
				
				if (charCode == FlxBitmapFont.SPACE_CODE)
				{
					numSpaces++;
				}
				else if (charCode == FlxBitmapFont.TAB_CODE)
				{
					numSpaces += numSpacesInTab;
				}
			}
			
			var lineWidth:Int = getStringWidth(line);
			var totalSpacesWidth:Int = numSpaces * font.spaceWidth;
			spaceWidth = Std.int((textWidth - lineWidth + totalSpacesWidth) / numSpaces);
		}
		
		var tabWidth:Int = spaceWidth * numSpacesInTab;
		
		var prevIndex:Int = 0;
		for (i in 0...lineIndex)
		{
			prevIndex += regexp(ERegTag.Space).replace(_lines[i], "").length;
		}
		
		var p_textRed:Float = 1;
		var p_textGreen:Float = 1;
		var p_textBlue:Float = 1;
		var p_tAlpha:Float = 1;
		var p_fadeAlpha:Float = 1;
		var p_fadeYOffset:Float = 0;
		var nonSpaceCount:Int = 0;
		
		for (i in 0...lineLength)
		{
			var charIndex:Int = prevIndex + nonSpaceCount;
			
			if (parseColored && colorTags[colorTagIndex].start == charIndex)
			{
				p_textRed = colorTags[colorTagIndex].color.redFloat;
				p_textGreen = colorTags[colorTagIndex].color.greenFloat;
				p_textBlue = colorTags[colorTagIndex].color.blueFloat;
				p_tAlpha = colorTags[colorTagIndex].color.alphaFloat;
				_colorParams.setMultipliers(p_textRed, p_textGreen, p_textBlue, p_tAlpha);
			}
			
			if (parseAnimated && animTags[animTagIndex].end == charIndex)
			{
				animTagIndex++;
				if (animTagIndex >= animTags.length)
				{
					parseAnimated = false;
				}
				inAnimTag = false;
			}
			if (parseAnimated && animTags[animTagIndex].start == charIndex)
			{
				inAnimTag = true;
			}
			
			charCode = line.charCodeAt(i);//Utf8.charCodeAt(line, i);
			
			if (charCode == FlxBitmapFont.SPACE_CODE)
			{
				curX += spaceWidth;
			}
			else if (charCode == FlxBitmapFont.TAB_CODE)
			{
				curX += tabWidth;
			}
			else
			{
				if (isTyping)
				{
					p_fadeAlpha = typingCounter[charIndex].alpha;
					p_fadeYOffset = typingCounter[charIndex].yoffset;
				}
				
				charFrame = font.getCharFrame(charCode);
				
				if (charFrame != null)
				{
					
					if (inAnimTag)
					{
						_flashPoint.setTo(curX, Math.round(curY + 
							animTags[animTagIndex].amount * Math.sin(
							count * animTags[animTagIndex].speed + 
							charIndex * animTags[animTagIndex].freq) + 
							animTags[animTagIndex].amount - p_fadeYOffset + typingYOffset));
						
					}
					else
					{
						_flashPoint.setTo(curX, curY - p_fadeYOffset + typingYOffset);
					}
					
					charFrame.paint(textBitmap, _flashPoint, true);
					
					rect.x = _flashPoint.x - 1;
					rect.y =  _flashPoint.y;
					rect.width = charFrame.frame.width + 1;
					rect.height = lineHeight;
					_colorParams.alphaMultiplier *= p_fadeAlpha;
					textBitmap.colorTransform(rect, _colorParams);
					
					curX += font.getCharAdvance(charCode);
					nonSpaceCount++;
				}
				
			}
			
			if (parseColored && colorTags[colorTagIndex].end - 1 == charIndex)
			{
				colorTagIndex++;
				if (colorTagIndex >= colorTags.length)
				{
					parseColored = false;
				}
				p_textRed = 1;
				p_textGreen = 1;
				p_textBlue = 1;
				p_tAlpha = 1 * p_fadeAlpha;
				_colorParams.setMultipliers(p_textRed, p_textGreen, p_textBlue, p_tAlpha);
			}
			
			curX += letterSpacing;
		}
	}
	
	private function parseTag(value:String):String
	{
		var tag:EReg = regexp(ERegTag.Tag);
		while (tag.match(value))
		{
			//trace(value);
			var actual:String = regexp(ERegTag.TagAll).replace(tag.matched(3), "");
			var name:String = tag.matched(1).toLowerCase();
			var nameVal:String = tag.matched(2);
			var tagpos = tag.matchedPos();
			var vtag:EReg = regexp(name);
			if (vtag.match(nameVal))
			{
				var attr:String = vtag.matched(1).toLowerCase();
				switch(name)
				{
					case ERegTag.Color:
						var tagColor:Int = FlxColor.WHITE;
						switch(attr)
						{
							case "transparent":
								tagColor = FlxColor.TRANSPARENT;
							case "white":
								tagColor = FlxColor.WHITE;
							case "gray":
								tagColor = FlxColor.GRAY;
							case "black":
								tagColor = FlxColor.BLACK;
							case "green":
								tagColor = FlxColor.GREEN;
							case "lime":
								tagColor = FlxColor.LIME;
							case "yellow":
								tagColor = FlxColor.YELLOW;
							case "orange":
								tagColor = FlxColor.ORANGE;
							case "red":
								tagColor = FlxColor.RED;
							case "purple":
								tagColor = FlxColor.PURPLE;
							case "blue":
								tagColor = FlxColor.BLUE;
							case "brown":
								tagColor = FlxColor.BROWN;
							case "pink":
								tagColor = FlxColor.PINK;
							case "magenta":
								tagColor = FlxColor.MAGENTA;
							case "cyan":
								tagColor = FlxColor.CYAN;
							default:
								tagColor = Std.parseInt("0x" + attr);
						}
						colored = true;
						var startIndex = tagpos.pos;
						var endIndex =  tagpos.pos + actual.length;
						colorTags.push( { start:startIndex, end:endIndex, color:tagColor} );
					case ERegTag.Anim:
						var a_amount:Float = 0;
						var a_speed:Float = 0;
						var a_freq:Float = 0;
						animated = true;
						switch(attr)
						{
							case "sine":
								a_amount = 1;
								a_speed = 10;
								a_freq = 0.5;
							case "shake":
								#if neko
								a_amount = 0.5;
								#else
								a_amount = 1;
								#end
								a_speed = 50;
								a_freq = 3;
							default:
								a_amount = Std.parseFloat(attr);
								a_speed = Std.parseFloat(vtag.matched(2));
								if (Math.isNaN(a_speed))
								{
									a_speed = 1;
								}
								a_freq = Std.parseFloat(vtag.matched(3));
								if (Math.isNaN(a_freq))
								{
									a_freq = 1;
								}
						}
						var startIndex = tagpos.pos;
						var endIndex =  tagpos.pos + actual.length;
						animTags.push( { start:startIndex, end:endIndex, amount:a_amount, speed:a_speed, freq:a_freq } );
					default:
				}
			}
			value = tag.replace(value, "$3");
		}
		return "";
	}
	override private function set_text(value:String):String 
	{
		if (value != null && value != "" && text != value )
		{
			animated = false;
			colored = false;
			var trimmed:String = regexp(ERegTag.NewLine).replace(value, "");
			//if (!FlxG.renderBlit)
			//{
				trimmed = regexp(ERegTag.Space).replace(value, "");
			//}
			//apparently very fast for html5
			while (colorTags.length > 0)
			{
				colorTags.pop();
			}
			while (animTags.length > 0)
			{
				animTags.pop();
			}
			parseTag(trimmed);
			//trace(colorTags);
			//trace(animTags);
			value = regexp(ERegTag.TagAll).replace(value, "");
			//trace(value);
			
			if (typing)
			{
				typingCount = 0;
				typingIndex = 0;
				doneTypingIndex = 0;
				isTyping = true;
				while (typingCounter.length > 0)
				{
					typingCounter.pop();
				}
				for (_ in 0...regexp(ERegTag.Space).replace(value, "").length)
				{
					typingCounter.push({ alpha:0, yoffset:typingYOffset});
				}
			}
		}
		return super.set_text(value);
	}
	
	private function regexp(tagType:ERegTag):EReg
	{
		switch(tagType)
		{
			case ERegTag.NewLine:
				return ~/\n/g;
			case ERegTag.Space:
				return ~/\s/g;
			case ERegTag.Tag: //check for any valid tag
				return ~/<([A-Za-z]+)(=[#A-Za-z0-9,.]+)?>((?!<\1|<\/\1).*?)<\/\1>/i;
			case ERegTag.TagAll: //check for any valid tag
				return ~/<\/?[#A-Za-z0-9,.=]+>/ig;
			case ERegTag.Color:
				return ~/=#?([A-Fa-f0-9]{8}|[A-Fa-f0-9]{6}|[A-Za-z]+)/;
			case ERegTag.Anim:
				return ~/=([0-9.]+|[A-Za-z]+),?([0-9.]+)?,?([0-9.]+)?/;
			default:
				return null;
			
		}
	}
}

typedef ColorTag =
{
	start:Int,
	end:Int,
	color:FlxColor
}
typedef AnimTag =
{
	start:Int,
	end:Int,
	amount:Float,
	speed:Float,
	freq:Float,
}
typedef TypingProperty =
{
	alpha:Float,
	yoffset:Float,
}

@:enum
abstract AniTextType(String) from String to String
{
	var Sine		= "sine";
	var Shake		= "shake";
}

@:enum
abstract ERegTag(String) from String to String
{
	var Tag			= "tag";		//special check for tag
	var TagAll		= "tagall";		//special check for all tags
	var NewLine		= "newline";	//special check for newline character
	var Space		= "space";		//special check for space character
	var Color 		= "color";
	var Anim 		= "anim";
}