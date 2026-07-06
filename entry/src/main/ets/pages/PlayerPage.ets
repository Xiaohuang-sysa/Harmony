import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { LyricHelper } from '../helper/LyricHelper';
import { HttpHelper } from '../helper/HttpHelper';
import { Song } from '../entity/Song';
import { LyricLine } from '../entity/LyricLine';
import { PlayMode } from '../constants/AppConstants';
import { StorageHelper } from '../helper/StorageHelper';
import { ArtistParams } from './ArtistPage';
import { Artist } from '../entity/Artist';
import { Playlist } from '../entity/Playlist';

@Builder
export function PlayerPageBuilder() {
  PlayerPage()
}

@Component
export struct PlayerPage {
  @Consume('pathStack') pathStack: NavPathStack;

  @StorageProp('songDetail') @Watch('onSongChange') song: Song | null = null;
  @StorageProp('current') current: number = 0;
  @StorageProp('duration') duration: number = 0;
  @StorageProp('cStr') cStr: string = '00:00';
  @StorageProp('dStr') dStr: string = '00:00';
  @StorageProp('symbol') isPlaying: boolean = false;
  @StorageProp('playback_speed') currentSpeed: number = 1.0;
  @StorageProp('current_mode') currentMode: number = PlayMode.SEQUENCE;
  @StorageProp('favorites') favorites: Song[] = [];
  @StorageProp('custom_playlists') customPlaylists: Playlist[] = [];
  @State showSpeedMenu: boolean = false;
  @State showPlaylistDialog: boolean = false;
  @State bgImgFailed: boolean = false;
  @State coverImgFailed: boolean = false;
  @State lyricLines: LyricLine[] = [];
  @State currentLyricIndex: number = -1;
  @State showLyrics: boolean = false;
  private lyricScroll: Scroller = new Scroller();
  private lastSongId: number = 0;

  async aboutToAppear() {
    if (this.song) {
      this.lastSongId = this.song.id;
      await this.loadLyrics(this.song.id);
    }
  }

  onSongChange(): void {
    if (this.song && this.song.id !== this.lastSongId) {
      this.lastSongId = this.song.id;
      this.coverImgFailed = false;
      this.bgImgFailed = false;
      this.loadLyrics(this.song.id);
    }
  }

  async loadLyrics(songId: number): Promise<void> {
    const lrcText = await HttpHelper.fetchLyric(songId);
    this.lyricLines = LyricHelper.parseLrc(lrcText);
    const idx = LyricHelper.getCurrentIndex(this.lyricLines, this.current);
    this.currentLyricIndex = idx;
  }

  scrollToLyricIndex(index: number): void {
    if (index < 0 || this.lyricLines.length === 0) return;
    // +1 补偿顶部的 Header spacer
    const targetIndex = index + 1;
    this.lyricScroll.scrollToIndex(targetIndex, true, ScrollAlign.CENTER);
  }

  aboutToUpdate(): void {
    if (this.lyricLines.length === 0) return;
    const newIndex = LyricHelper.getCurrentIndex(this.lyricLines, this.current);
    if (newIndex !== this.currentLyricIndex) {
      this.currentLyricIndex = newIndex;
      this.scrollToLyricIndex(newIndex);
    }
  }

  cycleMode(): void {
    let newMode: number;
    if (this.currentMode === PlayMode.LOOP_LIST) {
      newMode = PlayMode.RANDOM;
    } else if (this.currentMode === PlayMode.RANDOM) {
      newMode = PlayMode.LOOP_SINGLE;
    } else {
      newMode = PlayMode.LOOP_LIST;
    }
    AppStorage.set<number>('current_mode', newMode);
  }

  getModeIcon(): Resource {
    if (this.currentMode === PlayMode.LOOP_LIST) {
      return $r('sys.symbol.repeat');
    } else if (this.currentMode === PlayMode.RANDOM) {
      return $r('sys.symbol.shuffle');
    } else {
      return $r('sys.symbol.repeat');
    }
  }

  isFavorite(songId: number): boolean {
    return this.favorites.some((s: Song) => s.id === songId);
  }

  toggleFavorite(): void {
    if (!this.song) {
      return;
    }
    StorageHelper.toggleFavorite(this.song);
  }

