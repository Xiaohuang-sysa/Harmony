import { HttpHelper } from '../helper/HttpHelper';
import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { AppConstants } from '../constants/AppConstants';
import { RoamChannel } from '../entity/RoamChannel';
import { Song } from '../entity/Song';

class MoodItem {
  title: string = '';
  color: string = '';
}

@Component
export struct RoamView {
  @Consume('pathStack') pathStack: NavPathStack;

  @State channels: RoamChannel[] = [];
  @State dailySongs: Song[] = [];

  async aboutToAppear() {
    this.loadFromCache();
    if (this.channels.length === 0 || this.dailySongs.length === 0) {
      await this.refreshData();
    }
  }

  async refreshData(): Promise<void> {
    const results = await Promise.all([
      HttpHelper.fetchRoamChannels(),
      HttpHelper.fetchDailyRoam()
    ]);
    const channels = results[0] as RoamChannel[];
    const dailySongs = results[1] as Song[];
    if (channels.length > 0) {
      this.channels = channels;
      AppStorage.set<string>(AppConstants.CACHE_CHANNELS, JSON.stringify(channels));
    }
    if (dailySongs.length > 0) {
      this.dailySongs = dailySongs;
      AppStorage.set<string>(AppConstants.CACHE_RECENT_SONGS, JSON.stringify(dailySongs));
    }
    AppStorage.set<number>(AppConstants.CACHE_FETCH_TIME, Date.now());
  }

  loadFromCache(): void {
    const channelsStr = AppStorage.get<string>(AppConstants.CACHE_CHANNELS);
    if (channelsStr) {
      try { this.channels = JSON.parse(channelsStr); } catch (e) {}
    }
    const songsStr = AppStorage.get<string>(AppConstants.CACHE_RECENT_SONGS);
    if (songsStr) {
      try { this.dailySongs = JSON.parse(songsStr); } catch (e) {}
    }
  }

  private moodList: MoodItem[] = [
    { title: '轻松 (Chill)', color: '#FFB6C1' } as MoodItem,
    { title: '专注 (Focus)', color: '#87CEFA' } as MoodItem,
    { title: '运动 (Workout)', color: '#FFA07A' } as MoodItem,
    { title: '睡眠 (Sleep)', color: '#9370DB' } as MoodItem
  ];

  build() {
    Scroll() {
      Column({ space: 24 }) {
        // Header
        Row() {
          Text('漫游')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')
        .padding({ top: 16, left: 16, right: 16 })
        .justifyContent(FlexAlign.Start)

        // Music Radio (Immersive Card)
        Column({ space: 12 }) {
          Text('音乐电台')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
            .width('100%')
            .padding({ left: 16 })

          Swiper() {
            ForEach(this.channels, (item: RoamChannel) => {
              Stack({ alignContent: Alignment.BottomStart }) {
                // Background
                Image(item.picUrl)
                  .width('100%')
                  .height('100%')
                  .borderRadius(16)
                  .backgroundColor('#EEEEEE')
                  .objectFit(ImageFit.Cover)
                  .onError(() => {
                    // fallback to backgroundColor
                  })

                // Content
                Row() {
                  Column({ space: 4 }) {
                    Text(item.title)
                      .fontSize(24)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(Color.White)
                    Text('最懂你的音乐品味')
                      .fontSize(14)
                      .fontColor('#E0E0E0')
                  }
                  .alignItems(HorizontalAlign.Start)

                  Blank()

                  // Play Button
                  Row() {
                    SymbolGlyph($r('sys.symbol.play_fill'))
                      .fontSize(24)
                      .fontColor([Color.Black])
                  }
                  .width(48)
                  .height(48)
                  .backgroundColor(Color.White)
                  .borderRadius(24)
                  .justifyContent(FlexAlign.Center)
                  .alignItems(VerticalAlign.Center)
                }
                .width('100%')
                .padding(16)
                .alignItems(VerticalAlign.Center)
              }
              .width('100%')
              .height(200)
              .padding({ left: 16, right: 16 })
            }, (item: RoamChannel) => item.id.toString())
          }
          .autoPlay(true)
          .itemSpace(10)
          .indicator(true)
        }
        .width('100%')

        // Mood / Genres
        Column({ space: 12 }) {
          Text('心情流派')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
            .width('100%')
            .padding({ left: 16 })

          Grid() {
            ForEach(this.moodList, (item: MoodItem) => {
              GridItem() {
                Stack() {
                  Column()
                    .width('100%')
                    .height('100%')
                    .backgroundColor(item.color)
                    .borderRadius(12)
                    .opacity(0.85)

                  Text(item.title)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)
                }
                .width('100%')
                .height(80)
              }
            })
          }
          .columnsTemplate('1fr 1fr')
          .rowsGap(12)
          .columnsGap(12)
          .padding({ left: 16, right: 16 })
          .height(180) 
        }
        .width('100%')

        // Endless Roam (Mock Playlist)
        Column({ space: 12 }) {
          Text('每日漫游')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
            .width('100%')
            .padding({ left: 16 })

          Column({ space: 16 }) {
            ForEach(this.dailySongs, (item: Song) => {
              Row({ space: 12 }) {
                // Placeholder Cover
                Image(item.al?.picUrl)
                  .width(56)
                  .height(56)
                  .borderRadius(8)
                  .backgroundColor($r('sys.color.comp_background_tertiary'))
                  .objectFit(ImageFit.Cover)
                  .onError(() => {
                    // fallback to backgroundColor
                  })
                  
                Column({ space: 4 }) {
                  Text(item.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('sys.color.font_primary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(item.ar && item.ar.length > 0 ? item.ar.map(a => a.name).join(' / ') : '未知歌手')
                    .fontSize(14)
                    .fontColor($r('sys.color.font_secondary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                SymbolGlyph($r('sys.symbol.more'))
                  .fontSize(24)
                  .fontColor([$r('sys.color.icon_secondary')])
              }
              .width('100%')
              .padding({ left: 16, right: 16 })
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                AvPlayerHelper.playMusic(item);
                this.pathStack.pushPath({ name: 'PlayerPage' });
              })
            }, (item: Song) => item.id.toString())
          }
        }
        .width('100%')
        .padding({ bottom: 32 })

      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
  }
}
