import { HttpHelper } from '../helper/HttpHelper';
import { AppConstants } from '../constants/AppConstants';
import { UserInfo } from '../entity/UserInfo';
import { Playlist } from '../entity/Playlist';
import { ArtistParams } from '../pages/ArtistPage';
import { AlbumParams } from '../pages/AlbumDetailPage';

@Component
export struct MineView {
  @Consume('pathStack') pathStack: NavPathStack;

  @State userInfo: UserInfo = new UserInfo();
  @State createdPlaylists: Playlist[] = [];

  async aboutToAppear() {
    this.loadFromCache();
    if (this.userInfo.nickname === '' || this.createdPlaylists.length === 0) {
      await this.refreshData();
    }
  }

  loadFromCache(): void {
    const userStr = AppStorage.get<string>(AppConstants.CACHE_USER);
    if (userStr) {
      try { this.userInfo = JSON.parse(userStr); } catch (e) {}
    }
    const playlistsStr = AppStorage.get<string>(AppConstants.CACHE_PLAYLISTS);
    if (playlistsStr) {
      try { this.createdPlaylists = JSON.parse(playlistsStr); } catch (e) {}
    }
  }

  async refreshData(): Promise<void> {
    const results = await Promise.all([
      HttpHelper.fetchUserDetail(12345),
      HttpHelper.fetchPersonalizedPlaylists()
    ]);
    const user = results[0] as UserInfo;
    const playlists = results[1] as Playlist[];
    if (user.nickname !== '') {
      this.userInfo = user;
      AppStorage.set<string>(AppConstants.CACHE_USER, JSON.stringify(user));
    }
    if (playlists.length > 0) {
      this.createdPlaylists = playlists;
      AppStorage.set<string>(AppConstants.CACHE_PLAYLISTS, JSON.stringify(playlists));
    }
    AppStorage.set<number>(AppConstants.CACHE_FETCH_TIME, Date.now());
  }

  build() {
    Scroll() {
      Column() {
        // User Profile Header
        Row() {
          Image(this.userInfo.avatarUrl)
            .width(64)
            .height(64)
            .borderRadius(24)
            .backgroundColor('#E5E5E5')
            .objectFit(ImageFit.Cover)
            .onError(() => {
              // fallback to backgroundColor
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

        // Statistics
        Row() {
          this.StatItem('关注', this.userInfo.follows.toString())
          this.StatItem('粉丝', this.userInfo.followeds.toString())
          this.StatItem('等级', `Lv.${this.userInfo.level}`)
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 24 })
        .justifyContent(FlexAlign.SpaceAround)

        // Primary Entrances Grid
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

        // Artist & Album Entrances
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

        // Created Playlists Section
        Column() {
          Row() {
            Text('自建歌单')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1A1A')
            Blank()
            SymbolGlyph($r('sys.symbol.plus'))
              .fontSize(24)
              .fontColor(['#666666'])
              .onClick(() => {
                // Handle create playlist
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 8 })

          List() {
            ForEach(this.createdPlaylists, (item: Playlist) => {
              ListItem() {
                Row() {
                  Image(item.coverImgUrl)
                    .width(48)
                    .height(48)
                    .borderRadius(12)
                    .backgroundColor('#F0F0F0')
                    .objectFit(ImageFit.Cover)
                    .onError(() => {
                      // fallback to backgroundColor
                    })
                  
                  Column() {
                    Text(item.name)
                      .fontSize(15)
                      .fontColor('#1A1A1A')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(`${item.trackCount} 首`)
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .margin({ left: 12 })
                  .layoutWeight(1)

                  SymbolGlyph($r('sys.symbol.more'))
                    .fontSize(24)
                    .fontColor(['#999999'])
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                .onClick(() => {
                  class Param { id: number = 0; }
                  let p = new Param();
                  p.id = item.id;
                  this.pathStack.pushPathByName('PlaylistDetailPage', p);
                })
              }
            }, (item: Playlist) => item.id.toString())
          }
          .width('100%')
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius(24)
        .padding({ bottom: 12 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 120 }) // Safe area for mini player and bottom tabs
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
        .fontColor(['#E3323D']) // Themed primary color
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
