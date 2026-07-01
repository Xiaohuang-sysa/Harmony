import { preferences } from '@kit.ArkData';
import { Song } from '../entity/Song';
import { hilog } from '@kit.PerformanceAnalysisKit';

export class StorageHelper {
  private static pref: preferences.Preferences | null = null;

  // Key constants
  static readonly KEY_PLAY_HISTORY = 'play_history';
  static readonly KEY_FAVORITES = 'favorites';
  static readonly KEY_RECENT_SEARCHES = 'recent_searches';
  static readonly KEY_PLAY_MODE = 'play_mode';
  static readonly KEY_PLAYBACK_SPEED = 'playback_speed';
  static readonly KEY_LAST_SONG_INDEX = 'last_song_index';
  static readonly KEY_LAST_SONG_LIST = 'last_song_list';
  static readonly KEY_PLAY_POSITION = 'play_position';

  static async init(context: Context): Promise<void> {
    try {
      StorageHelper.pref = await preferences.getPreferences(context, 'hw_music_preferences');
    } catch (err) {
      hilog.error(0x0000, 'StorageHelper', `init failed: ${JSON.stringify(err)}`);
    }
  }

  // 播放历史
  static async getPlayHistory(): Promise<Song[]> {
    return await StorageHelper.getObjectArray<Song>(StorageHelper.KEY_PLAY_HISTORY);
  }

  static async addPlayHistory(song: Song): Promise<void> {
    try {
      let history = await StorageHelper.getPlayHistory();
      // 去重：移除已存在的相同歌曲
      history = history.filter(s => s.id !== song.id);
      // 插入到最前面
      history.unshift({
        id: song.id,
        name: song.name,
        ar: song.ar,
        al: song.al,
        dt: song.dt,
        url: song.url
      } as Song);
      // 最多保留 50 条
      if (history.length > 50) {
        history = history.slice(0, 50);
      }
      await StorageHelper.putObjectArray(StorageHelper.KEY_PLAY_HISTORY, history);
      AppStorage.set<Song[]>('play_history', history);
    } catch (err) {
      hilog.error(0x0000, 'StorageHelper', `addPlayHistory failed: ${JSON.stringify(err)}`);
    }
  }

  // 收藏歌曲
  static async getFavorites(): Promise<Song[]> {
    return await StorageHelper.getObjectArray<Song>(StorageHelper.KEY_FAVORITES);
  }

  static async toggleFavorite(song: Song): Promise<boolean> {
    try {
      let favorites = await StorageHelper.getFavorites();
      const idx = favorites.findIndex(s => s.id === song.id);
      if (idx >= 0) {
        favorites.splice(idx, 1);
        await StorageHelper.putObjectArray(StorageHelper.KEY_FAVORITES, favorites);
        AppStorage.set<Song[]>('favorites', favorites);
        return false; // removed
      } else {
        favorites.unshift({
          id: song.id,
          name: song.name,
          ar: song.ar,
          al: song.al,
          dt: song.dt,
          url: song.url
        } as Song);
        await StorageHelper.putObjectArray(StorageHelper.KEY_FAVORITES, favorites);
        AppStorage.set<Song[]>('favorites', favorites);
        return true; // added
      }
    } catch (err) {
      hilog.error(0x0000, 'StorageHelper', `toggleFavorite failed: ${JSON.stringify(err)}`);
      return false;
    }
  }

  static async isFavorite(songId: number): Promise<boolean> {
    const favorites = await StorageHelper.getFavorites();
    return favorites.some(s => s.id === songId);
  }

  // 最近搜索
  static async getRecentSearches(): Promise<string[]> {
    try {
      const json = await StorageHelper.get(StorageHelper.KEY_RECENT_SEARCHES);
      if (json) {
        return JSON.parse(json) as string[];
      }
      return [];
    } catch {
      return [];
    }
  }

  static async addRecentSearch(keyword: string): Promise<void> {
    try {
      let searches = await StorageHelper.getRecentSearches();
      searches = searches.filter(s => s !== keyword);
      searches.unshift(keyword);
      if (searches.length > 20) {
        searches = searches.slice(0, 20);
      }
      await StorageHelper.put(StorageHelper.KEY_RECENT_SEARCHES, JSON.stringify(searches));
      AppStorage.set<string[]>('recent_searches', searches);
    } catch (err) {
      hilog.error(0x0000, 'StorageHelper', `addRecentSearch failed: ${JSON.stringify(err)}`);
    }
  }

  // 恢复播放状态
  static async restorePlaybackState(): Promise<void> {
    try {
      const position = await StorageHelper.get(StorageHelper.KEY_PLAY_POSITION);
      const mode = await StorageHelper.get(StorageHelper.KEY_PLAY_MODE);
      const speed = await StorageHelper.get(StorageHelper.KEY_PLAYBACK_SPEED);
      if (mode) AppStorage.set<number>('current_mode', parseInt(mode));
      if (speed) AppStorage.set<number>('playback_speed', parseFloat(speed));
    } catch (err) {
      hilog.error(0x0000, 'StorageHelper', `restorePlaybackState failed: ${JSON.stringify(err)}`);
    }
  }

  static async savePlaybackState(position: number): Promise<void> {
    const mode = AppStorage.get<number>('current_mode') || 0;
    const speed = AppStorage.get<number>('playback_speed') || 1.0;
    await StorageHelper.put(StorageHelper.KEY_PLAY_POSITION, position.toString());
    await StorageHelper.put(StorageHelper.KEY_PLAY_MODE, mode.toString());
    await StorageHelper.put(StorageHelper.KEY_PLAYBACK_SPEED, speed.toString());
  }

  // Low-level helpers
  private static async get(key: string): Promise<string | null> {
    if (!StorageHelper.pref) return null;
    try {
      const val = await StorageHelper.pref.get(key, '');
      if (typeof val === 'string') {
        return val;
      }
      return null;
    } catch {
      return null;
    }
  }

  private static async put(key: string, value: string): Promise<void> {
    if (!StorageHelper.pref) return;
    try {
      await StorageHelper.pref.put(key, value);
      await StorageHelper.pref.flush();
    } catch (err) {
      hilog.error(0x0000, 'StorageHelper', `put failed: ${JSON.stringify(err)}`);
    }
  }

  private static async getObjectArray<T>(key: string): Promise<T[]> {
    try {
      const json = await StorageHelper.get(key);
      if (json) {
        return JSON.parse(json) as T[];
      }
    } catch {}
    return [];
  }

  private static async putObjectArray<T>(key: string, data: T[]): Promise<void> {
    try {
      const json = JSON.stringify(data);
      await StorageHelper.put(key, json);
    } catch (err) {
      hilog.error(0x0000, 'StorageHelper', `putObjectArray failed: ${JSON.stringify(err)}`);
    }
  }

  static async loadPlayHistory(): Promise<void> {
    try {
      const json = await StorageHelper.get(StorageHelper.KEY_PLAY_HISTORY);
      if (json) {
        const history = JSON.parse(json) as Song[];
        AppStorage.set<Song[]>('play_history', history);
      }
    } catch {}
  }

  static async loadFavorites(): Promise<void> {
    try {
      const json = await StorageHelper.get(StorageHelper.KEY_FAVORITES);
      if (json) {
        const favorites = JSON.parse(json) as Song[];
        AppStorage.set<Song[]>('favorites', favorites);
      }
    } catch {}
  }
}
