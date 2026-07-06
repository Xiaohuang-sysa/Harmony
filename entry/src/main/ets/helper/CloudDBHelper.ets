import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type Context from '@ohos.app.ability.common';
import { CloudSongObject, CloudPlaylistObject, CloudPlaylistSongObject, CloudFavoriteObject } from '../entity/CloudSongObject';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'CloudSyncDB.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

const SQL_CREATE_SONGS = `
  CREATE TABLE IF NOT EXISTS cloud_songs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    songId INTEGER NOT NULL,
    name TEXT NOT NULL DEFAULT '',
    artist TEXT DEFAULT '',
    album TEXT DEFAULT '',
    coverUrl TEXT DEFAULT '',
    duration INTEGER DEFAULT 0,
    userId TEXT NOT NULL DEFAULT 'default_user',
    addTime TEXT DEFAULT ''
  )
`;

const SQL_CREATE_PLAYLISTS = `
  CREATE TABLE IF NOT EXISTS cloud_playlists (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL DEFAULT '',
    coverImgUrl TEXT DEFAULT '',
    description TEXT DEFAULT '',
    trackCount INTEGER DEFAULT 0,
    userId TEXT NOT NULL DEFAULT 'default_user',
    createTime TEXT DEFAULT ''
  )
`;

const SQL_CREATE_PLAYLIST_SONGS = `
  CREATE TABLE IF NOT EXISTS cloud_playlist_songs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    playlistId INTEGER NOT NULL,
    songId INTEGER NOT NULL,
    songName TEXT DEFAULT '',
    artist TEXT DEFAULT '',
    album TEXT DEFAULT '',
    coverUrl TEXT DEFAULT '',
    duration INTEGER DEFAULT 0,
    userId TEXT NOT NULL DEFAULT 'default_user'
  )
`;

const SQL_CREATE_FAVORITES = `
  CREATE TABLE IF NOT EXISTS cloud_favorites (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    songId INTEGER NOT NULL,
    songName TEXT DEFAULT '',
    artist TEXT DEFAULT '',
    album TEXT DEFAULT '',
    coverUrl TEXT DEFAULT '',
    duration INTEGER DEFAULT 0,
    userId TEXT NOT NULL DEFAULT 'default_user',
    addTime TEXT DEFAULT ''
  )
`;

const SQL_CREATE_INDEXES = `
  CREATE INDEX IF NOT EXISTS idx_songs_userId ON cloud_songs(userId);
  CREATE INDEX IF NOT EXISTS idx_songs_songId ON cloud_songs(songId, userId);
  CREATE INDEX IF NOT EXISTS idx_playlists_userId ON cloud_playlists(userId);
  CREATE INDEX IF NOT EXISTS idx_playlist_songs_playlistId ON cloud_playlist_songs(playlistId, userId);
  CREATE INDEX IF NOT EXISTS idx_favorites_userId ON cloud_favorites(userId);
  CREATE INDEX IF NOT EXISTS idx_favorites_songId ON cloud_favorites(songId, userId);
`;

export class CloudDBHelper {
  private static store: relationalStore.RdbStore | null = null;
  private static isInitialized: boolean = false;

  static async init(context: Context): Promise<void> {
    if (CloudDBHelper.isInitialized) return;
    try {
      CloudDBHelper.store = await relationalStore.getRdbStore(context, STORE_CONFIG);
      await CloudDBHelper.store.executeSql(SQL_CREATE_SONGS);
      await CloudDBHelper.store.executeSql(SQL_CREATE_PLAYLISTS);
      await CloudDBHelper.store.executeSql(SQL_CREATE_PLAYLIST_SONGS);
      await CloudDBHelper.store.executeSql(SQL_CREATE_FAVORITES);
      await CloudDBHelper.store.executeSql(SQL_CREATE_INDEXES);
      CloudDBHelper.isInitialized = true;
      hilog.info(0x0000, 'CloudDBHelper', 'SQLite CloudDB initialized successfully');
    } catch (err) {
      hilog.error(0x0000, 'CloudDBHelper', `CloudDB init failed: ${JSON.stringify(err)}`);
      throw new Error(`CloudDB init failed: ${JSON.stringify(err)}`);
    }
  }

  private static ensureStore(): relationalStore.RdbStore {
    if (!CloudDBHelper.store) {
      throw new Error('CloudDBHelper not initialized. Call init() first.');
    }
    return CloudDBHelper.store;
  }

  // ==================== Cloud Songs ====================

