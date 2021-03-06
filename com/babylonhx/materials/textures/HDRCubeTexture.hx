package com.babylonhx.materials.textures;

import com.babylonhx.math.Color3;
import com.babylonhx.math.SphericalHarmonics;
import com.babylonhx.math.SphericalPolynomial;
import com.babylonhx.math.Matrix;
import com.babylonhx.math.Tools;
import com.babylonhx.math.Vector3;
import com.babylonhx.engine.Engine;
import com.babylonhx.tools.hdr.CubeMapToSphericalPolynomialTools;
import com.babylonhx.tools.hdr.PMREMGenerator;
import com.babylonhx.tools.hdr.HDRTools;

import com.babylonhx.utils.typedarray.ArrayBuffer;
import com.babylonhx.utils.typedarray.ArrayBufferView;
import com.babylonhx.utils.typedarray.Float32Array;
import com.babylonhx.utils.typedarray.UInt8Array;
import com.babylonhx.utils.typedarray.Int32Array;


/**
 * ...
 * @author Krtolica Vujadin
 */

/**
 * This represents a texture coming from an HDR input.
 * 
 * The only supported format is currently panorama picture stored in RGBE format.
 * Example of such files can be found on HDRLib: http://hdrlib.com/
 */
class HDRCubeTexture extends BaseTexture {
	
	private static var _facesMapping = [
		"left",
		"down",
		"front",
		"right",
		"up",
		"back"
	];

	private var _useInGammaSpace:Bool = false;
    private var _generateHarmonics:Bool = true;
	private var _noMipmap:Bool;
	private var _extensions:Array<String>;
	private var _textureMatrix:Matrix;
	private var _size:Int;
	private var _usePMREMGenerator:Bool;
	private var _isBABYLONPreprocessed:Bool = false;
	private var _onLoad:Void->Void = null;
    private var _onError:Void->Void = null;
	
	/**
	 * The texture URL.
	 */
	public var url:String;
	
	/**
	 * Specifies wether the texture has been generated through the PMREMGenerator tool.
	 * This is usefull at run time to apply the good shader.
	 */
	public var isPMREM:Bool = false;
	
	//private var _isBlocking:Bool = true;
	//public var isBlocking(get, set):Bool;
	///**
	 //* Sets wether or not the texture is blocking during loading.
	 //*/
	//private inline function set_isBlocking(value:Bool):Bool {
		//return this._isBlocking = value;
	//}
	///**
	 //* Gets wether or not the texture is blocking during loading.
	 //*/
	//private inline function get_isBlocking():Bool {
		//return this._isBlocking;
	//}
	
	/**
	 * Gets or sets the center of the bounding box associated with the cube texture
	 * It must define where the camera used to render the texture was set
	 */
	public var boundingBoxPosition:Vector3 = Vector3.Zero();

	private var _boundingBoxSize:Vector3;
	public var boundingBoxSize(get, set):Vector3;
	/**
	 * Gets or sets the size of the bounding box associated with the cube texture
	 * When defined, the cubemap will switch to local mode
	 * @see https://community.arm.com/graphics/b/blog/posts/reflections-based-on-local-cubemaps-in-unity
	 * @example https://www.babylonjs-playground.com/#RNASML
	 */
	function set_boundingBoxSize(value:Vector3):Vector3 {
		if (this._boundingBoxSize != null && this._boundingBoxSize.equals(value)) {
			return value;
		}
		this._boundingBoxSize = value;
		var scene = this.getScene();
		if (scene != null) {
			scene.markAllMaterialsAsDirty(Material.TextureDirtyFlag);
		}
		return value;
	}
	inline function get_boundingBoxSize():Vector3 {
		return this._boundingBoxSize;
	}
	

