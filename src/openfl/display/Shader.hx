package openfl.display;


import lime.graphics.GLRenderContext;
import lime.graphics.opengl.GLProgram;
import lime.utils.Float32Array;
import lime.utils.GLUtils;
import openfl.utils.ByteArray;
import openfl.display.ShaderParameter;

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

#if (!display && !macro)
@:autoBuild(openfl._internal.macros.ShaderMacro.build())
@:build(openfl._internal.macros.ShaderMacro.build())
#end


class Shader {
	
	
	public var byteCode (null, default):ByteArray;
	public var data (get, set):ShaderData;
	public var glFragmentSource (get, set):String;
	public var glProgram (default, null):GLProgram;
	public var glVertexSource (get, set):String;
	public var precisionHint:ShaderPrecision;
	
	private var gl:GLRenderContext;
	
	private var __data:ShaderData;
	private var __glFragmentSource:String;
	private var __glSourceDirty:Bool;
	private var __glVertexSource:String;
	private var __inputBitmapData:Array<ShaderParameterSampler>;
	private var __numPasses:Int;
	private var __param:Array<ShaderParameter>;
	private var __skipEnableVertexAttribArray:Bool;
	
	
	@:glFragmentSource(
		
		#if emscripten
		"varying float vAlpha;
		varying mat4 vColorMultipliers;
		varying vec4 vColorOffsets;
		varying vec2 vTexCoord;
		
		uniform bool uColorTransform;
		uniform sampler2D uImage0;
		
		void main(void) {
			
			vec4 color = texture2D (uImage0, vTexCoord);
			
			if (color.a == 0.0) {
				
				gl_FragColor = vec4 (0.0, 0.0, 0.0, 0.0);
				
			} else if (uColorTransform) {
				
				color = vec4 (color.rgb / color.a, color.a);
				color = vColorOffsets + (color * vColorMultipliers);
				
				gl_FragColor = vec4 (color.bgr * color.a * vAlpha, color.a * vAlpha);
				
			} else {
				
				gl_FragColor = color.bgra * vAlpha;
				
			}
			
		}"
		#else
		"varying float vAlpha;
		varying vec4 vColorMultipliers0;
		varying vec4 vColorMultipliers1;
		varying vec4 vColorMultipliers2;
		varying vec4 vColorMultipliers3;
		varying vec4 vColorOffsets;
		varying vec2 vTexCoord;
		
		uniform bool uColorTransform;
		uniform sampler2D uImage0;
		
		void main(void) {
			
			vec4 color = texture2D (uImage0, vTexCoord);
			
			if (color.a == 0.0) {
				
				gl_FragColor = vec4 (0.0, 0.0, 0.0, 0.0);
				
			} else if (uColorTransform) {
				
				color = vec4 (color.rgb / color.a, color.a);
				
				mat4 colorMultiplier;
				colorMultiplier[0] = vColorMultipliers0;
				colorMultiplier[1] = vColorMultipliers1;
				colorMultiplier[2] = vColorMultipliers2;
				colorMultiplier[3] = vColorMultipliers3;
				
				color = vColorOffsets + (color * colorMultiplier);
				
				if (color.a > 0.0) {
					
					gl_FragColor = vec4 (color.rgb * color.a * vAlpha, color.a * vAlpha);
					
				} else {
					
					gl_FragColor = vec4 (0.0, 0.0, 0.0, 0.0);
					
				}
				
			} else {
				
				gl_FragColor = color * vAlpha;
				
			}
			
		}"
		#end
		
	)
	
	
	@:glVertexSource(
		
		"attribute float aAlpha;
		attribute vec4 aColorMultipliers0;
		attribute vec4 aColorMultipliers1;
		attribute vec4 aColorMultipliers2;
		attribute vec4 aColorMultipliers3;
		attribute vec4 aColorOffsets;
		attribute vec4 aPosition;
		attribute vec2 aTexCoord;
		varying float vAlpha;
		varying vec4 vColorMultipliers0;
		varying vec4 vColorMultipliers1;
		varying vec4 vColorMultipliers2;
		varying vec4 vColorMultipliers3;
		varying vec4 vColorOffsets;
		varying vec2 vTexCoord;
		
		uniform mat4 uMatrix;
		uniform bool uColorTransform;
		
		void main(void) {
			
			vAlpha = aAlpha;
			vTexCoord = aTexCoord;
			
			if (uColorTransform) {
				
				vColorMultipliers0 = aColorMultipliers0;
				vColorMultipliers1 = aColorMultipliers1;
				vColorMultipliers2 = aColorMultipliers2;
				vColorMultipliers3 = aColorMultipliers3;
				vColorOffsets = aColorOffsets;
				
			}
			
			gl_Position = uMatrix * aPosition;
			
		}"
		
	)
	
	
	public function new (code:ByteArray = null) {
		
		byteCode = code;
		precisionHint = FULL;
		
		__skipEnableVertexAttribArray = false;
		__glSourceDirty = true;
		__numPasses = 1;
		
	}
	
	
	private function __disable ():Void {
		
		if (glProgram != null) {
			
			__disableGL ();
			
		}
		
	}
	
	
	private function __disableGL ():Void {
		
		if (data.uImage0 != null) {
			
			data.uImage0.input = null;
			
		}
		
		for (parameter in __param) {
			
			parameter.disable (gl);
			
		}
		
		gl.bindBuffer (gl.ARRAY_BUFFER, null);
		gl.bindTexture (gl.TEXTURE_2D, null);
		
	}
	
	
	private function __enable ():Void {
		
		__init ();
		
		if (glProgram != null) {
			
			__enableGL ();
			
		}
		
	}
	
	
	private function __enableGL ():Void {
		
		for (input in __inputBitmapData) {
			
			input.enable (gl);
			
		}
		
	}
	
	
	private function __init ():Void {
		
		if (__data == null) {
			
			__data = cast new ShaderData (null);
			
		}
		
		if (__glFragmentSource != null && __glVertexSource != null && (glProgram == null || __glSourceDirty)) {
			
			__initGL ();
			
		}
		
	}
	
	
	private function __initGL ():Void {
		
		if (__glSourceDirty || __param == null) {
			
			__glSourceDirty = false;
			glProgram = null;
			
			__inputBitmapData = new Array ();
			__param = new Array ();
			
			__processGLData (glVertexSource, "attribute");
			__processGLData (glVertexSource, "uniform");
			__processGLData (glFragmentSource, "uniform");
			
		}
		
		if (gl != null && glProgram == null) {
			
			var fragment = 
				
				"#ifdef GL_ES
				precision " + (precisionHint == FULL ? "mediump" : "lowp") + " float;
				#endif
				" + glFragmentSource;
			
			glProgram = GLUtils.createProgram (glVertexSource, fragment);
			
			if (glProgram != null) {
				
				for (input in __inputBitmapData) {
					
					input.init (gl, glProgram);
					
				}
				
				for (parameter in __param) {
					
					parameter.init (gl, glProgram);
					
				}
				
			}
			
		}
		
	}
	
	
	private function __processGLData (source:String, storageType:String):Void {
		
		var lastMatch = 0, position, regex, name, type;

		var isUniform = storageType == "uniform";
		if (isUniform) {
			
			regex = ~/uniform ([A-Za-z0-9]+) ([A-Za-z0-9]+)/;
			
		} else {
			
			regex = ~/attribute ([A-Za-z0-9]+) ([A-Za-z0-9]+)/;
			
		}
		
		var textureIndex = 0;
		while (regex.matchSub (source, lastMatch)) {
			
			type = regex.matched (1);
			name = regex.matched (2);
			
			if (StringTools.startsWith (type, "sampler")) {
				
				var input = new ShaderParameterSampler (name, textureIndex);
				textureIndex++;
				__inputBitmapData.push (input);
				Reflect.setField (data, name, input);
				
			} else {
				
				var parameter:ShaderParameter;
				if (!isUniform) {
					parameter = new ShaderParameterAttrib (name);
				} else {
					parameter = switch (type) {
						case "bool": new ShaderParameterBool (name);
						case "double", "float": new ShaderParameterFloat (name);
						case "int", "uint": new ShaderParameterInt (name);
						case "bvec2": new ShaderParameterBool2 (name);
						case "bvec3": new ShaderParameterBool3 (name);
						case "bvec4": new ShaderParameterBool4 (name);
						case "ivec2", "uvec2": new ShaderParameterInt2 (name);
						case "ivec3", "uvec3": new ShaderParameterInt3 (name);
						case "ivec4", "uvec4": new ShaderParameterInt4 (name);
						case "vec2", "dvec2": new ShaderParameterFloat2 (name);
						case "vec3", "dvec3": new ShaderParameterFloat3 (name);
						case "vec4", "dvec4": new ShaderParameterFloat4 (name);
						case "mat2", "mat2x2": new ShaderParameterMatrix2 (name);
						case "mat3", "mat3x3": new ShaderParameterMatrix3 (name);
						case "mat4", "mat4x4": new ShaderParameterMatrix4 (name);
						default: throw "unsupported shader parameter type: " + type;
					}
					
				}
				__param.push (parameter);
				Reflect.setField (data, name, parameter);
				
			}
			
			position = regex.matchedPos ();
			lastMatch = position.pos + position.len;
			
		}
		
	}
	
	
	private function __update ():Void {
		
		if (glProgram != null) {
			
			__updateGL ();
			
		}
		
	}
	
	
	private function __updateGL ():Void {
		
		for (input in __inputBitmapData) {
			
			input.update (gl, false);
	
		}
		
		for (parameter in __param) {
			parameter.update (gl, __skipEnableVertexAttribArray);
		}
		
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_data ():ShaderData {
		
		if (__glSourceDirty || __data == null) {
			
			__init ();
			
		}
		
		return __data;
		
	}
	
	
	private function set_data (value:ShaderData):ShaderData {
		
		return __data = cast value;
		
	}
	
	
	private function get_glFragmentSource ():String {
		
		return __glFragmentSource;
		
	}
	
	
	private function set_glFragmentSource (value:String):String {
		
		if (value != __glFragmentSource) {
			
			__glSourceDirty = true;
			
		}
		
		return __glFragmentSource = value;
		
	}
	
	
	private function get_glVertexSource ():String {
		
		return __glVertexSource;
		
	}
	
	
	private function set_glVertexSource (value:String):String {
		
		if (value != __glVertexSource) {
			
			__glSourceDirty = true;
			
		}
		
		return __glVertexSource = value;
		
	}
	
	
}
