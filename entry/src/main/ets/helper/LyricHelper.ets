import { LyricLine } from '../entity/LyricLine';

export class LyricHelper {
  /**
   * 解析 LRC 格式歌词文本
   * 支持格式: [mm:ss.xx] 或 [mm:ss] 或 [mm:ss.xxx]
   */
  static parseLrc(lrcText: string): LyricLine[] {
    const lines: LyricLine[] = [];
    if (!lrcText) {
      return lines;
    }
    const regex = /\[(\d{2}):(\d{2})(?:\.(\d{2,3}))?\](.*)/g;
    let match: RegExpExecArray | null;
    while ((match = regex.exec(lrcText)) !== null) {
      const m = parseInt(match[1], 10);
      const s = parseInt(match[2], 10);
      const msStr = match[3] || '0';
      const ms = msStr.length === 3 ? parseInt(msStr, 10) : parseInt(msStr, 10) * 10;
      const time = m * 60000 + s * 1000 + ms;
      const text = match[4].trim();
      if (text) {
        const line = new LyricLine();
        line.time = time;
        line.text = text;
        lines.push(line);
      }
    }
    // 按时间排序
    lines.sort((a, b) => a.time - b.time);
    return lines;
  }

  /**
   * 根据当前播放时间获取当前歌词索引
   */
  static getCurrentIndex(lines: LyricLine[], currentTime: number): number {
    if (lines.length === 0) {
      return -1;
    }
    for (let i = lines.length - 1; i >= 0; i--) {
      if (currentTime >= lines[i].time) {
        return i;
      }
    }
    return -1;
  }
}