  build() {
    NavDestination() {
      Stack() {
        // Background blur
        if (this.song?.al?.picUrl && !this.bgImgFailed) {
          Image(this.song.al.picUrl)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .blur(50)
            .opacity(0.8)
            .onError(() => {
              this.bgImgFailed = true;
            })
        } else {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#121212')
        }

        // Dark overlay
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.4)')

        Column() {
          // Navigation Bar
          Row() {
            SymbolGlyph($r('sys.symbol.chevron_down'))
              .fontSize(32)
              .fontColor([Color.White])
              .onClick(() => {
                this.pathStack.pop();
              })

            SymbolGlyph(this.isFavorite(this.song?.id ?? -1) ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
              .fontSize(24)
              .fontColor(this.isFavorite(this.song?.id ?? -1) ? ['#FF3B30'] : ['rgba(255,255,255,0.8)'])
              .margin({ left: 12, right: 12 })
              .onClick(() => {
                this.toggleFavorite();
              })
            
            Column() {
              Text('正在播放')
                .fontSize(16)
                .fontColor(Color.White)
                .opacity(0.8)
              Text(this.song?.name || '未知歌曲')
                .fontSize(14)
                .fontColor(Color.White)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)

            // Mode + playlist + toggle lyrics/cover
            Row({ space: 10 }) {
              // Mode cycle button
              if (this.currentMode === PlayMode.LOOP_SINGLE) {
                Stack() {
                  SymbolGlyph($r('sys.symbol.repeat'))
                    .fontSize(18)
                    .fontColor(['rgba(255,255,255,0.7)'])
                  Text('1')
                    .fontSize(9)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)
                }
                .width(24)
                .height(24)
                .onClick(() => {
                  this.cycleMode();
                })
              } else {
                SymbolGlyph(this.getModeIcon())
                  .fontSize(18)
                  .fontColor(['rgba(255,255,255,0.7)'])
                  .onClick(() => {
                    this.cycleMode();
                  })
              }

              // Playlist button
              SymbolGlyph($r('sys.symbol.list_bullet'))
                .fontSize(18)
                .fontColor(['rgba(255,255,255,0.7)'])
                .onClick(() => {
                  this.pathStack.pushPath({ name: 'PlaylistPage' });
                })

              Text('词')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.showLyrics ? Color.White : 'rgba(255,255,255,0.5)')
                .onClick(() => {
                  this.showLyrics = !this.showLyrics;
                })

              SymbolGlyph($r('sys.symbol.plus'))
                .fontSize(20)
                .fontColor(['rgba(255,255,255,0.7)'])
                .onClick(() => {
                  this.showPlaylistDialog = true;
                  StorageHelper.loadCustomPlaylists();
                })
            }
          }
          .width('100%')
          .padding({ top: 40, left: 20, right: 20 })
          .height(72)
          .alignItems(VerticalAlign.Center)

          // Album Cover (shown when lyrics are hidden)
          if (!this.showLyrics) {
            if (this.song?.al?.picUrl && !this.coverImgFailed) {
              Image(this.song.al.picUrl)
                .width(240)
                .height(240)
                .borderRadius(120)
                .margin({ top: 20 })
                .shadow({ radius: 20, color: 'rgba(0,0,0,0.5)', offsetX: 0, offsetY: 10 })
                .backgroundColor('rgba(255,255,255,0.1)')
                .onError(() => {
                  this.coverImgFailed = true;
                })
            } else {
              Column()
                .width(240)
                .height(240)
                .borderRadius(120)
                .margin({ top: 20 })
                .backgroundColor('rgba(255,255,255,0.15)')
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
              {
                SymbolGlyph($r('sys.symbol.music'))
                  .fontSize(64)
                  .fontColor([Color.White])
              }
            }
          }

          // Song Info
          Column() {
            Text(this.song?.name || '未知歌曲')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ bottom: 6 })

            Text(this.song?.ar?.[0]?.name || '未知歌手')
              .fontSize(15)
              .fontColor('rgba(255, 255, 255, 0.7)')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .onClick(() => {
                if (this.song && this.song.ar && this.song.ar.length > 0) {
                  const artist: Artist = this.song.ar[0];
                  ArtistParams.id = artist.id;
                  ArtistParams.title = artist.name;
                  ArtistParams.picUrl = artist.picUrl;
                  this.pathStack.pushPath({ name: 'ArtistPage' });
                }
              })
          }
          .width('80%')
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 16, bottom: 12 })

          // Lyrics Area
          if (this.lyricLines.length > 0) {
            List({ scroller: this.lyricScroll }) {
              // Header spacer for centering first line
              ListItem() {
                Blank().height(160)
              }

              ForEach(this.lyricLines, (line: LyricLine, index: number) => {
                ListItem() {
                  Text(line.text)
                    .fontSize(16)
                    .fontColor(index === this.currentLyricIndex ? Color.White : 'rgba(255,255,255,0.4)')
                    .fontWeight(index === this.currentLyricIndex ? FontWeight.Bold : FontWeight.Regular)
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .padding({ top: 10, bottom: 10 })
                    .animation({ duration: 300 })
                }
              })

              // Footer spacer for centering last line
              ListItem() {
                Blank().height(160)
              }
            }
            .width('100%')
            .layoutWeight(1)
            .divider({ strokeWidth: 0 })
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.None)
            .onAppear(() => {
              if (this.currentLyricIndex >= 0) {
                this.scrollToLyricIndex(this.currentLyricIndex);
              }
            })
          } else {
            // Empty state for lyrics
            Column() {
              SymbolGlyph($r('sys.symbol.music'))
                .fontSize(40)
                .fontColor(['rgba(255,255,255,0.2)'])
              Text('暂无歌词')
                .fontSize(14)
                .fontColor('rgba(255,255,255,0.3)')
                .margin({ top: 8 })
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          }

          // Speed selector menu
          if (this.showSpeedMenu) {
            Row({ space: 8 }) {
              ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], (speed: number) => {
                Text(`${speed}x`)
                  .fontSize(12)
                  .fontWeight(speed === this.currentSpeed ? FontWeight.Bold : FontWeight.Regular)
                  .fontColor(speed === this.currentSpeed ? Color.White : 'rgba(255,255,255,0.5)')
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor(speed === this.currentSpeed ? 'rgba(255,59,48,0.7)' : 'rgba(255,255,255,0.1)')
                  .borderRadius(14)
                  .onClick(() => {
                    AvPlayerHelper.setSpeed(speed);
                    this.showSpeedMenu = false;
                  })
                  .animation({ duration: 200 })
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: 4, bottom: 4 })
            .margin({ bottom: 4 })
          }

          // Progress Bar
          Row() {
            Text(this.cStr)
              .fontSize(11)
              .fontColor('rgba(255, 255, 255, 0.6)')
              .width(36)
              .textAlign(TextAlign.Start)

            Slider({
              value: this.current,
              min: 0,
              max: this.duration > 0 ? this.duration : 100,
              style: SliderStyle.OutSet
            })
              .blockColor(Color.White)
              .trackColor('rgba(255, 255, 255, 0.2)')
              .selectedColor('#FF3B30')
              .layoutWeight(1)
              .margin({ left: 6, right: 6 })
              .onChange((value: number) => {
                AvPlayerHelper.seekTo(value);
              })

            Text(this.dStr)
              .fontSize(11)
              .fontColor('rgba(255, 255, 255, 0.6)')
              .width(36)
              .textAlign(TextAlign.End)

            // Speed rate button
            Text(`x${this.currentSpeed.toFixed(1)}`)
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.showSpeedMenu ? Color.White : 'rgba(255,255,255,0.6)')
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor(this.showSpeedMenu ? 'rgba(255,255,255,0.2)' : 'transparent')
              .borderRadius(4)
              .margin({ left: 8 })
              .onClick(() => {
                this.showSpeedMenu = !this.showSpeedMenu;
              })
          }
          .width('90%')
          .margin({ top: 12, bottom: 16 })

          // Playback Controls
          Row() {
            SymbolGlyph($r('sys.symbol.backward_end_fill'))
              .fontSize(36)
              .fontColor([Color.White])
              .margin({ right: 36 })
              .onClick(() => {
                AvPlayerHelper.preSong();
              })

            SymbolGlyph(this.isPlaying ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'))
              .fontSize(72)
              .fontColor([Color.White])
              .margin({ left: 36, right: 36 })
              .onClick(() => {
                AvPlayerHelper.togglePlay();
              })

            SymbolGlyph($r('sys.symbol.forward_end_fill'))
              .fontSize(36)
              .fontColor([Color.White])
              .margin({ left: 36 })
              .onClick(() => {
                AvPlayerHelper.nextSong();
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 40 })
        }
        .width('100%')
        .height('100%')

        if (this.showPlaylistDialog) {
          Column() {
            Column() {
              Text('添加到歌单')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#ff333333')
                .margin({ bottom: 20 })
              
              if (this.customPlaylists.length === 0) {
                Text('暂无歌单，请先创建')
                  .fontSize(14)
                  .fontColor('#ff999999')
              } else {
                Column({ space: 12 }) {
                  ForEach(this.customPlaylists, (item: Playlist) => {
                    Row({ space: 12 }) {
                      Stack({ alignContent: Alignment.Center }) {
                        Image(item.coverImgUrl)
                          .width(48)
                          .height(48)
                          .borderRadius(8)
                          .backgroundColor('#ffeeeeee')
                          .objectFit(ImageFit.Cover)
                          .onError(() => {
                          })
                        if (!item.coverImgUrl) {
                          SymbolGlyph($r('sys.symbol.music'))
                            .fontSize(20)
                            .fontColor(['#ff999999'])
                        }
                      }
                      
                      Column({ space: 4 }) {
                        Text(item.name)
                          .fontSize(15)
                          .fontColor('#ff333333')
                        Text(`${item.trackCount} 首`)
                          .fontSize(12)
                          .fontColor('#ff999999')
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                      
                      SymbolGlyph($r('sys.symbol.plus'))
                        .fontSize(20)
                        .fontColor(['#E3323D'])
                    }
                    .width('100%')
                    .padding(12)
                    .backgroundColor('#fff5f5f5')
                    .borderRadius(12)
                    .onClick(() => {
                      if (this.song) {
                        StorageHelper.addSongToPlaylist(item.id, this.song);
                        StorageHelper.loadCustomPlaylists();
                        this.showPlaylistDialog = false;
                      }
                    })
                  }, (item: Playlist) => item.id.toString())
                }
                .width('100%')
              }
              
              Button('取消')
                .width('100%')
                .height(44)
                .backgroundColor('#fff5f5f5')
                .fontColor('#ff666666')
                .borderRadius(22)
                .margin({ top: 20 })
                .onClick(() => {
                  this.showPlaylistDialog = false;
                })
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
            this.showPlaylistDialog = false;
          })
        }
      }
    }
    .hideTitleBar(true)
  }
}
