import { http } from '@kit.NetworkKit';
import { AppConstants } from '../constants/AppConstants';
import { hilog } from '@kit.PerformanceAnalysisKit';

import { BannerItem } from '../entity/BannerItem';
import { Playlist } from '../entity/Playlist';
import { Song } from '../entity/Song';
import { NoteItem } from '../entity/NoteItem';
import { UserInfo } from '../entity/UserInfo';
import { RoamChannel } from '../entity/RoamChannel';
import { SongResponse } from '../entity/SongResponse';
import { SongDetailResponse } from '../entity/SongDetailResponse';

interface BannerResponse {
  banners: BannerItem[];
}

interface PersonalizedResponse {
  result: Playlist[];
}

interface RecommendSongsData {
  dailySongs: Song[];
}

interface RecommendSongsResponse {
  data: RecommendSongsData;
}

interface CommentHotwallResponse {
  data: NoteItem[];
}

interface UserDetailResponse {
  profile: UserInfo;
}

interface DjRecommendResponse {
  data: RoamChannel[];
}

interface SongUrlItem {
  url: string;
}

interface SongUrlResponse {
  data: SongUrlItem[];
}

interface MusicCommentsData {
  comments?: NoteItem[];
}

interface MusicCommentsResponse {
  comments?: NoteItem[];
  data?: MusicCommentsData;
}

interface CloudDiskItem {
  id?: number;
  name?: string;
  simpleSong?: Song;
  song?: Song;
}

interface TopPlaylistResponse {
  playlists: Playlist[];
}

interface PlaylistTrackResponse {
  songs: Song[];
}

interface ArtistSongsResponse {
  songs: Song[];
}

interface AlbumResponse {
  songs: Song[];
}

interface ArtistDetailArtist {
  id: number;
  name: string;
  picUrl: string;
  albumSize: number;
  musicSize: number;
  mvSize: number;
  followed: boolean;
}

interface ArtistDetailData {
  artist: ArtistDetailArtist;
}

interface ArtistDetailResponse {
  data: ArtistDetailData;
}

interface RawAlbumItem {
  id: number;
  name: string;
  picUrl: string;
  description: string;
  size: number;
}

interface RawArtistAlbumsResponse {
  hotAlbums: RawAlbumItem[];
}

interface ArtistMvItem {
  id: number;
  name: string;
  imgurl: string;
  imgurl16v9: string;
  duration: number;
  artistName: string;
  playCount: number;
}

interface ArtistMvsResponse {
  mvs: ArtistMvItem[];
}

interface MvUrlData {
  url: string;
}

interface MvUrlResponse {
  data: MvUrlData;
}

