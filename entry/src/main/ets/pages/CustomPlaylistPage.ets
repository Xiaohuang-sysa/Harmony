import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { StorageHelper } from '../helper/StorageHelper';
import { HttpHelper } from '../helper/HttpHelper';
import { LocalMusicHelper } from '../helper/LocalMusicHelper';
import { Song } from '../entity/Song';
import { Playlist } from '../entity/Playlist';
import getContext from '@ohos.app.ability.common';
import type Context from '@ohos.app.ability.common';

@Builder
export function CustomPlaylistPageBuilder() {
  CustomPlaylistPage()
}

export class CustomPlaylistParams {
  static id: number = 0;
}

@Component
struct CustomPlaylistPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @StorageProp('favorites') favorites: Song[] = [];
  @State playlistName: string = '';
  @State songs: Song[] = [];
  @State showDeleteConfirm: boolean = false;
  @State showEditMode: boolean = false;
  @State editTab: string = 'search';
  @State searchKeyword: string = '';
  @State searchResults: Song[] = [];
  @State isSearching: boolean = false;
  @State showActionSheet: boolean = false;
  @State selectedSong: Song | null = null;
  @State showDeletePlaylistConfirm: boolean = false;
  private coverFailedSet: Set<number> = new Set();

  isCoverFailed(songId: number): boolean {
    return this.coverFailedSet.has(songId);
  }

  markCoverFailed(songId: number): void {
    this.coverFailedSet.add(songId);
  }

  private getCurrentPlaylistId(): number {
    return CustomPlaylistParams.id;
  }

  async aboutToAppear() {
    // 验证歌单是否仍存在，防止访问已删除的歌单
    const playlists = await StorageHelper.getCustomPlaylists();
    const playlist = playlists.find(p => p.id === this.getCurrentPlaylistId());
    if (!playlist) {
      this.pathStack.pop();
      return;
    }
    await this.loadPlaylistInfo();
    await this.loadSongs();
  }

  async loadPlaylistInfo(): Promise<void> {
    const playlists = await StorageHelper.getCustomPlaylists();
    const playlist = playlists.find(p => p.id === this.getCurrentPlaylistId());
    if (playlist) {
      this.playlistName = playlist.name;
    }
  }

  async loadSongs(): Promise<void> {
    const songs = await StorageHelper.getPlaylistSongs(this.getCurrentPlaylistId());
    this.songs = songs.slice();
  }

  async deleteSong(): Promise<void> {
    if (!this.selectedSong) return;
    const updatedSongs = await StorageHelper.removeSongFromPlaylist(this.getCurrentPlaylistId(), this.selectedSong.id);
    this.songs = updatedSongs.slice();
    this.showActionSheet = false;
    this.selectedSong = null;
  }

  async deletePlaylist(): Promise<void> {
    await StorageHelper.deletePlaylist(this.getCurrentPlaylistId());
    this.pathStack.pop();
  }

  async addSong(song: Song): Promise<void> {
    const updatedSongs = await StorageHelper.addSongToPlaylist(this.getCurrentPlaylistId(), song);
    this.songs = updatedSongs.slice();
  }

  async addToFavorites(song: Song): Promise<void> {
    await StorageHelper.toggleFavorite(song);
    this.showActionSheet = false;
    this.selectedSong = null;
  }

  async downloadToLocal(song: Song): Promise<void> {
    const context = getContext(this) as Context;
    await LocalMusicHelper.init(context);
    await LocalMusicHelper.addLocalMusic(song);
    this.showActionSheet = false;
    this.selectedSong = null;
  }

  isSongInPlaylist(songId: number): boolean {
    return this.songs.some(s => s.id === songId);
  }

  async searchSongs(): Promise<void> {
    if (!this.searchKeyword.trim()) {
      this.searchResults = [];
      return;
    }
    this.isSearching = true;
    this.searchResults = await HttpHelper.searchMusic(this.searchKeyword.trim());
    this.isSearching = false;
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          if (!this.showEditMode) {
            // ========== 主视图：歌曲列表（参考MyFavoritePage风格） ==========
            Row() {
              Text(this.playlistName || '歌单')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Text('(' + this.songs.length + ')')
                .fontSize(14)
                .fontColor('rgba(255,255,255,0.5)')
                .margin({ left: 8 })
              Blank()
              Button() {
                SymbolGlyph($r('sys.symbol.plus'))
                  .fontSize(20)
                  .fontColor(['#007DFF'])
              }
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.showEditMode = true;
              })
              .margin({ right: 4 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 8 })

            if (this.songs.length === 0) {
              Column({ space: 12 }) {
                SymbolGlyph($r('sys.symbol.music'))
                  .fontSize(48)
                  .fontColor(['rgba(255,255,255,0.2)'])
                Text('歌单暂无歌曲')
                  .fontSize(15)
                  .fontColor('rgba(255,255,255,0.4)')
                Text('点击右上角编辑添加歌曲')
                  .fontSize(13)
                  .fontColor('rgba(255,255,255,0.3)')
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
            } else {
              List({ space: 0 }) {
                ForEach(this.songs, (item: Song, index: number) => {
                  ListItem() {
                    Row({ space: 10 }) {
                      Text(String(index + 1))
                        .fontSize(13)
                        .fontColor('rgba(255,255,255,0.4)')
                        .width(24)
                        .textAlign(TextAlign.Center)

                      if (item.al && item.al.picUrl && !this.isCoverFailed(item.id)) {
                        Image(item.al.picUrl)
                          .width(40)
                          .height(40)
                          .borderRadius(6)
                          .objectFit(ImageFit.Cover)
                          .backgroundColor('rgba(255,255,255,0.1)')
                          .onError(() => {
                            this.markCoverFailed(item.id);
                          })
                      } else {
                        Column()
                          .width(40)
                          .height(40)
                          .borderRadius(6)
                          .backgroundColor('rgba(255,255,255,0.1)')
                          .justifyContent(FlexAlign.Center)
                          .alignItems(HorizontalAlign.Center)
                        {
                          SymbolGlyph($r('sys.symbol.music'))
                            .fontSize(20)
                            .fontColor(['rgba(255,255,255,0.4)'])
                        }
                      }

                      Column({ space: 2 }) {
                        Text(item.name)
                          .fontSize(14)
                          .fontColor(Color.White)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                        Text(item.ar && item.ar.length > 0 ? item.ar[0].name : '未知歌手')
                          .fontSize(11)
                          .fontColor('rgba(255,255,255,0.5)')
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                      .layoutWeight(1)
                      .alignItems(HorizontalAlign.Start)

                      // 菜单标志（参考云同步）
                      SymbolGlyph($r('sys.symbol.more'))
                        .fontSize(20)
                        .fontColor(['#CCCCCC'])
                        .onClick(() => {
                          this.selectedSong = item;
                          this.showActionSheet = true;
                        })
                    }
                    .width('100%')
                    .height(56)
                    .padding({ left: 12, right: 12 })
                    .alignItems(VerticalAlign.Center)
                    .onClick(() => {
                      AvPlayerHelper.playMusic(item, this.songs);
                      this.pathStack.pushPath({ name: 'PlayerPage' });
                    })
                  }
                  .width('100%')
                })
              }
              .width('100%')
              .layoutWeight(1)
            }
          } else {
            // ========== 编辑模式 ==========
            Column() {
              Row() {
                Button('取消')
                  .fontSize(14)
                  .fontColor('#ff666666')
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    this.showEditMode = false;
                    this.searchKeyword = '';
                    this.searchResults = [];
                  })
                Blank()
                Text('添加歌曲')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#ff333333')
                Blank()
                Text('完成')
                  .fontSize(14)
                  .fontColor('#E3323D')
                  .onClick(() => {
                    this.showEditMode = false;
                    this.searchKeyword = '';
                    this.searchResults = [];
                  })
              }
              .width('100%')
              .padding({ top: 12, bottom: 12, left: 16, right: 16 })

              Row() {
                Text('搜索')
                  .fontSize(14)
                  .fontColor(this.editTab === 'search' ? '#E3323D' : '#ff999999')
                  .fontWeight(this.editTab === 'search' ? FontWeight.Bold : FontWeight.Regular)
                  .padding({ right: 24 })
                  .onClick(() => { this.editTab = 'search'; })
                Text('我的收藏')
                  .fontSize(14)
                  .fontColor(this.editTab === 'favorites' ? '#E3323D' : '#ff999999')
                  .fontWeight(this.editTab === 'favorites' ? FontWeight.Bold : FontWeight.Regular)
                  .padding({ right: 24 })
                  .onClick(() => { this.editTab = 'favorites'; })
              }
              .width('100%')
              .padding({ left: 16, bottom: 12 })

              if (this.editTab === 'search') {
                Column() {
                  Row({ space: 8 }) {
                    SymbolGlyph($r('sys.symbol.magnifyingglass'))
                      .fontSize(18)
                      .fontColor(['#ffcccccc'])
                    TextInput({ placeholder: '搜索歌曲' })
                      .layoutWeight(1)
                      .height(44)
                      .backgroundColor('#fff5f5f5')
                      .borderRadius(22)
                      .padding({ left: 12 })
                      .onChange((value: string) => { this.searchKeyword = value; })
                      .onSubmit(() => { this.searchSongs(); })
                    Button('搜索')
                      .fontSize(14)
                      .fontColor(Color.White)
                      .backgroundColor('#E3323D')
                      .borderRadius(22)
                      .padding({ left: 16, right: 16 })
                      .onClick(() => { this.searchSongs(); })
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16 })

                  Scroll() {
                    Column({ space: 10 }) {
                      if (this.isSearching) {
                        Column() {
                          LoadingProgress().width(48).height(48).color('#E3323D')
                        }
                        .width('100%').padding({ top: 40 }).justifyContent(FlexAlign.Center)
                      } else if (this.searchResults.length === 0 && this.searchKeyword.trim()) {
                        Column({ space: 8 }) {
                          SymbolGlyph($r('sys.symbol.music')).fontSize(32).fontColor(['#ffcccccc'])
                          Text('未找到相关歌曲').fontSize(14).fontColor('#ff999999')
                        }
                        .width('100%').padding({ top: 40 }).justifyContent(FlexAlign.Center)
                      } else if (this.searchResults.length > 0) {
                        ForEach(this.searchResults, (item: Song) => {
                          Row({ space: 12 }) {
                            Image(item.al?.picUrl)
                              .width(52).height(52).backgroundColor('#ffeeeeee')
                              .borderRadius(12).objectFit(ImageFit.Cover)
                              .onError(() => {})

                            Column({ space: 6 }) {
                              Text(item.name)
                                .fontSize(15).fontWeight(FontWeight.Medium)
                                .fontColor('#ff333333')
                                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                              Text(item.ar && item.ar.length > 0 ? item.ar.map(a => a.name).join(' / ') : '未知歌手')
                                .fontSize(12).fontColor('#ff999999')
                                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                            }
                            .alignItems(HorizontalAlign.Start).layoutWeight(1)

                            if (this.isSongInPlaylist(item.id)) {
                              SymbolGlyph($r('sys.symbol.square_fill'))
                                .fontSize(20).fontColor(['#E3323D'])
                            } else {
                              SymbolGlyph($r('sys.symbol.plus'))
                                .fontSize(20).fontColor(['#ffcccccc'])
                                .onClick(() => { this.addSong(item); })
                            }
                          }
                          .width('100%').padding(12)
                          .backgroundColor('#fff9f9f9').borderRadius(16)
                        }, (item: Song) => item.id.toString())
                      }
                    }
                    .width('100%').padding({ top: 12, bottom: 40 })
                  }
                  .width('100%').layoutWeight(1)
                }
                .width('100%').layoutWeight(1)
              } else {
                Scroll() {
                  Column({ space: 10 }) {
                    if (this.favorites.length === 0) {
                      Column({ space: 8 }) {
                        SymbolGlyph($r('sys.symbol.heart')).fontSize(32).fontColor(['#ffcccccc'])
                        Text('暂无收藏歌曲').fontSize(14).fontColor('#ff999999')
                      }
                      .width('100%').padding({ top: 40 }).justifyContent(FlexAlign.Center)
                    } else {
                      ForEach(this.favorites, (item: Song) => {
                        Row({ space: 12 }) {
                          Image(item.al?.picUrl)
                            .width(52).height(52).backgroundColor('#ffeeeeee')
                            .borderRadius(12).objectFit(ImageFit.Cover)
                            .onError(() => {})

                          Column({ space: 6 }) {
                            Text(item.name)
                              .fontSize(15).fontWeight(FontWeight.Medium)
                              .fontColor('#ff333333')
                              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                            Text(item.ar && item.ar.length > 0 ? item.ar.map(a => a.name).join(' / ') : '未知歌手')
                              .fontSize(12).fontColor('#ff999999')
                              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                          }
                          .alignItems(HorizontalAlign.Start).layoutWeight(1)

                          if (this.isSongInPlaylist(item.id)) {
                            SymbolGlyph($r('sys.symbol.square_fill'))
                              .fontSize(20).fontColor(['#E3323D'])
                          } else {
                            SymbolGlyph($r('sys.symbol.plus'))
                              .fontSize(20).fontColor(['#ffcccccc'])
                              .onClick(() => { this.addSong(item); })
                          }
                        }
                        .width('100%').padding(12)
                        .backgroundColor('#fff9f9f9').borderRadius(16)
                      }, (item: Song) => item.id.toString())
                    }
                  }
                  .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 40 })
                }
                .width('100%').layoutWeight(1)
              }
            }
            .width('100%').layoutWeight(1)
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#1C1C1E')

        // ========== 删除确认弹窗 ==========
        if (this.showDeleteConfirm) {
          Column() {
            Column() {
              Text('确认从歌单中删除此歌曲？')
                .fontSize(18).fontWeight(FontWeight.Bold)
                .fontColor('#ff333333').margin({ bottom: 20 })

              Row({ space: 12 }) {
                Button('取消')
                  .width(120).height(44)
                  .backgroundColor('#fff5f5f5').fontColor('#ff666666')
                  .borderRadius(22)
                  .onClick(() => {
                    this.showDeleteConfirm = false;
                    this.selectedSong = null;
                  })
                Button('确认删除')
                  .width(120).height(44)
                  .backgroundColor('#ffFF4D4F').fontColor(Color.White)
                  .borderRadius(22)
                  .onClick(() => { this.deleteSong(); })
              }
              .width('100%').justifyContent(FlexAlign.Center).margin({ top: 24 })
            }
            .width('80%').backgroundColor(Color.White).borderRadius(24)
            .padding({ top: 24, bottom: 24, left: 20, right: 20 })
            .shadow({ radius: 20, color: 'rgba(0,0,0,0.15)', offsetY: 10 })
          }
          .width('100%').height('100%')
          .backgroundColor('rgba(0,0,0,0.5)')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.showDeleteConfirm = false;
            this.selectedSong = null;
          })
        }

        // ========== 菜单 ActionSheet（参考云同步） ==========
        if (this.showActionSheet) {
          Column() {
            Column() {
              Row({ space: 12 }) {
                SymbolGlyph($r('sys.symbol.heart'))
                  .fontSize(24).fontColor(['#FF4D4F'])
                Text('添加到收藏')
                  .fontSize(16).fontColor('#333333')
              }
              .width('100%').height(56).justifyContent(FlexAlign.Center)
              .onClick(() => {
                if (this.selectedSong) { this.addToFavorites(this.selectedSong); }
              })

              Divider().width('100%').color('#EEEEEE')

              Row({ space: 12 }) {
                SymbolGlyph($r('sys.symbol.download'))
                  .fontSize(24).fontColor(['#007DFF'])
                Text('下载到本地')
                  .fontSize(16).fontColor('#333333')
              }
              .width('100%').height(56).justifyContent(FlexAlign.Center)
              .onClick(() => {
                if (this.selectedSong) { this.downloadToLocal(this.selectedSong); }
              })

              Divider().width('100%').color('#EEEEEE')

              Row({ space: 12 }) {
                SymbolGlyph($r('sys.symbol.trash'))
                  .fontSize(24).fontColor(['#FF4D4F'])
                Text('从歌单移除')
                  .fontSize(16).fontColor('#FF4D4F')
              }
              .width('100%').height(56).justifyContent(FlexAlign.Center)
              .onClick(() => {
                if (this.selectedSong) {
                  this.showActionSheet = false;
                  this.showDeleteConfirm = true;
                }
              })

              Divider().width('100%').color('#EEEEEE')

              Text('取消')
                .fontSize(16).fontColor('#999999')
                .width('100%').height(56).textAlign(TextAlign.Center)
                .onClick(() => {
                  this.showActionSheet = false;
                  this.selectedSong = null;
                })
            }
            .width('100%').backgroundColor(Color.White)
            .borderRadius({ topLeft: 24, topRight: 24 }).padding({ bottom: 20 })
          }
          .width('100%').height('100%')
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
