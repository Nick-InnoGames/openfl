package openfl._internal.renderer.opengl;


import lime.utils.Float32Array;
import lime.graphics.opengl.GL;
import openfl._internal.renderer.RenderSession;
import openfl.display.Bitmap;

#if gl_stats
import openfl._internal.renderer.opengl.stats.GLStats;
import openfl._internal.renderer.opengl.stats.DrawCallContext;
#end

#if !openfl_debug
@:fileXml(' tags="haxe,release" ')
@:noDebug
#end

@:access(openfl.display.Bitmap)
@:access(openfl.display.BitmapData)
@:access(openfl.display.Stage)
@:access(openfl.filters.BitmapFilter)
@:access(openfl.geom.ColorTransform)


class GLBitmap {
	
	
	public static function render (bitmap:Bitmap, renderSession:RenderSession):Void {
		
		if (!bitmap.__renderable || bitmap.__worldAlpha <= 0) return;
		
		if (bitmap.__bitmapData != null && bitmap.__bitmapData.__isValid) {
			
			renderSession.maskManager.pushObject (bitmap);
			renderSession.batcher.render (bitmap.__getBatchQuad (renderSession));
			renderSession.maskManager.popObject (bitmap);
			
		}
		
	}
	
	
	public static function renderMask (bitmap:Bitmap, renderSession:RenderSession):Void {
		
		if (bitmap.__bitmapData != null && bitmap.__bitmapData.__isValid) {
			
			var renderer:GLRenderer = cast renderSession.renderer;
			var gl = renderSession.gl;
			
			var shader = (cast renderSession.maskManager:GLMaskManager).maskShader;
			renderSession.shaderManager.setShader (shader);
			
			shader.data.uImage0.input = bitmap.__bitmapData;
			shader.data.uImage0.smoothing = renderSession.allowSmoothing && (bitmap.smoothing || renderSession.forceSmoothing);
			shader.data.uMatrix.value = renderer.getMatrix (bitmap.__renderTransform, bitmap.__snapToPixel());
			
			var vaoRendered = GLVAORenderHelper.renderMask (bitmap, renderSession, shader, bitmap.__bitmapData);
			
			if (vaoRendered) return;
			
			renderSession.shaderManager.updateShader (shader);
			
			gl.bindBuffer (GL.ARRAY_BUFFER, bitmap.__bitmapData.getBuffer (gl, bitmap.__worldAlpha, bitmap.__worldColorTransform));
			
			gl.vertexAttribPointer (shader.data.aPosition.index, 3, GL.FLOAT, false, 26 * Float32Array.BYTES_PER_ELEMENT, 0);
			gl.vertexAttribPointer (shader.data.aTexCoord.index, 2, GL.FLOAT, false, 26 * Float32Array.BYTES_PER_ELEMENT, 3 * Float32Array.BYTES_PER_ELEMENT);
			
			gl.drawArrays (GL.TRIANGLE_STRIP, 0, 4);
			
			#if gl_stats
				GLStats.incrementDrawCall (DrawCallContext.STAGE);
			#end
			
		}
		
	}
	
	
}