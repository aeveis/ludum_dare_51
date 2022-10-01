package ui;
import flixel.FlxObject;

/**
 * ...
 * @author aeveis
 */
enum TextTriggerState
{
	Ready;
	Playing;
	Done;
}

class TextTrigger extends FlxObject
{
	public var text:Array<String>;
	public var callbacks:Map<Int, Void->Void>;
	public var callAuto:Bool = false;
	public var state:TextTriggerState;
	
	public var index:Int = 0;
	public var locked:Bool = true;
	public var onTrigger:Bool = false;
	
	public var name:String;
	public var animName:String = "Normal";
	
	public var typeSoundName = "type";
	public var typeSoundRandomCount = 1;
	
	public function new(px:Float, py:Float, pwidth:Float, pheight:Float, pname:String, ptext:Array<String>, plocked:Bool = true) 
	{
		super(px, py);
		width = pwidth;
		height = pheight;
		text = ptext;
		name = pname;
		locked = plocked;
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
	
	override public function update(elapsed:Float)
	{
		super.update(elapsed);
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
		if (!locked)
		{
			index++;
		}
		
		if (index == text.length)
		{
			state = TextTriggerState.Done;
		}
		return rtext;
	}
	
}