	/**
	 * Instantiates an HDRTexture from the following parameters.
	 * 
	 * @param url The location of the HDR raw data (Panorama stored in RGBE format)
	 * @param scene The scene the texture will be used in
	 * @param size The cubemap desired size (the more it increases the longer the generation will be) 
	 * If the size is omitted this implies you are using a preprocessed cubemap.
	 * @param noMipmap Forces to not generate the mipmap if true
	 * @param generateHarmonics Specifies whether you want to extract the polynomial harmonics during the generation process
	 * @param useInGammaSpace Specifies if the texture will be use in gamma or linear space (the PBR material requires those
	 * texture in linear space, but the standard material would require them in Gamma space)
	 * @param usePMREMGenerator Specifies whether or not to generate the CubeMap through CubeMapGen 
	 * to avoid seams issue at run time.
	 */
	public function new(url:String = "", scene:Scene, size:Int = -1, noMipmap:Bool = false, generateHarmonics:Bool = true, useInGammaSpace:Bool = false, usePMREMGenerator:Bool = false, onLoad:Void->Void = null, onError:Void->Void = null) {
		super(scene);
		
		if (url == "") {
			return;
		}
		
		this.coordinatesMode = Texture.CUBIC_MODE;
		
		this.name = url;
		this.url = url;
		this.hasAlpha = false;
		this.isCube = true;
		this._textureMatrix = Matrix.Identity();
		this._onLoad = onLoad;
		this._onError = onError;
		this.gammaSpace = false;
		
		var caps = scene.getEngine().getCaps();
		
		if (size > 0) {
			this._isBABYLONPreprocessed = false;
			this._noMipmap = noMipmap;
			this._size = size;
			this._useInGammaSpace = useInGammaSpace;
			this._usePMREMGenerator = usePMREMGenerator && caps.textureLOD && caps.textureFloat && !this._useInGammaSpace;
		}
		else {
			this._isBABYLONPreprocessed = true;
			this._noMipmap = false;
			this._useInGammaSpace = false;
			this._usePMREMGenerator = caps.textureLOD && caps.textureFloat && !this._useInGammaSpace;
		}
		this.isPMREM = this._usePMREMGenerator;
		
		this._texture = this._getFromCache(url, this._noMipmap);
		
		if (this._texture == null) {
			if (!scene.useDelayedTextureLoading) {
				this.loadTexture();
			} 
			else {
				this.delayLoadState = Engine.DELAYLOADSTATE_NOTLOADED;
			}
		}
	}
	
