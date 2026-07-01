import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { StorageHelper } from '../helper/StorageHelper';
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
  @State playlistId: number = 0;
  @State playlistName: string = '';
  @State songs: Song[] = [];
  @State showAddDialog: boolean = false;
  @State showDeleteConfirm: boolean = false;
  @State songToDelete: number = 0;

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

  build() {
    NavDestination() {
      Stack() {
        Column() {
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
                  Text('播放歌曲时可以添加到歌单')
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
      Button('删除歌单')
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