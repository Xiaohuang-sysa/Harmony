import { Artist } from './Artist';
import { Album } from './Album';

export class Song {
  id: number = 0;
  name: string = '';
  ar: Artist[] = [];
  al: Album = new Album();
  url: string = '';
  fee: number = 0;
  dt: number = 0;
}
