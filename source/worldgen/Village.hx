package worldgen;
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;

using flixel.util.FlxArrayUtil;

/**
 * ...
 * @author Masadow
 */
class Village extends FlxGroup
{
    private static var nameLeft : Array<String> = new Array<String>();
    
    public static function isBuildable(tileID : Int, world : World, erase : Bool = false) {
        var terrain = world.tilemap.getTileByIndex(tileID);
        var object = terrain;
        if (world.config.villages.objectLayer)
            object = world.objects.getTileByIndex(tileID);
        return terrain == world.tinfo.grass() || (erase && object == world.tinfo.village());
    }
    
    public static function spawn(world : World) {
        for (i in 0...world.tilemap.totalTiles) {
            if (isBuildable(i, world) && Math.random() < world.config.villages.spawnRate) {
                var x = i % world.tilemap.widthInTiles;
                var y = Math.floor(i / world.tilemap.widthInTiles);
                if (Helper.checkTilesInCircle(x, y, world.config.villages.minDistance, function (x, y) {
                    if (world.config.villages.objectLayer)
                        return world.objects.getTile(x, y) != world.tinfo.village();
                    else
                        return world.tilemap.getTile(x, y) != world.tinfo.village();
                })) {
                    world.villages.add(new Village(world, new FlxPoint(x, y)));
                }
            }
        }
    }
   
    //World coordinates of the village
    public var worldPos(default, null) : FlxPoint;
    private var text : FlxText;
    private var world : World;
    private var tilemap : FlxTilemap;
    public var name : String;
    public var tiles : Array<FlxPoint>;

    public function new(world : World, coords : FlxPoint)
    {
        super();
        this.world = world;
        worldPos = coords;
        tiles = [coords];
        tilemap = world.config.villages.objectLayer ? world.objects : world.tilemap;

        //Pick a name from bank
        if (nameLeft.length == 0) {
            nameLeft = world.config.villages.nameBank.copy();
        }
        name = world.random.getObject(nameLeft);
        nameLeft.fastSplice(name);
        
        add((text = new FlxText(0, 0, 0, name)));

        tilemap.setTile(Std.int(coords.x), Std.int(coords.y), world.tinfo.village());
        
        extend(world.random.int(world.config.villages.minSize, world.config.villages.maxSize) - 1);
        
        rescale();
    }
    
    public function rescale() {
        text.x = tilemap.x + world.tinfo.width() * worldPos.x * tilemap.scale.x - text.width * 0.5;
        text.y = tilemap.y + world.tinfo.height() * worldPos.y * tilemap.scale.y;
    }
    
    private function excludeAround(current : FlxPoint, erase : Bool) {
        var exclude : Array<Int> = [];
        if (current.x == 0 || !isBuildable(Std.int(current.x - 1) + tilemap.widthInTiles * Std.int(current.y), world, erase))
            exclude.push(0); //LEFT
        if (current.y == 0 || !isBuildable(Std.int(current.x) + tilemap.widthInTiles * Std.int(current.y - 1), world, erase))
            exclude.push(1); //TOP
        if (current.x == tilemap.widthInTiles - 1 || !isBuildable(Std.int(current.x) + 1 + tilemap.widthInTiles * Std.int(current.y), world, erase))
            exclude.push(2); //RIGHT
        if (current.y == tilemap.heightInTiles - 1 || !isBuildable(Std.int(current.x) + tilemap.widthInTiles *  Std.int(current.y + 1), world, erase))
            exclude.push(3); //BOTTOM
        return exclude;
    }
    
    //It is possible to ask for a certain amount of buildable tiles
    public function isExtensible(sizeNeeded : Int = 1) {
        //Check if the village is extensible
    }
    
    public function extend(size : Int) {
        var current = worldPos;
        switch (world.config.villages.shape) {
            case RANDOM:
                //Problems not handled
                //  * Not enough space remaining
                //  * Touching villages
                //Pick a non village neighboor tile
                while (size > 0) {
                    var exclude = excludeAround(current, false);
                    if (exclude.length == 4) { // We are stuck, we move and ignore this turn
                        exclude = excludeAround(current, true);
                        if (exclude.length == 4) {
                            //Inifinite loop is possible if the village is surrounded by obstacles and there are not enough tiles remaining
                            size = 0;
                            break;
                        }
                        size++;
                    }
                    var dest = world.random.int(0, 3, exclude);
                    if (dest == 0)
                        current.x--;
                    if (dest == 1)
                        current.y--;
                    else if (dest == 2)
                        current.x++;
                    else if (dest == 3)
                        current.y++;
                    size--;
                    reclaim(current);
                }
            case REALISTIC:
            case SQUARE:
            case ROUND:
        }
    }
    
    public function reclaim(pos : FlxPoint) {
        tiles.push(pos);
        tilemap.setTile(Std.int(pos.x), Std.int(pos.y), world.tinfo.village());
    }
    
}