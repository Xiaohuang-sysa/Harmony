import { HttpHelper } from '../helper/HttpHelper';
import { Song } from '../entity/Song';
import { AvPlayerHelper } from '../helper/AvPlayerHelper';

class CloudSong {
  id: number = 0;
  name: string = '';
  artist: string = '';
  album: string = '';
  coverUrl: string = '';
  addTime: string = '';
  size: number = 0;
}

@Builder
export function CloudSyncPageBuilder() {
  CloudSyncPage()
}

@Component
export struct CloudSyncPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @State cloudSongs: CloudSong[] = [];
  @State isLoading: boolean = true;
  @State uploadProgress: number = -1;
  @State uploadFileName: string = '';

  async aboutToAppear() {
    await this.loadCloudSongs();
  }

  async loadCloudSongs() {
    this.isLoading = true;
    try {
      // 通过网易云 API 获取云盘歌曲列表
      const songs = await HttpHelper.fetchCloudDiskSongs();
      const mapped: CloudSong[] = [];
      for (const s of songs) {
        const cs = new CloudSong();
        cs.id = s.id;
        cs.name = s.name;
        cs.artist = s.ar?.map(a => a.name).join(' / ') || '未知歌手';
        cs.album = s.al?.name || '未知专辑';
        cs.coverUrl = s.al?.picUrl || '';
        cs.addTime = '2025-01-01';
        cs.size = 0;
        mapped.push(cs);
      }
      this.cloudSongs = mapped;
    } catch (err) {
      console.error('Failed to load cloud songs', JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        // Header
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_down'))
            .fontSize(28)
            .fontColor(['#1A1A1A'])
            .onClick(() => {
              this.pathStack.pop();
            })
          Blank()
          Text('云同步')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
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
              .margin({ bottom: 16 })
            Text('正在同步云端数据...')
              .fontSize(15)
              .fontColor('#999999')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column() {
              // Cloud Storage Card
              Row() {
                Column({ space: 4 }) {
                  Text('云盘空间')
                    .fontSize(14)
                    .fontColor('#999999')
                  Text(`${this.cloudSongs.length} 首`)
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1A1A1A')
                }
                .alignItems(HorizontalAlign.Start)

                Blank()

                SymbolGlyph($r('sys.symbol.cloud'))
                  .fontSize(48)
                  .fontColor(['#007DFF'])
                  .opacity(0.3)
              }
              .width('100%')
              .padding(20)
              .backgroundColor('#F0F7FF')
              .borderRadius(16)
              .margin({ bottom: 20 })

              // Upload Button
              Row({ space: 8 }) {
                SymbolGlyph($r('sys.symbol.arrow_up_circle'))
                  .fontSize(20)
                  .fontColor([Color.White])
                Text('上传音乐')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.White)
              }
              .width('100%')
              .height(48)
              .backgroundColor('#007DFF')
              .borderRadius(24)
              .justifyContent(FlexAlign.Center)
              .margin({ bottom: 24 })
              .onClick(() => {
                // TODO: implement file picker and upload
              })

              if (this.uploadProgress >= 0) {
                Column({ space: 8 }) {
                  Text(`正在上传: ${this.uploadFileName}`)
                    .fontSize(13)
                    .fontColor('#666666')
                  Progress({ value: this.uploadProgress, total: 100 })
                    .width('100%')
                    .color('#007DFF')
                }
                .width('100%')
                .margin({ bottom: 20 })
              }

              // Sync Status
              Row({ space: 8 }) {
                SymbolGlyph($r('sys.symbol.arrow_clockwise'))
                  .fontSize(16)
                  .fontColor(['#34C759'])
                Text('已同步')
                  .fontSize(14)
                  .fontColor('#34C759')
                Text('· 刚刚')
                  .fontSize(12)
                  .fontColor('#999999')
                Blank()
                Text('立即同步')
                  .fontSize(14)
                  .fontColor('#007DFF')
                  .fontWeight(FontWeight.Medium)
                  .onClick(() => {
                    this.loadCloudSongs();
                  })
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#F5FFF5')
              .borderRadius(12)
              .margin({ bottom: 20 })

              // Song List Section
              Row() {
                Text('我的云盘歌曲')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1A1A1A')
                Blank()
                Text(`${this.cloudSongs.length} 首`)
                  .fontSize(14)
                  .fontColor('#999999')
              }
              .width('100%')
              .margin({ bottom: 12 })

              if (this.cloudSongs.length === 0) {
                Column({ space: 16 }) {
                  SymbolGlyph($r('sys.symbol.cloud'))
                    .fontSize(64)
                    .fontColor(['#DDDDDD'])
                    .opacity(0.5)
                  Text('暂无云盘歌曲')
                    .fontSize(16)
                    .fontColor('#999999')
                  Text('点击上方按钮上传你的音乐文件')
                    .fontSize(13)
                    .fontColor('#CCCCCC')
                }
                .width('100%')
                .padding({ top: 60, bottom: 60 })
                .alignItems(HorizontalAlign.Center)
              } else {
                List({ space: 8 }) {
                  ForEach(this.cloudSongs, (item: CloudSong) => {
                    ListItem() {
                      Row({ space: 12 }) {
                        Image(item.coverUrl)
                          .width(48)
                          .height(48)
                          .borderRadius(8)
                          .backgroundColor('#F0F0F0')
                          .objectFit(ImageFit.Cover)
                          .onError(() => {})

                        Column({ space: 4 }) {
                          Text(item.name)
                            .fontSize(15)
                            .fontWeight(FontWeight.Medium)
                            .fontColor('#1A1A1A')
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                          Text(item.artist)
                            .fontSize(12)
                            .fontColor('#999999')
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        }
                        .alignItems(HorizontalAlign.Start)
                        .layoutWeight(1)

                        SymbolGlyph($r('sys.symbol.more'))
                          .fontSize(20)
                          .fontColor(['#CCCCCC'])
                      }
                      .width('100%')
                      .padding(8)
                      .onClick(() => {
                        const song = new Song();
                        song.id = item.id;
                        song.name = item.name;
                        AvPlayerHelper.playMusic(song);
                        this.pathStack.pushPath({ name: 'PlayerPage' });
                      })
                    }
                  }, (item: CloudSong) => item.id.toString())
                }
                .width('100%')
                .layoutWeight(1)
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 40 })
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
    }
    .hideTitleBar(true)
  }
}
