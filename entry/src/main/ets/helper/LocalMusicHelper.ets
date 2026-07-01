import { Song } from '../entity/Song';
import { Artist } from '../entity/Artist';
import { Album } from '../entity/Album';
import { hilog } from '@kit.PerformanceAnalysisKit';

interface LocalSongInfo {
  uri: string;
  displayName: string;
  title: string;
  artist: string;
  album: string;
  duration: number;
  size: number;
}

export class LocalMusicHelper {
  /**
   * 扫描本地音频文件（通过 mediaLibrary）
   */
  static async scanLocalSongs(context: Context): Promise<Song[]> {
    const songs: Song[] = [];
    try {
      // 尝试使用媒体库 API 扫描
      const result = await LocalMusicHelper.queryMediaAudio(context);
      for (const item of result) {
        const song = new Song();
        song.id = -Math.abs(item.uri.hashCode()); // 本地文件用负数 id
        song.name = item.title || item.displayName || '未知歌曲';

        const artist = new Artist();
        artist.name = item.artist || '本地歌手';
        song.ar = [artist];

        const album = new Album();
        album.name = item.album || '本地专辑';
        album.picUrl = '';
        song.al = album;

        song.dt = item.duration;
        song.url = item.uri;
        songs.push(song);
      }
    } catch (err) {
      hilog.error(0x0000, 'LocalMusicHelper', `scanLocalSongs failed: ${JSON.stringify(err)}`);
    }
    return songs;
  }

  /**
   * 通过 mediaLibrary 查询音频文件
   */
  private static async queryMediaAudio(context: Context): Promise<LocalSongInfo[]> {
    const result: LocalSongInfo[] = [];
    try {
      const mediaLibrary = await import('@ohos.multimedia.mediaLibrary');
      const media = mediaLibrary.getMediaLibrary(context);
      const fetchOp = {
        selections: '',
        selectionArgs: [],
        uri: ''
      };
      const fileAssets = await media.getFileAssets(fetchOp);
      if (fileAssets && fileAssets.length > 0) {
        for (const asset of fileAssets) {
          if (asset.mediaType === mediaLibrary.MediaType.AUDIO) {
            result.push({
              uri: asset.uri,
              displayName: asset.displayName,
              title: asset.title,
              artist: asset.artist,
              album: asset.album,
              duration: asset.duration,
              size: asset.size
            });
          }
        }
      }
    } catch (err) {
      hilog.error(0x0000, 'LocalMusicHelper', `queryMediaAudio failed: ${JSON.stringify(err)}`);
    }
    return result;
  }
}
