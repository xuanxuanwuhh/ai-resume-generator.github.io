🎯 简历生成与优化工作台（Jekyll 静态网站版）
================================================

基于 Jekyll 的简历制作工具，支持多种场景、模板和主题，本地规则评分，隐私友好


✨ 项目简介
----------

本项目由原 Vue/FastAPI 简历生成器改造而来，按《创新实验》期末大作业"静态网站"方向重新实现。

- **技术栈**: Jekyll + HTML + CSS + JavaScript
- **运行方式**: Docker 一键启动，无需后端
- **核心特性**: 本地规则评分，数据不上传，隐私安全


📋 重要说明
-----------

| 事项 | 说明 |
|------|------|
| 🚫 | 本版本不在前端直接调用大模型 API |
| 🧠 | 建议区采用浏览器本地规则评分和关键词匹配 |
| 🔒 | 所有数据仅在浏览器本地处理，不上传服务器 |
| 📊 | 评分规则清晰可解释，可离线运行 |


🎁 功能模块
-----------

| 图标 | 模块 | 功能描述 |
|------|------|----------|
| 🚪 | 入口界面 | 选择材料场景、模板、主题色和语言 |
| 🎯 | 场景选择 | 求职 / 考研 / 保研 / 升学 |
| ✏️ | 简历编辑 | 个人信息、教育背景、项目经历、技能奖项 |
| 👁️ | 实时预览 | 编辑内容即时刷新 A4 简历预览 |
| 🎨 | 模板切换 | 9 个精美模板可选 |
| 💅 | 主题切换 | 极光蓝 / 森林绿 / 琥珀橙 / 学院紫 |
| 🌐 | 语言切换 | 中文 / English |
| 📈 | 本地评分 | 简历完整度、量化表达、关键词匹配评分 |
| 🔍 | 目标匹配 | 粘贴岗位 JD 进行关键词匹配分析 |
| 📤 | 导出打印 | 浏览器打印导出 PDF |


📐 模板展示
-----------

Jekyll 静态版提供 9 个精美模板：

📄 现代通用 | 🏆 蓝金正式 | 📑 侧栏信息 | 🤝 蓝灰团队 | 📖 经典单栏  
✨ 极简投递 | ⏱️ 时间线项目 | 💼 专业沉稳 | 📦 紧凑信息


🛠️ 技术架构
-----------

```
┌─────────────────────────────────────┐
│         Jekyll 静态网站架构          │
├─────────────────────────────────────┤
│  Jekyll 构建层                       │
│  ├── _config.yml                    │
│  ├── index.html (Liquid 模板)       │
│  └── 静态资源管理                    │
├─────────────────────────────────────┤
│  页面展示层                          │
│  ├── 入口选择界面                    │
│  ├── 编辑工作台                      │
│  ├── A4 简历预览                    │
│  └── 模板/主题切换                  │
├─────────────────────────────────────┤
│  本地交互层                          │
│  ├── JavaScript 状态同步             │
│  ├── 材料评分算法                    │
│  ├── 关键词匹配                     │
│  └── 打印导出 PDF                   │
└─────────────────────────────────────┘
```


🚀 快速启动
-----------

### 环境要求

Docker Desktop 29.x 或更高版本

### 一键启动（推荐）

```powershell
Set-Location -LiteralPath "C:\Users\13617\ai-resume-generator.github.io"
.\start-jekyll.ps1
```

**启动脚本功能：**
- ✅ 停止旧容器
- ✅ 检查 4000 端口占用
- ✅ Docker Compose 启动
- ✅ 自动轮询验证服务就绪

### 状态检查

```powershell
Set-Location -LiteralPath "C:\Users\13617\ai-resume-generator.github.io"
.\check-jekyll.ps1
```

### 手动命令

```powershell
docker compose up -d        # 启动服务
docker compose logs -f jekyll  # 查看日志
docker compose down         # 停止服务
```


🌐 访问地址
-----------

| 图标 | 页面 | 地址 |
|------|------|------|
| 🏠 | 主页 | http://127.0.0.1:4000/ |
| 📝 | 保研场景 | http://127.0.0.1:4000/?case=recommendation&template=blue&theme=ember |
| 🌍 | 英文升学 | http://127.0.0.1:4000/?case=admission&template=sidebar&theme=violet&lang=en |
| 📚 | 考研时间线 | http://127.0.0.1:4000/?case=postgraduate&template=timeline&theme=forest |


🦋 Flutter 子项目
----------------

仓库中已新增 Flutter 版本，目录为 `flutter-version/`，用于在 Flutter Web 中复刻简历工作台的核心体验。

**当前能力：**

- 入口页与场景选择
- 简历编辑表单
- 实时预览
- 模板 / 主题 / 语言切换
- 本地规则评分
- 本地关键词匹配
- 本地优化建议
- Web 端打印入口

**本地运行：**

```powershell
Set-Location -LiteralPath ".\flutter-version"
D:\dev\flutter\bin\flutter.bat pub get
D:\dev\flutter\bin\flutter.bat run -d chrome
```

**质量检查：**

```powershell
Set-Location -LiteralPath ".\flutter-version"
D:\dev\flutter\bin\flutter.bat analyze
D:\dev\flutter\bin\flutter.bat test
```

**在线地址：**

- Jekyll 首页：`https://xuanxuanwuhh.github.io/ai-resume-generator.github.io/`
- Flutter Web：`https://xuanxuanwuhh.github.io/ai-resume-generator.github.io/flutter-version/`


🔗 GitHub Pages 在线预览
-------------------------

仓库已配置 GitHub Actions 自动部署，当前会同时发布：

- 根目录 Jekyll 站点
- `flutter-version/` 下的 Flutter Web 构建产物

**开启步骤：**

1. 打开仓库 **Settings**
2. 进入 **Pages**
3. 在 **Build and deployment** 中选择 **Source → GitHub Actions**
4. 等待 **Deploy Jekyll site to GitHub Pages** 工作流完成

**线上地址：**

https://xuanxuanwuhh.github.io/ai-resume-generator.github.io/


👥 小组协作
-----------

四人协作分工、分支命名和避免冲突的文件归属见 `TEAM_WORK_PLAN.md`。


📁 项目结构
-----------

```
ai-resume-generator.github.io/
├── .github/workflows/    # GitHub Actions 部署配置
├── assets/               # 静态资源
│   ├── css/style.css     # 样式文件
│   └── js/app.js         # 交互脚本
├── flutter-version/      # Flutter Web 版本
├── report-assets/        # 报告截图素材
├── _config.yml           # Jekyll 配置
├── index.html            # 主页面
├── README.md             # 项目说明
├── TEAM_WORK_PLAN.md     # 团队分工计划
├── build_exp5_report.py  # 报告生成脚本
├── docker-compose.yml    # Docker 配置
├── start-jekyll.ps1      # 启动脚本
└── check-jekyll.ps1      # 检查脚本
```


📜 许可证
---------

本项目仅供学习和课程作业使用，遵循课程要求和学术诚信规范。

---

*Made with ❤️ for 创新实验课程*
