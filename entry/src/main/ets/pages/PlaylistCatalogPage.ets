import { HttpHelper } from '../helper/HttpHelper';
import { Playlist } from '../entity/Playlist';
import { PlaylistDetailParams } from './PlaylistDetailPage';

@Builder
export function PlaylistCatalogPageBuilder() {
  PlaylistCatalogPage()
}

@Component
export struct PlaylistCatalogPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @State playlists: Playlist[] = [];
  @State isLoading: boolean = true;

  async aboutToAppear() {
    await this.loadPlaylists();
  }

  async loadPlaylists() {
    this.isLoading = true;
    try {
      this.playlists = await HttpHelper.fetchTopPlaylist();
    } catch (err) {
      console.error('loadPlaylists failed', JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor(['#FFFFFF'])
            .onClick(() => {
              this.pathStack.pop();
            })
          Text('热门歌单')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .margin({ left: 12 })
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
              .color(Color.White)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else if (this.playlists.length === 0) {
          Column({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.music'))
              .fontSize(48)
              .fontColor(['rgba(255,255,255,0.2)'])
            Text('暂无歌单数据')
              .fontSize(15)
              .fontColor('rgba(255,255,255,0.4)')
            Text('请确认 API 服务器已启动')
              .fontSize(13)
              .fontColor('rgba(255,255,255,0.3)')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column({ space: 12 }) {
              ForEach(this.playlists, (item: Playlist) => {
                Row({ space: 12 }) {
                  Image(item.coverImgUrl)
                    .width(80)
                    .height(80)
                    .borderRadius(12)
                    .objectFit(ImageFit.Cover)
                    .backgroundColor('rgba(255,255,255,0.1)')
                    .onError(() => {
                    })

                  Column({ space: 6 }) {
                    Text(item.name)
                      .fontSize(16)
                      .fontColor(Color.White)
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    if (item.description && item.description.length > 0) {
                      Text(item.description)
                        .fontSize(12)
                        .fontColor('rgba(255,255,255,0.5)')
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .lineHeight(16)
                    }
                    Text(`${item.trackCount} 首`)
                      .fontSize(12)
                      .fontColor('rgba(255,255,255,0.4)')
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  SymbolGlyph($r('sys.symbol.chevron_right'))
                    .fontSize(20)
                    .fontColor(['rgba(255,255,255,0.3)'])
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                .backgroundColor('rgba(255,255,255,0.05)')
                .borderRadius(16)
                .onClick(() => {
                  PlaylistDetailParams.id = item.id;
                  PlaylistDetailParams.title = item.name;
                  PlaylistDetailParams.coverImgUrl = item.coverImgUrl;
                  PlaylistDetailParams.description = item.description || '';
                  this.pathStack.pushPath({ name: 'PlaylistDetailPage' });
                })
              }, (item: Playlist) => item.id.toString())
            }
            .width('100%')
            .padding({ left: 12, right: 12, bottom: 32 })
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
}