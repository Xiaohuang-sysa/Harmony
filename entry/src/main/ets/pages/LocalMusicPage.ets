import { Song } from '../entity/Song';
import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BasicDataSource } from '../helper/LazyDataSource';

@Builder
export function LocalMusicPageBuilder() {
  LocalMusicPage()
}

@Component
export struct LocalMusicPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @State localSongDataSource: BasicDataSource<Song> = new BasicDataSource([]);

  build() {
    NavDestination() {
      Column() {
        // Header
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor(['#1A1A1A'])
            .onClick(() => {
              this.pathStack.pop();
            })
          Blank()
          Text('本地音乐')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
          Blank()
          // Refresh button (placeholder)
          SymbolGlyph($r('sys.symbol.arrow_clockwise'))
            .fontSize(20)
            .fontColor(['#DDDDDD'])
            .opacity(0.3)
        }
        .width('100%')
        .padding({ top: 12, bottom: 12, left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
        .border({ width: { bottom: 1 }, color: '#F0F0F0' })

        if (this.localSongDataSource.totalCount() > 0) {
          // Song list
          Text(`共 ${this.localSongDataSource.totalCount()} 首本地歌曲`)
            .fontSize(14)
            .fontColor('#999999')
            .width('100%')
            .padding({ left: 16, top: 12, bottom: 8 })

          List({ space: 2 }) {
            LazyForEach(this.localSongDataSource, (song: Song) => {
              ListItem() {
                Row({ space: 12 }) {
                  Column()
                    .width(48)
                    .height(48)
                    .borderRadius(8)
                    .backgroundColor('#F0F0F0')
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                  {
                    SymbolGlyph($r('sys.symbol.music'))
                      .fontSize(20)
                      .fontColor(['#CCCCCC'])
                  }

                  Column({ space: 4 }) {
                    Text(song.name)
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#1A1A1A')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(song.ar && song.ar.length > 0 ? song.ar[0].name : '未知歌手')
                      .fontSize(12)
                      .fontColor('#999999')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  SymbolGlyph($r('sys.symbol.play_fill'))
                    .fontSize(20)
                    .fontColor(['#007DFF'])
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                .onClick(() => {
                  AvPlayerHelper.playMusic(song);
                  this.pathStack.pushPath({ name: 'PlayerPage' });
                })
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
        } else {
          // Empty state
          Column({ space: 16 }) {
            SymbolGlyph($r('sys.symbol.music'))
              .fontSize(72)
              .fontColor(['#E0E0E0'])

            Text('即将支持本地音乐扫描')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')

            Text('鸿蒙系统 API 升级中，后续版本将支持\n扫描设备本地音频文件并自动导入')
              .fontSize(14)
              .fontColor('#999999')
              .textAlign(TextAlign.Center)
              .lineHeight(22)

            Column({ space: 12 }) {
              Text('当前您可以使用以下方式播放音乐：')
                .fontSize(13)
                .fontColor('#BBBBBB')
                .padding({ bottom: 4 })

              Row({ space: 8 }) {
                SymbolGlyph($r('sys.symbol.magnifyingglass'))
                  .fontSize(14)
                  .fontColor(['#007DFF'])
                Text('在"发现"页搜索在线歌曲')
                  .fontSize(14)
                  .fontColor('#666666')
              }

              Row({ space: 8 }) {
                SymbolGlyph($r('sys.symbol.star'))
                  .fontSize(14)
                  .fontColor(['#007DFF'])
                Text('浏览推荐歌单并添加歌曲')
                  .fontSize(14)
                  .fontColor('#666666')
              }

              Row({ space: 8 }) {
                SymbolGlyph($r('sys.symbol.music'))
                  .fontSize(14)
                  .fontColor(['#007DFF'])
                Text('在线搜索海量音乐直接播放')
                  .fontSize(14)
                  .fontColor('#666666')
              }
            }
            .padding(20)
            .backgroundColor('#F8F9FA')
            .borderRadius(12)
            .width('85%')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
    }
    .hideTitleBar(true)
  }
}
