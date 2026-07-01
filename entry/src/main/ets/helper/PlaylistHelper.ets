import { Song } from '../entity/Song';

/**
 * 播放列表管理
 * 自动记录所有点播过的歌曲，支持排序和删除
 */
export class PlaylistHelper {
  /** 初始化播放列表存储 */
  public static init(): void {
    const existing = AppStorage.get<Song[]>('playlist');
    if (!existing) {
      AppStorage.setOrCreate<Song[]>('playlist', []);
    }
  }

  /** 获取播放列表 */
  public static getPlaylist(): Song[] {
    return AppStorage.get<Song[]>('playlist') || [];
  }

  /** 添加歌曲到播放列表（已在顶部则移到最前） */
  public static addSong(song: Song): void {
    const list: Song[] = (AppStorage.get<Song[]>('playlist') || []).slice();
    const idx = list.findIndex(s => s.id === song.id);
    if (idx !== -1) {
      list.splice(idx, 1);
    }
    list.unshift(song);
    if (list.length > 200) {
      list.pop();
    }
    AppStorage.set<Song[]>('playlist', list);
  }

  /** 上移 */
  public static moveUp(index: number): void {
    if (index <= 0) return;
    const list: Song[] = (AppStorage.get<Song[]>('playlist') || []).slice();
    const temp = list[index];
    list[index] = list[index - 1];
    list[index - 1] = temp;
    AppStorage.set<Song[]>('playlist', list);
  }

  /** 下移 */
  public static moveDown(index: number): void {
    const list: Song[] = (AppStorage.get<Song[]>('playlist') || []).slice();
    if (index >= list.length - 1) return;
    const temp = list[index];
    list[index] = list[index + 1];
    list[index + 1] = temp;
    AppStorage.set<Song[]>('playlist', list);
  }

  /** 删除歌曲 */
  public static removeSong(index: number): void {
    const list: Song[] = (AppStorage.get<Song[]>('playlist') || []).slice();
    if (index < 0 || index >= list.length) return;
    list.splice(index, 1);
    AppStorage.set<Song[]>('playlist', list);
  }

  /** 清空列表 */
  public static clearAll(): void {
    AppStorage.set<Song[]>('playlist', []);
  }

  /** 从指定索引位置播放 */
  public static playAtIndex(index: number): void {
    const list = PlaylistHelper.getPlaylist();
    if (index < 0 || index >= list.length) return;
    const songList: Song[] = (AppStorage.get<Song[]>('songList') || []).slice();
    const song = list[index];
    const si = songList.findIndex(s => s.id === song.id);
    if (si === -1) {
      songList.unshift(song);
      AppStorage.set<Song[]>('songList', songList);
    }
    AppStorage.set<number>('index', si === -1 ? 0 : si);
    AppStorage.set<Song>('songDetail', song);
    AppStorage.set<boolean>('needs_play', true);
  }
}
