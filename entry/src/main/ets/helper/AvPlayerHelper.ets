import { media } from '@kit.MediaKit';
import { Song } from '../entity/Song';
import { PlayMode } from '../constants/AppConstants';
import { HttpHelper } from './HttpHelper';
import { PlaylistHelper } from './PlaylistHelper';
import { hilog } from '@kit.PerformanceAnalysisKit';

export class AvPlayerHelper {
  private static avPlayer: media.AVPlayer | null = null;
  private static isInitialized: boolean = false;

  /**
   * 初始化全局播放状态（绑定至 AppStorage）
   */
  public static initGlobalState(): void {
    if (AvPlayerHelper.isInitialized) {
      return;
    }
    AppStorage.setOrCreate<number>('duration', 0);
    AppStorage.setOrCreate<number>('current', 0);
    AppStorage.setOrCreate<string>('dStr', '00:00');
    AppStorage.setOrCreate<string>('cStr', '00:00');
    AppStorage.setOrCreate<boolean>('symbol', false);
    AppStorage.setOrCreate<number>('index', 0);
    AppStorage.setOrCreate<Song[]>('songList', []);
    AppStorage.setOrCreate<Song | null>('songDetail', null);
    AppStorage.setOrCreate<number>('current_mode', PlayMode.SEQUENCE);
    AppStorage.setOrCreate<number>('playback_speed', 1.0);
    AppStorage.setOrCreate<Song[]>('play_history', []);
    AppStorage.setOrCreate<Song[]>('favorites', []);
    AppStorage.setOrCreate<string[]>('recent_searches', []);

    AvPlayerHelper.isInitialized = true;
  }

  /**
   * 播放器初始化
   */
  public static async initPlayer(): Promise<void> {
    if (AvPlayerHelper.avPlayer) {
      return;
    }
    try {
      AvPlayerHelper.avPlayer = await media.createAVPlayer();
    } catch (err) {
      hilog.error(0x0000, 'AvPlayerHelper', `createAVPlayer failed: ${JSON.stringify(err)}`);
      return;
    }
    
    // 注册状态机监听
    AvPlayerHelper.avPlayer.on('stateChange', async (state: media.AVPlayerState) => {
      switch (state) {
        case 'initialized':
          await AvPlayerHelper.avPlayer?.prepare();
          break;
        case 'prepared':
          // 更新总时长
          const duration = AvPlayerHelper.avPlayer?.duration || 0;
          AppStorage.set<number>('duration', duration);
          AppStorage.set<string>('dStr', AvPlayerHelper.formatTime(duration));
          await AvPlayerHelper.avPlayer?.play();
          break;
        case 'playing':
          AppStorage.set<boolean>('symbol', true);
          break;
        case 'paused':
        case 'stopped':
          AppStorage.set<boolean>('symbol', false);
          break;
        case 'completed':
          AppStorage.set<boolean>('symbol', false);
          AvPlayerHelper.nextSong();
          break;
        case 'error':
          hilog.error(0x0000, 'AvPlayerHelper', 'AVPlayer error occurred');
          AppStorage.set<boolean>('symbol', false);
          break;
      }
    });

    AvPlayerHelper.avPlayer.on('timeUpdate', (time: number) => {
      AppStorage.set<number>('current', time);
      AppStorage.set<string>('cStr', AvPlayerHelper.formatTime(time));
    });

    AvPlayerHelper.avPlayer.on('error', (err) => {
      hilog.error(0x0000, 'AvPlayerHelper', `AVPlayer error: ${JSON.stringify(err)}`);
    });
  }

