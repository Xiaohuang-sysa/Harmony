import { preferences } from '@kit.ArkData';
import { Song } from '../entity/Song';
import { Playlist } from '../entity/Playlist';
import { UserInfo } from '../entity/UserInfo';
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
  static readonly KEY_CUSTOM_PLAYLISTS = 'custom_playlists';
  static readonly KEY_PLAYLIST_SONGS_PREFIX = 'playlist_songs_';
  static readonly KEY_LOGIN_STATE = 'login_state';
  static readonly KEY_USER_INFO = 'user_info';

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

  // 自建歌单管理
  static async getCustomPlaylists(): Promise<Playlist[]> {
    return await StorageHelper.getObjectArray<Playlist>(StorageHelper.KEY_CUSTOM_PLAYLISTS);
  }

  static async createPlaylist(name: string): Promise<Playlist | null> {
    try {
      const playlists = await StorageHelper.getCustomPlaylists();
      const newPlaylist: Playlist = {
        id: Date.now(),
        name: name,
        coverImgUrl: '',
        description: '',
        trackCount: 0
      };
      playlists.push(newPlaylist);
      await StorageHelper.putObjectArray(StorageHelper.KEY_CUSTOM_PLAYLISTS, playlists);
      AppStorage.set<Playlist[]>('custom_playlists', playlists.slice());
      return newPlaylist;
    } catch (err) {
      hilog.error(0x0000, 'StorageHelper', `createPlaylist failed: ${JSON.stringify(err)}`);
      return null;
    }
  }

  static async deletePlaylist(playlistId: number): Promise<void> {
    try {
      let playlists = await StorageHelper.getCustomPlaylists();
      playlists = playlists.filter(p => p.id !== playlistId);
      await StorageHelper.putObjectArray(StorageHelper.KEY_CUSTOM_PLAYLISTS, playlists);
      await StorageHelper.put(`${StorageHelper.KEY_PLAYLIST_SONGS_PREFIX}${playlistId}`, '[]');
      AppStorage.set<Playlist[]>('custom_playlists', playlists.slice());
    } catch (err) {
      hilog.error(0x0000, 'StorageHelper', `deletePlaylist failed: ${JSON.stringify(err)}`);
    }
  }

  static async getPlaylistSongs(playlistId: number): Promise<Song[]> {
    const key = `${StorageHelper.KEY_PLAYLIST_SONGS_PREFIX}${playlistId}`;
    return await StorageHelper.getObjectArray<Song>(key);
  }

  static async addSongToPlaylist(playlistId: number, song: Song): Promise<Song[]> {
    try {
      const key = `${StorageHelper.KEY_PLAYLIST_SONGS_PREFIX}${playlistId}`;
      let songs = await StorageHelper.getPlaylistSongs(playlistId);
      if (!songs.some(s => s.id === song.id)) {
        songs.push({
          id: song.id,
          name: song.name,
          ar: song.ar,
          al: song.al,
          dt: song.dt,
          url: song.url
        } as Song);
        await StorageHelper.putObjectArray(key, songs);
        const playlists = await StorageHelper.getCustomPlaylists();
        const playlist = playlists.find(p => p.id === playlistId);
        if (playlist) {
          playlist.trackCount = songs.length;
          // 只有新增第一首歌时更新封面为首首歌封面
          if (songs.length === 1 && song.al && song.al.picUrl) {
            playlist.coverImgUrl = song.al.picUrl;
          }
          await StorageHelper.putObjectArray(StorageHelper.KEY_CUSTOM_PLAYLISTS, playlists);
          AppStorage.set<Playlist[]>('custom_playlists', playlists.slice());
        }
      }
      return songs;
    } catch (err) {
      hilog.error(0x0000, 'StorageHelper', `addSongToPlaylist failed: ${JSON.stringify(err)}`);
      return await StorageHelper.getPlaylistSongs(playlistId);
    }
  }

  static async removeSongFromPlaylist(playlistId: number, songId: number): Promise<Song[]> {
    try {
      const key = `${StorageHelper.KEY_PLAYLIST_SONGS_PREFIX}${playlistId}`;
      let songs = await StorageHelper.getPlaylistSongs(playlistId);
      songs = songs.filter(s => s.id !== songId);
      await StorageHelper.putObjectArray(key, songs);
      const playlists = await StorageHelper.getCustomPlaylists();
      const playlist = playlists.find(p => p.id === playlistId);
      if (playlist) {
        playlist.trackCount = songs.length;
        // 封面跟随第一首歌
        playlist.coverImgUrl = songs.length > 0 && songs[0].al ? songs[0].al.picUrl || '' : '';
        await StorageHelper.putObjectArray(StorageHelper.KEY_CUSTOM_PLAYLISTS, playlists);
        AppStorage.set<Playlist[]>('custom_playlists', playlists.slice());
      }
      return songs;
    } catch (err) {
      hilog.error(0x0000, 'StorageHelper', `removeSongFromPlaylist failed: ${JSON.stringify(err)}`);
      return await StorageHelper.getPlaylistSongs(playlistId);
    }
  }

  static async loadCustomPlaylists(): Promise<void> {
    try {
      const json = await StorageHelper.get(StorageHelper.KEY_CUSTOM_PLAYLISTS);
      if (json) {
        const playlists = JSON.parse(json) as Playlist[];
        AppStorage.set<Playlist[]>('custom_playlists', playlists.slice());
      }
    } catch {}
  }

  static async loadLoginState(): Promise<void> {
    try {
      const json = await StorageHelper.get(StorageHelper.KEY_LOGIN_STATE);
      if (json) {
        AppStorage.set<boolean>('is_logged_in', json === 'true');
      }
      const userJson = await StorageHelper.get(StorageHelper.KEY_USER_INFO);
      if (userJson) {
        AppStorage.set<UserInfo>('cache_user', JSON.parse(userJson) as UserInfo);
      }
    } catch {}
  }

  static async saveLoginState(isLoggedIn: boolean, userInfo: UserInfo): Promise<void> {
    await StorageHelper.put(StorageHelper.KEY_LOGIN_STATE, isLoggedIn.toString());
    await StorageHelper.put(StorageHelper.KEY_USER_INFO, JSON.stringify(userInfo));
  }
}
