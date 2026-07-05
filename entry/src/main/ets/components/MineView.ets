import { HttpHelper } from '../helper/HttpHelper';
import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { StorageHelper } from '../helper/StorageHelper';
import { AppConstants } from '../constants/AppConstants';
import { UserInfo } from '../entity/UserInfo';
import { Playlist } from '../entity/Playlist';
import { CustomPlaylistParams } from '../pages/CustomPlaylistPage';


@Component
export struct MineView {
  @Consume('pathStack') pathStack: NavPathStack;
  @StorageProp('custom_playlists') customPlaylists: Playlist[] = [];
  @StorageProp('is_logged_in') isLoggedIn: boolean = false;
  @StorageProp('cache_user') userInfo: UserInfo = new UserInfo();
  @State showCreateDialog: boolean = false;
  @State newPlaylistName: string = '';
  @State showDeleteConfirm: boolean = false;
  @State deleteTargetId: number = 0;
  @State deleteTargetName: string = '';

  async aboutToAppear() {
    this.loadFromCache();
    await StorageHelper.loadCustomPlaylists();
    if (this.userInfo.nickname === '') {
      await this.refreshData();
    }
  }

  loadFromCache(): void {
    const userStr = AppStorage.get<string>(AppConstants.CACHE_USER);
    if (userStr) {
      try { 
        const parsed = JSON.parse(userStr) as UserInfo;
        AppStorage.set<UserInfo>('cache_user', parsed);
      } catch (e) {}
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

  async createPlaylist(): Promise<void> {
    if (this.newPlaylistName.trim()) {
      await StorageHelper.createPlaylist(this.newPlaylistName.trim());
      this.newPlaylistName = '';
      this.showCreateDialog = false;
    }
  }

  confirmDeletePlaylist(id: number, name: string): void {
    this.deleteTargetId = id;
    this.deleteTargetName = name;
    this.showDeleteConfirm = true;
  }

  async deletePlaylist(): Promise<void> {
    await StorageHelper.deletePlaylist(this.deleteTargetId);
    this.showDeleteConfirm = false;
    this.deleteTargetId = 0;
    this.deleteTargetName = '';
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
        Row() {
          Image(this.userInfo.avatarUrl || '')
            .width(64)
            .height(64)
            .borderRadius(24)
            .backgroundColor('#E5E5E5')
            .objectFit(ImageFit.Cover)
            .onError(() => {
            })

          Column() {
            Text(this.isLoggedIn ? this.userInfo.nickname : '点击登录')
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
        .onClick(() => {
          if (!this.isLoggedIn) {
            this.pathStack.pushPath({ name: 'LoginPage' });
          }
        })

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

        Column() {
          Row() {
            Text('自建歌单')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#ff000000')
            Blank()
            Row({ space: 4 }) {
              SymbolGlyph($r('sys.symbol.plus'))
              .fontSize(16)
              .fontColor(['#E3323D'])
              Text('新建')
                .fontSize(12)
                .fontColor('#E3323D')
            }
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor('#FFF0F0')
            .borderRadius(14)
            .onClick(() => {
              this.showCreateDialog = true;
            })
          }
          .width('100%')
          
          if (this.customPlaylists.length === 0) {
            Column({ space: 8 }) {
              SymbolGlyph($r('sys.symbol.music'))
                .fontSize(32)
                .fontColor(['#ffcccccc'])
              Text('暂无自建歌单，点击新建创建')
                .fontSize(14)
                .fontColor('#ff999999')
            }
            .width('100%')
            .padding({ top: 20, bottom: 20 })
            .justifyContent(FlexAlign.Center)
          } else {
            Column({ space: 12 }) {
              ForEach(this.customPlaylists, (item: Playlist) => {
                Row({ space: 12 }) {
                  Stack({ alignContent: Alignment.Center }) {
                    Image(item.coverImgUrl)
                      .width(60)
                      .height(60)
                      .borderRadius(12)
                      .backgroundColor('#ffeeeeee')
                      .objectFit(ImageFit.Cover)
                      .onError(() => {
                      })
                    if (!item.coverImgUrl) {
                      SymbolGlyph($r('sys.symbol.music'))
                        .fontSize(24)
                        .fontColor(['#ff999999'])
                    }
                  }
                  
                  Column({ space: 6 }) {
                    Text(item.name)
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#ff333333')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(`${item.trackCount} 首歌曲`)
                      .fontSize(12)
                      .fontColor('#ff999999')
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  SymbolGlyph($r('sys.symbol.trash'))
                    .fontSize(18)
                    .fontColor(['#ff999999'])
                    .onClick(() => {
                      this.confirmDeletePlaylist(item.id, item.name);
                    })
                }
                .width('100%')
                .padding(12)
                .backgroundColor('#fff9f9f9')
                .borderRadius(16)
                .onClick(() => {
                  CustomPlaylistParams.id = item.id;
                  this.pathStack.pushPath({ name: 'CustomPlaylistPage' });
                })
              }, (item: Playlist) => item.id.toString())
            }
            .width('100%')
          }
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius(24)
        .padding({ bottom: 12 })
        .margin({ bottom: 12 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 120 })
    }
    .width('100%')
        .height('100%')
        .backgroundColor('#F4F4F4')
        .scrollBar(BarState.Off)

      if (this.showCreateDialog) {
        Column() {
          Column() {
            Text('新建歌单')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#ff333333')
              .margin({ bottom: 20 })
            
            TextInput({ placeholder: '请输入歌单名称' })
              .width('100%')
              .height(48)
              .backgroundColor('#fff5f5f5')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.newPlaylistName = value;
              })
            
            Row({ space: 12 }) {
              Button('取消')
                .width(120)
                .height(44)
                .backgroundColor('#fff5f5f5')
                .fontColor('#ff666666')
                .borderRadius(22)
                .onClick(() => {
                  this.showCreateDialog = false;
                  this.newPlaylistName = '';
                })
              
              Button('创建')
                .width(120)
                .height(44)
                .backgroundColor('#ffE3323D')
                .fontColor(Color.White)
                .borderRadius(22)
                .onClick(() => {
                  this.createPlaylist();
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 24 })
          }
          .width('80%')
          .backgroundColor(Color.White)
          .borderRadius(24)
          .padding({ top: 24, bottom: 24, left: 20, right: 20 })
          .shadow({ radius: 20, color: 'rgba(0,0,0,0.15)', offsetY: 10 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showCreateDialog = false;
          this.newPlaylistName = '';
        })
      }

      if (this.showDeleteConfirm) {
        Column() {
          Column() {
            Text('确认删除歌单')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#ff333333')
              .margin({ bottom: 12 })

            Text(`确定要删除「${this.deleteTargetName}」吗？`)
              .fontSize(14)
              .fontColor('#ff666666')
              .margin({ bottom: 20 })
            
            Row({ space: 12 }) {
              Button('取消')
                .width(120)
                .height(44)
                .backgroundColor('#fff5f5f5')
                .fontColor('#ff666666')
                .borderRadius(22)
                .onClick(() => {
                  this.showDeleteConfirm = false;
                })
              
              Button('删除')
                .width(120)
                .height(44)
                .backgroundColor('#ffFF4D4F')
                .fontColor(Color.White)
                .borderRadius(22)
                .onClick(() => {
                  this.deletePlaylist();
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 24 })
          }
          .width('80%')
          .backgroundColor(Color.White)
          .borderRadius(24)
          .padding({ top: 24, bottom: 24, left: 20, right: 20 })
          .shadow({ radius: 20, color: 'rgba(0,0,0,0.15)', offsetY: 10 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showDeleteConfirm = false;
        })
      }
    }
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