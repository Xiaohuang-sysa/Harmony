import { HttpHelper } from '../helper/HttpHelper';
import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { AppConstants } from '../constants/AppConstants';
import { UserInfo } from '../entity/UserInfo';
import { Song } from '../entity/Song';
import { ArtistParams } from '../pages/ArtistPage';
import { AlbumParams } from '../pages/AlbumDetailPage';

@Component
export struct MineView {
  @Consume('pathStack') pathStack: NavPathStack;
  @StorageProp('play_history') playHistory: Song[] = [];

  @State userInfo: UserInfo = new UserInfo();

  async aboutToAppear() {
    this.loadFromCache();
    if (this.userInfo.nickname === '') {
      await this.refreshData();
    }
  }

  loadFromCache(): void {
    const userStr = AppStorage.get<string>(AppConstants.CACHE_USER);
    if (userStr) {
      try { this.userInfo = JSON.parse(userStr); } catch (e) {}
    }
  }

  async refreshData(): Promise<void> {
    const user = await HttpHelper.fetchUserDetail(12345) as UserInfo;
    if (user.nickname !== '') {
      this.userInfo = user;
      AppStorage.set<string>(AppConstants.CACHE_USER, JSON.stringify(user));
    }
    AppStorage.set<number>(AppConstants.CACHE_FETCH_TIME, Date.now());
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Image(this.userInfo.avatarUrl)
            .width(64)
            .height(64)
            .borderRadius(24)
            .backgroundColor('#E5E5E5')
            .objectFit(ImageFit.Cover)
            .onError(() => {
            })

          Column() {
            Text(this.userInfo.nickname || 'Harmony User')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')
            
            Row() {
              Text(this.userInfo.vipType > 0 ? `VIP ${this.userInfo.vipType}` : '普通用户')
                .fontSize(10)
                .fontColor('#D4AF37')
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor('#FFF9E6')
                .borderRadius(8)
                .margin({ top: 6 })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 16 })
          .layoutWeight(1)

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(24)
            .fontColor(['#999999'])
        }
        .width('100%')
        .padding({ top: 32, bottom: 20, left: 20, right: 20 })
        .alignItems(VerticalAlign.Center)

        Row() {
          this.StatItem('关注', this.userInfo.follows.toString())
          this.StatItem('粉丝', this.userInfo.followeds.toString())
          this.StatItem('等级', `Lv.${this.userInfo.level}`)
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 24 })
        .justifyContent(FlexAlign.SpaceAround)

        Row() {
          this.EntranceItem($r('sys.symbol.music'), '本地音乐', 'LocalMusicPage')
          this.EntranceItem($r('sys.symbol.cloud'), '云同步', 'CloudSyncPage')
          this.EntranceItem($r('sys.symbol.heart'), '我的收藏', 'MyFavoritePage')
          this.EntranceItem($r('sys.symbol.clock'), '最近播放', 'RecentPlayPage')
          this.EntranceItem($r('sys.symbol.star_fill'), '排行榜', 'ChartsPage')
        }
        .width('100%')
        .padding({ top: 20, bottom: 20 })
        .backgroundColor(Color.White)
        .borderRadius(24)
        .margin({ bottom: 12 })

        Row() {
          Column() {
            SymbolGlyph($r('sys.symbol.person'))
              .fontSize(28)
              .fontColor(['#E3323D'])
              .margin({ bottom: 8 })
            Text('歌手')
              .fontSize(12)
              .fontColor('#333333')
          }
          .width('25%')
          .onClick(() => {
            this.pathStack.pushPath({ name: 'ArtistPage' });
          })
          Column() {
            SymbolGlyph($r('sys.symbol.rectangle_stack'))
              .fontSize(28)
              .fontColor(['#E3323D'])
              .margin({ bottom: 8 })
            Text('专辑')
              .fontSize(12)
              .fontColor('#333333')
          }
          .width('25%')
          .onClick(() => {
            this.pathStack.pushPath({ name: 'AlbumDetailPage' });
          })
          Column()
            .width('25%')
          Column()
            .width('25%')
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
        .backgroundColor(Color.White)
        .borderRadius(24)
        .margin({ bottom: 20 })

        Column() {
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
              ForEach(this.playHistory, (item: Song) => {
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
        .backgroundColor(Color.White)
        .borderRadius(24)
        .padding({ bottom: 12 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 120 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F4F4')
    .scrollBar(BarState.Off)
  }

  @Builder
  StatItem(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
      Text(label)
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 4 })
    }
  }

  @Builder
  EntranceItem(icon: Resource, label: string, targetPage: string) {
    Column() {
      SymbolGlyph(icon)
        .fontSize(28)
        .fontColor(['#E3323D'])
        .margin({ bottom: 8 })
      Text(label)
        .fontSize(12)
        .fontColor('#333333')
    }
    .width('25%')
    .onClick(() => {
      this.pathStack.pushPath({ name: targetPage });
    })
  }
}