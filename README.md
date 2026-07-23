# 大乐透规则分析器

体彩大乐透（前区 5 红 + 后区 2 蓝）跨平台号码规则分析工具。

支持 **Android / iOS / Windows / Web**，可在手机模拟器或真机上运行。

> 本项目仅供学习与娱乐分析，不构成任何购彩建议。请理性购彩。

## 功能

- 输入 5 注大乐透号码（本地保存）
- 自定义多条分析规则（`①1` 表示第 1 注第 1 个号；`空` 表示随机取未出现号码）
- 红球 / 蓝球规则互不跨越
- 按规则生成预测号码（启用规则数 = 生成注数）
- 填写期号与开奖号码，核对命中情况
- 号码重复校验、升序异常提示

## 规则语义

| 写法 | 含义 |
|------|------|
| `①1` | 第 1 注的第 1 个号码（原样取值） |
| `②3` | 第 2 注的第 3 个号码 |
| `空` | 随机取一个不在当前 5 注同色号码中的数，并尽量符合升序 |

- 最终号码始终升序排列
- 若按规则取值无法升序或有重复，仍会排列，并提示问题

## 环境要求

- [Flutter](https://flutter.dev) 3.35+（Dart 3.9+）
- Android：Android SDK / 模拟器或真机
- 可选：Chrome（Web 调试）

## 快速开始

```bash
git clone https://github.com/<YOUR_USER>/caipiao-analyzer.git
cd caipiao-analyzer
flutter pub get
flutter run
```

### Android

```bash
flutter devices
flutter run -d <deviceId>
# 或打包
flutter build apk --release
```

### Web

```bash
flutter run -d chrome
```

## 开发

```bash
flutter test
flutter analyze
```

## 目录结构

```
lib/
  models/       # 号码、规则、开奖核对模型
  services/     # 规则引擎
  screens/      # 输入 / 规则 / 分析页
  widgets/      # 输入框、球号、规则编辑
  state/        # 本地持久化状态
```

## 开源协议

[MIT](LICENSE)
