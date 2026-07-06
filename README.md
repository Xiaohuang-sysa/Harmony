# HW_Music - 华为鸿蒙音乐播放器

基于 HarmonyOS NEXT API 24 (6.1.1) 的音乐播放器应用，使用 ArkTS 语言开发，Stage 模式架构。

## 功能特性

| 模块 | 功能 |
|---|---|
| 歌曲播放 | 在线播放、本地播放、倍速播放（0.5x ~ 2.0x）、歌词滚动同步 |
| 播放模式 | 列表循环 / 单曲循环 / 随机播放 |
| 发现音乐 | Banner 轮播、推荐歌曲、排行榜、每日推荐 |
| 搜索 | 歌曲搜索、艺人搜索 |
| 歌单系统 | 自建歌单（创建/删除/添加歌曲）、系统歌单浏览 |
| 我的收藏 | 收藏/取消收藏歌曲 |
| 最近播放 | 播放历史记录 |
| 本地音乐 | 本地音频文件扫描与播放 |
| 用户系统 | 注册/登录/退出、登录态持久化（SQLite） |
| 云同步 | 云端歌单备份、去重、一键清空，用户级数据隔离 |
| 迷你播放器 | 底部悬浮播放栏，支持 下一首 / 播放暂停 快捷操作 |

## 技术架构

```
├── pages/          # 17 个页面
├── components/     # 6 个核心组件（MineView、FoundView、MiniPlayer...）
├── helper/         # 9 个工具类
├── entity/         # 12 个数据实体
├── constants/      # 全局常量（API 地址、缓存 Key）
└── entryability/   # 应用入口
```

### 核心技术栈

- **播放引擎**：AVPlayer（`@ohos.multimedia.media`）
- **本地存储**：Preferences + relationalStore (SQLite)
- **网络请求**：`@kit.NetworkKit`（对接网易云音乐 Node.js 后端, `http://10.0.2.2:3000`）
- **UI 框架**：ArkTS 声明式组件 + NavPathStack 路由

### 数据库

| 数据库 | 引擎 | 用途 |
|---|---|---|
| `hw_music_users.db` | SQLite | 用户账号（`users` 表）+ 登录会话（`user_session` 表） |
| `CloudSyncDB.db` | SQLite | 云同步：歌曲/歌单/收藏（按 userId 隔离） |
| `hw_music_db` | Preferences | 播放历史、收藏、自定义歌单、播放状态 |

## 构建运行

**环境要求**：DevEco Studio 5.0+ / HarmonyOS SDK API 24 / hvigor 构建工具

```bash
# 克隆仓库
git clone git@github.com:Xiaohuang-sysa/Harmony.git
cd Harmony

# 在 DevEco Studio 中打开，选择 entry 模块，Run 到模拟器或真机
```

**后端服务**：本项目依赖一个运行在 `localhost:3000` 的网易云音乐 Node.js API 服务（模拟器中通过 `10.0.2.2:3000` 访问）。

## 推送代码（中国大陆）

由于 HTTPS 443 端口不可用，请使用 SSH 方式推送：

```powershell
git remote set-url origin git@github.com:Xiaohuang-sysa/Harmony.git
$env:GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new"
git push
```

## 项目结构

```
HW_Music/
├── AppScope/                    # 应用级配置
├── entry/
│   └── src/main/
│       ├── module.json5         # 模块清单（权限、Ability）
│       ├── ets/
│       │   ├── entryability/    # 入口 Ability
│       │   ├── constants/       # 常量
│       │   ├── entity/          # 数据实体
│       │   ├── helper/          # 工具类
│       │   ├── components/      # 组件
│       │   └── pages/           # 页面
│       └── resources/           # 资源文件
├── build-profile.json5          # 构建配置
└── oh-package.json5             # 依赖声明
```

## 权限

| 权限 | 用途 |
|---|---|
| `INTERNET` | 网络访问 |
| `KEEP_BACKGROUND_RUNNING` | 后台播放 |
| `READ_MEDIA` | 读取本地音频 |
| `DISTRIBUTED_DATASYNC` | 云同步 |
| `GET_NETWORK_INFO` | 网络状态检测 |

## License

MIT