  /**
   * 播放指定歌曲
   */
  public static async playMusic(song: Song): Promise<void> {
    if (!AvPlayerHelper.avPlayer) {
      await AvPlayerHelper.initPlayer();
    }
    
    // 更新播放列表索引
    const rawSongList = AppStorage.get<Song[]>('songList') || [];
    const idx = rawSongList.findIndex(s => s.id === song.id);
    if (idx !== -1) {
      AppStorage.set<number>('index', idx);
    } else {
      // 没在列表里就插到开头并更新列表
      const newList: Song[] = rawSongList.slice();
      newList.unshift(song);
      AppStorage.set<Song[]>('songList', newList);
      AppStorage.set<number>('index', 0);
    }

    // 自动加入播放列表
    PlaylistHelper.addSong(song);

    // 更新详情
    AvPlayerHelper.httpSongDetail(song);

    // 获取播放URL
    const url = await HttpHelper.getSongUrl(song.id);
    if (!url) {
      hilog.warn(0x0000, 'AvPlayerHelper', 'No URL available for this song, skipping...');
      AvPlayerHelper.nextSong();
      return;
    }

    try {
      const state = AvPlayerHelper.avPlayer?.state;
      if (state === 'playing' || state === 'paused' || state === 'completed' || state === 'prepared' || state === 'stopped') {
        await AvPlayerHelper.avPlayer?.reset();
      }
      if (AvPlayerHelper.avPlayer) {
        AvPlayerHelper.avPlayer.url = url;
      }
    } catch (err) {
      hilog.error(0x0000, 'AvPlayerHelper', `Failed to set url: ${JSON.stringify(err)}`);
    }
  }
  
  public static togglePlay(): void {
    const isPlaying = AppStorage.get<boolean>('symbol');
    try {
      if (isPlaying) {
        AvPlayerHelper.avPlayer?.pause();
      } else {
        AvPlayerHelper.avPlayer?.play();
      }
    } catch (err) {
      hilog.error(0x0000, 'AvPlayerHelper', `togglePlay failed: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 设置播放速度（0.5x ~ 2.0x）
   */
  public static setSpeed(speed: number): void {
    try {
      AvPlayerHelper.avPlayer?.setSpeed(speed);
      AppStorage.set<number>('playback_speed', speed);
    } catch (err) {
      hilog.error(0x0000, 'AvPlayerHelper', `setSpeed failed: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 跳转到指定进度（毫秒）
   */
  public static seekTo(timeMs: number): void {
    if (AvPlayerHelper.avPlayer) {
      AvPlayerHelper.avPlayer.seek(timeMs);
      AppStorage.set<number>('current', timeMs);
      AppStorage.set<string>('cStr', AvPlayerHelper.formatTime(timeMs));
    }
  }

  /**
   * 获取歌曲封面等详情
   */
  public static async httpSongDetail(song: Song): Promise<void> {
    const detail = await HttpHelper.getSongDetail(song.id);
    if (detail) {
      AppStorage.set<Song>('songDetail', detail);
    } else {
      AppStorage.set<Song>('songDetail', song); // Fallback to basic info
    }
  }

  /**
   * 播放下一曲
   */
  public static nextSong(): void {
    const songList = AppStorage.get<Song[]>('songList') || [];
    if (songList.length === 0) return;
    
    let index = AppStorage.get<number>('index') || 0;
    const mode = AppStorage.get<number>('current_mode') || PlayMode.SEQUENCE;
    
    if (mode === PlayMode.RANDOM) {
      index = Math.floor(Math.random() * songList.length);
    } else if (mode === PlayMode.LOOP_SINGLE) {
      // single loop keeps same index
    } else {
      // SEQUENCE and LOOP fall here
      index = (index + 1) % songList.length;
    }
    
    AvPlayerHelper.playMusic(songList[index]);
  }

  /**
   * 播放上一曲
   */
  public static preSong(): void {
    const songList = AppStorage.get<Song[]>('songList') || [];
    if (songList.length === 0) return;
    
    let index = AppStorage.get<number>('index') || 0;
    const mode = AppStorage.get<number>('current_mode') || PlayMode.SEQUENCE;
    
    if (mode === PlayMode.RANDOM) {
      index = Math.floor(Math.random() * songList.length);
    } else if (mode === PlayMode.LOOP_SINGLE) {
      // single loop keeps same index
    } else {
      index = (index - 1 + songList.length) % songList.length;
    }
    
    AvPlayerHelper.playMusic(songList[index]);
  }

  private static formatTime(ms: number): string {
    const totalSeconds = Math.floor(ms / 1000);
    const m = Math.floor(totalSeconds / 60);
    const s = totalSeconds % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  }
}
