import { HttpHelper } from '../helper/HttpHelper';
import { AvPlayerHelper } from '../helper/AvPlayerHelper';
import { Song } from '../entity/Song';
import { Artist } from '../entity/Artist';
import { BasicDataSource } from '../helper/LazyDataSource';
import { ArtistParams } from './ArtistPage';

@Builder
export function SearchPageBuilder() {
  SearchPage()
}

@Component
export struct SearchPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @State songDataSource: BasicDataSource<Song> = new BasicDataSource([]);
  @State searchKey: string = '';
  @State isLoading: boolean = false;

  build() {
    NavDestination() {
      Column() {
        Search({ value: this.searchKey, placeholder: '搜索歌曲、歌手' })
          .searchButton('搜索')
          .width('100%')
          .height(40)
          .backgroundColor('#F5F5F5')
          .placeholderColor(Color.Grey)
          .placeholderFont({ size: 14, weight: 400 })
          .textFont({ size: 14, weight: 400 })
          .onSubmit(async (value: string) => {
            if (!value || value.trim() === '') {
              return;
            }
            this.searchKey = value;
            this.isLoading = true;
            try {
              this.songDataSource.setData(await HttpHelper.searchMusic(value));
            } finally {
              this.isLoading = false;
            }
          })
          .onChange((value: string) => {
            this.searchKey = value;
          })
          .margin({ top: 10, bottom: 10, left: 15, right: 15 })

        if (this.isLoading) {
          LoadingProgress()
            .width(40)
            .height(40)
            .margin({ top: 20 })
        } else {
          List({ space: 10 }) {
            LazyForEach(this.songDataSource, (song: Song) => {
              ListItem() {
                Row() {
                  Column() {
                    Text(song.name)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#333333')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(song.ar && song.ar.length > 0 ? song.ar[0].name : '未知歌手')
                      .fontSize(12)
                      .fontColor(Color.Gray)
                      .margin({ top: 4 })
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .onClick(() => {
                        if (song.ar && song.ar.length > 0) {
                          const firstArtist: Artist = song.ar[0];
                          ArtistParams.id = firstArtist.id;
                          ArtistParams.title = firstArtist.name;
                          ArtistParams.picUrl = firstArtist.picUrl;
                          this.pathStack.pushPath({ name: 'ArtistPage' });
                        }
                      })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                }
                .width('100%')
                .padding({ left: 15, right: 15, top: 10, bottom: 10 })
                .onClick(() => {
                  AvPlayerHelper.playMusic(song);
                  this.pathStack.pushPath({ name: 'PlayerPage' });
                })
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
    }
    .title('搜索')
  }
}
