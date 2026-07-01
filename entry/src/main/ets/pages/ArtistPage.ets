import { HttpHelper } from '../helper/HttpHelper';
import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { Song } from '../entity/Song';
import { Playlist } from '../entity/Playlist';
import { AlbumParams } from './AlbumDetailPage';

export class ArtistParams {
  static id: number = 0;
  static title: string = '';
  static picUrl: string = '';
}

@Builder
export function ArtistPageBuilder() {
  ArtistPage()
}

@Component
export struct ArtistPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @State artistName: string = '';
  @State artistPicUrl: string = '';
  @State albumSize: number = 0;
  @State musicSize: number = 0;
  @State hotSongs: Song[] = [];
  @State albums: Playlist[] = [];
  @State isLoading: boolean = true;
  @State selectedTab: number = 0;
  private coverFailedSet: Set<number> = new Set();

  isCoverFailed(songId: number): boolean {
    return this.coverFailedSet.has(songId);
  }

  markCoverFailed(songId: number): void {
    this.coverFailedSet.add(songId);
  }

  async aboutToAppear() {
    this.artistName = ArtistParams.title;
    this.artistPicUrl = ArtistParams.picUrl;
    const artistId = ArtistParams.id;
    if (artistId > 0) {
      await this.loadArtistData(artistId);
    }
  }

  async loadArtistData(artistId: number) {
    this.isLoading = true;
    try {
      const results = await Promise.all([
        HttpHelper.fetchArtistDetail(artistId),
        HttpHelper.fetchArtistSongs(artistId),
        HttpHelper.fetchArtistAlbums(artistId)
      ]);
      const detail = results[0];
      const songs = results[1] as Song[];
      const albumList = results[2] as Playlist[];
      if (detail) {
        this.albumSize = detail.albumSize;
        this.musicSize = detail.musicSize;
        if (detail.picUrl && this.artistPicUrl === '') {
          this.artistPicUrl = detail.picUrl;
        }
      }
      if (songs) {
        this.hotSongs = songs;
      }
      if (albumList) {
        this.albums = albumList;
      }
    } catch (err) {
      console.error('loadArtistData failed', JSON.stringify(err));
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
            Image(this.artistPicUrl)
              .width(200)
              .height(200)
              .borderRadius(100)
              .objectFit(ImageFit.Cover)
              .backgroundColor('rgba(255,255,255,0.1)')
              .onError(() => {
                // fallback
              })

            Text(this.artistName)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .margin({ top: 16 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Row() {
              Text('歌曲: ' + this.musicSize)
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.5)')
              Text('专辑: ' + this.albumSize)
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.5)')
                .margin({ left: 16 })
            }
            .margin({ top: 8 })
          }
          .width('100%')
          .padding({ top: 32, bottom: 16 })
          .alignItems(HorizontalAlign.Center)

          // Tab selector
          Row() {
            Column() {
              Text('热门歌曲')
                .fontSize(16)
                .fontColor(this.selectedTab === 0 ? Color.White : 'rgba(255,255,255,0.5)')
                .fontWeight(this.selectedTab === 0 ? FontWeight.Bold : FontWeight.Normal)
            }
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .onClick(() => {
              this.selectedTab = 0;
            })

            Column() {
              Text('专辑')
                .fontSize(16)
                .fontColor(this.selectedTab === 1 ? Color.White : 'rgba(255,255,255,0.5)')
                .fontWeight(this.selectedTab === 1 ? FontWeight.Bold : FontWeight.Normal)
            }
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .onClick(() => {
              this.selectedTab = 1;
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .justifyContent(FlexAlign.Start)

          // Divider
          Divider()
            .width('100%')
            .color('rgba(255,255,255,0.1)')
            .height(1)

          if (this.selectedTab === 0) {
            // Hot songs list
            List({ space: 2 }) {
              ForEach(this.hotSongs, (item: Song, index: number) => {
                ListItem() {
                  this.songRow(item, index)
                }
                .width('100%')
              }, (item: Song) => item.id.toString())
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Off)
          } else {
            // Albums grid
            Grid() {
              ForEach(this.albums, (item: Playlist) => {
                GridItem() {
                  Column() {
                    Image(item.coverImgUrl)
                      .width('100%')
                      .aspectRatio(1)
                      .borderRadius(8)
                      .objectFit(ImageFit.Cover)
                      .backgroundColor('rgba(255,255,255,0.1)')
                      .onError(() => {
                        // fallback
                      })

                    Text(item.name)
                      .fontSize(13)
                      .fontColor(Color.White)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ top: 6 })
                      .lineHeight(16)
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Start)
                  .onClick(() => {
                    AlbumParams.id = item.id;
                    AlbumParams.title = item.name;
                    AlbumParams.coverUrl = item.coverImgUrl;
                    AlbumParams.artistName = this.artistName;
                    this.pathStack.pushPath({ name: 'AlbumDetailPage' });
                  })
                }
              }, (item: Playlist) => item.id.toString())
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(12)
            .rowsGap(16)
            .width('100%')
            .layoutWeight(1)
            .padding({ left: 16, right: 16, top: 12 })
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