  static async getCloudSongs(userId: string): Promise<CloudSongObject[]> {
    const store = CloudDBHelper.ensureStore();
    const predicates = new relationalStore.RdbPredicates('cloud_songs');
    predicates.equalTo('userId', userId);
    const resultSet = await store.query(predicates);
    const songs: CloudSongObject[] = [];
    while (resultSet.goToNextRow()) {
      songs.push(CloudDBHelper.rowToCloudSong(resultSet));
    }
    resultSet.close();
    return songs;
  }

  static async insertSong(song: CloudSongObject): Promise<number> {
    const store = CloudDBHelper.ensureStore();
    // 检查是否已存在相同 songId + userId
    const checkResult = await store.querySql(
      'SELECT id FROM cloud_songs WHERE songId = ? AND userId = ?',
      [song.songId.toString(), song.userId]
    );
    if (checkResult.rowCount > 0) {
      checkResult.goToFirstRow();
      const existingId = checkResult.getLong(0);
      checkResult.close();
      return existingId;
    }
    checkResult.close();

    const valueBucket: relationalStore.ValuesBucket = {
      songId: song.songId || song.id,
      name: song.name,
      artist: song.artist,
      album: song.album,
      coverUrl: song.coverUrl,
      duration: song.duration,
      userId: song.userId,
      addTime: song.addTime || new Date().toISOString()
    };
    const rowId = await store.insert('cloud_songs', valueBucket);
    return rowId > 0 ? rowId : Date.now();
  }

  static async deleteSong(id: number, userId: string): Promise<void> {
    const store = CloudDBHelper.ensureStore();
    const predicates = new relationalStore.RdbPredicates('cloud_songs');
    predicates.equalTo('id', id).and().equalTo('userId', userId);
    await store.delete(predicates);
  }

  static async deleteSongBySongId(songId: number, userId: string): Promise<void> {
    const store = CloudDBHelper.ensureStore();
    const predicates = new relationalStore.RdbPredicates('cloud_songs');
    predicates.equalTo('songId', songId).and().equalTo('userId', userId);
    await store.delete(predicates);
  }

  static async updateSong(song: CloudSongObject): Promise<void> {
    const store = CloudDBHelper.ensureStore();
    const valueBucket: relationalStore.ValuesBucket = {
      name: song.name,
      artist: song.artist,
      album: song.album,
      coverUrl: song.coverUrl,
      duration: song.duration,
      addTime: song.addTime || new Date().toISOString()
    };
    const predicates = new relationalStore.RdbPredicates('cloud_songs');
    predicates.equalTo('id', song.id).and().equalTo('userId', song.userId);
    await store.update(valueBucket, predicates);
  }

  // ==================== Cloud Playlists ====================

  static async getCloudPlaylists(userId: string): Promise<CloudPlaylistObject[]> {
    const store = CloudDBHelper.ensureStore();
    const predicates = new relationalStore.RdbPredicates('cloud_playlists');
    predicates.equalTo('userId', userId);
    const resultSet = await store.query(predicates);
    const playlists: CloudPlaylistObject[] = [];
    while (resultSet.goToNextRow()) {
      playlists.push(CloudDBHelper.rowToCloudPlaylist(resultSet));
    }
    resultSet.close();
    return playlists;
  }

  static async insertPlaylist(playlist: CloudPlaylistObject): Promise<number> {
    const store = CloudDBHelper.ensureStore();
    const checkResult = await store.querySql(
      'SELECT id FROM cloud_playlists WHERE name = ? AND userId = ?',
      [playlist.name, playlist.userId]
    );
    if (checkResult.rowCount > 0) {
      checkResult.goToFirstRow();
      const existingId = checkResult.getLong(0);
      checkResult.close();
      return existingId;
    }
    checkResult.close();

    const valueBucket: relationalStore.ValuesBucket = {
      name: playlist.name,
      coverImgUrl: playlist.coverImgUrl,
      description: playlist.description,
      trackCount: playlist.trackCount,
      userId: playlist.userId,
      createTime: playlist.createTime || new Date().toISOString()
    };
    return await store.insert('cloud_playlists', valueBucket);
  }

  static async deletePlaylist(id: number, userId: string): Promise<void> {
    const store = CloudDBHelper.ensureStore();
    // 级联删除 playlist_songs
    await store.executeSql('DELETE FROM cloud_playlist_songs WHERE playlistId = ?', [id.toString()]);
    const predicates = new relationalStore.RdbPredicates('cloud_playlists');
    predicates.equalTo('id', id).and().equalTo('userId', userId);
    await store.delete(predicates);
  }

  // ==================== Cloud Playlist Songs ====================

  static async getCloudPlaylistSongs(playlistId: number, userId: string): Promise<CloudPlaylistSongObject[]> {
    const store = CloudDBHelper.ensureStore();
    const resultSet = await store.querySql(
      'SELECT * FROM cloud_playlist_songs WHERE playlistId = ? AND userId = ?',
      [playlistId.toString(), userId]
    );
    const songs: CloudPlaylistSongObject[] = [];
    while (resultSet.goToNextRow()) {
      songs.push(CloudDBHelper.rowToCloudPlaylistSong(resultSet));
    }
    resultSet.close();
    return songs;
  }

