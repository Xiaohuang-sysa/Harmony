import { HttpHelper } from '../helper/HttpHelper';
import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { AppConstants } from '../constants/AppConstants';
import { BannerItem } from '../entity/BannerItem';
import { Playlist } from '../entity/Playlist';
import { Song } from '../entity/Song';
import { PlaylistDetailParams } from '../pages/PlaylistDetailPage';

@Builder
function QuickAccessItem(icon: Resource, title: string, color: string, onClick: () => void) {
  Column({ space: 8 }) {
    Row() {
      SymbolGlyph(icon)
        .fontSize(24)
        .fontColor([color])
    }
    .width(48)
    .height(48)
    .backgroundColor('#ffe6e6e6')
    .borderRadius(24)
    .justifyContent(FlexAlign.Center)
    
    Text(title)
      .fontSize(12)
      .fontColor('#ff666666')
  }
  .width('33.33%')
  .onClick(onClick)
}

@Component
export struct RecommendView {
  @Consume('pathStack') pathStack: NavPathStack;
  @StorageProp('play_history') playHistory: Song[] = [];

  @State bannerList: BannerItem[] = [];
  @State playlistData: Playlist[] = [];

  async aboutToAppear() {
    this.loadFromCache();
    if (this.bannerList.length === 0) {
      await this.refreshData();
    }
  }

  async refreshData(): Promise<void> {
    const results = await Promise.all([
      HttpHelper.fetchBanners(),
      HttpHelper.fetchPersonalizedPlaylists()
    ]);
    const banners = results[0] as BannerItem[];
    const playlists = results[1] as Playlist[];
    if (banners.length > 0) {
      this.bannerList = banners;
      AppStorage.set<string>(AppConstants.CACHE_BANNERS, JSON.stringify(banners));
    }
    if (playlists.length > 0) {
      this.playlistData = playlists;
      AppStorage.set<string>(AppConstants.CACHE_PLAYLISTS, JSON.stringify(playlists));
    }
    AppStorage.set<number>(AppConstants.CACHE_FETCH_TIME, Date.now());
  }

  loadFromCache(): void {
    const bannersStr = AppStorage.get<string>(AppConstants.CACHE_BANNERS);
    if (bannersStr) {
      try { this.bannerList = JSON.parse(bannersStr); } catch (e) {}
    }
    const playlistsStr = AppStorage.get<string>(AppConstants.CACHE_PLAYLISTS);
    if (playlistsStr) {
      try { this.playlistData = JSON.parse(playlistsStr); } catch (e) {}
    }
  }

  build() {
    Scroll() {
      Column({ space: 20 }) {
        if (this.bannerList.length === 0 && this.playlistData.length === 0) {
          Row() {
            SymbolGlyph($r('sys.symbol.arrow_clockwise'))
              .fontSize(16)
              .fontColor(['#007DFF'])
            Text('点击刷新')
              .fontSize(14)
              .fontColor('#007DFF')
              .fontWeight(FontWeight.Medium)
              .margin({ left: 6 })
          }
          .width('100%')
          .height(44)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#F0F7FF')
          .borderRadius(22)
          .onClick(async () => {
            await this.refreshData();
          })
        }

        Swiper() {
          ForEach(this.bannerList, (item: BannerItem) => {
            Row() {
              Image(item.imageUrl)
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
                .backgroundColor('#ffcccccc')
                .onError((err) => {
                })
            }
            .width('100%')
            .height(140)
            .backgroundColor('#ffcccccc')
            .borderRadius(24)
            .justifyContent(FlexAlign.Center)
          }, (item: BannerItem) => item.imageUrl)
        }
        .width('100%')
        .height(140)
        .autoPlay(true)
        .itemSpace(10)
        .indicator(true)

        Row() {
          QuickAccessItem($r('sys.symbol.music'), '每日推荐', '#E3323D', () => {
            this.pathStack.pushPath({ name: 'DailyRecommendPage' });
          })
          QuickAccessItem($r('sys.symbol.folder'), '歌单', '#007DFF', () => {
            this.pathStack.pushPath({ name: 'PlaylistCatalogPage' });
          })
          QuickAccessItem($r('sys.symbol.star'), '排行榜', '#FF9500', () => {
            this.pathStack.pushPath({ name: 'ChartsPage' });
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)

        Column({ space: 12 }) {
          Row() {
            Text('猜你喜欢')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#ff000000')
            Blank()
            Text('更多 >')
              .fontSize(12)
              .fontColor('#ff999999')
          }
          .width('100%')
          
          Scroll() {
            Row({ space: 12 }) {
              ForEach(this.playlistData, (item: Playlist) => {
                Column({ space: 8 }) {
                  Image(item.coverImgUrl)
                    .width(104)
                    .height(104)
                    .borderRadius(20)
                    .backgroundColor('#ffeeeeee')
                    .objectFit(ImageFit.Cover)
                    .onError(() => {
                    })
                  
                  Text(item.name)
                    .fontSize(13)
                    .fontColor('#ff333333')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                    .textAlign(TextAlign.Start)
                }
                .width(104)
                .onClick(() => {
                  PlaylistDetailParams.id = item.id;
                  PlaylistDetailParams.title = item.name;
                  PlaylistDetailParams.coverImgUrl = item.coverImgUrl;
                  PlaylistDetailParams.description = item.description;
                  this.pathStack.pushPath({ name: 'PlaylistDetailPage' });
                })
              }, (item: Playlist) => item.id.toString())
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
        }
        .width('100%')
        
        Column({ space: 12 }) {
          Row() {
            Text('最近播放')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#ff000000')
            Blank()
            Text('更多 >')
              .fontSize(12)
              .fontColor('#ff999999')
          }
          .width('100%')
          
          if (this.playHistory.length === 0) {
            Column({ space: 8 }) {
              SymbolGlyph($r('sys.symbol.music'))
                .fontSize(32)
                .fontColor(['#ffcccccc'])
              Text('暂无播放记录')
                .fontSize(14)
                .fontColor('#ff999999')
            }
            .width('100%')
            .padding({ top: 20, bottom: 20 })
            .justifyContent(FlexAlign.Center)
          } else {
            Column({ space: 10 }) {
              ForEach(this.playHistory.slice(0, 10), (item: Song) => {
                Row({ space: 12 }) {
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
            .width('100%')
          }
        }
        .width('100%')
        .padding({ bottom: 40 })
        
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
  }
}