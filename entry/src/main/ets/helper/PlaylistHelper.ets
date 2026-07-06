import { Song } from '../entity/Song';

/** 
 * 播放列表管理
 * 全局播放队列，点击任意歌曲即加入队列，严格按队列顺序播放
 */
export class PlaylistHelper {
  /** 初始化播放列表存储 */
  public static init(): void {
    const existing = AppStorage.get<Song[]>('songList');
    if (!existing) {
      AppStorage.setOrCreate<Song[]>('songList', []);
    }
  }

  /** 上移 */
  public static moveUp(index: number): void {
    if (index <= 0) return;
    const list: Song[] = (AppStorage.get<Song[]>('songList') || []).slice();
    const temp = list[index];
    list[index] = list[index - 1];
    list[index - 1] = temp;
    AppStorage.set<Song[]>('songList', list);
    PlaylistHelper.updateCurrentIndex(list, index - 1);
  }

  /** 下移 */
  public static moveDown(index: number): void {
    const list: Song[] = (AppStorage.get<Song[]>('songList') || []).slice();
    if (index >= list.length - 1) return;
    const temp = list[index];
    list[index] = list[index + 1];
    list[index + 1] = temp;
    AppStorage.set<Song[]>('songList', list);
    PlaylistHelper.updateCurrentIndex(list, index + 1);
  }

  /** 删除歌曲 */
  public static removeSong(index: number): void {
    const list: Song[] = (AppStorage.get<Song[]>('songList') || []).slice();
    if (index < 0 || index >= list.length) return;
    list.splice(index, 1);
    AppStorage.set<Song[]>('songList', list);
    PlaylistHelper.updateCurrentIndex(list, Math.min(index, list.length - 1));
  }

  /** 清空列表 */
  public static clearAll(): void {
    AppStorage.set<Song[]>('songList', []);
    AppStorage.set<number>('index', 0);
  }
  
  /** 更新当前播放索引 */
  private static updateCurrentIndex(list: Song[], newIndex: number): void {
    if (list.length === 0) {
      AppStorage.set<number>('index', 0);
      return;
    }
    if (newIndex < 0) newIndex = 0;
    if (newIndex >= list.length) newIndex = list.length - 1;
    AppStorage.set<number>('index', newIndex);
  }
}