	/**
	 * Occurs when the file is a preprocessed .babylon.hdr file.
	 */
	private function loadBabylonTexture() {
		var mipLevels:Int = 0;
		var floatArrayView:Float32Array = null;
		var scene = this.getScene();
		
		var mipmapGenerator = (!this._useInGammaSpace && scene != null && scene.getEngine().getCaps().textureFloat) ? function(data:Array<ArrayBufferView>):Array<Array<ArrayBufferView>> {
			var mips:Array<Array<Float32Array>> = [];
			
			if (floatArrayView == null) {
				return cast mips;
			}
			
			var startIndex = 30;
			for (level in 0...mipLevels) {
				mips[level] = [];
				// Fill each pixel of the mip level.
				var faceSize:Int = Std.int(Math.pow(this._size >> level, 2) * 3);
				for (faceIndex in 0...6) {
					var faceData = floatArrayView.subarray(startIndex, startIndex + faceSize);
					mips[level].push(faceData);
					
					startIndex += faceSize;
				}
			}
			
			return cast mips;
		} : null;
		
		var callback = function(buffer:ArrayBuffer):Array<ArrayBufferView> {
			var scene = this.getScene();
			
			if (scene == null) {
				return null;
			}
			
			// Create Native Array Views
			var intArrayView:Int32Array = new Int32Array(buffer);
			floatArrayView = new Float32Array(buffer);
			
			// Fill header.
			var version = intArrayView[0]; // Version 1. (MAy be use in case of format changes for backward compaibility)
			this._size = intArrayView[1]; // CubeMap max mip face size.
			
			// Update Texture Information.
			if (this._texture == null) {
				return null;
			}
			this._texture.updateSize(this._size, this._size);
			
			// Fill polynomial information.
			this.sphericalPolynomial = new SphericalPolynomial();
			this.sphericalPolynomial.x.copyFromFloats(floatArrayView[2], floatArrayView[3], floatArrayView[4]);
			this.sphericalPolynomial.y.copyFromFloats(floatArrayView[5], floatArrayView[6], floatArrayView[7]);
			this.sphericalPolynomial.z.copyFromFloats(floatArrayView[8], floatArrayView[9], floatArrayView[10]);
			this.sphericalPolynomial.xx.copyFromFloats(floatArrayView[11], floatArrayView[12], floatArrayView[13]);
			this.sphericalPolynomial.yy.copyFromFloats(floatArrayView[14], floatArrayView[15], floatArrayView[16]);
			this.sphericalPolynomial.zz.copyFromFloats(floatArrayView[17], floatArrayView[18], floatArrayView[19]);
			this.sphericalPolynomial.xy.copyFromFloats(floatArrayView[20], floatArrayView[21], floatArrayView[22]);
			this.sphericalPolynomial.yz.copyFromFloats(floatArrayView[23], floatArrayView[24], floatArrayView[25]);
			this.sphericalPolynomial.zx.copyFromFloats(floatArrayView[26], floatArrayView[27], floatArrayView[28]);
			
			// Fill pixel data.
			mipLevels = intArrayView[29]; // Number of mip levels.
			var startIndex = 30;
			var data:Array<Float32Array> = [];
			var faceSize:Int = Std.int(Math.pow(this._size, 2) * 3);
			for (faceIndex in 0...6) {
				data.push(floatArrayView.subarray(startIndex, startIndex + faceSize));
				startIndex += faceSize;
			}
			
			var results:Array<ArrayBufferView> = [];
			var byteArray:UInt8Array = null;
			
			// Push each faces.
			for (k in 0...6) {
				var dataFace:Float32Array = null;
				
				// To be deprecated.
				if (version == 1) {
					var j:Int = ([0, 2, 4, 1, 3, 5])[k]; // Transforms +X+Y+Z... to +X-X+Y-Y...
					dataFace = data[j];
				}
				
				// If special cases.
				if (mipmapGenerator == null && dataFace != null) {					
					if (!scene.getEngine().getCaps().textureFloat) {
						// 3 channels of 1 bytes per pixel in bytes.
						var byteBuffer = new ArrayBuffer(faceSize);
						byteArray = new UInt8Array(byteBuffer);
					}
					
					for (i in 0...this._size * this._size) {
						// Put in gamma space if requested.
						if (this._useInGammaSpace) {
							dataFace[(i * 3) + 0] = Math.pow(dataFace[(i * 3) + 0], Color3.ToGammaSpace);
							dataFace[(i * 3) + 1] = Math.pow(dataFace[(i * 3) + 1], Color3.ToGammaSpace);
							dataFace[(i * 3) + 2] = Math.pow(dataFace[(i * 3) + 2], Color3.ToGammaSpace);
						}
						
						// Convert to int texture for fallback.
						if (byteArray != null) {							
							var r:Int = cast Math.max(dataFace[Std.int(i * 3) + 0] * 255, 0);
							var g:Int = cast Math.max(dataFace[Std.int(i * 3) + 1] * 255, 0);
							var b:Int = cast Math.max(dataFace[Std.int(i * 3) + 2] * 255, 0);
							
							// May use luminance instead if the result is not accurate.
							var max = Math.max(Math.max(r, g), b);
							if (max > 255) {
								var scale = 255 / max;
								r = Std.int(r * scale);
								g = Std.int(g * scale);
								b = Std.int(b * scale);
							}
							
							byteArray[Std.int(i * 3) + 0] = r;
							byteArray[Std.int(i * 3) + 1] = g;
							byteArray[Std.int(i * 3) + 2] = b;
						}
					}
				}
				
				// Fill the array accordingly.
				if (byteArray != null) {
					results.push(cast byteArray);
				}
				else {
					results.push(cast dataFace);
				}
			}
			
			return results;
		}
		
		if (scene != null) {
			this._texture = scene.getEngine().createRawCubeTextureFromUrl(this.url, scene, this._size, 
				Engine.TEXTUREFORMAT_RGB, 
				scene.getEngine().getCaps().textureFloat ? Engine.TEXTURETYPE_FLOAT : Engine.TEXTURETYPE_UNSIGNED_INT, 
				this._noMipmap, 
				callback, 
				mipmapGenerator, this._onLoad, this._onError);
		}
	}

