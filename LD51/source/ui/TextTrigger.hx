package ui;
import flixel.FlxObject;
import util.Input;

/**
 * ...
 * @author aeveis
 */
enum TextTriggerState
{
	Ready;
	Playing;
	Done;
	Disabled;
}

class TextTrigger extends FlxObject
{
	public var text:Array<String>;
	public var callbacks:Map<Int, Void->Void>;
	public var state:TextTriggerState;
	
	public var index:Int = 0;
	public var onTrigger:Bool = false;
	
	public var name:String;
	public var animName:String = "Normal";
	
	public var oneShot:Bool = false;
	public var cooldown:Float = 5.0;
	public var counter:Float = 0;
	
	public var typeSoundName = "type";
	public var typeSoundRandomCount = 1;
	
	public function new(px:Float, py:Float, pwidth:Float, pheight:Float, pname:String, ptext:Array<String>) 
	{
		super(px, py);
		width = pwidth;
		height = pheight;
		text = ptext;
		name = pname;
		solid = true;
				
		callbacks = new Map<Int, Void->Void>();
		
		state = TextTriggerState.Ready;
	}
	
	public function addCallback(index:Int, pcallback:Void->Void)
	{
		callbacks.set(index, pcallback);
	}
	
	public function setTypeSound(soundName:String, soundRandomCount:Int = 0)
	{
		typeSoundName = soundName;
		typeSoundRandomCount = soundRandomCount;
	}
	
	public function setActive(active:Bool)
	{
		if (active)
		{
			oneShot = false;
			solid = true;
			state = TextTriggerState.Ready;
		}
		else
		{
			oneShot = true;
			solid = false;
			state = TextTriggerState.Disabled;
		}
	}
	
	public function setCooldown()
	{
		solid = false;
		state = TextTriggerState.Disabled;
		counter = cooldown;	
		var callback = callbacks.get(index - 1);
		if (callback != null)
		{
			callback();
		}
	}
	
	override public function update(elapsed:Float)
	{
		if (state == TextTriggerState.Disabled)
		{
			if (counter > 0 && !oneShot)
			{
				counter -= elapsed;
				if (counter <= 0)
				{
					solid = true;
					state = TextTriggerState.Ready;
				}
			}
			return;
		}
		super.update(elapsed);
		
		if (onTrigger && Input.control.keys.get("select").justPressed)
		{
			if (state == TextTriggerState.Ready || state == TextTriggerState.Done)
			{				
				var callback = callbacks.get(index - 1);
				if (callback != null)
				{
					callback();
				}
			}
		}
		if (!onTrigger)
		{
			state = TextTriggerState.Ready;
			index = 0;
		}
		onTrigger = false;
	}
	
	public function getText():String
	{
		var rtext = text[index];
		index++;
		
		if (index == text.length)
		{
			state = TextTriggerState.Done;
		}
		return rtext;
	}
	
}