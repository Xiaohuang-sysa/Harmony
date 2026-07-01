import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { StorageHelper } from '../helper/StorageHelper';
import { Song } from '../entity/Song';

@Builder
export function MyFavoritePageBuilder() {
  MyFavoritePage()
}

@Component
export struct MyFavoritePage {
  @Consume('pathStack') pathStack: NavPathStack;
  @StorageProp('favorites') favorites: Song[] = [];
  private coverFailedSet: Set<number> = new Set();

  isCoverFailed(songId: number): boolean {
    return this.coverFailedSet.has(songId);
  }

  markCoverFailed(songId: number): void {
    this.coverFailedSet.add(songId);
  }

  removeFavorite(song: Song): void {
    StorageHelper.toggleFavorite(song);
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text('我的收藏')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text('(' + this.favorites.length + ')')
            .fontSize(14)
            .fontColor('rgba(255,255,255,0.5)')
            .margin({ left: 8 })
          Blank()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

        if (this.favorites.length === 0) {
          Column({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.heart'))
              .fontSize(48)
              .fontColor(['rgba(255,255,255,0.2)'])
            Text('暂无收藏歌曲')
              .fontSize(15)
              .fontColor('rgba(255,255,255,0.4)')
            Text('播放页点击红心即可收藏')
              .fontSize(13)
              .fontColor('rgba(255,255,255,0.3)')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 0 }) {
            ForEach(this.favorites, (item: Song, index: number) => {
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

                  SymbolGlyph($r('sys.symbol.heart_fill'))
                    .fontSize(20)
                    .fontColor(['#FF3B30'])
                    .onClick(() => {
                      this.removeFavorite(item);
                    })
                }
                .width('100%')
                .height(56)
                .padding({ left: 12, right: 12 })
                .alignItems(VerticalAlign.Center)
                .onClick(() => {
                  AvPlayerHelper.playMusic(item);
                })
              }
              .width('100%')
            })
          }
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#1C1C1E')
    }
    .hideTitleBar(true)
  }
}
