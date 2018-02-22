package com.babylonhx.layer;

import com.babylonhx.cameras.Camera;

/**
 * @author Krtolica Vujadin
 */

/**
 * Highlight layer options. This helps customizing the behaviour
 * of the highlight layer.
 */
typedef IHighlightLayerOptions = {
	
	/**
	 * Multiplication factor apply to the canvas size to compute the render target size
	 * used to generated the glowing objects (the smaller the faster).
	 */
	@:optional var mainTextureRatio:Null<Float>;
	
	/**
     * Enforces a fixed size texture to ensure resize independant blur.
     */
	@:optional var mainTextureFixedSize:Null<Int>;

	/**
	 * Multiplication factor apply to the main texture size in the first step of the blur to reduce the size 
	 * of the picture to blur (the smaller the faster).
	 */
	@:optional var blurTextureSizeRatio:Null<Float>;

	/**
	 * How big in texel of the blur texture is the vertical blur.
	 */
	@:optional var blurVerticalSize:Null<Float>;

	/**
	 * How big in texel of the blur texture is the horizontal blur.
	 */
	@:optional var blurHorizontalSize:Null<Float>;

	/**
	 * Alpha blending mode used to apply the blur. Default is combine.
	 */
	@:optional var alphaBlendingMode:Null<Int>;
	
	/**
     * The camera attached to the layer.
     */
    @:optional var camera:Null<Camera>;
	
	/**
     * Should we display highlight as a solid stroke@:optional var 
     */
    @:optional var isStroke:Null<Bool>;
  
}
