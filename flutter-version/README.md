# Flutter Resume Generator

Flutter 版本的简历生成与优化工作台，目录位于仓库 `flutter-version/`。

## 功能

- 入口页与场景选择
- 简历信息编辑
- 实时预览
- 模板 / 主题 / 语言切换
- 本地规则评分
- 本地目标匹配
- 本地优化建议
- Web 打印入口

## 本地开发

```powershell
Set-Location -LiteralPath ".\flutter-version"
D:\dev\flutter\bin\flutter.bat pub get
D:\dev\flutter\bin\flutter.bat run -d chrome
```

## 质量检查

```powershell
Set-Location -LiteralPath ".\flutter-version"
D:\dev\flutter\bin\flutter.bat analyze
D:\dev\flutter\bin\flutter.bat test
```

## 发布

GitHub Actions 会在主仓库 Pages 流程中自动构建并发布 Flutter Web 版本到：

`/ai-resume-generator.github.io/flutter-version/`
