import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type Context from '@ohos.app.ability.common';
import { CloudSongObject, CloudPlaylistObject, CloudPlaylistSongObject, CloudFavoriteObject } from '../entity/CloudSongObject';

export class CloudDBHelper {
  private static pref: preferences.Preferences | null = null;
  private static isInitialized: boolean = false;

  private static KEY_CLOUD_SONGS = 'cloud_songs';
  private static KEY_CLOUD_PLAYLISTS = 'cloud_playlists';
  private static KEY_CLOUD_PLAYLIST_SONGS = 'cloud_playlist_songs';
  private static KEY_CLOUD_FAVORITES = 'cloud_favorites';

  static async init(context: Context): Promise<void> {
    if (CloudDBHelper.isInitialized) return;
    try {
      CloudDBHelper.pref = await preferences.getPreferences(context, 'cloud_sync_db');
      CloudDBHelper.isInitialized = true;
      hilog.info(0x0000, 'CloudDBHelper', 'CloudDB initialized successfully');
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `CloudDB init failed: ${JSON.stringify(err)}`);
      throw new Error(`CloudDB init failed: ${JSON.stringify(err)}`);
    }
  }

  private static async get(key: string): Promise<string | null> {
    if (!CloudDBHelper.pref) return null;
    try {
      const val = await CloudDBHelper.pref.get(key, '');
      if (typeof val === 'string') {
        return val;
      }
      return null;
    } catch {
      return null;
    }
  }

  private static async put(key: string, value: string): Promise<void> {
    if (!CloudDBHelper.pref) return;
    try {
      await CloudDBHelper.pref.put(key, value);
      await CloudDBHelper.pref.flush();
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `put failed: ${JSON.stringify(err)}`);
      throw new Error(`put failed: ${JSON.stringify(err)}`);
    }
  }

  static async getCloudSongs(userId: string): Promise<CloudSongObject[]> {
    try {
      const json = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_SONGS);
      if (json) {
        const allSongs: CloudSongObject[] = JSON.parse(json);
        return allSongs.filter(s => s.userId === userId);
      }
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `getCloudSongs failed: ${JSON.stringify(err)}`);
    }
    return [];
  }

  static async insertSong(song: CloudSongObject): Promise<number> {
    try {
      const json = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_SONGS);
      const songs: CloudSongObject[] = json ? JSON.parse(json) : [];
      const existing = songs.find(s => s.songId === song.songId && s.userId === song.userId);
      if (!existing) {
        song.id = Date.now();
        songs.push(song);
        await CloudDBHelper.put(CloudDBHelper.KEY_CLOUD_SONGS, JSON.stringify(songs));
      }
      return song.id;
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `insertSong failed: ${JSON.stringify(err)}`);
      throw new Error(`insertSong failed: ${JSON.stringify(err)}`);
    }
  }

  static async deleteSong(id: number, userId: string): Promise<void> {
    try {
      const json = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_SONGS);
      let songs: CloudSongObject[] = json ? JSON.parse(json) : [];
      songs = songs.filter(s => !(s.id === id && s.userId === userId));
      await CloudDBHelper.put(CloudDBHelper.KEY_CLOUD_SONGS, JSON.stringify(songs));
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `deleteSong failed: ${JSON.stringify(err)}`);
      throw new Error(`deleteSong failed: ${JSON.stringify(err)}`);
    }
  }

  static async updateSong(song: CloudSongObject): Promise<void> {
    try {
      const json = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_SONGS);
      let songs: CloudSongObject[] = json ? JSON.parse(json) : [];
      const index = songs.findIndex(s => s.id === song.id && s.userId === song.userId);
      if (index >= 0) {
        songs[index] = song;
        await CloudDBHelper.put(CloudDBHelper.KEY_CLOUD_SONGS, JSON.stringify(songs));
      }
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `updateSong failed: ${JSON.stringify(err)}`);
      throw new Error(`updateSong failed: ${JSON.stringify(err)}`);
    }
  }

  static async getCloudPlaylists(userId: string): Promise<CloudPlaylistObject[]> {
    try {
      const json = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_PLAYLISTS);
      if (json) {
        const allPlaylists: CloudPlaylistObject[] = JSON.parse(json);
        return allPlaylists.filter(p => p.userId === userId);
      }
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `getCloudPlaylists failed: ${JSON.stringify(err)}`);
    }
    return [];
  }

  static async insertPlaylist(playlist: CloudPlaylistObject): Promise<number> {
    try {
      const json = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_PLAYLISTS);
      const playlists: CloudPlaylistObject[] = json ? JSON.parse(json) : [];
      const existing = playlists.find(p => p.name === playlist.name && p.userId === playlist.userId);
      if (!existing) {
        playlist.id = Date.now();
        playlists.push(playlist);
        await CloudDBHelper.put(CloudDBHelper.KEY_CLOUD_PLAYLISTS, JSON.stringify(playlists));
      }
      return playlist.id;
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `insertPlaylist failed: ${JSON.stringify(err)}`);
      throw new Error(`insertPlaylist failed: ${JSON.stringify(err)}`);
    }
  }

  static async deletePlaylist(id: number, userId: string): Promise<void> {
    try {
      const json = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_PLAYLISTS);
      let playlists: CloudPlaylistObject[] = json ? JSON.parse(json) : [];
      playlists = playlists.filter(p => !(p.id === id && p.userId === userId));
      await CloudDBHelper.put(CloudDBHelper.KEY_CLOUD_PLAYLISTS, JSON.stringify(playlists));

      const songJson = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_PLAYLIST_SONGS);
      let songs: CloudPlaylistSongObject[] = songJson ? JSON.parse(songJson) : [];
      songs = songs.filter(s => s.playlistId !== id);
      await CloudDBHelper.put(CloudDBHelper.KEY_CLOUD_PLAYLIST_SONGS, JSON.stringify(songs));
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `deletePlaylist failed: ${JSON.stringify(err)}`);
      throw new Error(`deletePlaylist failed: ${JSON.stringify(err)}`);
    }
  }

  static async getCloudPlaylistSongs(playlistId: number, userId: string): Promise<CloudPlaylistSongObject[]> {
    try {
      const json = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_PLAYLIST_SONGS);
      if (json) {
        const allSongs: CloudPlaylistSongObject[] = JSON.parse(json);
        return allSongs.filter(s => s.playlistId === playlistId && s.userId === userId);
      }
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `getCloudPlaylistSongs failed: ${JSON.stringify(err)}`);
    }
    return [];
  }

  static async insertPlaylistSong(song: CloudPlaylistSongObject): Promise<number> {
    try {
      const json = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_PLAYLIST_SONGS);
      const songs: CloudPlaylistSongObject[] = json ? JSON.parse(json) : [];
      const existing = songs.find(s => s.playlistId === song.playlistId && s.songId === song.songId && s.userId === song.userId);
      if (!existing) {
        song.id = Date.now();
        songs.push(song);
        await CloudDBHelper.put(CloudDBHelper.KEY_CLOUD_PLAYLIST_SONGS, JSON.stringify(songs));
      }
      return song.id;
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `insertPlaylistSong failed: ${JSON.stringify(err)}`);
      throw new Error(`insertPlaylistSong failed: ${JSON.stringify(err)}`);
    }
  }

  static async deletePlaylistSong(id: number, userId: string): Promise<void> {
    try {
      const json = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_PLAYLIST_SONGS);
      let songs: CloudPlaylistSongObject[] = json ? JSON.parse(json) : [];
      songs = songs.filter(s => !(s.id === id && s.userId === userId));
      await CloudDBHelper.put(CloudDBHelper.KEY_CLOUD_PLAYLIST_SONGS, JSON.stringify(songs));
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `deletePlaylistSong failed: ${JSON.stringify(err)}`);
      throw new Error(`deletePlaylistSong failed: ${JSON.stringify(err)}`);
    }
  }

  static async getCloudFavorites(userId: string): Promise<CloudFavoriteObject[]> {
    try {
      const json = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_FAVORITES);
      if (json) {
        const allFavorites: CloudFavoriteObject[] = JSON.parse(json);
        return allFavorites.filter(f => f.userId === userId);
      }
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `getCloudFavorites failed: ${JSON.stringify(err)}`);
    }
    return [];
  }

  static async insertFavorite(favorite: CloudFavoriteObject): Promise<number> {
    try {
      const json = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_FAVORITES);
      const favorites: CloudFavoriteObject[] = json ? JSON.parse(json) : [];
      const existing = favorites.find(f => f.songId === favorite.songId && f.userId === favorite.userId);
      if (!existing) {
        favorite.id = Date.now();
        favorites.push(favorite);
        await CloudDBHelper.put(CloudDBHelper.KEY_CLOUD_FAVORITES, JSON.stringify(favorites));
      }
      return favorite.id;
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `insertFavorite failed: ${JSON.stringify(err)}`);
      throw new Error(`insertFavorite failed: ${JSON.stringify(err)}`);
    }
  }

  static async deleteFavorite(songId: number, userId: string): Promise<void> {
    try {
      const json = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_FAVORITES);
      let favorites: CloudFavoriteObject[] = json ? JSON.parse(json) : [];
      favorites = favorites.filter(f => !(f.songId === songId && f.userId === userId));
      await CloudDBHelper.put(CloudDBHelper.KEY_CLOUD_FAVORITES, JSON.stringify(favorites));
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `deleteFavorite failed: ${JSON.stringify(err)}`);
      throw new Error(`deleteFavorite failed: ${JSON.stringify(err)}`);
    }
  }

  static async sync(): Promise<void> {
    try {
      if (CloudDBHelper.pref) {
        await CloudDBHelper.pref.flush();
      }
      hilog.info(0x0000, 'CloudDBHelper', 'CloudDB sync completed');
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `sync failed: ${JSON.stringify(err)}`);
      throw new Error(`sync failed: ${JSON.stringify(err)}`);
    }
  }

  static async close(): Promise<void> {
    CloudDBHelper.pref = null;
    CloudDBHelper.isInitialized = false;
  }

  static async clearAll(userId: string): Promise<void> {
    try {
      let json = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_SONGS);
      let songs: CloudSongObject[] = json ? JSON.parse(json) : [];
      songs = songs.filter(s => s.userId !== userId);
      await CloudDBHelper.put(CloudDBHelper.KEY_CLOUD_SONGS, JSON.stringify(songs));

      json = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_PLAYLISTS);
      let playlists: CloudPlaylistObject[] = json ? JSON.parse(json) : [];
      playlists = playlists.filter(p => p.userId !== userId);
      await CloudDBHelper.put(CloudDBHelper.KEY_CLOUD_PLAYLISTS, JSON.stringify(playlists));

      json = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_PLAYLIST_SONGS);
      let playlistSongs: CloudPlaylistSongObject[] = json ? JSON.parse(json) : [];
      playlistSongs = playlistSongs.filter(s => s.userId !== userId);
      await CloudDBHelper.put(CloudDBHelper.KEY_CLOUD_PLAYLIST_SONGS, JSON.stringify(playlistSongs));

      json = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_FAVORITES);
      let favs: CloudFavoriteObject[] = json ? JSON.parse(json) : [];
      favs = favs.filter(f => f.userId !== userId);
      await CloudDBHelper.put(CloudDBHelper.KEY_CLOUD_FAVORITES, JSON.stringify(favs));

      hilog.info(0x0000, 'CloudDBHelper', 'All cloud data cleared for user');
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `clearAll failed: ${JSON.stringify(err)}`);
      throw new Error(`clearAll failed: ${JSON.stringify(err)}`);
    }
  }

  static async deduplicateSongs(userId: string): Promise<number> {
    let removed = 0;
    try {
      const json = await CloudDBHelper.get(CloudDBHelper.KEY_CLOUD_SONGS);
      const songs: CloudSongObject[] = json ? JSON.parse(json) : [];
      const userSongs = songs.filter(s => s.userId === userId);
      const otherSongs = songs.filter(s => s.userId !== userId);
      const seen: Set<number> = new Set();
      const unique: CloudSongObject[] = [];
      for (const s of userSongs) {
        const key = s.songId || s.id;
        if (!seen.has(key)) {
          seen.add(key);
          unique.push(s);
        } else {
          removed++;
        }
      }
      const result = [...otherSongs, ...unique];
      await CloudDBHelper.put(CloudDBHelper.KEY_CLOUD_SONGS, JSON.stringify(result));
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `deduplicateSongs failed: ${JSON.stringify(err)}`);
    }
    return removed;
  }

  static async querySongs(userId: string): Promise<CloudSongObject[]> {
    return CloudDBHelper.getCloudSongs(userId);
  }

  static async queryPlaylists(userId: string): Promise<CloudPlaylistObject[]> {
    return CloudDBHelper.getCloudPlaylists(userId);
  }

  static async queryPlaylistSongs(playlistId: number): Promise<CloudPlaylistSongObject[]> {
    return CloudDBHelper.getCloudPlaylistSongs(playlistId, 'default_user');
  }

  static async queryFavorites(userId: string): Promise<CloudFavoriteObject[]> {
    return CloudDBHelper.getCloudFavorites(userId);
  }
}