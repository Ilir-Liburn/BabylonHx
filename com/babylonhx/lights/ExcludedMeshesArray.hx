package com.babylonhx.lights;

import com.babylonhx.mesh.AbstractMesh;

/**
 * ...
 * @author Krtolica Vujadin
 */
class ExcludedMeshesArray {

	var _items:Array<AbstractMesh>;
	var _light:Light;
	
	public var items(get, never):Array<AbstractMesh>;
	inline private function get_items():Array<AbstractMesh> {
		return this._items;
	}
	
	public var length(get, never):Int;
	inline private function get_length():Int {
		return this._items.length;
	}
	

	public function new(light:Light) {
		this._items = new Array<AbstractMesh>();
		this._light = light;
	}
	
	public function push(item:AbstractMesh):Int {
		this._items.push(item);
		
		item._resyncLighSource(this._light);
		
		return this._items.length;
	}
	
	public function splice(pos:Int, len:Int):Array<AbstractMesh> {
		var deleted = this._items.splice(pos, len);
		
		for (item in deleted) {
			item._resyncLighSource(this._light);
		}
		
		return deleted;
	}
	
	public function indexOf(item:AbstractMesh):Int {
		return this._items.indexOf(item);
	}
	
}