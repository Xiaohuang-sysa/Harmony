import { HttpHelper } from '../helper/HttpHelper';
import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { Song } from '../entity/Song';

@Builder
export function DailyRecommendPageBuilder() {
  DailyRecommendPage()
}

@Component
export struct DailyRecommendPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @State songs: Song[] = [];
  @State isLoading: boolean = true;
  private coverFailedSet: Set<number> = new Set();

  isCoverFailed(songId: number): boolean {
    return this.coverFailedSet.has(songId);
  }

  markCoverFailed(songId: number): void {
    this.coverFailedSet.add(songId);
  }

  async aboutToAppear() {
    await this.loadDailyRecommend();
  }

  async loadDailyRecommend() {
    this.isLoading = true;
    try {
      this.songs = await HttpHelper.fetchDailyRoam();
    } catch (err) {
      console.error('loadDailyRecommend failed', JSON.stringify(err));
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
          Text('每日推荐')
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
        } else if (this.songs.length === 0) {
          Column({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.music'))
              .fontSize(48)
              .fontColor(['rgba(255,255,255,0.2)'])
            Text('暂无推荐歌曲')
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
            Column({ space: 2 }) {
              ForEach(this.songs, (item: Song, index: number) => {
                Row({ space: 12 }) {
                  Text(String(index + 1))
                    .fontSize(13)
                    .fontColor('rgba(255,255,255,0.4)')
                    .width(24)
                    .textAlign(TextAlign.Center)

                  if (item.al && item.al.picUrl && !this.isCoverFailed(item.id)) {
                    Image(item.al.picUrl)
                      .width(44)
                      .height(44)
                      .borderRadius(10)
                      .objectFit(ImageFit.Cover)
                      .backgroundColor('rgba(255,255,255,0.1)')
                      .onError(() => {
                        this.markCoverFailed(item.id);
                      })
                  } else {
                    Column()
                      .width(44)
                      .height(44)
                      .borderRadius(10)
                      .backgroundColor('rgba(255,255,255,0.1)')
                      .justifyContent(FlexAlign.Center)
                      .alignItems(HorizontalAlign.Center)
                    {
                      SymbolGlyph($r('sys.symbol.music'))
                        .fontSize(18)
                        .fontColor(['rgba(255,255,255,0.4)'])
                    }
                  }

                  Column({ space: 4 }) {
                    Text(item.name)
                      .fontSize(15)
                      .fontColor(Color.White)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(item.ar && item.ar.length > 0 ? item.ar.map(a => a.name).join(' / ') : '未知歌手')
                      .fontSize(12)
                      .fontColor('rgba(255,255,255,0.5)')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  SymbolGlyph($r('sys.symbol.more'))
                    .fontSize(20)
                    .fontColor(['rgba(255,255,255,0.4)'])
                }
                .width('100%')
                .height(60)
                .padding({ left: 16, right: 16 })
                .alignItems(VerticalAlign.Center)
                .onClick(() => {
                  AvPlayerHelper.playMusic(item);
                  this.pathStack.pushPath({ name: 'PlayerPage' });
                })
              }, (item: Song) => item.id.toString())
            }
            .width('100%')
            .padding({ bottom: 32 })
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