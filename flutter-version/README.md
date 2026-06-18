# Flutter Resume Workbench

这是项目中的主编辑器版本。

## 功能

- 多板块结构化编辑
- 每个板块支持新增 / 删除条目
- 教育经历多条录入
- 课程成绩多条录入
- 实习 / 校园经历多条录入
- 项目经历多条录入
- 技能多条录入
- 奖项 / 证书多条录入
- 手机端编辑 / 预览切换
- 头像拍照上传、相册选择与预览
- 定位权限获取当前位置
- PDF 导出、打印与分享

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
