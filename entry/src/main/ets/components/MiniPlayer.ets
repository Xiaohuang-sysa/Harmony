import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { Song } from '../entity/Song';

@Component
export struct MiniPlayer {
  @Consume('pathStack') pathStack: NavPathStack;
  @StorageProp('songDetail') song: Song | null = null;
  @StorageProp('symbol') isPlaying: boolean = false;
  @State coverFailed: boolean = false;

  build() {
    // 没有歌曲时隐藏
    if (!this.song) {
      Column().height(0)
    } else {
      Row({ space: 12 }) {
        // 左侧+中间：点击进入播放页
        Row({ space: 8 }) {
          // 圆形封面
          if (this.song.al && this.song.al.picUrl && !this.coverFailed) {
            Image(this.song.al.picUrl)
              .width(40)
              .height(40)
              .borderRadius(20)
              .objectFit(ImageFit.Cover)
              .backgroundColor('rgba(255,255,255,0.1)')
              .onError(() => {
                this.coverFailed = true;
              })
          } else {
            Column()
              .width(40)
              .height(40)
              .borderRadius(20)
              .backgroundColor('rgba(255,255,255,0.15)')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
            {
              SymbolGlyph($r('sys.symbol.music'))
                .fontSize(18)
                .fontColor(['rgba(255,255,255,0.6)'])
            }
          }

          // 歌曲名 + 歌手
          Column({ space: 2 }) {
            Text(this.song.name)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.song.ar && this.song.ar.length > 0 ? this.song.ar[0].name : '未知歌手')
              .fontSize(11)
              .fontColor('rgba(255,255,255,0.6)')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .height('100%')
        .onClick(() => {
          this.pathStack.pushPath({ name: 'PlayerPage' });
        })

        // 右侧：播放/暂停 + 下一首 + 列表
        SymbolGlyph(this.isPlaying ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'))
          .fontSize(28)
          .fontColor([Color.White])
          .margin({ right: 10 })
          .onClick(() => {
            AvPlayerHelper.togglePlay();
          })

        SymbolGlyph($r('sys.symbol.forward_end_fill'))
          .fontSize(22)
          .fontColor(['rgba(255,255,255,0.8)'])
          .margin({ right: 10 })
          .onClick(() => {
            AvPlayerHelper.nextSong();
          })

        SymbolGlyph($r('sys.symbol.list_bullet'))
          .fontSize(24)
          .fontColor(['rgba(255,255,255,0.7)'])
          .onClick(() => {
            this.pathStack.pushPath({ name: 'PlaylistPage' });
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#2A2A2E')
      .alignItems(VerticalAlign.Center)
      .borderRadius(20)
      .shadow({ radius: 12, color: 'rgba(0,0,0,0.4)', offsetY: -4 })
    }
  }
}
