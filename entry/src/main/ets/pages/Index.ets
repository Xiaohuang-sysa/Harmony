import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { StorageHelper } from '../helper/StorageHelper';
import { PlaylistHelper } from '../helper/PlaylistHelper';
import { FoundView } from '../components/FoundView';
import { RecommendView } from '../components/RecommendView';
import { MineView } from '../components/MineView';
import { MiniPlayer } from '../components/MiniPlayer';

@Entry
@Component
struct Index {
  @Provide('pathStack') pathStack: NavPathStack = new NavPathStack();
  @Provide('refresh_trigger') refreshTrigger: number = 0;
  @State currentIndex: number = 0;

  async aboutToAppear(): Promise<void> {
    // 页面加载前初始化全局状态机与播放器骨架
    AvPlayerHelper.initGlobalState();
    AvPlayerHelper.initPlayer();
    // 初始化本地存储并加载已保存的数据
    await StorageHelper.init(getContext(this));
    await StorageHelper.loadPlayHistory();
    await StorageHelper.loadFavorites();
    await StorageHelper.loadCustomPlaylists();
    await StorageHelper.restorePlaybackState();
    StorageHelper.loadLoginState();
    // 初始化播放列表
    PlaylistHelper.init();
  }

  @Builder tabBuilder(index: number, title: string, icon: Resource) {
    Column() {
      SymbolGlyph(icon)
        .fontSize(24)
        .fontColor([this.currentIndex === index ? '#007DFF' : '#99000000'])
      Text(title)
        .fontSize(10)
        .margin({ top: 4 })
        .fontColor(this.currentIndex === index ? '#007DFF' : '#99000000')
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }

  build() {
    Column() {
      Navigation(this.pathStack) {
        Stack() {
          Tabs({ barPosition: BarPosition.End }) {
            TabContent() {
              RecommendView()
            }
            .tabBar(this.tabBuilder(0, '推荐', $r('sys.symbol.house')))

            TabContent() {
              FoundView()
            }
            .tabBar(this.tabBuilder(1, '发现', $r('sys.symbol.magnifyingglass')))

            TabContent() {
              MineView()
            }
            .tabBar(this.tabBuilder(2, '我的', $r('sys.symbol.person')))
          }
          .barHeight(56)
          .onChange((index: number) => {
            this.currentIndex = index;
            if (index === 2) {
              this.refreshTrigger = Date.now();
            }
          })
          .scrollable(false)

          MiniPlayer()
            .position({ bottom: 56 })
        }
      }
      .mode(NavigationMode.Stack)
      .hideTitleBar(true)
      .hideToolBar(true)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding({ top: 16, left: 12, right: 12, bottom: 16 })
    .clip(true)
  }
}