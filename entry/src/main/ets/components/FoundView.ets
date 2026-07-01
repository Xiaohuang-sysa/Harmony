import { HttpHelper } from '../helper/HttpHelper';
import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { AppConstants } from '../constants/AppConstants';
import { BannerItem } from '../entity/BannerItem';
import { Playlist } from '../entity/Playlist';
import { Song } from '../entity/Song';

@Component
export struct FoundView {
  @Consume('pathStack') pathStack: NavPathStack;
  private swiperController: SwiperController = new SwiperController();

  @State banners: BannerItem[] = [];
  @State playlists: Playlist[] = [];
  @State songs: Song[] = [];

  async aboutToAppear() {
    // 优先从 AppStorage 缓存恢复数据（避免 Tab 切换时数据丢失）
    this.loadFromCache();
    // 只在首次加载或缓存过期时拉取新数据
    if (this.banners.length === 0) {
      await this.refreshData();
    }
  }

  async refreshData(): Promise<void> {
    const results = await Promise.all([
      HttpHelper.fetchBanners(),
      HttpHelper.fetchPersonalizedPlaylists(),
      HttpHelper.fetchDailyRoam()
    ]);
    const banners = results[0] as BannerItem[];
    const playlists = results[1] as Playlist[];
    const songs = results[2] as Song[];
    if (banners.length > 0) {
      this.banners = banners;
      AppStorage.set<string>(AppConstants.CACHE_BANNERS, JSON.stringify(banners));
    }
    if (playlists.length > 0) {
      this.playlists = playlists;
      AppStorage.set<string>(AppConstants.CACHE_PLAYLISTS, JSON.stringify(playlists));
    }
    if (songs.length > 0) {
      this.songs = songs;
      AppStorage.set<string>(AppConstants.CACHE_RECENT_SONGS, JSON.stringify(songs));
    }
    AppStorage.set<number>(AppConstants.CACHE_FETCH_TIME, Date.now());
  }

  loadFromCache(): void {
    const bannersStr = AppStorage.get<string>(AppConstants.CACHE_BANNERS);
    if (bannersStr) {
      try { this.banners = JSON.parse(bannersStr); } catch (e) {}
    }
    const playlistsStr = AppStorage.get<string>(AppConstants.CACHE_PLAYLISTS);
    if (playlistsStr) {
      try { this.playlists = JSON.parse(playlistsStr); } catch (e) {}
    }
    const songsStr = AppStorage.get<string>(AppConstants.CACHE_RECENT_SONGS);
    if (songsStr) {
      try { this.songs = JSON.parse(songsStr); } catch (e) {}
    }
  }

  build() {
    Scroll() {
      Column({ space: 24 }) {
        // 顶部搜索框
        Row() {
          Row({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.magnifyingglass'))
              .fontSize(18)
              .fontColor(['#999999'])
            Text('搜索你想听的歌曲、歌手')
              .fontSize(14)
              .fontColor('#999999')
          }
          .width('100%')
          .height(44)
          .backgroundColor('#FFFFFF')
          .borderRadius(22)
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Center)
          .shadow({ radius: 12, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })
        .onClick(() => {
          this.pathStack.pushPath({ name: 'SearchPage' });
        })

        // Banner 轮播图
        Swiper(this.swiperController) {
          ForEach(this.banners, (item: BannerItem) => {
            this.BannerCard(item)
          }, (item: BannerItem) => item.imageUrl || item.typeTitle)
        }
        .autoPlay(true)
        .interval(4000)
        .indicator(
          Indicator.dot()
            .itemWidth(6)
            .itemHeight(6)
            .selectedItemWidth(18)
            .selectedItemHeight(6)
            .color('rgba(255,255,255,0.4)')
            .selectedColor('#FFFFFF')
        )
        .width('100%')
        .height(150)
        .itemSpace(16)
        .padding({ left: 16, right: 16 })

        // 推荐歌单
        this.SectionTitle('推荐歌单')
        
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          ForEach(this.playlists, (item: Playlist) => {
            this.PlaylistCard(item)
          }, (item: Playlist) => item.id.toString())
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        
        // 发现新音乐
        this.SectionTitle('发现新音乐')

        Column({ space: 16 }) {
          ForEach(this.songs.slice(0, 5), (item: Song, index: number) => {
            this.NewReleaseItem((index + 1).toString(), item)
          }, (item: Song) => item.id.toString())
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 80 }) // 留出底部 TabBar 的空间
      }
      .width('100%')
      .backgroundColor('#FAFAFA') // 微弱的背景色，使卡片和白色元素更突出
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
  }

  @Builder
  BannerCard(item: BannerItem) {
    Stack({ alignContent: Alignment.BottomStart }) {
      Image(item.imageUrl)
        .width('100%')
        .height('100%')
        .borderRadius(16)
        .objectFit(ImageFit.Cover)
        .backgroundColor('#E8E8E8')
        .onError(() => {
          // fallback to backgroundColor
        })
      
      Column() {
        Text(item.typeTitle)
          .fontSize(24)
          .fontWeight(FontWeight.Bolder)
          .fontColor(Color.White)
          .margin({ bottom: 4 })
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.3)', offsetY: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 24, bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.1)', offsetY: 6 })
  }