	/**
	 * Occurs when the file is raw .hdr file.
	 */
	private function loadHDRTexture() {
		var callback = function(buffer:Dynamic):Array<ArrayBufferView> {
			var scene = this.getScene();
			
			if (scene == null) {
				return null;
			}
			
			// Extract the raw linear data.
			var data = HDRTools.GetCubeMapTextureData(buffer, this._size);
			
			// Generate harmonics if needed.
			if (this._generateHarmonics) {
				this.sphericalPolynomial = CubeMapToSphericalPolynomialTools.ConvertCubeMapToSphericalPolynomial(data);
			}
			
			var results:Array<ArrayBufferView> = [];
			var byteArray:UInt8Array = null;
			
			// Push each faces.
			for (j in 0...6) {
				// Create uintarray fallback.
				var textureFloat = scene.getEngine().getCaps().textureFloat;
				if ( #if js textureFloat == null || #end textureFloat == false) {
					// 3 channels of 1 bytes per pixel in bytes.
					trace(textureFloat);
					var byteBuffer = new ArrayBuffer(this._size * this._size * 3);
					byteArray = new UInt8Array(byteBuffer);
				}
				
				var dataFace:Float32Array = Reflect.getProperty(data, HDRCubeTexture._facesMapping[j]);
				
				// If special cases.
				if (this._useInGammaSpace || byteArray != null) {
					for (i in 0...this._size * this._size) {
						// Put in gamma space if requested.
						if (this._useInGammaSpace) {
							dataFace[(i * 3) + 0] = Math.pow(dataFace[(i * 3) + 0], Color3.ToGammaSpace);
							dataFace[(i * 3) + 1] = Math.pow(dataFace[(i * 3) + 1], Color3.ToGammaSpace);
							dataFace[(i * 3) + 2] = Math.pow(dataFace[(i * 3) + 2], Color3.ToGammaSpace);
						}
						
						// Convert to int texture for fallback.
						if (byteArray != null) {
							var r:Int = cast Math.max(dataFace[Std.int(i * 3) + 0] * 255, 0);
							var g:Int = cast Math.max(dataFace[Std.int(i * 3) + 1] * 255, 0);
							var b:Int = cast Math.max(dataFace[Std.int(i * 3) + 2] * 255, 0);
							
							// May use luminance instead if the result is not accurate.
							var max = Math.max(Math.max(r, g), b);
							if (max > 255) {
								var scale = 255 / max;
								r = Std.int(r * scale);
								g = Std.int(g * scale);
								b = Std.int(b * scale);
							}
							
							byteArray[(i * 3) + 0] = r;
							byteArray[(i * 3) + 1] = g;
							byteArray[(i * 3) + 2] = b;
						}
					}
				}
				
				if (byteArray != null) {
					results.push(byteArray);
				}
				else {
					results.push(dataFace);
				}
			}
			
			return results;
		};
		
		var mipmapGenerator = null;
		
		// TODO. Implement In code PMREM Generator following the LYS toolset generation.
		//if (!this._noMipmap && this._usePMREMGenerator) {
			//mipmapGenerator = function(data:Array<ArrayBufferView>):Array<Array<ArrayBufferView>> {
				//// Custom setup of the generator matching with the PBR shader values.
				//var generator = new PMREMGenerator(
					//data,
					//this._size,
					//this._size,
					//0,
					//3,
					//this.getScene().getEngine().getCaps().textureFloat,
					//2048,
					//0.25,
					//false,
					//true
				//);
				//
				//return generator.filterCubeMap();
			//};
		//}
		
		var scene = this.getScene();
		
		if (scene != null) {
			this._texture = scene.getEngine().createRawCubeTextureFromUrl(this.url, scene, this._size, 
				Engine.TEXTUREFORMAT_RGB, 
				scene.getEngine().getCaps().textureFloat ? Engine.TEXTURETYPE_FLOAT : Engine.TEXTURETYPE_UNSIGNED_INT, 
				this._noMipmap, 
				callback, 
				mipmapGenerator, this._onLoad, this._onError);
		}
	}

	/**
	 * Starts the loading process of the texture.
	 */
	private function loadTexture() {
		if (this._isBABYLONPreprocessed) {
			this.loadBabylonTexture();
		}
		else {
			this.loadHDRTexture();
		}
	}
	
	override public function clone():HDRCubeTexture {
		var scene = this.getScene();
		if (scene == null) {
			return this;
		}
		
		var size = this._isBABYLONPreprocessed ? null : this._size;
		var newTexture = new HDRCubeTexture(this.url, scene, size, this._noMipmap, 
			this._generateHarmonics, this._useInGammaSpace, this._usePMREMGenerator);
		
		// Base texture
		newTexture.level = this.level;
		newTexture.wrapU = this.wrapU;
		newTexture.wrapV = this.wrapV;
		newTexture.coordinatesIndex = this.coordinatesIndex;
		newTexture.coordinatesMode = this.coordinatesMode;
		
		return newTexture;
	}

