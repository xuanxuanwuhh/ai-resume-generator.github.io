# Flutter OCR API

这是 Flutter 工作台对应的成绩单 OCR 后端。

## 作用

提供一个后端接口，让 Flutter 页面上传成绩单文件后，由服务端读取 `.env` 中的阿里云密钥并调用 OCR。

## 接口

```text
GET  /
POST /api/transcript/parse
```

## 环境变量

从 `.env.example` 复制为 `.env`：

```powershell
Copy-Item .env.example .env
```

需要配置：

- `ALIBABA_CLOUD_ACCESS_KEY_ID`
- `ALIBABA_CLOUD_ACCESS_KEY_SECRET`
- `ALIYUN_OCR_ENDPOINT`
- `CORS_ALLOW_ORIGINS`

## 启动

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

## 注意

- 不要把 OCR 密钥放进 Flutter Web 页面
- 如果要给 GitHub Pages 在线页面使用，后端必须单独部署成 HTTPS 服务
- `CORS_ALLOW_ORIGINS` 建议写成逗号分隔的前端地址，例如 `https://xuanxuanwuhh.github.io,http://127.0.0.1:4000`
