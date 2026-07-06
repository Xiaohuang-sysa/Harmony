import getContext from '@ohos.app.ability.common';
import type Context from '@ohos.app.ability.common';
import { CloudDBHelper } from '../helper/CloudDBHelper';
import { StorageHelper } from '../helper/StorageHelper';
import { LocalMusicHelper } from '../helper/LocalMusicHelper';
import { CloudSongObject, CloudFavoriteObject, CloudPlaylistObject, CloudPlaylistSongObject } from '../entity/CloudSongObject';
import { Song } from '../entity/Song';
import { Artist } from '../entity/Artist';
import { Album } from '../entity/Album';
import { AvPlayerHelper } from '../helper/AvPlayerHelper';

class CloudSong {
  id: number = 0;
  name: string = '';
  artist: string = '';
  album: string = '';
  coverUrl: string = '';
  addTime: string = '';
  size: number = 0;
}

@Builder
export function CloudSyncPageBuilder() {
  CloudSyncPage()
}

@Component
export struct CloudSyncPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @State cloudSongs: CloudSong[] = [];
  @State isLoading: boolean = true;
  @State uploadProgress: number = -1;
  @State uploadFileName: string = '';
  @State showDeleteConfirm: boolean = false;
  @State songToDelete: CloudSong | null = null;
  @State showActionSheet: boolean = false;
  @State selectedSong: CloudSong | null = null;
  @State syncStatus: string = '已同步';
  @State syncTime: string = '刚刚';
  @State userId: string = '';
  @State showClearAllConfirm: boolean = false;

  async aboutToAppear() {
    this.userId = AppStorage.get<number>('current_user_id')?.toString() || 'default_user';
    await this.initCloudDB();
    await this.loadCloudSongs();
  }

  async initCloudDB() {
    try {
      const context = getContext(this) as Context;
      await CloudDBHelper.init(context);
    } catch (err) {
      console.error('CloudDB init failed', JSON.stringify(err));
    }
  }

  async loadCloudSongs() {
    this.isLoading = true;
    try {
      const songs = await CloudDBHelper.querySongs(this.userId);
      const mapped: CloudSong[] = [];
      const seenIds: Set<number> = new Set();
      for (const s of songs) {
        const dedupKey = s.songId || s.id;
        if (seenIds.has(dedupKey)) continue;
        seenIds.add(dedupKey);
        const cs = new CloudSong();
        cs.id = dedupKey;
        cs.name = s.name;
        cs.artist = s.artist;
        cs.album = s.album;
        cs.coverUrl = s.coverUrl;
        cs.addTime = s.addTime;
        cs.size = 0;
        mapped.push(cs);
      }
      this.cloudSongs = mapped;
    } catch (err) {
      console.error('Failed to load cloud songs', JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }

  async deleteCloudSong() {
    if (!this.songToDelete) return;
    this.isLoading = true;
    try {
      await CloudDBHelper.deleteSongBySongId(this.songToDelete.id, this.userId);
      this.cloudSongs = this.cloudSongs.filter(s => s.id !== this.songToDelete?.id);
    } catch (err) {
      console.error('Failed to delete cloud song', JSON.stringify(err));
    } finally {
      this.isLoading = false;
      this.showDeleteConfirm = false;
      this.songToDelete = null;
    }
  }

  async uploadMusic() {
    // 检查是否已存在测试歌曲
    const existing = await CloudDBHelper.querySongs(this.userId);
    if (existing.some(s => s.name === '测试歌曲' && s.artist === '测试歌手')) {
      this.uploadProgress = -1;
      return;
    }
    this.uploadProgress = 0;
    this.uploadFileName = '测试歌曲.mp3';
    for (let i = 0; i <= 100; i += 10) {
      this.uploadProgress = i;
      await new Promise<void>((resolve: () => void) => setTimeout(resolve, 200));
    }
    const testSong = new CloudSongObject(Date.now(), '测试歌曲', '测试歌手', '测试专辑', '', 180, this.userId);
    await CloudDBHelper.insertSong(testSong);
    this.uploadProgress = -1;
    await this.loadCloudSongs();
    this.updateSyncStatus();
  }

  async syncLocalToCloud() {
    this.isLoading = true;
    this.syncStatus = '同步中';
    try {
      const favorites = await StorageHelper.getFavorites();
      const playlists = await StorageHelper.getCustomPlaylists();
      let syncCount = 0;

      for (const fav of favorites) {
        const cloudSongs = await CloudDBHelper.querySongs(this.userId);
        if (!cloudSongs.some(s => s.songId === fav.id)) {
          const cloudSong = new CloudSongObject(
            Date.now(),
            fav.name,
            fav.ar?.map(a => a.name).join(' / ') || '',
            fav.al?.name || '',
            fav.al?.picUrl || '',
            fav.dt || 0,
            this.userId
          );
          cloudSong.songId = fav.id;
          await CloudDBHelper.insertSong(cloudSong);

          const cloudFav = new CloudFavoriteObject(
            Date.now(),
            fav.id,
            fav.name,
            fav.ar?.map(a => a.name).join(' / ') || '',
            fav.al?.name || '',
            fav.al?.picUrl || '',
            fav.dt || 0,
            this.userId
          );
          await CloudDBHelper.insertFavorite(cloudFav);
          syncCount++;
        }
      }

      for (const playlist of playlists) {
        const cloudPlaylists = await CloudDBHelper.queryPlaylists(this.userId);
        let cloudPlaylistId = cloudPlaylists.find(p => p.name === playlist.name)?.id;
        if (!cloudPlaylistId) {
          const cloudPlaylist = new CloudPlaylistObject(
            Date.now(),
            playlist.name,
            playlist.coverImgUrl,
            playlist.description,
            playlist.trackCount,
            this.userId
          );
          cloudPlaylistId = await CloudDBHelper.insertPlaylist(cloudPlaylist);
        }

        const playlistSongs = await StorageHelper.getPlaylistSongs(playlist.id);
        for (const song of playlistSongs) {
          const cloudSongs = await CloudDBHelper.querySongs(this.userId);
          if (!cloudSongs.some(s => s.songId === song.id)) {
            const cloudSong = new CloudSongObject(
              Date.now(),
              song.name,
              song.ar?.map(a => a.name).join(' / ') || '',
              song.al?.name || '',
              song.al?.picUrl || '',
              song.dt || 0,
              this.userId
            );
            cloudSong.songId = song.id;
            await CloudDBHelper.insertSong(cloudSong);
            syncCount++;
          }

          const cloudPlaylistSongs = await CloudDBHelper.queryPlaylistSongs(cloudPlaylistId);
          if (!cloudPlaylistSongs.some(s => s.songId === song.id)) {
            const cloudPlaylistSong = new CloudPlaylistSongObject(
              Date.now(),
              cloudPlaylistId,
              song.id,
              song.name,
              song.ar?.map(a => a.name).join(' / ') || '',
              song.al?.name || '',
              song.al?.picUrl || '',
              song.dt || 0,
              this.userId
            );
            await CloudDBHelper.insertPlaylistSong(cloudPlaylistSong);
          }
        }
      }

      this.syncStatus = `已同步 ${syncCount} 首歌曲`;
      // 同步后去重
      const dedupCount = await CloudDBHelper.deduplicateSongs(this.userId);
      if (dedupCount > 0) {
        this.syncStatus += ` 去重 ${dedupCount} 首`;
      }
    } catch (err) {
      console.error('Sync failed', JSON.stringify(err));
      this.syncStatus = '同步失败';
    } finally {
      this.isLoading = false;
      this.syncTime = '刚刚';
      await this.loadCloudSongs();
    }
  }

  async downloadToLocal(song: CloudSong) {
    const songItem = new Song();
    songItem.id = song.id;
    songItem.name = song.name;
    const artist = new Artist();
    artist.id = 0;
    artist.name = song.artist;
    artist.picUrl = '';
    songItem.ar = [artist];
    const album = new Album();
    album.id = 0;
    album.name = song.album;
    album.picUrl = song.coverUrl;
    songItem.al = album;
    await LocalMusicHelper.addLocalMusic(songItem);
    this.showActionSheet = false;
    this.selectedSong = null;
  }

  addToFavorites(song: CloudSong) {
    const songItem = new Song();
    songItem.id = song.id;
    songItem.name = song.name;
    const artist = new Artist();
    artist.id = 0;
    artist.name = song.artist;
    artist.picUrl = '';
    songItem.ar = [artist];
    const album = new Album();
    album.id = 0;
    album.name = song.album;
    album.picUrl = song.coverUrl;
    songItem.al = album;
    StorageHelper.toggleFavorite(songItem);
    this.showActionSheet = false;
    this.selectedSong = null;
  }

  updateSyncStatus() {
    this.syncStatus = '已同步';
    this.syncTime = '刚刚';
  }

  async clearAllCloudData(): Promise<void> {
    this.isLoading = true;
    try {
      await CloudDBHelper.clearAll(this.userId);
      this.cloudSongs = [];
      this.syncStatus = '已清空';
      this.syncTime = '刚刚';
    } catch (err) {
      console.error('Clear all failed', JSON.stringify(err));
      this.syncStatus = '清空失败';
    } finally {
      this.isLoading = false;
      this.showClearAllConfirm = false;
    }
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          Row() {
            SymbolGlyph($r('sys.symbol.chevron_down'))
              .fontSize(28)
              .fontColor(['#1A1A1A'])
              .onClick(() => {
                this.pathStack.pop();
              })
            Blank()
            Text('云同步')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')
            Blank()
          }
          .width('100%')
          .padding({ top: 12, bottom: 12, left: 16, right: 16 })
          .alignItems(VerticalAlign.Center)

          if (this.isLoading) {
            Column() {
              LoadingProgress()
                .width(48)
                .height(48)
                .margin({ bottom: 16 })
              Text('正在同步云端数据...')
                .fontSize(15)
                .fontColor('#999999')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          } else {
            Scroll() {
              Column() {
                Row() {
                  Column({ space: 4 }) {
                    Text('云盘空间')
                      .fontSize(14)
                      .fontColor('#999999')
                    Text(`${this.cloudSongs.length} 首`)
                      .fontSize(28)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#1A1A1A')
                  }
                  .alignItems(HorizontalAlign.Start)

                  Blank()

                  SymbolGlyph($r('sys.symbol.cloud'))
                    .fontSize(48)
                    .fontColor(['#007DFF'])
                    .opacity(0.3)
                }
                .width('100%')
                .padding(20)
                .backgroundColor('#F0F7FF')
                .borderRadius(16)
                .margin({ bottom: 20 })

                Row({ space: 12 }) {
                  Row({ space: 8 }) {
                    SymbolGlyph($r('sys.symbol.arrow_up_circle'))
                      .fontSize(20)
                      .fontColor([Color.White])
                    Text('上传音乐')
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(Color.White)
                  }
                  .width('48%')
                  .height(48)
                  .backgroundColor('#007DFF')
                  .borderRadius(24)
                  .justifyContent(FlexAlign.Center)
                  .onClick(() => {
                    this.uploadMusic();
                  })

                  Row({ space: 8 }) {
                    SymbolGlyph($r('sys.symbol.download'))
                      .fontSize(20)
                      .fontColor([Color.White])
                    Text('同步上传')
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(Color.White)
                  }
                  .width('48%')
                  .height(48)
                  .backgroundColor('#00C853')
                  .borderRadius(24)
                  .justifyContent(FlexAlign.Center)
                  .onClick(() => {
                    this.syncLocalToCloud();
                  })
                }
                .width('100%')
                .margin({ bottom: 8 })

                Row({ space: 12 }) {
                  Row({ space: 8 }) {
                    SymbolGlyph($r('sys.symbol.arrow_clockwise'))
                      .fontSize(20)
                      .fontColor([Color.White])
                    Text('去重')
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(Color.White)
                  }
                  .width('48%')
                  .height(48)
                  .backgroundColor('#FF9500')
                  .borderRadius(24)
                  .justifyContent(FlexAlign.Center)
                  .onClick(async () => {
                    const count = await CloudDBHelper.deduplicateSongs(this.userId);
                    this.syncStatus = `已去重 ${count} 首`;
                    this.syncTime = '刚刚';
                    await this.loadCloudSongs();
                  })

                  Row({ space: 8 }) {
                    SymbolGlyph($r('sys.symbol.trash'))
                      .fontSize(20)
                      .fontColor([Color.White])
                    Text('一键清空')
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(Color.White)
                  }
                  .width('48%')
                  .height(48)
                  .backgroundColor('#FF4D4F')
                  .borderRadius(24)
                  .justifyContent(FlexAlign.Center)
                  .onClick(() => {
                    this.showClearAllConfirm = true;
                  })
                }
                .width('100%')
                .margin({ bottom: 20 })

                if (this.uploadProgress >= 0) {
                  Column({ space: 8 }) {
                    Text(`正在上传: ${this.uploadFileName}`)
                      .fontSize(13)
                      .fontColor('#666666')
                    Progress({ value: this.uploadProgress, total: 100 })
                      .width('100%')
                      .color('#007DFF')
                  }
                  .width('100%')
                  .margin({ bottom: 20 })
                }

                Row({ space: 8 }) {
                  SymbolGlyph($r('sys.symbol.arrow_clockwise'))
                    .fontSize(16)
                    .fontColor(['#34C759'])
                  Text(this.syncStatus)
                    .fontSize(14)
                    .fontColor('#34C759')
                  Text(`· ${this.syncTime}`)
                    .fontSize(12)
                    .fontColor('#999999')
                  Blank()
                  Text('刷新')
                    .fontSize(14)
                    .fontColor('#007DFF')
                    .fontWeight(FontWeight.Medium)
                    .onClick(() => {
                      this.loadCloudSongs();
                    })
                }
                .width('100%')
                .padding(12)
                .backgroundColor('#F5FFF5')
                .borderRadius(12)
                .margin({ bottom: 20 })

                Row() {
                  Text('我的云盘歌曲')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1A1A1A')
                  Blank()
                  Text(`${this.cloudSongs.length} 首`)
                    .fontSize(14)
                    .fontColor('#999999')
                }
                .width('100%')
                .margin({ bottom: 12 })

                if (this.cloudSongs.length === 0) {
                  Column({ space: 16 }) {
                    SymbolGlyph($r('sys.symbol.cloud'))
                      .fontSize(64)
                      .fontColor(['#DDDDDD'])
                      .opacity(0.5)
                    Text('暂无云盘歌曲')
                      .fontSize(16)
                      .fontColor('#999999')
                    Text('点击上方按钮上传你的音乐文件')
                      .fontSize(13)
                      .fontColor('#CCCCCC')
                  }
                  .width('100%')
                  .padding({ top: 60, bottom: 60 })
                  .alignItems(HorizontalAlign.Center)
                } else {
                  List({ space: 8 }) {
                    ForEach(this.cloudSongs, (item: CloudSong) => {
                      ListItem() {
                        Row({ space: 12 }) {
                          Image(item.coverUrl)
                            .width(48)
                            .height(48)
                            .borderRadius(8)
                            .backgroundColor('#F0F0F0')
                            .objectFit(ImageFit.Cover)
                            .onError(() => {})

                          Column({ space: 4 }) {
                            Text(item.name)
                              .fontSize(15)
                              .fontWeight(FontWeight.Medium)
                              .fontColor('#1A1A1A')
                              .maxLines(1)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                            Text(item.artist)
                              .fontSize(12)
                              .fontColor('#999999')
                              .maxLines(1)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                          }
                          .alignItems(HorizontalAlign.Start)
                          .layoutWeight(1)

                          SymbolGlyph($r('sys.symbol.more'))
                            .fontSize(20)
                            .fontColor(['#CCCCCC'])
                            .onClick(() => {
                              this.selectedSong = item;
                              this.showActionSheet = true;
                            })
                        }
                        .width('100%')
                        .padding(8)
                        .onClick(() => {
                          const song = new Song();
                          song.id = item.id;
                          song.name = item.name;
                          const artist = new Artist();
                          artist.id = 0;
                          artist.name = item.artist;
                          song.ar = [artist];
                          const album = new Album();
                          album.id = 0;
                          album.name = item.album;
                          album.picUrl = item.coverUrl;
                          song.al = album;
                          const songList: Song[] = this.cloudSongs.map(cs => {
                            const s = new Song();
                            s.id = cs.id;
                            s.name = cs.name;
                            const a = new Artist();
                            a.id = 0;
                            a.name = cs.artist;
                            s.ar = [a];
                            const al = new Album();
                            al.id = 0;
                            al.name = cs.album;
                            al.picUrl = cs.coverUrl;
                            s.al = al;
                            return s;
                          });
                          AvPlayerHelper.playMusic(song, songList);
                          this.pathStack.pushPath({ name: 'PlayerPage' });
                        })
                      }
                    }, (item: CloudSong) => item.id.toString())
                  }
                  .width('100%')
                  .layoutWeight(1)
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 8, bottom: 40 })
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Off)
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#FFFFFF')

        if (this.showDeleteConfirm) {
          Column() {
            Column() {
              Text('确认从云盘删除此歌曲？')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#ff333333')
                .margin({ bottom: 20 })

              Row({ space: 12 }) {
                Button('取消')
                  .width(120)
                  .height(44)
                  .backgroundColor('#fff5f5f5')
                  .fontColor('#ff666666')
                  .borderRadius(22)
                  .onClick(() => {
                    this.showDeleteConfirm = false;
                    this.songToDelete = null;
                  })

                Button('确认删除')
                  .width(120)
                  .height(44)
                  .backgroundColor('#ffFF4D4F')
                  .fontColor(Color.White)
                  .borderRadius(22)
                  .onClick(() => {
                    this.deleteCloudSong();
                  })
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .margin({ top: 24 })
            }
            .width('80%')
            .backgroundColor(Color.White)
            .borderRadius(24)
            .padding({ top: 24, bottom: 24, left: 20, right: 20 })
            .shadow({ radius: 20, color: 'rgba(0,0,0,0.15)', offsetY: 10 })
          }
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.5)')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.showDeleteConfirm = false;
            this.songToDelete = null;
          })
        }

        if (this.showClearAllConfirm) {
          Column() {
            Column() {
              Text('确认清空云盘')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#ff333333')
                .margin({ bottom: 12 })

              Text('此操作将删除所有云端歌单、歌曲和收藏数据，不可恢复。确定要继续吗？')
                .fontSize(14)
                .fontColor('#ff666666')
                .margin({ bottom: 20 })

              Row({ space: 12 }) {
                Button('取消')
                  .width(120)
                  .height(44)
                  .backgroundColor('#fff5f5f5')
                  .fontColor('#ff666666')
                  .borderRadius(22)
                  .onClick(() => {
                    this.showClearAllConfirm = false;
                  })

                Button('确认清空')
                  .width(120)
                  .height(44)
                  .backgroundColor('#ffFF4D4F')
                  .fontColor(Color.White)
                  .borderRadius(22)
                  .onClick(() => {
                    this.clearAllCloudData();
                  })
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .margin({ top: 24 })
            }
            .width('80%')
            .backgroundColor(Color.White)
            .borderRadius(24)
            .padding({ top: 24, bottom: 24, left: 20, right: 20 })
            .shadow({ radius: 20, color: 'rgba(0,0,0,0.15)', offsetY: 10 })
          }
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.5)')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.showClearAllConfirm = false;
          })
        }

        if (this.showActionSheet) {
          Column() {
            Column() {
              Row({ space: 12 }) {
                SymbolGlyph($r('sys.symbol.heart'))
                  .fontSize(24)
                  .fontColor(['#FF4D4F'])
                Text('添加到收藏')
                  .fontSize(16)
                  .fontColor('#333333')
              }
              .width('100%')
              .height(56)
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                if (this.selectedSong) {
                  this.addToFavorites(this.selectedSong);
                }
              })

              Divider()
                .width('100%')
                .color('#EEEEEE')

              Row({ space: 12 }) {
                SymbolGlyph($r('sys.symbol.download'))
                  .fontSize(24)
                  .fontColor(['#007DFF'])
                Text('下载到本地')
                  .fontSize(16)
                  .fontColor('#333333')
              }
              .width('100%')
              .height(56)
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                if (this.selectedSong) {
                  this.downloadToLocal(this.selectedSong);
                }
              })

              Divider()
                .width('100%')
                .color('#EEEEEE')

              Row({ space: 12 }) {
                SymbolGlyph($r('sys.symbol.trash'))
                  .fontSize(24)
                  .fontColor(['#FF4D4F'])
                Text('删除歌曲')
                  .fontSize(16)
                  .fontColor('#FF4D4F')
              }
              .width('100%')
              .height(56)
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                if (this.selectedSong) {
                  this.songToDelete = this.selectedSong;
                  this.showDeleteConfirm = true;
                  this.showActionSheet = false;
                }
              })

              Divider()
                .width('100%')
                .color('#EEEEEE')

              Text('取消')
                .fontSize(16)
                .fontColor('#999999')
                .width('100%')
                .height(56)
                .textAlign(TextAlign.Center)
                .onClick(() => {
                  this.showActionSheet = false;
                  this.selectedSong = null;
                })
            }
            .width('100%')
            .backgroundColor(Color.White)
            .borderRadius({ topLeft: 24, topRight: 24 })
            .padding({ bottom: 20 })
          }
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.5)')
          .justifyContent(FlexAlign.End)
          .onClick(() => {
            this.showActionSheet = false;
            this.selectedSong = null;
          })
        }
      }
    }
    .hideTitleBar(true)
  }
}