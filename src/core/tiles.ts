// Tile registry: map-legend names -> generated tileset frames/props.
// The tileset itself is produced by tools/generate_tileset.py, which writes
// public/assets/tiles/ground.png (+ props/) and src/data/tileset.gen.json.
// Map JSON only ever references these names, never raw indices.
import manifest from '../data/tileset.gen.json';

const FRAMES: Record<string, number> = (manifest as any).tiles;

export function frameOf(name: string): number {
  const f = FRAMES[name];
  if (f === undefined) throw new Error(`Unknown tileset frame: ${name}`);
  return f;
}

export interface TileInfo {
  /** Ground frame name in the 'ground' sheet. */
  frame?: string;
  /** Prop image (y-sorted sprite, drawn over a ground base). */
  prop?: string;
  /** Ground drawn underneath (props default to grass indoors use floor). */
  base?: string;
  solid?: boolean;
  /** Animation key created in BootScene ('tile_water', 'tile_flowers'). */
  anim?: string;
  /** Auto-edge family: fringe overlays drawn where neighbors differ. */
  edges?: 'path' | 'water';
}

export const TILES: Record<string, TileInfo> = {
  // outdoor ground
  grass:      { frame: 'grass' },
  grass2:     { frame: 'grass2' },
  meadow:     { frame: 'meadow' },
  flowers:    { frame: 'flowers_0', anim: 'tile_flowers' },
  path:       { frame: 'path', edges: 'path' },
  water:      { frame: 'water_0', anim: 'tile_water', solid: true, edges: 'water' },
  // outdoor props (y-sorted)
  tall_grass: { prop: 'tallgrass', base: 'grass' },
  tree:       { prop: 'tree', base: 'grass', solid: true },
  pine:       { prop: 'pine', base: 'grass', solid: true },
  bush:       { prop: 'bush', base: 'grass' },
  sign:       { prop: 'sign', base: 'grass', solid: true },
  rock:       { prop: 'rock', base: 'grass', solid: true },
  well:       { prop: 'well', base: 'grass', solid: true },
  brazier:    { prop: 'brazier', base: 'grass', solid: true },
  fence:      { frame: 'fence', base: 'grass', solid: true },
  // buildings
  roof_red_top:    { frame: 'roof_red_top', solid: true },
  roof_red_eave:   { frame: 'roof_red_eave', solid: true },
  roof_slate_top:  { frame: 'roof_slate_top', solid: true },
  roof_slate_mid:  { frame: 'roof_slate_mid', solid: true },
  roof_slate_eave: { frame: 'roof_slate_eave', solid: true },
  wall:       { frame: 'wall', solid: true },
  wall_stone: { frame: 'wall_stone', solid: true },
  window:     { frame: 'window', solid: true },
  door:       { frame: 'door', solid: true },
  cave_wall:  { frame: 'cave_wall', solid: true },
  brick:      { frame: 'brick', solid: true },
  // interiors
  floor_wood:  { frame: 'floor_wood' },
  floor_stone: { frame: 'floor_stone' },
  rug:         { frame: 'rug' },
  rug_n:       { frame: 'rug_n' },
  rug_s:       { frame: 'rug_s' },
  mat:         { frame: 'mat' },
  iwall:       { frame: 'iwall', solid: true },
  iwall_top:   { frame: 'iwall_top', solid: true },
  counter:     { frame: 'counter', solid: true },
  shelf:       { frame: 'shelf', solid: true },
  table:       { frame: 'table', solid: true },
  bed:         { prop: 'bed', base: 'floor_wood', solid: true },
  plant:       { prop: 'plant', base: 'floor_wood', solid: true },
  brazier_in:  { prop: 'brazier', base: 'floor_stone', solid: true },
};

export function tileInfo(name: string): TileInfo {
  const t = TILES[name];
  if (!t) throw new Error(`Unknown tile name: ${name}`);
  return t;
}