	// Methods
	override public function delayLoad() {
		if (this.delayLoadState != Engine.DELAYLOADSTATE_NOTLOADED) {
			return;
		}
		
		this.delayLoadState = Engine.DELAYLOADSTATE_LOADED;
		this._texture = this._getFromCache(this.url, this._noMipmap);
		
		if (this._texture == null) {
			this.loadTexture();
		}
	}

	override public function getReflectionTextureMatrix():Matrix {
		return this._textureMatrix;
	}
	
	public function setReflectionTextureMatrix(value:Matrix) {
        this._textureMatrix = value;
    }
	
	public static function Parse(parsedTexture:Dynamic, scene:Scene, rootUrl:String):HDRCubeTexture {
		var texture:HDRCubeTexture = null;
		if (parsedTexture.name != null && (parsedTexture.isRenderTarget == null || parsedTexture.isRenderTarget == false)) {
			var size = parsedTexture.isBABYLONPreprocessed ? null : parsedTexture.size;
			texture = new HDRCubeTexture(rootUrl + parsedTexture.name, scene, size, 
				parsedTexture.generateHarmonics, parsedTexture.useInGammaSpace, parsedTexture.usePMREMGenerator);
			texture.name = parsedTexture.name;
			texture.hasAlpha = parsedTexture.hasAlpha;
			texture.level = parsedTexture.level;
			texture.coordinatesMode = parsedTexture.coordinatesMode;
			texture.isBlocking = parsedTexture.isBlocking;
		}
		if (texture != null) {
			if (parsedTexture.boundingBoxPosition != null) {
				texture.boundingBoxPosition = Vector3.FromArray(cast parsedTexture.boundingBoxPosition);
			}
			if (parsedTexture.boundingBoxSize) {
				texture.boundingBoxSize = Vector3.FromArray(cast parsedTexture.boundingBoxSize);
			}
		}
		
		return texture;
	}

	override public function serialize():Dynamic {
		if (this.name == null) {
			return null;
		}
		
		var serializationObject:Dynamic = { };
		serializationObject.name = this.name;
		serializationObject.hasAlpha = this.hasAlpha;
		serializationObject.isCube = true;
		serializationObject.level = this.level;
		serializationObject.size = this._size;
		serializationObject.coordinatesMode = this.coordinatesMode;
		serializationObject.useInGammaSpace = this._useInGammaSpace;
		serializationObject.generateHarmonics = this._generateHarmonics;
		serializationObject.usePMREMGenerator = this._usePMREMGenerator;
		serializationObject.isBABYLONPreprocessed = this._isBABYLONPreprocessed;
		serializationObject.customType = "BABYLON.HDRCubeTexture";
		serializationObject.noMipmap = this._noMipmap;
		serializationObject.isBlocking = this._isBlocking;
		
		return serializationObject;
	}
	
	/**
	 * Saves as a file the data contained in the texture in a binary format.
	 * This can be used to prevent the long loading tie associated with creating the seamless texture as well
	 * as the spherical used in the lighting.
	 * @param url The HDR file url.
	 * @param size The size of the texture data to generate (one of the cubemap face desired width).
	 * @param onError Method called if any error happens during download.
	 * @return The packed binary data.
	 */
	public static function generateBabylonHDROnDisk(url:String, size:Int, onError:Dynamic) {
		// VK TODO
		#if js
		var callback = function (buffer:UInt8Array) {
			/*var data = untyped __js__("new Blob([buffer], { type: 'application/octet-stream' })");
			
			// Returns a URL you can use as a href.
			var objUrl = js.Browser.window.URL.createObjectURL(data);
			
			// Simulates a link to it and click to dowload.
			var a = js.Browser.document.createElement("a");
			document.body.appendChild(a);
			a.style.display = "none";
			a.href = objUrl;
			a.download = "envmap.babylon.hdr";
			a.click();*/
		};
		#else
		var callback = function (buffer:UInt8Array) {
			
		};
		#end
		
		HDRCubeTexture.generateBabylonHDR(url, size, callback, onError);
	}

