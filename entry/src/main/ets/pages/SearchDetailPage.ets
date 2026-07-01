@Builder
export function SearchDetailPageBuilder() {
  SearchDetailPage()
}

@Component
export struct SearchDetailPage {
  @Consume('pathStack') pathStack: NavPathStack;

  build() {
    NavDestination() {
      Column() {
        Text('搜索结果页')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .title('搜索结果')
  }
}
