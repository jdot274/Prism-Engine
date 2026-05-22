export interface PlayerState {
  id: string;
  position: { x: number; y: number; z: number };
  rotation: { x: number; y: number; z: number; w: number };
}
