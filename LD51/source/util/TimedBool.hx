package util;

/**
 * ...
 * @author aeveis
 */
class TimedBool
{
	public var delay:Float;
	public var delay_timer:Float = 0;
	public var hard:Bool;
	public var soft(get, null):Bool;
	function get_soft() {
		return delay_timer > 0;
	}
	public function new(Delay:Float) 
	{
		delay = Delay;
	}
	
	public function update(elapsed:Float) {
		if (hard) {
			delay_timer = delay;
		} else {
			delay_timer -= elapsed;
		}
	}
	
}