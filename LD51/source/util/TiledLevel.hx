package util;

import flixel.FlxG;
import flixel.addons.editors.tiled.TiledLayer;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.addons.editors.tiled.TiledTileSet;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;
import openfl.display.Tileset;

/**
 * ...
 * @author aeveis
 */
class TiledLevel extends TiledMap
{
	public var px:Float = 0;
	public var py:Float = 0;
	public var tilemap:FlxTilemap;
	public var gid:Int = 1;

	public function new(TMXPath:Dynamic)
	{
		super(TMXPath);
		FlxG.worldBounds.set(0, 0, fullWidth, fullHeight);
		FlxG.camera.setScrollBoundsRect(0, 0, fullWidth, fullHeight);
	}

	public function loadTileMap(TileFileName:String, TiledLayerName:String = "tiles", gpuImage:Bool = false):FlxTilemap
	{
		var tiledLayer:TiledTileLayer = cast getLayer(TiledLayerName);
		if (tiledLayer.type != TiledLayerType.TILE)
			throw "Tiled Layer " + TiledLayerName + "is not a tile layer";
		tilemap = new FlxTilemap();

		var tileset:TiledTileSet = getTileSet(TileFileName);
		gid = tileset.firstGID;

		tilemap.loadMapFromCSV(tiledLayer.csvData, AssetPaths.getFile(TileFileName + (gpuImage ? "_gpu" : "")), tileWidth, tileHeight,
			FlxTilemapAutoTiling.OFF, tileset.firstGID, 1, 1);
		return tilemap;
	}

	public function loadObjects(TiledLayerName:String, callback:TiledObject->Float->Float->Void)
	{
		var tiledLayer:TiledObjectLayer = cast getLayer(TiledLayerName);
		if (tiledLayer.type != TiledLayerType.OBJECT)
			throw "Tiled Layer " + TiledLayerName + "is not a object layer";
		for (obj in tiledLayer.objects)
		{
			var x:Float = Math.round(obj.x + tilemap.x);
			var y:Float = Math.round(obj.y - obj.height + tilemap.y);
			callback(obj, x, y);
		}
	}
}
