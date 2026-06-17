# AI Resume Generator

当前仓库已经整理成一套完整的项目结构，而不是单一静态页：

- 根页 `index.html`：项目介绍页
- `legacy-jekyll/`：保留原始 Jekyll 简历生成器
- `flutter-version/`：新的 Flutter Web 主编辑器
- `flutter-api/`：成绩单 OCR 后端

## 目录说明

```text
ai-resume-generator.github.io/
|- index.html
|- legacy-jekyll/
|- flutter-version/
|- flutter-api/
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

这是现在的主编辑器，支持：

- 多条教育经历
- 多条课程成绩
- 多条实习 / 校园经历
- 多条项目经历
- 多条技能
- 多条奖项 / 证书
- 右侧实时简历预览
- 浏览器导出 PDF
- 成绩单 OCR 导入

在线地址：

```text
https://xuanxuanwuhh.github.io/ai-resume-generator.github.io/flutter-version/
```

## OCR 后端

仓库中新增：

```text
flutter-api/
```

这个目录里放的是 Flutter 页面实际可调用的成绩单 OCR 后端。

### 路由

```text
GET  /
POST /api/transcript/parse
```

### 技术栈

- FastAPI
- Uvicorn
- PyMuPDF
- Pillow
- Aliyun OCR SDK

### 密钥配置

不要把 OCR 密钥写进 Jekyll 或 Flutter 页面。

只在后端 `.env` 中配置，模板见：

```text
flutter-api/.env.example
```

需要的变量：

- `ALIBABA_CLOUD_ACCESS_KEY_ID`
- `ALIBABA_CLOUD_ACCESS_KEY_SECRET`
- `ALIYUN_OCR_ENDPOINT`

## 本地运行

### Flutter 前端

```powershell
Set-Location -LiteralPath ".\flutter-version"
flutter pub get
flutter run -d chrome
```

### OCR 后端

```powershell
Set-Location -LiteralPath ".\flutter-api"
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

然后在 Flutter 页面里把 `OCR 后端地址` 设为：

```text
http://127.0.0.1:8000
```

## 在线 OCR 的限制

GitHub Pages 上的 Flutter 页面是 `https`。

所以如果你要在**线上页面**里直接使用 OCR，必须部署一个你自己的 **HTTPS FastAPI 后端**。  
线上页面不能直接调用本机 `http://127.0.0.1:8000`。

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
