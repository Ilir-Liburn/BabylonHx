package com.babylonhx.postprocess;

import com.babylonhx.engine.Engine;
import com.babylonhx.materials.textures.BaseTexture;
import com.babylonhx.materials.ColorCurves;
import com.babylonhx.materials.Effect;
import com.babylonhx.materials.ImageProcessingConfiguration;
import com.babylonhx.materials.IImageProcessingConfigurationDefines;
import com.babylonhx.math.Color4;
import com.babylonhx.math.Tools;
import com.babylonhx.cameras.Camera;
import com.babylonhx.tools.Observer;

/**
 * ...
 * @author Krtolica Vujadin
 */

// BHX only
class IPCD implements IImageProcessingConfigurationDefines {
	
	public var IMAGEPROCESSING:Int = 0;
	public var VIGNETTE:Int = 0;
	public var VIGNETTEBLENDMODEMULTIPLY:Int = 0;
	public var VIGNETTEBLENDMODEOPAQUE:Int = 0;
	public var TONEMAPPING:Int = 0;
	public var CONTRAST:Int = 0;
	public var COLORCURVES:Int = 0;
	public var COLORGRADING:Int = 0;
	public var COLORGRADING3D:Int = 0;
	public var FROMLINEARSPACE:Int = 0;
	public var SAMPLER3DGREENDEPTH:Int = 0;
	public var SAMPLER3DBGRMAP:Int = 0;
	public var IMAGEPROCESSINGPOSTPROCESS:Int = 0;
	public var EXPOSURE:Int = 0;	
	
	
	public function new() { }
	
}
 
class ImageProcessingPostProcess extends PostProcess {
	
	/**
	 * Default configuration related to image processing available in the PBR Material.
	 */
	private var _imageProcessingConfiguration:ImageProcessingConfiguration;

	public var imageProcessingConfiguration(get, set):ImageProcessingConfiguration;
	/**
	 * Gets the image processing configuration used either in this material.
	 */
	inline private function get_imageProcessingConfiguration():ImageProcessingConfiguration {
		return this._imageProcessingConfiguration;
	}
	/**
	 * Sets the Default image processing configuration used either in the this material.
	 * 
	 * If sets to null, the scene one is in use.
	 */
	inline private function set_imageProcessingConfiguration(value:ImageProcessingConfiguration):ImageProcessingConfiguration {
		this._attachImageProcessingConfiguration(value);
		return value;
	}

	/**
	 * Keep track of the image processing observer to allow dispose and replace.
	 */
	private var _imageProcessingObserver:Observer<ImageProcessingConfiguration>;

	/**
	 * Attaches a new image processing configuration to the PBR Material.
	 * @param configuration 
	 */
	public function _attachImageProcessingConfiguration(configuration:ImageProcessingConfiguration, doNotBuild:Bool = false) {
		if (configuration != null && configuration == this._imageProcessingConfiguration) {
			return;
		}
		
		// Detaches observer.
		if (this._imageProcessingConfiguration != null && this._imageProcessingObserver != null) {
			this._imageProcessingConfiguration.onUpdateParameters.remove(this._imageProcessingObserver);
		}
		
		// Pick the scene configuration if needed.
		if (configuration == null) {
			var scene = null;
            var engine = this.getEngine();
			var camera = this.getCamera();
			
			if (camera != null) {
                scene = camera.getScene();
            }
            else if (engine != null && engine.scenes != null) {
                var scenes = engine.scenes;
                scene = scenes[scenes.length - 1];
            }
            else {
                scene = Engine.LastCreatedScene;
            }
			
			this._imageProcessingConfiguration = scene.imageProcessingConfiguration;
		}
		else {
			this._imageProcessingConfiguration = configuration;
		}
		
		// Attaches observer.
		this._imageProcessingObserver = this._imageProcessingConfiguration.onUpdateParameters.add(function(_, _) {
			this._updateParameters();
		});
		
		// Ensure the effect will be rebuilt.
		if (!doNotBuild) {
			this._updateParameters();
		}
	}