export class HttpHelper {
  /**
   * 封装通用网络请求
   */
  static async request(url: string, method: http.RequestMethod = http.RequestMethod.GET, extraData: string | Record<string, string | number> | null = null): Promise<string> {
    const httpRequest = http.createHttp();
    try {
      const responsePromise: Promise<http.HttpResponse> = httpRequest.request(
        url,
        {
          method: method,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: extraData,
          connectTimeout: AppConstants.TIMEOUT_CONNECT,
          readTimeout: AppConstants.TIMEOUT_READ,
        }
      );
      const response: http.HttpResponse = await responsePromise;
      
      if (response.responseCode === 200) {
        return response.result as string;
      } else {
        throw new Error(`HTTP Code: ${response.responseCode}`);
      }
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `Request failed for url: ${url}, error: ${JSON.stringify(err)}`);
      throw new Error(JSON.stringify(err));
    } finally {
      // 必须调用 destroy 释放资源
      httpRequest.destroy();
    }
  }

  /**
   * 通用 GET 请求
   */
  static async get(url: string): Promise<string> {
    return HttpHelper.request(url, http.RequestMethod.GET);
  }

  /**
   * 通用 POST 请求
   */
  static async post(url: string, data: string | Record<string, string | number>): Promise<string> {
    return HttpHelper.request(url, http.RequestMethod.POST, data);
  }

  /**
   * 获取首页轮播图
   */
  static async fetchBanners(): Promise<BannerItem[]> {
    try {
      const url = `${AppConstants.API_BASE_URL}/banner`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as BannerResponse;
      if (json && json.banners) {
        return json.banners;
      }
      return [];
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `fetchBanners failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /**
   * 获取推荐歌单
   */
  static async fetchPersonalizedPlaylists(): Promise<Playlist[]> {
    try {
      const url = `${AppConstants.API_BASE_URL}/personalized`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as PersonalizedResponse;
      if (json && json.result) {
        return json.result;
      }
      return [];
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `fetchPersonalizedPlaylists failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /**
   * 获取每日推荐歌曲
   */
  static async fetchDailyRoam(): Promise<Song[]> {
    try {
      const url = `${AppConstants.API_BASE_URL}/recommend/songs`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as RecommendSongsResponse;
      if (json && json.data && json.data.dailySongs) {
        return json.data.dailySongs;
      }
      return [];
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `fetchDailyRoam failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /**
   * 获取热门评论（社区笔记）
   */
  static async fetchCommunityNotes(): Promise<NoteItem[]> {
    try {
      const url = `${AppConstants.API_BASE_URL}/comment/hotwall/list`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as CommentHotwallResponse;
      if (json && json.data) {
        return json.data;
      }
      return [];
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `fetchCommunityNotes failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /**
   * 获取用户详情
   */
  static async fetchUserDetail(uid: number): Promise<UserInfo> {
    try {
      const url = `${AppConstants.API_BASE_URL}/user/detail?uid=${uid}`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as UserDetailResponse;
      if (json && json.profile) {
        return json.profile;
      }
      return new UserInfo();
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `fetchUserDetail failed: ${JSON.stringify(err)}`);
      return new UserInfo();
    }
  }

  /**
   * 获取漫游频道推荐
   */
  static async fetchRoamChannels(): Promise<RoamChannel[]> {
    try {
      const url = `${AppConstants.API_BASE_URL}/dj/personalize/recommend`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as DjRecommendResponse;
      if (json && json.data) {
        return json.data;
      }
      return [];
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `fetchRoamChannels failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /**
   * 获取云盘歌曲列表
   */
  static async fetchCloudDiskSongs(): Promise<Song[]> {
    try {
      const url = `${AppConstants.API_BASE_URL}/user/cloud`;
      const res = await HttpHelper.get(url);
      interface CloudResponse {
        data?: CloudDiskItem[];
      }
      const json = JSON.parse(res) as CloudResponse;
      if (json && json.data && Array.isArray(json.data)) {
        const result: Song[] = [];
        for (const item of json.data) {
          if (item.simpleSong) {
            result.push(item.simpleSong);
          } else if (item.song) {
            result.push(item.song);
          } else {
            const song = new Song();
            song.id = item.id || 0;
            song.name = item.name || '未知歌曲';
            result.push(song);
          }
        }
        return result;
      }
      return [];
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `fetchCloudDiskSongs failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /**
   * 搜索歌曲
   */
  static async searchMusic(keyword: string): Promise<Song[]> {
    try {
      const url = `${AppConstants.API_BASE_URL}/search?keywords=${encodeURIComponent(keyword)}`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as SongResponse;
      if (json && json.result && json.result.songs) {
        const result: Song[] = [];
        for (const s of json.result.songs) {
          const song = new Song();
          song.id = s.id;
          song.name = s.name;
          song.dt = s.dt;
          song.fee = s.fee;
          if (s.ar && s.ar.length > 0) {
            song.ar = s.ar;
          } else if ((s as Record<string, Object>)['artists'] && Array.isArray((s as Record<string, Object>)['artists'])) {
            const artists = (s as Record<string, Object>)['artists'] as Artist[];
            song.ar = artists;
          }
          if (s.al && s.al.name) {
            song.al = s.al;
          } else if ((s as Record<string, Object>)['album']) {
            const album = (s as Record<string, Object>)['album'] as Album;
            song.al = album;
          }
          result.push(song);
        }
        return result;
      }
      return [];
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `searchMusic failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /**
   * 获取歌曲详情
   */
  static async getSongDetail(id: number): Promise<Song | null> {
    try {
      const url = `${AppConstants.API_BASE_URL}/song/detail?ids=${id}`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as SongDetailResponse;
      if (json && json.songs && json.songs.length > 0) {
        return json.songs[0];
      }
      return null;
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `getSongDetail failed: ${JSON.stringify(err)}`);
      return null;
    }
  }

  /**
   * 获取歌词
   */
  static async fetchLyric(id: number): Promise<string> {
    try {
      const url = `${AppConstants.API_BASE_URL}/lyric?id=${id}`;
      const res = await HttpHelper.get(url);
      const json: Record<string, Object> = JSON.parse(res);
      const lrc = json['lrc'] as Record<string, Object>;
      if (lrc && lrc['lyric']) {
        return lrc['lyric'] as string;
      }
      return '';
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `fetchLyric failed: ${JSON.stringify(err)}`);
      return '';
    }
  }

  /**
   * 获取歌曲播放链接
   */
  static async getSongUrl(id: number): Promise<string> {
    try {
      const url = `${AppConstants.API_BASE_URL}/song/url/v1?id=${id}&level=standard`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as SongUrlResponse;
      if (json && json.data && json.data.length > 0 && json.data[0].url) {
        return json.data[0].url;
      }
      return '';
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `getSongUrl failed: ${JSON.stringify(err)}`);
      return '';
    }
  }

  /**
   * 获取歌曲评论
   */
  static async getMusicComments(id: number): Promise<NoteItem[]> {
    try {
      const url = `${AppConstants.API_BASE_URL}/comment/music?id=${id}`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as MusicCommentsResponse;
      if (json && json.comments) {
        return json.comments;
      }
      if (json && json.data && json.data.comments) {
        return json.data.comments;
      }
      return [];
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `getMusicComments failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /**
   * 获取热门歌单（排行榜）
   */
  static async fetchTopPlaylist(): Promise<Playlist[]> {
    try {
      const url = `${AppConstants.API_BASE_URL}/top/playlist?limit=20&order=hot`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as TopPlaylistResponse;
      if (json && json.playlists) {
        return json.playlists;
      }
      return [];
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `fetchTopPlaylist failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /**
   * 获取歌单内所有歌曲
   */
  static async fetchPlaylistSongs(playlistId: number): Promise<Song[]> {
    try {
      const url = `${AppConstants.API_BASE_URL}/playlist/track/all?id=${playlistId}&limit=100`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as PlaylistTrackResponse;
      if (json && json.songs) {
        return json.songs;
      }
      return [];
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `fetchPlaylistSongs failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /**
   * 获取歌手热门歌曲
   */
  static async fetchArtistSongs(artistId: number): Promise<Song[]> {
    try {
      const url = `${AppConstants.API_BASE_URL}/artist/songs?id=${artistId}&limit=50`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as ArtistSongsResponse;
      if (json && json.songs) {
        return json.songs;
      }
      return [];
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `fetchArtistSongs failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /**
   * 获取专辑歌曲
   */
  static async fetchAlbumSongs(albumId: number): Promise<Song[]> {
    try {
      const url = `${AppConstants.API_BASE_URL}/album?id=${albumId}`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as AlbumResponse;
      if (json && json.songs) {
        return json.songs;
      }
      return [];
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `fetchAlbumSongs failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /**
   * 获取歌手详情
   */
  static async fetchArtistDetail(artistId: number): Promise<ArtistDetailArtist> {
    try {
      const url = `${AppConstants.API_BASE_URL}/artist/detail?id=${artistId}`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as ArtistDetailResponse;
      if (json && json.data && json.data.artist) {
        return json.data.artist;
      }
      return { id: 0, name: '', picUrl: '', albumSize: 0, musicSize: 0, mvSize: 0, followed: false };
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `fetchArtistDetail failed: ${JSON.stringify(err)}`);
      return { id: 0, name: '', picUrl: '', albumSize: 0, musicSize: 0, mvSize: 0, followed: false };
    }
  }

  /**
   * 获取歌手专辑
   */
  static async fetchArtistAlbums(artistId: number): Promise<Playlist[]> {
    try {
      const url = `${AppConstants.API_BASE_URL}/artist/album?id=${artistId}&limit=20`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as RawArtistAlbumsResponse;
      if (json && json.hotAlbums) {
        const result: Playlist[] = [];
        for (const item of json.hotAlbums) {
          const playlist = new Playlist();
          playlist.id = item.id;
          playlist.name = item.name;
          playlist.coverImgUrl = item.picUrl;
          playlist.description = item.description;
          playlist.trackCount = item.size;
          result.push(playlist);
        }
        return result;
      }
      return [];
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `fetchArtistAlbums failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /**
   * 获取歌手MV
   */
  static async fetchArtistMvs(artistId: number): Promise<ArtistMvItem[]> {
    try {
      const url = `${AppConstants.API_BASE_URL}/artist/mv?id=${artistId}&limit=10`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as ArtistMvsResponse;
      if (json && json.mvs) {
        return json.mvs;
      }
      return [];
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `fetchArtistMvs failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  /**
   * 获取MV播放地址
   */
  static async fetchMvUrl(mvId: number): Promise<string> {
    try {
      const url = `${AppConstants.API_BASE_URL}/mv/url?id=${mvId}`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as MvUrlResponse;
      if (json && json.data && json.data.url) {
        return json.data.url;
      }
      return '';
    } catch (err) {
      hilog.error(0x0000, 'HttpHelper', `fetchMvUrl failed: ${JSON.stringify(err)}`);
      return '';
    }
  }
}
