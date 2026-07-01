import { HttpHelper } from '../helper/HttpHelper';
import { NoteItem } from '../entity/NoteItem';
import { AppConstants } from '../constants/AppConstants';

@Component
export struct NoteView {
  @Consume('pathStack') pathStack: NavPathStack;

  @State notes: NoteItem[] = [];

  async aboutToAppear() {
    // 优先从 AppStorage 缓存恢复数据
    this.loadFromCache();
    // 只在 notes 为空时拉取新数据
    if (this.notes.length === 0) {
      await this.refreshData();
    }
  }

  async refreshData(): Promise<void> {
    const result = await HttpHelper.fetchCommunityNotes();
    if (result.length > 0) {
      this.notes = result;
      AppStorage.set<string>(AppConstants.CACHE_NOTES, JSON.stringify(result));
      AppStorage.set<number>(AppConstants.CACHE_FETCH_TIME, Date.now());
    }
  }

  loadFromCache(): void {
    const notesStr = AppStorage.get<string>(AppConstants.CACHE_NOTES);
    if (notesStr) {
      try { this.notes = JSON.parse(notesStr); } catch (e) {}
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // Header
        Row() {
          Text('音乐笔记')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
          Blank()
          SymbolGlyph($r('sys.symbol.square_and_pencil'))
            .fontSize(24)
            .fontColor([$r('sys.color.icon_primary')])
            .onClick(() => {
              // Action to create a new note
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 8 })

        // Notes List
        ForEach(this.notes, (item: NoteItem) => {
          this.NoteCard(item)
        }, (item: NoteItem) => item.id)
      }
      .width('100%')
      .padding({ bottom: 32, left: 12, right: 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_primary'))
    .scrollBar(BarState.Off)
  }

  @Builder
  NoteCard(item: NoteItem) {
    Column() {
      // User Info
      Row({ space: 12 }) {
        // Avatar placeholder
        Image(item.avatarUrl)
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .objectFit(ImageFit.Cover)
          .onError(() => {
            // fallback to backgroundColor
          })
        
        Column() {
          Text(item.authorName)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
          Text(item.time)
            .fontSize(12)
            .fontColor($r('sys.color.font_tertiary'))
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        
        Blank()
        
        SymbolGlyph($r('sys.symbol.more'))
          .fontSize(20)
          .fontColor([$r('sys.color.icon_secondary')])
      }
      .width('100%')
      
      // Content
      Text(item.content)
        .fontSize(15)
        .lineHeight(22)
        .fontColor($r('sys.color.font_primary'))
        .margin({ top: 12, bottom: 12 })
        .width('100%')
        
      // Song Info Card
      Row({ space: 12 }) {
        // Cover placeholder
        Image(item.coverUrl)
          .width(48)
          .height(48)
          .borderRadius(8)
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .objectFit(ImageFit.Cover)
          .onError(() => {
            // fallback to backgroundColor
          })
          
        Column() {
          Text(item.songName)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(item.artistName)
            .fontSize(12)
            .fontColor($r('sys.color.font_secondary'))
            .margin({ top: 4 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        
        SymbolGlyph($r('sys.symbol.play_fill'))
          .fontSize(28)
          .fontColor([$r('sys.color.icon_primary')])
      }
      .width('100%')
      .padding(8)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(8)
      .onClick(() => {
        // Action to play song or navigate to song detail
      })
      
      // Interaction Bar
      Row({ space: 0 }) {
        this.InteractionButton($r('sys.symbol.hand_thumbsup'), item.likes.toString())
        this.InteractionButton($r('sys.symbol.message'), item.comments.toString())
        this.InteractionButton($r('sys.symbol.share'), '分享')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .margin({ top: 16 })
      .padding({ top: 16 })
      .border({ width: { top: 1 }, color: $r('sys.color.comp_divider') })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(16)
  }

  @Builder
  InteractionButton(icon: Resource, text: string) {
    Row({ space: 6 }) {
      SymbolGlyph(icon)
        .fontSize(20)
        .fontColor([$r('sys.color.icon_secondary')])
      Text(text)
        .fontSize(13)
        .fontColor($r('sys.color.font_secondary'))
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      // Interaction action
    })
  }
}

