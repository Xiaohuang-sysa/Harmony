import { HttpHelper } from '../helper/HttpHelper';
import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { Song } from '../entity/Song';

export class PlaylistDetailParams {
  static id: number = 0;
  static title: string = '';
  static coverImgUrl: string = '';
  static description: string = '';
}

@Builder
export function PlaylistDetailPageBuilder() {
  PlaylistDetailPage()
}

@Component
export struct PlaylistDetailPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @State songs: Song[] = [];
  @State isLoading: boolean = true;
  @State playlistName: string = '';
  @State coverUrl: string = '';
  @State desc: string = '';
  private coverFailedSet: Set<number> = new Set();

  isCoverFailed(songId: number): boolean {
    return this.coverFailedSet.has(songId);
  }

  markCoverFailed(songId: number): void {
    this.coverFailedSet.add(songId);
  }

  async aboutToAppear() {
    this.playlistName = PlaylistDetailParams.title;
    this.coverUrl = PlaylistDetailParams.coverImgUrl;
    this.desc = PlaylistDetailParams.description;
    const playlistId = PlaylistDetailParams.id;
    if (playlistId > 0) {
      await this.loadSongs(playlistId);
    }
  }

  async loadSongs(playlistId: number) {
    this.isLoading = true;
    try {
      this.songs = await HttpHelper.fetchPlaylistSongs(playlistId);
    } catch (err) {
      console.error('loadSongs failed', JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .width(48)
              .height(48)
              .color(Color.White)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          // Hero header
          Column() {
            Image(this.coverUrl)
              .width('100%')
              .height(200)
              .objectFit(ImageFit.Cover)
              .backgroundColor('rgba(255,255,255,0.1)')
              .onError(() => {
                // fallback
              })

            Column() {
              Text(this.playlistName)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')

              if (this.desc.length > 0) {
                Text(this.desc)
                  .fontSize(12)
                  .fontColor('rgba(255,255,255,0.5)')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .lineHeight(16)
                  .margin({ top: 6 })
                  .width('100%')
              }

              Text(this.songs.length + ' 首')
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.4)')
                .margin({ top: 6 })
                .width('100%')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')

          // Song list
          if (this.songs.length === 0) {
            Column({ space: 12 }) {
              SymbolGlyph($r('sys.symbol.music'))
                .fontSize(48)
                .fontColor(['rgba(255,255,255,0.2)'])
              Text('暂无歌曲')
                .fontSize(15)
                .fontColor('rgba(255,255,255,0.4)')
              Text('请确认 API 服务器已启动')
                .fontSize(13)
                .fontColor('rgba(255,255,255,0.3)')
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            List({ space: 2 }) {
              ForEach(this.songs, (item: Song, index: number) => {
                ListItem() {
                  this.songRow(item, index)
                }
                .width('100%')
              }, (item: Song) => item.id.toString())
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Off)
          }
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#1C1C1E')
    }
    .hideTitleBar(true)
  }

  @Builder songRow(song: Song, index: number) {
    Row({ space: 10 }) {
      // Track number
      Text(String(index + 1))
        .fontSize(13)
        .fontColor('rgba(255,255,255,0.4)')
        .width(24)
        .textAlign(TextAlign.Center)

      // Album art
      if (song.al && song.al.picUrl && !this.isCoverFailed(song.id)) {
        Image(song.al.picUrl)
          .width(40)
          .height(40)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)
          .backgroundColor('rgba(255,255,255,0.1)')
          .onError(() => {
            this.markCoverFailed(song.id);
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

      // Song info
      Column({ space: 2 }) {
        Text(song.name)
          .fontSize(14)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(song.ar && song.ar.length > 0 ? song.ar[0].name : '未知歌手')
          .fontSize(11)
          .fontColor('rgba(255,255,255,0.5)')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(56)
    .padding({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      AvPlayerHelper.playMusic(song);
      this.pathStack.pushPath({ name: 'PlayerPage' });
    })
  }
}
