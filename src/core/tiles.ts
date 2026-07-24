// Registry mapping tile names (used by map JSON legends) to indices in
// basictiles.png (8 columns × 15 rows, 16px tiles; index = row * 8 + col).
// Map legends reference these names so AI-generated maps never touch raw
// indices. Indices verified against the DebugScene tile viewer.

export interface TileInfo {
  index: number;
  solid?: boolean;
  /** Drawn on top of this base tile (e.g. trees sit on grass). */
  base?: string;
}

export const TILES: Record<string, TileInfo> = {
  grass:       { index: 11 },
  grass_pale:  { index: 10 },
  flowers:     { index: 12 },
  tall_grass:  { index: 20, base: 'grass' },
  water:       { index: 21, solid: true },
  tree:        { index: 38, base: 'grass', solid: true },
  pine:        { index: 30, base: 'grass', solid: true },
  bush:        { index: 19, base: 'grass' },
  path:        { index: 72 },
  stone_wall:  { index: 0, solid: true },
  brick:       { index: 1, solid: true },
  roof:        { index: 4, solid: true },
  wood_wall:   { index: 48, solid: true },
  window:      { index: 49, solid: true },
  door:        { index: 50, solid: true },
  sign:        { index: 67, base: 'grass', solid: true },
  well:        { index: 31, base: 'grass', solid: true },
  torch:       { index: 61, base: 'grass', solid: true },
  chest:       { index: 35, base: 'grass', solid: true },
  rock:        { index: 58, base: 'grass', solid: true },
  void:        { index: 22, solid: true },
};

export function tileInfo(name: string): TileInfo {
  const t = TILES[name];
  if (!t) throw new Error(`Unknown tile name: ${name}`);
  return t;
}
