export class AppConstants {
  // 注意：在模拟器中，localhost 指向模拟器自身，访问宿主机需使用 10.0.2.2 (或局域网 IP)
  static readonly API_BASE_URL: string = 'http://10.0.2.2:3000';
  static readonly TIMEOUT_CONNECT: number = 5000;
  static readonly TIMEOUT_READ: number = 10000;

  // AppStorage 缓存 Key
  static readonly CACHE_BANNERS = 'cache_banners';
  static readonly CACHE_PLAYLISTS = 'cache_playlists';
  static readonly CACHE_RECENT_SONGS = 'cache_recent_songs';
  static readonly CACHE_CHANNELS = 'cache_channels';
  static readonly CACHE_NOTES = 'cache_notes';
  static readonly CACHE_USER = 'cache_user';
  static readonly CACHE_FETCH_TIME = 'cache_fetch_time';
  // 缓存有效期（毫秒）— 5分钟内不重复拉取
  static readonly CACHE_TTL = 5 * 60 * 1000;
}

export enum PlayMode {
  SEQUENCE = 0,
  LOOP_LIST = 1,
  RANDOM = 2,
  LOOP_SINGLE = 3
}