  @Builder
  SectionTitle(title: string) {
    Row() {
      Text(title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
      
      Row({ space: 4 }) {
        Text('更多')
          .fontSize(12)
          .fontColor('#666666')
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(12)
          .fontColor(['#666666'])
      }
      .padding({ left: 10, right: 8, top: 4, bottom: 4 })
      .backgroundColor('#FFFFFF')
      .borderRadius(14)
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.03)', offsetY: 2 })
      .onClick(() => {
        // do nothing for now
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 16, right: 16, top: 8 })
  }

  @Builder
  PlaylistCard(item: Playlist) {
    Column() {
      Stack({ alignContent: Alignment.TopEnd }) {
        Image(item.coverImgUrl)
          .width('100%')
          .aspectRatio(1)
          .borderRadius(16)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#EEEEEE')
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.08)', offsetY: 4 })
          .onError(() => {
            // fallback to backgroundColor
          })
          
        Row({ space: 4 }) {
          SymbolGlyph($r('sys.symbol.play_fill'))
            .fontSize(10)
            .fontColor([Color.White])
          Text(item.trackCount > 0 ? `${item.trackCount}` : '推荐')
            .fontSize(10)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
        .padding({ top: 6, bottom: 6, left: 8, right: 8 })
        .backgroundColor('rgba(0,0,0,0.25)')
        .borderRadius({ bottomLeft: 12, topRight: 16 })
        .backdropBlur(10)
      }
      
      Text(item.name)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2C2C2C')
        .margin({ top: 10 })
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('31%')
    .margin({ bottom: 20 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  NewReleaseItem(index: string, item: Song) {
    Row() {
      Row({ space: 14 }) {
        Text(index)
          .fontSize(18)
          .fontColor(index === '1' || index === '2' || index === '3' ? '#FF4D4F' : '#B3B3B3')
          .fontWeight(FontWeight.Bold)
          .width(28)
          .textAlign(TextAlign.Center)
          .fontStyle(index === '1' || index === '2' || index === '3' ? FontStyle.Italic : FontStyle.Normal)
        
        Stack({ alignContent: Alignment.Center }) {
          Image(item.al?.picUrl)
            .width(56)
            .height(56)
            .borderRadius(12)
            .backgroundColor('#EEEEEE')
            .objectFit(ImageFit.Cover)
            .shadow({ radius: 6, color: 'rgba(0,0,0,0.06)', offsetY: 3 })
            .onError(() => {
              // fallback to backgroundColor
            })
          
          SymbolGlyph($r('sys.symbol.play_fill'))
            .fontSize(20)
            .fontColor(['rgba(255,255,255,0.8)'])
        }
          
        Column() {
          Text(item.name)
            .fontSize(16)
            .fontColor('#1A1A1A')
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(item.ar && item.ar.length > 0 ? item.ar.map(a => a.name).join(' / ') : '未知歌手')
            .fontSize(13)
            .fontColor('#808080')
            .margin({ top: 6 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      
      SymbolGlyph($r('sys.symbol.more'))
        .fontSize(20)
        .fontColor(['#B3B3B3'])
        .padding(10)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8, left: 8, right: 4 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.02)', offsetY: 4 })
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
    .onClick(() => {
      AvPlayerHelper.playMusic(item);
      this.pathStack.pushPath({ name: 'PlayerPage' });
    })
  }
}
