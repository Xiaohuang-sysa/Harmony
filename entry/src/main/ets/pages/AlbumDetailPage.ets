import { HttpHelper } from '../helper/HttpHelper';
import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { AppConstants } from '../constants/AppConstants';
import { Song } from '../entity/Song';

interface AlbumDetailAlbum {
  id: number;
  name: string;
  picUrl: string;
  description: string;
  size: number;
  artist: AlbumDetailArtist;
}

interface AlbumDetailArtist {
  id: number;
  name: string;
}

interface AlbumDetailResponse {
  songs: Song[];
  album: AlbumDetailAlbum;
}

export class AlbumParams {
  static id: number = 0;
  static title: string = '';
  static coverUrl: string = '';
  static artistName: string = '';
}

@Builder
export function AlbumDetailPageBuilder() {
  AlbumDetailPage()
}

@Component
export struct AlbumDetailPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @State songs: Song[] = [];
  @State isLoading: boolean = true;
  @State albumName: string = '';
  @State coverUrl: string = '';
  @State albumArtistName: string = '';
  @State albumDescription: string = '';
  private coverFailedSet: Set<number> = new Set();

  isCoverFailed(songId: number): boolean {
    return this.coverFailedSet.has(songId);
  }

  markCoverFailed(songId: number): void {
    this.coverFailedSet.add(songId);
  }

  async aboutToAppear() {
    this.albumName = AlbumParams.title;
    this.coverUrl = AlbumParams.coverUrl;
    this.albumArtistName = AlbumParams.artistName;
    const albumId = AlbumParams.id;
    if (albumId > 0) {
      await this.loadAlbumData(albumId);
    }
  }

  async loadAlbumData(albumId: number) {
    this.isLoading = true;
    try {
      const res = await HttpHelper.get(`${AppConstants.API_BASE_URL}/album?id=${albumId}`);
      const json = JSON.parse(res) as AlbumDetailResponse;
      if (json) {
        if (json.songs) {
          this.songs = json.songs;
        }
        if (json.album) {
          this.albumName = json.album.name;
          if (json.album.picUrl && this.coverUrl === '') {
            this.coverUrl = json.album.picUrl;
          }
          this.albumDescription = json.album.description;
          if (json.album.artist && json.album.artist.name && this.albumArtistName === '') {
            this.albumArtistName = json.album.artist.name;
          }
        }
      }
    } catch (err) {
      console.error('loadAlbumData failed', JSON.stringify(err));
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
              .width(200)
              .height(200)
              .borderRadius(16)
              .objectFit(ImageFit.Cover)
              .backgroundColor('rgba(255,255,255,0.1)')
              .onError(() => {
                // fallback
              })

            Text(this.albumName)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .margin({ top: 16 })
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Center)

            Text(this.albumArtistName)
              .fontSize(14)
              .fontColor('rgba(255,255,255,0.6)')
              .margin({ top: 6 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            if (this.albumDescription && this.albumDescription.length > 0) {
              Text(this.albumDescription)
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.4)')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .lineHeight(16)
                .margin({ top: 8 })
                .textAlign(TextAlign.Center)
            }

            Text(this.songs.length + ' 首')
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.4)')
              .margin({ top: 8 })
          }
          .width('100%')
          .padding({ top: 32, bottom: 16 })
          .alignItems(HorizontalAlign.Center)

          // Divider
          Divider()
            .width('100%')
            .color('rgba(255,255,255,0.1)')
            .height(1)

          // Song list
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