  static async insertPlaylistSong(song: CloudPlaylistSongObject): Promise<number> {
    const store = CloudDBHelper.ensureStore();
    const checkResult = await store.querySql(
      'SELECT id FROM cloud_playlist_songs WHERE playlistId = ? AND songId = ? AND userId = ?',
      [song.playlistId.toString(), song.songId.toString(), song.userId]
    );
    if (checkResult.rowCount > 0) {
      checkResult.goToFirstRow();
      const existingId = checkResult.getLong(0);
      checkResult.close();
      return existingId;
    }
    checkResult.close();

    const valueBucket: relationalStore.ValuesBucket = {
      playlistId: song.playlistId,
      songId: song.songId,
      songName: song.songName,
      artist: song.artist,
      album: song.album,
      coverUrl: song.coverUrl,
      duration: song.duration,
      userId: song.userId
    };
    return await store.insert('cloud_playlist_songs', valueBucket);
  }

  static async deletePlaylistSong(id: number, userId: string): Promise<void> {
    const store = CloudDBHelper.ensureStore();
    const predicates = new relationalStore.RdbPredicates('cloud_playlist_songs');
    predicates.equalTo('id', id).and().equalTo('userId', userId);
    await store.delete(predicates);
  }

  // ==================== Cloud Favorites ====================

  static async getCloudFavorites(userId: string): Promise<CloudFavoriteObject[]> {
    const store = CloudDBHelper.ensureStore();
    const predicates = new relationalStore.RdbPredicates('cloud_favorites');
    predicates.equalTo('userId', userId);
    const resultSet = await store.query(predicates);
    const favorites: CloudFavoriteObject[] = [];
    while (resultSet.goToNextRow()) {
      favorites.push(CloudDBHelper.rowToCloudFavorite(resultSet));
    }
    resultSet.close();
    return favorites;
  }

  static async insertFavorite(favorite: CloudFavoriteObject): Promise<number> {
    const store = CloudDBHelper.ensureStore();
    const checkResult = await store.querySql(
      'SELECT id FROM cloud_favorites WHERE songId = ? AND userId = ?',
      [favorite.songId.toString(), favorite.userId]
    );
    if (checkResult.rowCount > 0) {
      checkResult.goToFirstRow();
      const existingId = checkResult.getLong(0);
      checkResult.close();
      return existingId;
    }
    checkResult.close();

    const valueBucket: relationalStore.ValuesBucket = {
      songId: favorite.songId,
      songName: favorite.songName,
      artist: favorite.artist,
      album: favorite.album,
      coverUrl: favorite.coverUrl,
      duration: favorite.duration,
      userId: favorite.userId,
      addTime: favorite.addTime || new Date().toISOString()
    };
    return await store.insert('cloud_favorites', valueBucket);
  }

  static async deleteFavorite(songId: number, userId: string): Promise<void> {
    const store = CloudDBHelper.ensureStore();
    const predicates = new relationalStore.RdbPredicates('cloud_favorites');
    predicates.equalTo('songId', songId).and().equalTo('userId', userId);
    await store.delete(predicates);
  }

  // ==================== 批量操作 ====================

  static async sync(): Promise<void> {
    // SQLite 每次操作自动刷盘，无需手动 flush
    hilog.info(0x0000, 'CloudDBHelper', 'CloudDB sync (no-op with SQLite)');
  }

  static async close(): Promise<void> {
    if (CloudDBHelper.store) {
      CloudDBHelper.store.close();
    }
    CloudDBHelper.store = null;
    CloudDBHelper.isInitialized = false;
  }

  static async clearAll(userId: string): Promise<void> {
    const store = CloudDBHelper.ensureStore();
    await store.executeSql('DELETE FROM cloud_songs WHERE userId = ?', [userId]);
    await store.executeSql('DELETE FROM cloud_playlists WHERE userId = ?', [userId]);
    await store.executeSql('DELETE FROM cloud_playlist_songs WHERE userId = ?', [userId]);
    await store.executeSql('DELETE FROM cloud_favorites WHERE userId = ?', [userId]);
    hilog.info(0x0000, 'CloudDBHelper', 'All cloud data cleared for user');
  }

