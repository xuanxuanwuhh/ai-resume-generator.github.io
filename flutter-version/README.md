# Flutter Resume Workbench

这是项目中的主编辑器版本。

## 功能

- 左侧支持多板块结构化编辑
- 每个板块支持新增 / 删除条目
- 教育经历多条录入
- 课程成绩多条录入
- 实习 / 校园经历多条录入
- 项目经历多条录入
- 技能多条录入
- 奖项 / 证书多条录入
- 右侧实时简历预览
- 浏览器导出 PDF

## 本地运行

```powershell
Set-Location -LiteralPath ".\flutter-version"
flutter pub get
flutter run -d chrome
```

## 验证

```powershell
flutter analyze
flutter test
flutter build web --base-href "/ai-resume-generator.github.io/flutter-version/"
```
