package com.babylonhx.materials.textures.procedurals;

abstract RGBA(Int) from Int from Int to Int to Int {

	public static inline var White:RGBA = 0xffffffff;

	public var r(get, set):Int;
	public var g(get, set):Int;
	public var b(get, set):Int;
	public var a(get, set):Int;

	public var val(get, never):Int;
	
	inline function get_val():Int {
		return this;
	}

	inline function get_r():Int {
		return (this & 0x00ff0000) >>> 16;
	}
	inline function set_r(val:Int):Int {
		this = (a << 24) | (val << 16) | (g << 8) | b;
		return val;
	}
	
	inline function get_g(): Int {
		return (this & 0x0000ff00) >>> 8;
	}
	inline function set_g(val:Int):Int {
		this = (a << 24) | (r << 16) | (val << 8) | b;
		return val;
	}
	
	inline function get_b(): Int {
		return this & 0x000000ff;
	}
	inline function set_b(val:Int):Int {
		this = (a << 24) | (r << 16) | (g << 8) | val;
		return val;
	}
	
	inline function get_a(): Int {
		return this >>> 24;
	}
	inline function set_a(val:Int):Int {
		this = (val << 24) | (r << 16) | (g << 8) | b;
		return val;
	}

}	