  static async deduplicateSongs(userId: string): Promise<number> {
    const store = CloudDBHelper.ensureStore();
    // 删除重复记录，保留每组中 id 最小的
    const resultSet = await store.querySql(
      `DELETE FROM cloud_songs 
       WHERE userId = ? AND id NOT IN (
         SELECT MIN(id) FROM cloud_songs WHERE userId = ? GROUP BY songId
       )`,
      [userId, userId]
    );
    resultSet.close();
    // 重新查询去重后的数量计算删除数
    const countResult = await store.querySql(
      'SELECT COUNT(*) FROM cloud_songs WHERE userId = ?',
      [userId]
    );
    countResult.goToFirstRow();
    const remaining = countResult.getLong(0);
    countResult.close();
    hilog.info(0x0000, 'CloudDBHelper', `Deduplicated, ${remaining} songs remaining`);
    return remaining;
  }

  // ==================== 查询接口（兼容旧 API） ====================

  static async querySongs(userId: string): Promise<CloudSongObject[]> {
    return CloudDBHelper.getCloudSongs(userId);
  }

  static async queryPlaylists(userId: string): Promise<CloudPlaylistObject[]> {
    return CloudDBHelper.getCloudPlaylists(userId);
  }

  static async queryPlaylistSongs(playlistId: number): Promise<CloudPlaylistSongObject[]> {
    const userId = AppStorage.get<number>('current_user_id')?.toString() || 'default_user';
    return CloudDBHelper.getCloudPlaylistSongs(playlistId, userId);
  }

  static async queryFavorites(userId: string): Promise<CloudFavoriteObject[]> {
    return CloudDBHelper.getCloudFavorites(userId);
  }

  // ==================== ResultSet → Object 映射 ====================

  private static rowToCloudSong(rs: relationalStore.ResultSet): CloudSongObject {
    const song = new CloudSongObject();
    song.id = rs.getLong(rs.getColumnIndex('id'));
    song.songId = rs.getLong(rs.getColumnIndex('songId'));
    song.name = rs.getString(rs.getColumnIndex('name'));
    song.artist = rs.getString(rs.getColumnIndex('artist'));
    song.album = rs.getString(rs.getColumnIndex('album'));
    song.coverUrl = rs.getString(rs.getColumnIndex('coverUrl'));
    song.duration = rs.getLong(rs.getColumnIndex('duration'));
    song.userId = rs.getString(rs.getColumnIndex('userId'));
    song.addTime = rs.getString(rs.getColumnIndex('addTime'));
    return song;
  }

  private static rowToCloudPlaylist(rs: relationalStore.ResultSet): CloudPlaylistObject {
    const playlist = new CloudPlaylistObject();
    playlist.id = rs.getLong(rs.getColumnIndex('id'));
    playlist.name = rs.getString(rs.getColumnIndex('name'));
    playlist.coverImgUrl = rs.getString(rs.getColumnIndex('coverImgUrl'));
    playlist.description = rs.getString(rs.getColumnIndex('description'));
    playlist.trackCount = rs.getLong(rs.getColumnIndex('trackCount'));
    playlist.userId = rs.getString(rs.getColumnIndex('userId'));
    playlist.createTime = rs.getString(rs.getColumnIndex('createTime'));
    return playlist;
  }

  private static rowToCloudPlaylistSong(rs: relationalStore.ResultSet): CloudPlaylistSongObject {
    const ps = new CloudPlaylistSongObject();
    ps.id = rs.getLong(rs.getColumnIndex('id'));
    ps.playlistId = rs.getLong(rs.getColumnIndex('playlistId'));
    ps.songId = rs.getLong(rs.getColumnIndex('songId'));
    ps.songName = rs.getString(rs.getColumnIndex('songName'));
    ps.artist = rs.getString(rs.getColumnIndex('artist'));
    ps.album = rs.getString(rs.getColumnIndex('album'));
    ps.coverUrl = rs.getString(rs.getColumnIndex('coverUrl'));
    ps.duration = rs.getLong(rs.getColumnIndex('duration'));
    ps.userId = rs.getString(rs.getColumnIndex('userId'));
    return ps;
  }

  private static rowToCloudFavorite(rs: relationalStore.ResultSet): CloudFavoriteObject {
    const fav = new CloudFavoriteObject();
    fav.id = rs.getLong(rs.getColumnIndex('id'));
    fav.songId = rs.getLong(rs.getColumnIndex('songId'));
    fav.songName = rs.getString(rs.getColumnIndex('songName'));
    fav.artist = rs.getString(rs.getColumnIndex('artist'));
    fav.album = rs.getString(rs.getColumnIndex('album'));
    fav.coverUrl = rs.getString(rs.getColumnIndex('coverUrl'));
    fav.duration = rs.getLong(rs.getColumnIndex('duration'));
    fav.userId = rs.getString(rs.getColumnIndex('userId'));
    fav.addTime = rs.getString(rs.getColumnIndex('addTime'));
    return fav;
  }
}