	public var colorCurves(get, set):ColorCurves;
	/**
	 * Gets Color curves setup used in the effect if colorCurvesEnabled is set to true .
	 */
	inline private function get_colorCurves():ColorCurves {
		return this.imageProcessingConfiguration.colorCurves;
	}
	/**
	 * Sets Color curves setup used in the effect if colorCurvesEnabled is set to true .
	 */
	inline private function set_colorCurves(value:ColorCurves):ColorCurves {
		this.imageProcessingConfiguration.colorCurves = value;
		return value;
	}

	public var colorCurvesEnabled(get, set):Bool;
	/**
	 * Gets wether the color curves effect is enabled.
	 */
	inline private function get_colorCurvesEnabled():Bool {
		return this.imageProcessingConfiguration.colorCurvesEnabled;
	}
	/**
	 * Sets wether the color curves effect is enabled.
	 */
	inline private function set_colorCurvesEnabled(value:Bool):Bool {
		this.imageProcessingConfiguration.colorCurvesEnabled = value;
		return value;
	}

	public var colorGradingTexture(get, set):BaseTexture;
	/**
	 * Gets Color grading LUT texture used in the effect if colorGradingEnabled is set to true.
	 */
	inline private function get_colorGradingTexture():BaseTexture {
		return this.imageProcessingConfiguration.colorGradingTexture;
	}
	/**
	 * Sets Color grading LUT texture used in the effect if colorGradingEnabled is set to true.
	 */
	inline private function set_colorGradingTexture(value:BaseTexture):BaseTexture {
		this.imageProcessingConfiguration.colorGradingTexture = value;
		return value;
	}

	private var colorGradingEnabled(get, set):Bool;
	/**
	 * Gets wether the color grading effect is enabled.
	 */
	inline private function get_colorGradingEnabled():Bool {
		return this.imageProcessingConfiguration.colorGradingEnabled;
	}
	/**
	 * Gets wether the color grading effect is enabled.
	 */
	inline private function set_colorGradingEnabled(value:Bool):Bool {
		this.imageProcessingConfiguration.colorGradingEnabled = value;
		return value;
	}

	public var exposure(get, set):Float;
	/**
	 * Gets exposure used in the effect.
	 */
	inline private function get_exposure():Float {
		return this.imageProcessingConfiguration.exposure;
	}
	/**
	 * Sets exposure used in the effect.
	 */
	inline private function set_exposure(value:Float):Float {
		this.imageProcessingConfiguration.exposure = value;
		return value;
	}

	public var toneMappingEnabled(get, set):Bool;
	/**
	 * Gets wether tonemapping is enabled or not.
	 */
	inline private function get_toneMappingEnabled():Bool {
		return this._imageProcessingConfiguration.toneMappingEnabled;
	}
	/**
	 * Sets wether tonemapping is enabled or not
	 */
	inline private function set_toneMappingEnabled(value:Bool):Bool {
		this._imageProcessingConfiguration.toneMappingEnabled = value;
		return value;
	}

	public var contrast(get, set):Float;
	/**
	 * Gets contrast used in the effect.
	 */
	inline private function get_contrast():Float {
		return this.imageProcessingConfiguration.contrast;
	}
	/**
	 * Sets contrast used in the effect.
	 */
	inline private function set_contrast(value:Float):Float {
		this.imageProcessingConfiguration.contrast = value;
		return value;
	}

	public var vignetteStretch(get, set):Float;
	/**
	 * Gets Vignette stretch size.
	 */
	inline private function get_vignetteStretch():Float {
		return this.imageProcessingConfiguration.vignetteStretch;
	}
	/**
	 * Sets Vignette stretch size.
	 */
	inline private function set_vignetteStretch(value:Float):Float {
		this.imageProcessingConfiguration.vignetteStretch = value;
		return value;
	}

