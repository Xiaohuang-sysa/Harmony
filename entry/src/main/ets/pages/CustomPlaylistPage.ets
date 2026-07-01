import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { StorageHelper } from '../helper/StorageHelper';
import { HttpHelper } from '../helper/HttpHelper';
import { Song } from '../entity/Song';
import { Playlist } from '../entity/Playlist';

@Builder
export function CustomPlaylistPageBuilder() {
  CustomPlaylistPage()
}

@Component
struct CustomPlaylistPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @StorageProp('custom_playlists') customPlaylists: Playlist[] = [];
  @StorageProp('favorites') favorites: Song[] = [];
  @State playlistId: number = 0;
  @State playlistName: string = '';
  @State songs: Song[] = [];
  @State showDeleteConfirm: boolean = false;
  @State songToDelete: number = 0;
  @State showEditMode: boolean = false;
  @State editTab: string = 'search';
  @State searchKeyword: string = '';
  @State searchResults: Song[] = [];
  @State isSearching: boolean = false;

  async aboutToAppear() {
    this.playlistId = AppStorage.get<number>('current_playlist_id') || 0;
    await this.loadPlaylistInfo();
    await this.loadSongs();
  }

  async loadPlaylistInfo(): Promise<void> {
    const playlist = this.customPlaylists.find(p => p.id === this.playlistId);
    if (playlist) {
      this.playlistName = playlist.name;
    }
  }

  async loadSongs(): Promise<void> {
    const songs = await StorageHelper.getPlaylistSongs(this.playlistId);
    this.songs = songs;
  }

  async deleteSong(songId: number): Promise<void> {
    await StorageHelper.removeSongFromPlaylist(this.playlistId, songId);
    await this.loadSongs();
    await this.loadPlaylistInfo();
    this.showDeleteConfirm = false;
    this.songToDelete = 0;
  }

  async deletePlaylist(): Promise<void> {
    await StorageHelper.deletePlaylist(this.playlistId);
    this.pathStack.pop();
  }

  async addSong(song: Song): Promise<void> {
    await StorageHelper.addSongToPlaylist(this.playlistId, song);
    await this.loadSongs();
    await this.loadPlaylistInfo();
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
            Scroll() {
              Column({ space: 10 }) {
                if (this.songs.length === 0) {
                  Column({ space: 16 }) {
                    SymbolGlyph($r('sys.symbol.music'))
                      .fontSize(64)
                      .fontColor(['#ffcccccc'])
                    Text('歌单暂无歌曲')
                      .fontSize(16)
                      .fontColor('#ff999999')
                    Text('点击右上角编辑添加歌曲')
                      .fontSize(14)
                      .fontColor('#ffcccccc')
                  }
                  .width('100%')
                  .padding({ top: 100 })
                  .justifyContent(FlexAlign.Center)
                } else {
                  ForEach(this.songs, (item: Song, index: number) => {
                    Row({ space: 12 }) {
                      Text((index + 1).toString())
                        .fontSize(14)
                        .fontColor('#ff999999')
                        .width(24)
                        .textAlign(TextAlign.Center)
                      
                      Image(item.al?.picUrl)
                        .width(52)
                        .height(52)
                        .backgroundColor('#ffeeeeee')
                        .borderRadius(12)
                        .objectFit(ImageFit.Cover)
                        .onError(() => {
                        })
                      
                      Column({ space: 6 }) {
                        Text(item.name)
                          .fontSize(15)
                          .fontWeight(FontWeight.Medium)
                          .fontColor('#ff333333')
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                        Text(item.ar && item.ar.length > 0 ? item.ar.map(a => a.name).join(' / ') : '未知歌手')
                          .fontSize(12)
                          .fontColor('#ff999999')
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                      
                      Row({ space: 16 }) {
                        SymbolGlyph($r('sys.symbol.trash'))
                          .fontSize(20)
                          .fontColor(['#ffcccccc'])
                          .onClick(() => {
                            this.songToDelete = item.id;
                            this.showDeleteConfirm = true;
                          })
                        SymbolGlyph($r('sys.symbol.more'))
                          .fontSize(20)
                          .fontColor(['#ff999999'])
                      }
                    }
                    .width('100%')
                    .padding(12)
                    .backgroundColor('#fff9f9f9')
                    .borderRadius(16)
                    .onClick(() => {
                      AvPlayerHelper.playMusic(item);
                      this.pathStack.pushPath({ name: 'PlayerPage' });
                    })
                  }, (item: Song) => item.id.toString())
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 16, bottom: 80 })
            }
            .width('100%')
            .height('100%')
          } else {
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
                  .onClick(() => {
                    this.editTab = 'search';
                  })
                Text('我的收藏')
                  .fontSize(14)
                  .fontColor(this.editTab === 'favorites' ? '#E3323D' : '#ff999999')
                  .fontWeight(this.editTab === 'favorites' ? FontWeight.Bold : FontWeight.Regular)
                  .padding({ right: 24 })
                  .onClick(() => {
                    this.editTab = 'favorites';
                  })
              }
              .width('100%')
              .padding({ left: 16 })
              .padding({ bottom: 12 })

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
                      .onChange((value: string) => {
                        this.searchKeyword = value;
                      })
                      .onSubmit(() => {
                        this.searchSongs();
                      })
                    Button('搜索')
                      .fontSize(14)
                      .fontColor(Color.White)
                      .backgroundColor('#E3323D')
                      .borderRadius(22)
                      .padding({ left: 16, right: 16 })
                      .onClick(() => {
                        this.searchSongs();
                      })
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16 })

                  Scroll() {
                    Column({ space: 10 }) {
                      if (this.isSearching) {
                        Column() {
                          LoadingProgress()
                            .width(48)
                            .height(48)
                            .color('#E3323D')
                        }
                        .width('100%')
                        .padding({ top: 40 })
                        .justifyContent(FlexAlign.Center)
                      } else if (this.searchResults.length === 0 && this.searchKeyword.trim()) {
                        Column({ space: 8 }) {
                          SymbolGlyph($r('sys.symbol.music'))
                            .fontSize(32)
                            .fontColor(['#ffcccccc'])
                          Text('未找到相关歌曲')
                            .fontSize(14)
                            .fontColor('#ff999999')
                        }
                        .width('100%')
                        .padding({ top: 40 })
                        .justifyContent(FlexAlign.Center)
                      } else if (this.searchResults.length > 0) {
                        ForEach(this.searchResults, (item: Song) => {
                          Row({ space: 12 }) {
                            Image(item.al?.picUrl)
                              .width(52)
                              .height(52)
                              .backgroundColor('#ffeeeeee')
                              .borderRadius(12)
                              .objectFit(ImageFit.Cover)
                              .onError(() => {
                              })
                            
                            Column({ space: 6 }) {
                              Text(item.name)
                                .fontSize(15)
                                .fontWeight(FontWeight.Medium)
                                .fontColor('#ff333333')
                                .maxLines(1)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                              Text(item.ar && item.ar.length > 0 ? item.ar.map(a => a.name).join(' / ') : '未知歌手')
                                .fontSize(12)
                                .fontColor('#ff999999')
                                .maxLines(1)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                            }
                            .alignItems(HorizontalAlign.Start)
                            .layoutWeight(1)
                            
                            if (this.isSongInPlaylist(item.id)) {
                              SymbolGlyph($r('sys.symbol.check'))
                                .fontSize(20)
                                .fontColor(['#E3323D'])
                            } else {
                              SymbolGlyph($r('sys.symbol.plus'))
                                .fontSize(20)
                                .fontColor(['#ffcccccc'])
                                .onClick(() => {
                                  this.addSong(item);
                                })
                            }
                          }
                          .width('100%')
                          .padding(12)
                          .backgroundColor('#fff9f9f9')
                          .borderRadius(16)
                        }, (item: Song) => item.id.toString())
                      }
                    }
                    .width('100%')
                    .padding({ top: 12, bottom: 40 })
                  }
                  .width('100%')
                  .layoutWeight(1)
                }
                .width('100%')
                .layoutWeight(1)
              } else {
                Scroll() {
                  Column({ space: 10 }) {
                    if (this.favorites.length === 0) {
                      Column({ space: 8 }) {
                        SymbolGlyph($r('sys.symbol.heart'))
                          .fontSize(32)
                          .fontColor(['#ffcccccc'])
                        Text('暂无收藏歌曲')
                          .fontSize(14)
                          .fontColor('#ff999999')
                      }
                      .width('100%')
                      .padding({ top: 40 })
                      .justifyContent(FlexAlign.Center)
                    } else {
                      ForEach(this.favorites, (item: Song) => {
                        Row({ space: 12 }) {
                          Image(item.al?.picUrl)
                            .width(52)
                            .height(52)
                            .backgroundColor('#ffeeeeee')
                            .borderRadius(12)
                            .objectFit(ImageFit.Cover)
                            .onError(() => {
                            })
                          
                          Column({ space: 6 }) {
                            Text(item.name)
                              .fontSize(15)
                              .fontWeight(FontWeight.Medium)
                              .fontColor('#ff333333')
                              .maxLines(1)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                            Text(item.ar && item.ar.length > 0 ? item.ar.map(a => a.name).join(' / ') : '未知歌手')
                              .fontSize(12)
                              .fontColor('#ff999999')
                              .maxLines(1)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                          }
                          .alignItems(HorizontalAlign.Start)
                          .layoutWeight(1)
                          
                          if (this.isSongInPlaylist(item.id)) {
                            SymbolGlyph($r('sys.symbol.check'))
                              .fontSize(20)
                              .fontColor(['#E3323D'])
                          } else {
                            SymbolGlyph($r('sys.symbol.plus'))
                              .fontSize(20)
                              .fontColor(['#ffcccccc'])
                              .onClick(() => {
                                this.addSong(item);
                              })
                          }
                        }
                        .width('100%')
                        .padding(12)
                        .backgroundColor('#fff9f9f9')
                        .borderRadius(16)
                      }, (item: Song) => item.id.toString())
                    }
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 12, bottom: 40 })
                }
                .width('100%')
                .layoutWeight(1)
              }
            }
            .width('100%')
            .layoutWeight(1)
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F4F4F4')

        if (this.showDeleteConfirm) {
          Column() {
            Column() {
              Text(this.songToDelete === -1 ? '确认删除此歌单？' : '确认从歌单中删除此歌曲？')
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
                    this.songToDelete = 0;
                  })
                
                Button('确认')
                  .width(120)
                  .height(44)
                  .backgroundColor('#ffFF4D4F')
                  .fontColor(Color.White)
                  .borderRadius(22)
                  .onClick(() => {
                    if (this.songToDelete === -1) {
                      this.deletePlaylist();
                    } else {
                      this.deleteSong(this.songToDelete);
                    }
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
            this.songToDelete = 0;
          })
        }
      }
    }
    .title(this.playlistName || '歌单详情')
    .toolbar() {
      if (!this.showEditMode) {
        Button('编辑')
          .fontSize(14)
          .fontColor('#007DFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showEditMode = true;
          })
        Button('删除')
          .fontSize(14)
          .fontColor('#ffFF4D4F')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showDeleteConfirm = true;
            this.songToDelete = -1;
          })
      }
    }
  }
}