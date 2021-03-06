package com.babylonhx.helpers;

import com.babylonhx.math.Color3;
import com.babylonhx.math.Vector3;

/**
 * @author Krtolica Vujadin
 */

/**
 * Represents the different options available during the creation of 
 * a Environment helper.
 * 
 * This can control the default ground, skybox and image processing setup of your scene.
 */
typedef IEnvironmentHelperOptions = {
	
	/**
	 * Specifies wether or not to create a ground.
	 * True by default.
	 */
	@:optional var createGround:Null<Bool>;
	/**
	 * Specifies the ground size.
	 * 15 by default.
	 */
	@:optional var groundSize:Null<Int>;
	/**
	 * The texture used on the ground for the main color.
	 * Comes from the BabylonJS CDN by default.
	 * 
	 * Remarks: Can be either a texture or a url.
	 */
	@:optional var groundTexture:Null<Dynamic>;// string | BaseTexture;
	/**
	 * The color mixed in the ground texture by default.
	 * BabylonJS clearColor by default.
	 */
	@:optional var groundColor:Null<Color3>;
	/**
	 * Specifies the ground opacity.
	 * 1 by default.
	 */
	@:optional var groundOpacity:Null<Float>;
	/**
	 * Enables the ground to receive shadows.
	 * True by default.
	 */
	@:optional var enableGroundShadow:Null<Bool>;
	/**
	 * Helps preventing the shadow to be fully black on the ground.
	 * 0.5 by default.
	 */
	@:optional var groundShadowLevel:Null<Float>;
	/**
	 * Creates a mirror texture attach to the ground.
	 * false by default.
	 */
	@:optional var enableGroundMirror:Null<Bool>;
	/**
	 * Specifies the ground mirror size ratio.
	 * 0.3 by default as the default kernel is 64.
	 */
	@:optional var groundMirrorSizeRatio:Null<Float>;
	/**
	 * Specifies the ground mirror blur kernel size.
	 * 64 by default.
	 */
	@:optional var groundMirrorBlurKernel:Null<Float>;
	/**
	 * Specifies the ground mirror visibility amount.
	 * 1 by default
	 */
	@:optional var groundMirrorAmount:Null<Float>;
	/**
	 * Specifies the ground mirror reflectance weight.
	 * This uses the standard weight of the background material to setup the fresnel effect
	 * of the mirror.
	 * 1 by default.
	 */
	@:optional var groundMirrorFresnelWeight:Null<Float>;
	/**
	 * Specifies the ground mirror Falloff distance.
	 * This can helps reducing the size of the reflection.
	 * 0 by Default.
	 */
	@:optional var groundMirrorFallOffDistance:Null<Float>;
	/**
	 * Specifies the ground mirror texture type.
	 * Unsigned Int by Default.
	 */
	@:optional var groundMirrorTextureType:Null<Int>;
	
	/**
     * Specifies a bias applied to the ground vertical position to prevent z-fighyting with
     * the shown objects.
     */
    @:optional var groundYBias:Null<Float>;

	/**
	 * Specifies wether or not to create a skybox.
	 * True by default.
	 */
	@:optional var createSkybox:Null<Bool>;
	/**
	 * Specifies the skybox size.
	 * 20 by default.
	 */
	@:optional var skyboxSize:Null<Float>;
	/**
	 * The texture used on the skybox for the main color.
	 * Comes from the BabylonJS CDN by default.
	 * 
	 * Remarks: Can be either a texture or a url.
	 */
	@:optional var skyboxTexture:Null<Dynamic>;// string | BaseTexture;
	/**
	 * The color mixed in the skybox texture by default.
	 * BabylonJS clearColor by default.
	 */
	@:optional var skyboxColor:Null<Color3>;

	/**
	 * The background rotation around the Y axis of the scene.
	 * This helps aligning the key lights of your scene with the background.
	 * 0 by default.
	 */
	@:optional var backgroundYRotation:Null<Float>;

	/**
	 * Compute automatically the size of the elements to best fit with the scene.
	 */
	@:optional var sizeAuto:Null<Bool>;

	/**
	 * Default position of the rootMesh if autoSize is not true.
	 */
	@:optional var rootPosition:Null<Vector3>;

	/**
	 * Sets up the image processing in the scene.
	 * true by default.
	 */
	@:optional var setupImageProcessing:Null<Bool>;

	/**
	 * The texture used as your environment texture in the scene.
	 * Comes from the BabylonJS CDN by default and in use if setupImageProcessing is true.
	 * 
	 * Remarks: Can be either a texture or a url.
	 */
	@:optional var environmentTexture:Null<Dynamic>;// string | BaseTexture;

	/**
	 * The value of the exposure to apply to the scene.
	 * 0.6 by default if setupImageProcessing is true.
	 */
	@:optional var cameraExposure:Null<Float>;

	/**
	 * The value of the contrast to apply to the scene.
	 * 1.6 by default if setupImageProcessing is true.
	 */
	@:optional var cameraContrast:Null<Float>;

	/**
	 * Specifies wether or not tonemapping should be enabled in the scene.
	 * true by default if setupImageProcessing is true.
	 */
	@:optional var toneMappingEnabled:Null<Bool>;
  
}