	public var vignetteCentreX(get, set):Float;
	/**
	 * Gets Vignette centre X Offset.
	 */
	inline private function get_vignetteCentreX():Float {
		return this.imageProcessingConfiguration.vignetteCentreX;
	}
	/**
	 * Sets Vignette centre X Offset.
	 */
	inline private function set_vignetteCentreX(value:Float):Float {
		this.imageProcessingConfiguration.vignetteCentreX = value;
		return value;
	}

	public var vignetteCentreY(get, set):Float;
	/**
	 * Gets Vignette centre Y Offset.
	 */
	inline private function get_vignetteCentreY():Float {
		return this.imageProcessingConfiguration.vignetteCentreY;
	}
	/**
	 * Sets Vignette centre Y Offset.
	 */
	inline private function set_vignetteCentreY(value:Float):Float {
		this.imageProcessingConfiguration.vignetteCentreY = value;
		return value;
	}

	public var vignetteWeight(get, set):Float;
	/**
	 * Gets Vignette weight or intensity of the vignette effect.
	 */
	inline private function get_vignetteWeight():Float {
		return this.imageProcessingConfiguration.vignetteWeight;
	}
	/**
	 * Sets Vignette weight or intensity of the vignette effect.
	 */
	inline private function set_vignetteWeight(value:Float):Float {
		this.imageProcessingConfiguration.vignetteWeight = value;
		return value;
	}

	public var vignetteColor(get, set):Color4;
	/**
	 * Gets Color of the vignette applied on the screen through the chosen blend mode (vignetteBlendMode)
	 * if vignetteEnabled is set to true.
	 */
	inline private function get_vignetteColor():Color4 {
		return this.imageProcessingConfiguration.vignetteColor;
	}
	/**
	 * Sets Color of the vignette applied on the screen through the chosen blend mode (vignetteBlendMode)
	 * if vignetteEnabled is set to true.
	 */
	inline private function set_vignetteColor(value:Color4):Color4 {
		this.imageProcessingConfiguration.vignetteColor = value;
		return value;
	}

	public var vignetteCameraFov(get, set):Float;
	/**
	 * Gets Camera field of view used by the Vignette effect.
	 */
	inline private function get_vignetteCameraFov():Float {
		return this.imageProcessingConfiguration.vignetteCameraFov;
	}
	/**
	 * Sets Camera field of view used by the Vignette effect.
	 */
	inline private function set_vignetteCameraFov(value:Float):Float {
		this.imageProcessingConfiguration.vignetteCameraFov = value;
		return value;
	}

	public var vignetteBlendMode(get, set):Int;
	/**
	 * Gets the vignette blend mode allowing different kind of effect.
	 */
	inline private function get_vignetteBlendMode():Int {
		return this.imageProcessingConfiguration.vignetteBlendMode;
	}
	/**
	 * Sets the vignette blend mode allowing different kind of effect.
	 */
	inline private function set_vignetteBlendMode(value:Int):Int {
		this.imageProcessingConfiguration.vignetteBlendMode = value;
		return value;
	}

	public var vignetteEnabled(get, set):Bool;
	/**
	 * Gets wether the vignette effect is enabled.
	 */
	inline private function get_vignetteEnabled():Bool {
		return this.imageProcessingConfiguration.vignetteEnabled;
	}
	/**
	 * Sets wether the vignette effect is enabled.
	 */
	inline private function set_vignetteEnabled(value:Bool):Bool {
		this.imageProcessingConfiguration.vignetteEnabled = value;
		return value;
	}

	@serialize()
	private var _fromLinearSpace:Bool = true;
	
	public var fromLinearSpace(get, set):Bool;
	/**
	 * Gets wether the input of the processing is in Gamma or Linear Space.
	 */
	inline private function get_fromLinearSpace():Bool {
		return this._fromLinearSpace;
	}
	/**
	 * Sets wether the input of the processing is in Gamma or Linear Space.
	 */
	inline private function set_fromLinearSpace(value:Bool):Bool {
		if (this._fromLinearSpace == value) {
			return value;
		}
		
		this._fromLinearSpace = value;
		this._updateParameters();
		return value;
	}

	/**
	 * Defines cache preventing GC.
	 */
	private var _defines:IPCD = new IPCD();
	

