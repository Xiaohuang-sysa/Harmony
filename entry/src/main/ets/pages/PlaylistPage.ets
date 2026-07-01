import { PlaylistHelper } from '../helper/PlaylistHelper';
import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { Song } from '../entity/Song';

@Builder
export function PlaylistPageBuilder() {
  PlaylistPage()
}

@Component
export struct PlaylistPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @StorageProp('playlist') playlist: Song[] = [];
  private coverFailedSet: Set<number> = new Set();

  isCoverFailed(songId: number): boolean {
    return this.coverFailedSet.has(songId);
  }

  markCoverFailed(songId: number): void {
    this.coverFailedSet.add(songId);
  }

  build() {
    NavDestination() {
      Column() {
        // 标题栏
        Row() {
          Text('播放列表')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text('(' + this.playlist.length + ')')
            .fontSize(14)
            .fontColor('rgba(255,255,255,0.5)')
            .margin({ left: 8 })
          Blank()
          if (this.playlist.length > 0) {
            Text('清空')
              .fontSize(14)
              .fontColor('#FF453A')
              .onClick(() => {
                PlaylistHelper.clearAll();
              })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

        if (this.playlist.length === 0) {
          Column({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.music'))
              .fontSize(48)
              .fontColor(['rgba(255,255,255,0.2)'])
            Text('播放列表为空')
              .fontSize(15)
              .fontColor('rgba(255,255,255,0.4)')
            Text('从搜索或推荐页面点击歌曲即可自动加入')
              .fontSize(13)
              .fontColor('rgba(255,255,255,0.3)')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 0 }) {
            ForEach(this.playlist, (item: Song, index: number) => {
              ListItem() {
                this.songRow(item, index)
              }
              .width('100%')
            })
          }
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#1C1C1E')
    }
    .hideTitleBar(true)
  }

  @Builder songRow(song: Song, index: number) {
    Row({ space: 10 }) {
      Text(String(index + 1))
        .fontSize(13)
        .fontColor('rgba(255,255,255,0.4)')
        .width(24)
        .textAlign(TextAlign.Center)

      if (song.al && song.al.picUrl && !this.isCoverFailed(song.id)) {
        Image(song.al.picUrl)
          .width(40)
          .height(40)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)
          .backgroundColor('rgba(255,255,255,0.1)')
          .onError(() => {
            this.markCoverFailed(song.id);
          })
      } else {
        Column()
          .width(40)
          .height(40)
          .borderRadius(6)
          .backgroundColor('rgba(255,255,255,0.1)')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        {
          SymbolGlyph($r('sys.symbol.music'))
            .fontSize(20)
            .fontColor(['rgba(255,255,255,0.4)'])
        }
      }

      Column({ space: 2 }) {
        Text(song.name)
          .fontSize(14)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(song.ar && song.ar.length > 0 ? song.ar[0].name : '未知歌手')
          .fontSize(11)
          .fontColor('rgba(255,255,255,0.5)')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.chevron_up'))
        .fontSize(18)
        .fontColor(['rgba(255,255,255,0.5)'])
        .onClick(() => {
          PlaylistHelper.moveUp(index);
        })

      SymbolGlyph($r('sys.symbol.chevron_down'))
        .fontSize(18)
        .fontColor(['rgba(255,255,255,0.5)'])
        .margin({ left: 8 })
        .onClick(() => {
          PlaylistHelper.moveDown(index);
        })

      SymbolGlyph($r('sys.symbol.trash'))
        .fontSize(18)
        .fontColor(['rgba(255,255,255,0.4)'])
        .margin({ left: 8 })
        .onClick(() => {
          PlaylistHelper.removeSong(index);
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      AvPlayerHelper.playMusic(song);
    })
  }
}
