# AI Resume Generator Pages Repo

这个仓库现在分成两个清晰的层次：

- 根目录 `Jekyll` 首页：只作为升级说明页和入口页
- `flutter-version/`：真正的简历编辑器

这样处理的原因很直接：

1. 原来的 Jekyll 工作台已经出现样式和交互堆叠问题，最明显的是导出按钮显示异常
2. 你要的“多条经历增删 + 成绩单 OCR + 右侧只保留预览”更适合放到一个真正的前端应用里做
3. `Flutter Web` 虽然更适合做复杂交互，但它依然是浏览器前端，**不能安全存 OCR 密钥**

## 当前结构

```text
ai-resume-generator.github.io/
|- index.html                 # Jekyll 首页，升级说明与入口
|- flutter-version/           # Flutter Web 编辑器
|- .github/workflows/pages.yml
|- assets/                    # 旧 Jekyll 资源，当前首页已不再依赖
```

## Flutter 版当前功能

- 左侧所有板块支持新增和删除
- 支持多条教育经历
- 支持多条课程成绩
- 支持多条实习 / 校园经历
- 支持多条项目经历
- 支持多条技能
- 支持多条奖项 / 证书
- 支持导出 PDF
- 支持上传成绩单并调用 OCR 后端接口
- 右侧只保留简历预览，不再显示本地建议区

## OCR 设计

### 结论

OCR 密钥不能放在 Jekyll，也不能放在 Flutter Web。

原因是它们最终都运行在浏览器里，属于前端静态资源。只要把阿里云密钥写进去，用户就能拿到。

### 正确方案

```text
前端(Jekyll/Flutter Web)
    -> 你自己的后端 API
    -> 阿里云 OCR
```

### 当前接入方式

Flutter 页面里提供了一个可编辑的 `OCR 后端地址` 输入框，默认值：

- 本地开发：`http://127.0.0.1:8000`
- 线上页面：需要你自己部署的 `https://...` 后端

参考后端和密钥模板在：

- `D:\BiographicalNotes\ai-resume-backend`
- `D:\BiographicalNotes\ai-resume-backend\.env.example`

其中 `.env.example` 里可以看到需要的变量：

- `ALIBABA_CLOUD_ACCESS_KEY_ID`
- `ALIBABA_CLOUD_ACCESS_KEY_SECRET`
- `ALIYUN_OCR_ENDPOINT`

## 本地运行

### 1. 运行 Flutter

```powershell
Set-Location -LiteralPath ".\flutter-version"
flutter pub get
flutter run -d chrome
```

### 2. 如需 OCR，本地启动参考后端

在 `D:\BiographicalNotes\ai-resume-backend` 下配置 `.env` 后启动后端。

Flutter 页面里把 `OCR 后端地址` 设为：

```text
http://127.0.0.1:8000
```

## 质量检查

```powershell
Set-Location -LiteralPath ".\flutter-version"
flutter analyze
flutter test
flutter build web --base-href "/ai-resume-generator.github.io/flutter-version/"
```

## GitHub Pages

工作流会：

1. 构建根目录 Jekyll 首页
2. 构建 `flutter-version/` 的 Flutter Web
3. 把 Flutter 构建产物发布到：

```text
/ai-resume-generator.github.io/flutter-version/
```

线上地址：

- Jekyll 首页：`https://xuanxuanwuhh.github.io/ai-resume-generator.github.io/`
- Flutter 工作台：`https://xuanxuanwuhh.github.io/ai-resume-generator.github.io/flutter-version/`
