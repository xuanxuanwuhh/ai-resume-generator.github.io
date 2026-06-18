# AI Resume Generator

当前仓库已经整理成一套完整的项目结构，而不是单一静态页：

- 根页 `index.html`：项目介绍页
- `legacy-jekyll/`：保留原始 Jekyll 简历生成器
- `flutter-version/`：新的 Flutter Web 主编辑器

## 目录说明

```text
ai-resume-generator.github.io/
|- index.html
|- legacy-jekyll/
|- flutter-version/
|- assets/
|- report-assets/
|- .github/workflows/pages.yml
```

## 现在的三个前端入口

### 1. 项目介绍页

用于项目展示、技术说明和版本导航。

在线地址：

```text
https://xuanxuanwuhh.github.io/ai-resume-generator.github.io/
```

### 2. Jekyll 经典版

保留原始静态简历生成器，继续支持：

- 场景切换
- 模板切换
- 本地评分
- 本地目标匹配
- 导出 PDF

在线地址：

```text
https://xuanxuanwuhh.github.io/ai-resume-generator.github.io/legacy-jekyll/
```

### 3. Flutter 工作台

这是现在的主编辑器，已经按移动端场景继续增强，支持：

- 多条教育经历
- 多条课程成绩
- 多条实习 / 校园经历
- 多条项目经历
- 多条技能
- 多条奖项 / 证书
- 手机端编辑 / 预览切换
- 头像拍照上传、相册选择与即时预览
- 当前城市定位填充
- 统一 PDF 导出 / 打印 / 分享

在线地址：

```text
https://xuanxuanwuhh.github.io/ai-resume-generator.github.io/flutter-version/
```

## 本地运行

### Flutter 前端

```powershell
Set-Location -LiteralPath ".\flutter-version"
flutter pub get
flutter run -d chrome
```

真机调试：

```powershell
flutter devices
flutter run -d <device-id>
```

## 校验命令

### Flutter

```powershell
Set-Location -LiteralPath ".\flutter-version"
flutter analyze
flutter test
flutter build web --base-href "/ai-resume-generator.github.io/flutter-version/"
```

### Jekyll

```powershell
docker compose up -d
```
