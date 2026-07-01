import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { Song } from '../entity/Song';

@Builder
export function RecentPlayPageBuilder() {
  RecentPlayPage()
}

@Entry
@Component
struct RecentPlayPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @StorageProp('play_history') playHistory: Song[] = [];

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column({ space: 10 }) {
            if (this.playHistory.length === 0) {
              Column({ space: 16 }) {
                SymbolGlyph($r('sys.symbol.music'))
                  .fontSize(64)
                  .fontColor(['#ffcccccc'])
                Text('暂无播放记录')
                  .fontSize(16)
                  .fontColor('#ff999999')
              }
              .width('100%')
              .padding({ top: 100 })
              .justifyContent(FlexAlign.Center)
            } else {
              ForEach(this.playHistory, (item: Song, index: number) => {
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
                  
                  SymbolGlyph($r('sys.symbol.more'))
                    .fontSize(20)
                    .fontColor(['#ff999999'])
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
    }
    .title('最近播放')
  }
}