	public function new(name:String, options:Dynamic, ?camera:Camera, ?samplingMode:Int, ?engine:Engine, ?reusable:Bool, textureType:Int = Engine.TEXTURETYPE_UNSIGNED_INT, ?imageProcessingConfiguration:ImageProcessingConfiguration) {
		super(name, "imageProcessing", [], [], options, camera, samplingMode, engine, reusable,	null, textureType, "postprocess", null, true);
		
		// Setup the configuration as forced by the constructor. This would then not force the 
		// scene materials output in linear space and let untouched the default forward pass.
		if (imageProcessingConfiguration != null) {
			imageProcessingConfiguration.applyByPostProcess = true;
			this._attachImageProcessingConfiguration(imageProcessingConfiguration, true);
			// This will cause the shader to be compiled
			this.fromLinearSpace = false;
		}
		// Setup the default processing configuration to the scene.
		else {
			this._attachImageProcessingConfiguration(null, true);
			this.imageProcessingConfiguration.applyByPostProcess = true;
		}
		
		this.onApply = function(effect:Effect, _) {
			this.imageProcessingConfiguration.bind(effect, this.aspectRatio);
		};
	}
	
	public function getClassName():String {
		return "ImageProcessingPostProcess";
	}

	private function _updateParameters() {
		this._defines.FROMLINEARSPACE = this._fromLinearSpace ? 1 : 0;
		this.imageProcessingConfiguration.prepareDefines(this._defines, true);
		
		var defines = "";
		if (this._defines.IMAGEPROCESSING != 0) {
			defines = '#define IMAGEPROCESSING;\r\n';
		}
		if (this._defines.VIGNETTE != 0) {
			defines += '#define VIGNETTE;\r\n';
		}
		if (this._defines.VIGNETTEBLENDMODEMULTIPLY != 0) {
			defines += '#define VIGNETTEBLENDMODEMULTIPLY;\r\n';
		}
		if (this._defines.VIGNETTEBLENDMODEOPAQUE != 0) {
			defines += '#define VIGNETTEBLENDMODEOPAQUE;\r\n';
		}
		if (this._defines.TONEMAPPING != 0) {
			defines += '#define TONEMAPPING;\r\n';
		}
		if (this._defines.CONTRAST != 0) {
			defines += '#define CONTRAST;\r\n';
		}
		if (this._defines.COLORCURVES != 0) {
			defines += '#define COLORCURVES;\r\n';
		}
		if (this._defines.COLORGRADING != 0) {
			defines += '#define COLORGRADING;\r\n';
		}
		if (this._defines.FROMLINEARSPACE != 0) {
			defines += '#define FROMLINEARSPACE;\r\n';
		}
		if (this._defines.SAMPLER3DGREENDEPTH != 0) {
			defines += '#define SAMPLER3DGREENDEPTH;\r\n';
		}
		if (this._defines.SAMPLER3DBGRMAP != 0) {
			defines += '#define SAMPLER3DBGRMAP;\r\n';
		}
		if (this._defines.IMAGEPROCESSINGPOSTPROCESS != 0) {
			defines += '#define IMAGEPROCESSINGPOSTPROCESS;\r\n';
		}
		if (this._defines.EXPOSURE != 0) {
			defines += '#define EXPOSURE;\r\n';
		}
		
		var samplers = ["textureSampler"];
		ImageProcessingConfiguration.PrepareSamplers(samplers, this._defines);
		
		var uniforms = ["scale"];
		ImageProcessingConfiguration.PrepareUniforms(uniforms, this._defines);
		
		this.updateEffect(defines, uniforms, samplers);
	}

	override public function dispose(?camera:Camera) {
		super.dispose(camera);
		
		if (this._imageProcessingConfiguration != null && this._imageProcessingObserver != null) {
			this._imageProcessingConfiguration.onUpdateParameters.remove(this._imageProcessingObserver);
		}
		
		this.imageProcessingConfiguration.applyByPostProcess = false;
	}
	
}
