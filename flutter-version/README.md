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
- 成绩单 OCR 导入

## OCR 接法

Flutter Web 本身也是前端，不能安全放阿里云密钥。

当前实现方式是：

```text
Flutter Web -> FastAPI OCR Backend -> Aliyun OCR
```

后端目录已经放进当前仓库：

```text
../flutter-api/
```

## 本地运行

```powershell
Set-Location -LiteralPath ".\flutter-version"
flutter pub get
flutter run -d chrome
```

## 本地联调 OCR

先启动后端：

```powershell
Set-Location -LiteralPath ".\flutter-api"
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

然后在 Flutter 页面中填：

```text
http://127.0.0.1:8000
```

## 验证

```powershell
flutter analyze
flutter test
flutter build web --base-href "/ai-resume-generator.github.io/flutter-version/"
```
