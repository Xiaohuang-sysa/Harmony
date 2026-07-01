import { HttpHelper } from '../helper/HttpHelper';
import { AppConstants } from '../constants/AppConstants';
import { Playlist } from '../entity/Playlist';
import { PlaylistDetailParams } from './PlaylistDetailPage';

interface ToplistItem {
  id: number;
  name: string;
  coverImgUrl: string;
  description: string;
  trackCount: number;
}

interface ToplistDetailResponse {
  list: ToplistItem[];
}

@Builder
export function ChartsPageBuilder() {
  ChartsPage()
}

@Component
export struct ChartsPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @State chartList: Playlist[] = [];
  @State isLoading: boolean = true;

  async aboutToAppear() {
    await this.loadCharts();
  }

  async loadCharts() {
    this.isLoading = true;
    try {
      const url = `${AppConstants.API_BASE_URL}/toplist/detail`;
      const res = await HttpHelper.get(url);
      const json = JSON.parse(res) as ToplistDetailResponse;
      if (json && json.list) {
        const result: Playlist[] = [];
        for (const item of json.list) {
          const p = new Playlist();
          p.id = item.id;
          p.name = item.name;
          p.coverImgUrl = item.coverImgUrl;
          p.description = item.description;
          p.trackCount = item.trackCount;
          result.push(p);
        }
        this.chartList = result;
      }
    } catch (err) {
      console.error('loadCharts failed', JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        // Title bar
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor(['#FFFFFF'])
            .onClick(() => {
              this.pathStack.pop();
            })
          Text('排行榜')
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
        } else if (this.chartList.length === 0) {
          Column({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.music'))
              .fontSize(48)
              .fontColor(['rgba(255,255,255,0.2)'])
            Text('暂无榜单数据')
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
            Column() {
              Grid() {
                ForEach(this.chartList, (item: Playlist, index: number) => {
                  GridItem() {
                    Column() {
                      Image(item.coverImgUrl)
                        .width(80)
                        .height(80)
                        .borderRadius(12)
                        .objectFit(ImageFit.Cover)
                        .backgroundColor('rgba(255,255,255,0.1)')
                        .onError(() => {
                          // fallback
                        })
                      Text(item.name)
                        .fontSize(12)
                        .fontColor('rgba(255,255,255,0.8)')
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .lineHeight(16)
                        .margin({ top: 8 })
                        .textAlign(TextAlign.Center)
                    }
                    .width('100%')
                    .padding(8)
                    .onClick(() => {
                      PlaylistDetailParams.id = item.id;
                      PlaylistDetailParams.title = item.name;
                      PlaylistDetailParams.coverImgUrl = item.coverImgUrl;
                      PlaylistDetailParams.description = item.description;
                      this.pathStack.pushPath({ name: 'PlaylistDetailPage' });
                    })
                  }
                }, (item: Playlist) => item.id.toString())
              }
              .columnsTemplate('1fr 1fr 1fr')
              .rowsTemplate('auto')
              .columnsGap(8)
              .rowsGap(8)
              .width('100%')
              .padding(16)
            }
            .width('100%')
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
