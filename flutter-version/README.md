# Flutter Resume Workbench

这是仓库中的主编辑器版本。

## 当前能力

- 左侧多板块编辑
- 每个板块支持新增 / 删除条目
- 教育经历多条录入
- 课程成绩多条录入
- 实习 / 校园经历多条录入
- 项目经历多条录入
- 技能多条录入
- 奖项 / 证书多条录入
- 右侧实时简历预览
- 浏览器导出 PDF
- 成绩单 OCR 导入

## OCR 说明

这里的 OCR 不是直接在 Flutter Web 里放密钥。

Flutter Web 也是浏览器前端，密钥放进去并不安全。当前实现是：

```text
Flutter Web
  -> 你自己的后端 /api/transcript/parse
  -> 阿里云 OCR
```

参考后端在：

- `D:\BiographicalNotes\ai-resume-backend`

参考密钥模板在：

- `D:\BiographicalNotes\ai-resume-backend\.env.example`

## 本地运行

```powershell
Set-Location -LiteralPath ".\flutter-version"
flutter pub get
flutter run -d chrome
```

如果需要 OCR，把页面里的 `OCR 后端地址` 设置成：

```text
http://127.0.0.1:8000
```

## 检查命令

```powershell
flutter analyze
flutter test
flutter build web --base-href "/ai-resume-generator.github.io/flutter-version/"
```

## 线上发布

GitHub Pages 会把 Flutter Web 发布到：

```text
/ai-resume-generator.github.io/flutter-version/
```
