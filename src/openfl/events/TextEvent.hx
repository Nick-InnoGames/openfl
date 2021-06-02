package openfl.events;

class TextEvent extends Event {
	public static inline var LINK:EventType<TextEvent> = "link";
	public static inline var TEXT_INPUT:EventType<TextEvent> = "textInput";

	public var text:String;

	public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, text:String = "") {
		super(type, bubbles, cancelable);

		this.text = text;
	}

	public override function clone():TextEvent {
		var event = new TextEvent(type, bubbles, cancelable, text);
		event.target = target;
		event.currentTarget = currentTarget;
		event.eventPhase = eventPhase;
		return event;
	}

	public override function toString():String {
		return __formatToString("TextEvent", ["type", "bubbles", "cancelable", "text"]);
	}
}
