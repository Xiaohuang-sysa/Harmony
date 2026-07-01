import { SongResult } from './SongResult';

export class SongResponse {
  result: SongResult = new SongResult();
  code: number = 200;
}
