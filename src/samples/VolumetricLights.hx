package samples;

import com.babylonhx.cameras.ArcRotateCamera;
import com.babylonhx.lights.PointLight;
import com.babylonhx.materials.StandardMaterial;
import com.babylonhx.materials.textures.Texture;
import com.babylonhx.math.Color3;
import com.babylonhx.math.Vector3;
import com.babylonhx.postprocess.VolumetricLightScatteringPostProcess;
import com.babylonhx.Scene;
import com.babylonhx.loading.SceneLoader;
import com.babylonhx.loading.plugins.BabylonFileLoader;
import com.babylonhx.bones.Skeleton;
import com.babylonhx.mesh.Mesh;
import com.babylonhx.mesh.AbstractMesh;
import com.babylonhx.particles.ParticleSystem;

import com.babylonhx.materials.textures.CubeTexture;
import com.babylonhx.layer.HighlightLayer;

/**
 * ...
 * @author Krtolica Vujadin
 */
class VolumetricLights {

	public function new(scene:Scene) {
		//Adding a light
		var light = new PointLight("Omni", new Vector3(20, 20, 100), scene);
		
		//Adding an Arc Rotate Camera
		var camera = new ArcRotateCamera("Camera", -0.5, 2.2, 100, Vector3.Zero(), scene);
		camera.attachControl();
		
		var skull:AbstractMesh = null;
		
		// Skybox
		var skybox = Mesh.CreateBox("skyBox", 10000.0, scene);
		var skyboxMaterial = new StandardMaterial("skyBox", scene);
		skyboxMaterial.backFaceCulling = false;
		skyboxMaterial.reflectionTexture = new CubeTexture("assets/img/skybox/skybox", scene);
		skyboxMaterial.reflectionTexture.coordinatesMode = Texture.SKYBOX_MODE;
		skyboxMaterial.diffuseColor = new Color3(0, 0, 0);
		skyboxMaterial.specularColor = new Color3(0, 0, 0);
		skybox.material = skyboxMaterial;
		skybox.infiniteDistance = true;
		
		/*var hl1 = new HighlightLayer("hl1", scene);
		hl1.outerGlow = false;
		hl1.addMesh(skybox, Color3.Green());*/
		
		// The first parameter can be used to specify which mesh to import. Here we import all meshes
		SceneLoader.RegisterPlugin(BabylonFileLoader.plugin);
		SceneLoader.ImportMesh("", "assets/models/", "skull.babylon", scene, function(newMeshes:Array<AbstractMesh>, newParticles:Array<ParticleSystem>, newSkeletons:Array<Skeleton>) {
			// Set the target of the camera to the first imported mesh
			camera.target = newMeshes[0];
			
			skull = newMeshes[0];
			
			newMeshes[0].material = new StandardMaterial("skull", scene);
			cast(newMeshes[0].material, StandardMaterial).emissiveColor = new Color3(0.2, 0.2, 0.2);
			
			// Create the "God Rays" effect (volumetric light scattering)
			var godrays = new VolumetricLightScatteringPostProcess("godrays", 1, camera, null, 100, Texture.BILINEAR_SAMPLINGMODE, scene.getEngine(), false);
			
			// By default it uses a billboard to render the sun, just apply the desired texture
			// position and scale
			cast(godrays.mesh.material, StandardMaterial).diffuseTexture = new Texture("assets/img/haxe-logo.png", scene, true, false, Texture.BILINEAR_SAMPLINGMODE);
			cast(godrays.mesh.material, StandardMaterial).diffuseTexture.hasAlpha = true;
			cast(godrays.mesh.material, StandardMaterial).backFaceCulling = false;
			godrays.mesh.position = new Vector3(-150, 150, 150);
			godrays.mesh.scaling = new Vector3(350, 350, 350);
			
			//light.position = godrays.mesh.position;		
			
			scene.getEngine().runRenderLoop(function () {
				scene.render();
			});
		});
	}
	
}