	/**
	 * Serializes the data contained in the texture in a binary format.
	 * This can be used to prevent the long loading tie associated with creating the seamless texture as well
	 * as the spherical used in the lighting.
	 * @param url The HDR file url.
	 * @param size The size of the texture data to generate (one of the cubemap face desired width).
	 * @param onError Method called if any error happens during download.
	 * @return The packed binary data.
	 */
	public static function generateBabylonHDR(url:String = "", size:Int, callback:UInt8Array->Void, ?onError:Void->Void) {
		// Needs the url tho create the texture.
		if (url == "") {
			return;
		}
		
		// Check Power of two size.
		if (!Tools.IsExponentOfTwo(size)) {
			return;
		}
		
		var getDataCallback = function(dataBuffer:Dynamic) {
			// Extract the raw linear data.
			var cubeData = HDRTools.GetCubeMapTextureData(dataBuffer, size);
			
			// Generate harmonics if needed.
			var sphericalPolynomial = CubeMapToSphericalPolynomialTools.ConvertCubeMapToSphericalPolynomial(cubeData);
			
			// Generate seamless faces
			var mipGeneratorArray:Array<ArrayBufferView> = [];
			// Data are known to be in +X +Y +Z -X -Y -Z
			// mipmmapGenerator data is expected to be order in +X -X +Y -Y +Z -Z
			mipGeneratorArray.push(cubeData.right); // +X
			mipGeneratorArray.push(cubeData.left); // -X
			mipGeneratorArray.push(cubeData.up); // +Y
			mipGeneratorArray.push(cubeData.down); // -Y
			mipGeneratorArray.push(cubeData.front); // +Z
			mipGeneratorArray.push(cubeData.back); // -Z
			
			// Custom setup of the generator matching with the PBR shader values.
			var generator = new PMREMGenerator(
				mipGeneratorArray,
				size,
				size,
				0,
				3,
				true,
				2048,
				0.25,
				false,
				true
			);
			var mippedData = generator.filterCubeMap();
			
			// Compute required byte length.
			var byteLength = 1 * 4; // Raw Data Version int32.
			byteLength += 4; // CubeMap max mip face size int32.
			byteLength += (9 * 3 * 4); // Spherical polynomial byte length 9 Vector 3 of floats.
			// Add data size.
			byteLength += 4; // Number of mip levels int32.
			for (level in 0...mippedData.length) {
				var mipSize = size >> level;
				byteLength += (6 * mipSize * mipSize * 3 * 4); // 6 faces of size squared rgb float pixels.
			}
			
			// Prepare binary structure.
			var buffer = new ArrayBuffer(byteLength);
			var intArrayView = new Int32Array(buffer);
			var floatArrayView = new Float32Array(buffer);
			
			// Fill header.
			intArrayView[0] = 1; // Version 1.
			intArrayView[1] = size; // CubeMap max mip face size.
			
			// Fill polynomial information.
			sphericalPolynomial.x.toFloat32Array(floatArrayView, 2);
			sphericalPolynomial.y.toFloat32Array(floatArrayView, 5);
			sphericalPolynomial.z.toFloat32Array(floatArrayView, 8);
			sphericalPolynomial.xx.toFloat32Array(floatArrayView, 11);
			sphericalPolynomial.yy.toFloat32Array(floatArrayView, 14);
			sphericalPolynomial.zz.toFloat32Array(floatArrayView, 17);
			sphericalPolynomial.xy.toFloat32Array(floatArrayView, 20);
			sphericalPolynomial.yz.toFloat32Array(floatArrayView, 23);
			sphericalPolynomial.zx.toFloat32Array(floatArrayView, 26);
			
			// Fill pixel data.
			intArrayView[29] = mippedData.length; // Number of mip levels.
			var startIndex = 30;
			for (level in 0...mippedData.length) {
				// Fill each pixel of the mip level.
				var faceSize:Int = Std.int(Math.pow(size >> level, 2) * 3);
				for (faceIndex in 0...6) {
					floatArrayView.set( #if js cast #end mippedData[level][faceIndex], startIndex);
					startIndex += faceSize;
				}
			}
			
			// Callback.
			callback(new UInt8Array(buffer));
		};
		
		// Download and process.
		com.babylonhx.tools.Tools.LoadFile(url, function(data:Dynamic) {
			getDataCallback(data);
		}, null);
	}
	
}
