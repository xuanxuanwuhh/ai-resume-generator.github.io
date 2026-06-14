(function () {
  const cases = {
    job: {
      zh: { title: "岗位投递版", hint: "重点呈现岗位相关课程、项目实践和可验证技能。" },
      en: { title: "Job Application", hint: "Highlight position-related skills, projects and measurable outcomes." },
      keywords: ["HTML", "CSS", "JavaScript", "项目", "实习", "协作", "文档"]
    },
    postgraduate: {
      zh: { title: "考研复试版", hint: "重点呈现专业基础、核心课程、项目经历和复试表达能力。" },
      en: { title: "Postgraduate Interview", hint: "Show coursework, research readiness and academic communication." },
      keywords: ["课程", "专业", "复试", "英语", "科研", "项目", "成绩"]
    },
    recommendation: {
      zh: { title: "保研申请版", hint: "重点呈现排名、科研潜力、竞赛获奖和导师方向匹配。" },
      en: { title: "Recommendation Track", hint: "Show rank, research potential, awards and advisor fit." },
      keywords: ["排名", "科研", "竞赛", "论文", "项目", "英语", "导师"]
    },
    admission: {
      zh: { title: "升学申请版", hint: "重点呈现学术经历、语言能力、项目作品和申请项目契合度。" },
      en: { title: "Admission Portfolio", hint: "Show academic work, language skills, projects and program fit." },
      keywords: ["GPA", "语言", "项目", "作品", "申请", "研究", "经历"]
    }
  };

  const appShell = document.querySelector("#appShell");
  const entryScreen = document.querySelector("#entryScreen");
  const startBtn = document.querySelector("#startBtn");
  const entryCaseButtons = Array.from(document.querySelectorAll("[data-entry-case]"));
  const themeDots = Array.from(document.querySelectorAll("[data-theme-choice]"));
  const langButtons = Array.from(document.querySelectorAll("[data-lang-choice]"));
  const entryTemplate = document.querySelector("#entryTemplate");

  const form = document.querySelector("#resumeForm");
  const caseButtons = Array.from(document.querySelectorAll(".case-btn"));
  const templateSelect = document.querySelector("#templateSelect");
  const themeSelect = document.querySelector("#themeSelect");
  const languageSelect = document.querySelector("#languageSelect");
  const paper = document.querySelector("#resumePaper");
  const caseTitle = document.querySelector("#caseTitle");
  const educationHint = document.querySelector("#educationHint");
  const skillTags = document.querySelector("#skillTags");
  const scoreValue = document.querySelector("#scoreValue");
  const scoreLevel = document.querySelector("#scoreLevel");
  const scoreTips = document.querySelector("#scoreTips");
  const targetInput = document.querySelector("#targetInput");
  const matchBtn = document.querySelector("#matchBtn");
  const matchResult = document.querySelector("#matchResult");
  const optimizeBtn = document.querySelector("#optimizeBtn");
  const optimizeResult = document.querySelector("#optimizeResult");
  const printBtn = document.querySelector("#printBtn");

  const supportedTemplates = ["modern", "blue", "sidebar", "gray", "classic", "minimal", "timeline", "professional", "compact"];
  const supportedThemes = ["aurora", "forest", "ember", "violet"];

  const templateLabels = {
    zh: {
      modern: "现代通用",
      blue: "蓝金正式",
      sidebar: "侧栏信息",
      gray: "蓝灰团队",
      classic: "经典单栏",
      minimal: "极简投递",
      timeline: "时间线项目",
      professional: "专业沉稳",
      compact: "紧凑信息"
    },
    en: {
      modern: "General",
      blue: "Blue-Gold",
      sidebar: "Sidebar",
      gray: "Blue-Gray",
      classic: "Classic",
      minimal: "Minimal",
      timeline: "Timeline",
      professional: "Professional",
      compact: "Compact"
    }
  };

  const themeLabels = {
    zh: {
      aurora: { label: "极光蓝", short: "蓝" },
      forest: { label: "森林绿", short: "绿" },
      ember: { label: "琥珀橙", short: "橙" },
      violet: { label: "学院紫", short: "紫" }
    },
    en: {
      aurora: { label: "Aurora Blue", short: "B" },
      forest: { label: "Forest Green", short: "G" },
      ember: { label: "Amber", short: "A" },
      violet: { label: "Academic Purple", short: "P" }
    }
  };

  const uiText = {
    zh: {
      entryTitle: "简历生成与优化工作台",
      entryLead: "先选择材料场景、视觉模板、主题色和界面语言，再进入简历生成界面。静态站默认使用本地规则建议，不伪装成真实大模型。",
      entrySections: ["材料场景", "模板与主题", "语言"],
      start: "进入工作台",
      brandTitle: "简历生成与优化工作台",
      brandSub: "Jekyll 静态网站 · 本地规则建议",
      privacyTitle: "演示数据",
      privacyText: "页面示例不使用真实个人信息，所有评分与匹配均在浏览器本地完成。",
      caseHeading: "选择材料场景",
      infoHeading: "填写核心信息",
      fieldLabels: {
        name: "姓名",
        title: "定位",
        email: "邮箱",
        phone: "电话",
        school: "学校",
        major: "专业",
        summary: "个人简介",
        project: "项目经历",
        skills: "技能关键词",
        awards: "奖项证书"
      },
      cases: {
        job: "求职",
        postgraduate: "考研",
        recommendation: "保研",
        admission: "升学"
      },
      templateLabel: "简历模板",
      toolbarTemplate: "模板",
      toolbarTheme: "主题",
      toolbarLanguage: "语言",
      preview: "实时预览",
      print: "导出 PDF",
      resumeSections: ["个人简介", "教育背景", "项目经历", "技能关键词", "奖项证书"],
      scoreHeading: "本地规则评分",
      targetHeading: "本地目标匹配",
      adviceHeading: "本地优化建议",
      localNote: "所有评分与匹配均在浏览器本地完成。",
      targetLabel: "粘贴岗位 JD / 院校要求",
      match: "运行本地匹配",
      optimize: "生成优化建议"
    },
    en: {
      entryTitle: "Resume Builder Workspace",
      entryLead: "Choose a scenario, visual template, theme color and interface language before entering the builder. The static site uses local rules and does not pretend to be a real LLM.",
      entrySections: ["Scenario", "Template & Theme", "Language"],
      start: "Enter Workspace",
      brandTitle: "Resume Builder Workspace",
      brandSub: "Jekyll static site · local rule advice",
      privacyTitle: "Demo Data",
      privacyText: "The sample page uses neutral demo data. Scores and matching run locally in the browser.",
      caseHeading: "Choose Scenario",
      infoHeading: "Core Information",
      fieldLabels: {
        name: "Name",
        title: "Target",
        email: "Email",
        phone: "Phone",
        school: "School",
        major: "Major",
        summary: "Summary",
        project: "Project Experience",
        skills: "Skill Keywords",
        awards: "Awards"
      },
      cases: {
        job: "Job",
        postgraduate: "Interview",
        recommendation: "Recommendation",
        admission: "Admission"
      },
      templateLabel: "Resume Template",
      toolbarTemplate: "Template",
      toolbarTheme: "Theme",
      toolbarLanguage: "Language",
      preview: "Live Preview",
      print: "Export PDF",
      resumeSections: ["Summary", "Education", "Project Experience", "Skill Keywords", "Awards"],
      scoreHeading: "Local Rule Score",
      targetHeading: "Local Target Match",
      adviceHeading: "Local Advice",
      localNote: "Scores and matching run locally in the browser.",
      targetLabel: "Paste job JD / program requirements",
      match: "Run Local Match",
      optimize: "Generate Advice"
    }
  };

  const sampleDefaults = {
    zh: {
      name: "示例学生",
      title: "计算机方向申请者 / Web 项目实践者",
      email: "demo@example.com",
      phone: "000-0000-0000",
      school: "示例大学",
      major: "计算机类专业",
      summary: "具备 Web 前端、静态网站构建和项目文档整理基础，能够完成从需求分析、界面设计、交互实现到运行验证的完整实践流程。关注材料结构化表达、用户体验、隐私保护和可复现交付。",
      project: "Jekyll 简历生成与优化工作台：基于静态网站技术重新实现简历生成器，完成场景选择、信息编辑、实时预览、模板切换、本地材料评分和目标匹配等模块，实现无需后端即可运行和部署的课程项目版本。",
      skills: "HTML, CSS, JavaScript, Jekyll, Git, 信息架构, 交互设计, 文档写作",
      awards: "创新实验课程项目实践、Web开发综合训练",
      target: "前端开发实习生，要求熟悉 HTML、CSS、JavaScript，了解 Vue 或静态网站开发，有项目实践、文档能力和良好的沟通协作能力。"
    },
    en: {
      name: "Demo Student",
      title: "Computer Science Applicant / Web Project Builder",
      email: "demo@example.com",
      phone: "000-0000-0000",
      school: "Demo University",
      major: "Computer Science",
      summary: "Experienced in web front-end development, static site construction and project documentation. Able to complete requirement analysis, interface design, interaction implementation and reproducible delivery.",
      project: "Jekyll Resume Builder Workspace: rebuilt a resume generator as a static website, including scenario selection, information editing, live preview, template switching, local scoring and target matching without a backend service.",
      skills: "HTML, CSS, JavaScript, Jekyll, Git, Information Architecture, Interaction Design, Documentation",
      awards: "Innovation experiment course project, Web development training",
      target: "Front-end intern role requiring HTML, CSS, JavaScript, Vue or static site experience, project practice, documentation ability and clear collaboration."
    }
  };

  let activeCase = "job";
  let activeLang = "zh";
  let activeTheme = "aurora";

  function getData() {
    const data = new FormData(form);
    return Object.fromEntries(data.entries());
  }

  function splitKeywords(value) {
    return String(value || "")
      .split(/[,，、\s]+/)
      .map((item) => item.trim())
      .filter(Boolean);
  }

  function setTheme(theme) {
    activeTheme = supportedThemes.includes(theme) ? theme : "aurora";
    document.body.dataset.theme = activeTheme;
    themeDots.forEach((button) => {
      button.classList.toggle("active", button.dataset.themeChoice === activeTheme);
    });
    if (themeSelect) themeSelect.value = activeTheme;
  }

  function setText(selector, value) {
    const node = document.querySelector(selector);
    if (node) node.textContent = value;
  }

  function setLabelText(label, value) {
    if (!label) return;
    const textNode = Array.from(label.childNodes).find((node) => (
      node.nodeType === Node.TEXT_NODE && node.textContent.trim()
    ));
    if (textNode) textNode.textContent = `\n            ${value}\n            `;
  }

  function setOptionLabels(select, labels) {
    if (!select) return;
    Array.from(select.options).forEach((option) => {
      if (labels[option.value]) option.textContent = labels[option.value];
    });
  }

  function isSampleValue(key, value) {
    return value === sampleDefaults.zh[key] || value === sampleDefaults.en[key];
  }

  function syncSampleFieldsForLanguage(lang) {
    if (!form) return;
    const keys = ["name", "title", "email", "phone", "school", "major", "summary", "project", "skills", "awards"];
    const data = getData();
    const canSyncForm = keys.every((key) => isSampleValue(key, data[key]));
    if (canSyncForm) {
      keys.forEach((key) => {
        form.elements[key].value = sampleDefaults[lang][key];
      });
    }

    if (targetInput && isSampleValue("target", targetInput.value)) {
      targetInput.value = sampleDefaults[lang].target;
    }
  }

  function applyUiLanguage() {
    const text = uiText[activeLang];
    const templates = templateLabels[activeLang];
    const themes = themeLabels[activeLang];

    document.documentElement.lang = activeLang === "en" ? "en" : "zh-CN";
    setText(".entry-copy h1", text.entryTitle);
    setText(".entry-copy p", text.entryLead);
    document.querySelectorAll(".entry-section h2").forEach((node, index) => {
      node.textContent = text.entrySections[index] || node.textContent;
    });
    setLabelText(entryTemplate && entryTemplate.closest("label"), text.templateLabel);
    setText("#startBtn", text.start);
    setText(".brand h1", text.brandTitle);
    setText(".brand p", text.brandSub);
    setText(".privacy-note strong", text.privacyTitle);
    setText(".privacy-note span", text.privacyText);

    entryCaseButtons.forEach((button) => {
      button.textContent = text.cases[button.dataset.entryCase];
    });
    caseButtons.forEach((button) => {
      button.textContent = text.cases[button.dataset.case];
    });

    const controlTitles = document.querySelectorAll(".control-pane .panel-title h2");
    if (controlTitles[0]) controlTitles[0].textContent = text.caseHeading;
    if (controlTitles[1]) controlTitles[1].textContent = text.infoHeading;

    Object.keys(text.fieldLabels).forEach((key) => {
      setLabelText(form.elements[key].closest("label"), text.fieldLabels[key]);
    });

    setText(".eyebrow", text.preview);
    setLabelText(templateSelect.closest("label"), text.toolbarTemplate);
    setLabelText(themeSelect.closest("label"), text.toolbarTheme);
    setLabelText(languageSelect.closest("label"), text.toolbarLanguage);
    setText("#printBtn", text.print);

    setOptionLabels(entryTemplate, templates);
    setOptionLabels(templateSelect, templates);
    setOptionLabels(themeSelect, Object.fromEntries(
      supportedThemes.map((theme) => [theme, themes[theme].label])
    ));
    themeDots.forEach((button) => {
      const theme = button.dataset.themeChoice;
      button.textContent = themes[theme].short;
      button.title = themes[theme].label;
    });

    document.querySelectorAll(".resume-paper section h3").forEach((node, index) => {
      node.textContent = text.resumeSections[index] || node.textContent;
    });

    const assistantTitles = document.querySelectorAll(".assistant-pane .panel-title h2");
    if (assistantTitles[0]) assistantTitles[0].textContent = text.scoreHeading;
    if (assistantTitles[1]) assistantTitles[1].textContent = text.targetHeading;
    if (assistantTitles[2]) assistantTitles[2].textContent = text.adviceHeading;
    setText(".local-note", text.localNote);
    setLabelText(targetInput.closest("label"), text.targetLabel);
    setText("#matchBtn", text.match);
    setText("#optimizeBtn", text.optimize);
  }

  function setLanguage(lang) {
    activeLang = lang === "en" ? "en" : "zh";
    document.body.dataset.lang = activeLang;
    syncSampleFieldsForLanguage(activeLang);
    applyUiLanguage();
    langButtons.forEach((button) => {
      button.classList.toggle("active", button.dataset.langChoice === activeLang);
    });
    if (languageSelect) languageSelect.value = activeLang;
    renderResume();
    if (matchResult.textContent.trim()) analyzeMatch();
    if (optimizeResult.textContent.trim()) generateAdvice();
  }

  function applyTemplate(template) {
    const next = supportedTemplates.includes(template) ? template : "modern";
    paper.className = `resume-paper template-${next}`;
    templateSelect.value = next;
    entryTemplate.value = next;
  }

  function renderResume() {
    const data = getData();
    document.querySelectorAll("[data-bind]").forEach((node) => {
      const key = node.getAttribute("data-bind");
      node.textContent = data[key] || "";
    });

    skillTags.innerHTML = "";
    splitKeywords(data.skills).forEach((skill) => {
      const tag = document.createElement("span");
      tag.textContent = skill;
      skillTags.appendChild(tag);
    });

    caseTitle.textContent = cases[activeCase][activeLang].title;
    educationHint.textContent = cases[activeCase][activeLang].hint;
    updateScore();
  }

  function scoreResume() {
    const data = getData();
    const tips = [];
    let score = 0;

    if (data.name) score += 8;
    else tips.push(activeLang === "zh" ? "建议补充姓名。" : "Add a candidate name.");

    if (data.title && data.title.length >= 8) score += 10;
    else tips.push(activeLang === "zh" ? "定位标题建议写清目标方向。" : "Clarify the target direction in the title.");

    if (data.email && data.phone) score += 10;
    else tips.push(activeLang === "zh" ? "联系方式需要完整，便于材料投递。" : "Contact information should be complete.");

    if (data.summary && data.summary.length >= 60) score += 18;
    else tips.push(activeLang === "zh" ? "个人简介建议达到 60 字以上，并写出能力、经历和目标。" : "Expand the summary with strengths, experience and goals.");

    if (data.school && data.major) score += 14;
    else tips.push(activeLang === "zh" ? "教育背景需要包含学校和专业。" : "Include school and major.");

    if (data.project && data.project.length >= 80) score += 22;
    else tips.push(activeLang === "zh" ? "项目经历建议补充背景、方法、角色和结果。" : "Describe project context, method, role and result.");

    const skills = splitKeywords(data.skills);
    if (skills.length >= 6) score += 12;
    else tips.push(activeLang === "zh" ? "技能关键词建议不少于 6 个。" : "Use at least six skill keywords.");

    if (data.awards) score += 6;
    else tips.push(activeLang === "zh" ? "可补充奖项、证书或课程成果作为佐证。" : "Add awards or certificates as evidence.");

    const text = Object.values(data).join(" ");
    if (/\d+|%|人|项|次|篇|个/.test(text)) score += 8;
    else tips.push(activeLang === "zh" ? "建议加入数字化结果，如模块数量、比例或项目规模。" : "Add measurable results such as counts or percentages.");

    score = Math.min(score, 100);
    const levelZh = score >= 85 ? "优秀" : score >= 70 ? "良好" : score >= 55 ? "基本完整" : "待完善";
    const levelEn = score >= 85 ? "Strong" : score >= 70 ? "Good" : score >= 55 ? "Needs Proof" : "Needs Work";
    return { score, level: activeLang === "zh" ? levelZh : levelEn, tips };
  }

  function updateScore() {
    const result = scoreResume();
    scoreValue.textContent = result.score;
    scoreLevel.textContent = result.level;
    scoreTips.innerHTML = "";
    const defaultTip = activeLang === "zh"
      ? "材料结构完整，可继续根据目标补充关键词和量化成果。"
      : "Structure is complete. Add more measurable outcomes and target keywords.";
    const tips = result.tips.length ? result.tips : [defaultTip];
    tips.slice(0, 5).forEach((tip) => {
      const li = document.createElement("li");
      li.textContent = tip;
      scoreTips.appendChild(li);
    });
  }

  function changeCase(nextCase) {
    activeCase = cases[nextCase] ? nextCase : "job";
    caseButtons.forEach((button) => {
      button.classList.toggle("active", button.dataset.case === activeCase);
    });
    entryCaseButtons.forEach((button) => {
      button.classList.toggle("active", button.dataset.entryCase === activeCase);
    });
    renderResume();
  }

  function analyzeMatch() {
    const data = getData();
    const target = targetInput.value || "";
    const resumeText = Object.values(data).join(" ");
    const targetWords = splitKeywords(target.replace(/[，。；、]/g, " "));
    const caseWords = cases[activeCase].keywords;
    const allWords = Array.from(new Set(targetWords.concat(caseWords))).filter((word) => word.length >= 2);
    const matched = allWords.filter((word) => resumeText.toLowerCase().includes(word.toLowerCase()));
    const missing = allWords.filter((word) => !matched.includes(word)).slice(0, 8);
    const percent = allWords.length ? Math.round((matched.length / allWords.length) * 100) : 0;

    if (activeLang === "zh") {
      matchResult.textContent = [
        `匹配度：${percent}/100`,
        `已覆盖关键词：${matched.slice(0, 10).join("、") || "暂无明显覆盖"}`,
        `建议补充关键词：${missing.join("、") || "暂无明显缺口"}`,
        "说明：这是本地关键词匹配结果。"
      ].join("\n");
    } else {
      matchResult.textContent = [
        `Match score: ${percent}/100`,
        `Covered terms: ${matched.slice(0, 10).join(", ") || "No obvious coverage"}`,
        `Missing terms: ${missing.join(", ") || "No obvious gaps"}`,
        "Note: this is a local keyword matcher."
      ].join("\n");
    }
  }

  function generateAdvice() {
    const data = getData();
    const tips = [];
    if (!/[。；;]/.test(data.project || "")) {
      tips.push(activeLang === "zh"
        ? "项目经历可以拆成“背景-职责-方法-结果”四个短句。"
        : "Split the project block into context, role, method and result.");
    }
    if (!/\d+|%/.test(data.project || "")) {
      tips.push(activeLang === "zh"
        ? "项目成果建议加入数字，如模块数量、用户规模或效率提升。"
        : "Add measurable numbers such as modules, scale or efficiency gain.");
    }
    if ((data.summary || "").length > 160) {
      tips.push(activeLang === "zh"
        ? "个人简介略长，建议压缩到 80-120 字。"
        : "The summary is long. Compress it to 80-120 words/characters.");
    } else {
      tips.push(activeLang === "zh"
        ? "个人简介长度合适，可继续加入目标关键词。"
        : "The summary length is fine. Add more target keywords.");
    }
    tips.push(activeLang === "zh"
      ? `当前场景为“${cases[activeCase].zh.title}”，建议优先突出：${cases[activeCase].keywords.join("、")}。`
      : `Current mode: ${cases[activeCase].en.title}. Prioritize: ${cases[activeCase].keywords.join(", ")}.`);
    optimizeResult.textContent = tips.map((tip, index) => `${index + 1}. ${tip}`).join("\n");
  }

  function enterWorkspace() {
    entryScreen.classList.add("is-hidden");
    appShell.classList.remove("is-hidden");
    changeCase(activeCase);
    applyTemplate(entryTemplate.value);
    setTheme(activeTheme);
    setLanguage(activeLang);
    analyzeMatch();
    generateAdvice();
  }

  form.addEventListener("input", renderResume);
  caseButtons.forEach((button) => {
    button.addEventListener("click", () => changeCase(button.dataset.case));
  });
  entryCaseButtons.forEach((button) => {
    button.addEventListener("click", () => changeCase(button.dataset.entryCase));
  });
  themeDots.forEach((button) => {
    button.addEventListener("click", () => setTheme(button.dataset.themeChoice));
  });
  langButtons.forEach((button) => {
    button.addEventListener("click", () => setLanguage(button.dataset.langChoice));
  });
  templateSelect.addEventListener("change", () => applyTemplate(templateSelect.value));
  entryTemplate.addEventListener("change", () => applyTemplate(entryTemplate.value));
  themeSelect.addEventListener("change", () => setTheme(themeSelect.value));
  languageSelect.addEventListener("change", () => setLanguage(languageSelect.value));
  matchBtn.addEventListener("click", analyzeMatch);
  optimizeBtn.addEventListener("click", generateAdvice);
  printBtn.addEventListener("click", () => window.print());
  startBtn.addEventListener("click", enterWorkspace);

  const params = new URLSearchParams(window.location.search);
  const initialCase = params.get("case");
  const initialTemplate = params.get("template");
  const initialTheme = params.get("theme");
  const initialLang = params.get("lang");

  if (initialCase && cases[initialCase]) changeCase(initialCase);
  if (initialTemplate && supportedTemplates.includes(initialTemplate)) applyTemplate(initialTemplate);
  if (initialTheme && supportedThemes.includes(initialTheme)) setTheme(initialTheme);
  if (initialLang === "en" || initialLang === "zh") setLanguage(initialLang);

  renderResume();
  if (window.location.search) {
    enterWorkspace();
  }
})();
