package lime.utils.compress;


import haxe.io.Bytes;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

class GZip {
	
	
	public static function compress (bytes:Bytes):Bytes {
		
		#if js
		
		var data = untyped __js__ ("pako.gzip") (bytes.getData ());
		return Bytes.ofData (data);
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	public static function decompress (bytes:Bytes):Bytes {
		
		#if js
		
		var data = untyped __js__ ("pako.ungzip") (bytes.getData ());
		return Bytes.ofData (data);
		
		#else
		
		return null;
		
		#end
		
	}
	
	
}