import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'printing/print_helper.dart' as print_helper;

void main() {
  runApp(const ResumeStudioApp());
}

class ResumeStudioApp extends StatelessWidget {
  const ResumeStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Resume Generator Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      ),
      home: const ResumeStudioPage(),
    );
  }
}

class ResumeStudioPage extends StatefulWidget {
  const ResumeStudioPage({super.key});

  @override
  State<ResumeStudioPage> createState() => _ResumeStudioPageState();
}

class _ResumeStudioPageState extends State<ResumeStudioPage> {
  final Map<DraftField, TextEditingController> _controllers = {};
  late final TextEditingController _targetController;

  bool _enteredWorkspace = false;
  bool _isSyncingControllers = false;

  AppLanguage _language = AppLanguage.zh;
  ResumeScenario _scenario = ResumeScenario.job;
  ResumeTemplate _template = ResumeTemplate.modern;
  ResumeTheme _theme = ResumeTheme.aurora;

  MatchResult? _matchResult;
  List<String>? _adviceResult;

  @override
  void initState() {
    super.initState();
    for (final field in DraftField.values) {
      _controllers[field] = TextEditingController(
        text: sampleDrafts[_language]![field]!,
      )..addListener(_handleDraftChanged);
    }
    _targetController = TextEditingController(text: sampleTargets[_language]!)
      ..addListener(_handleDraftChanged);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _targetController.dispose();
    super.dispose();
  }

  ResumeDraft get _draft => ResumeDraft(
    values: {
      for (final entry in _controllers.entries)
        entry.key: entry.value.text.trim(),
    },
  );

  CopyDeck get _copy => copyDecks[_language]!;

  WorkspacePalette get _palette => WorkspacePalette.of(_theme);

  ScenarioInfo get _scenarioInfo => scenarioLibrary[_scenario]!;

  ScoreResult get _scoreResult => _buildScoreResult();

  void _handleDraftChanged() {
    if (_isSyncingControllers) {
      return;
    }

    setState(() {
      _refreshGeneratedPanels();
    });
  }

  void _refreshGeneratedPanels() {
    if (_matchResult != null) {
      _matchResult = _buildMatchResult();
    }
    if (_adviceResult != null) {
      _adviceResult = _buildAdvice();
    }
  }

  bool _isSampleValue(DraftField field, String value) {
    return value == sampleDrafts[AppLanguage.zh]![field] ||
        value == sampleDrafts[AppLanguage.en]![field];
  }

  bool get _shouldSyncDraftForLanguage {
    return DraftField.values.every((field) {
      return _isSampleValue(field, _controllers[field]!.text);
    });
  }

  bool get _shouldSyncTargetForLanguage {
    return _targetController.text == sampleTargets[AppLanguage.zh] ||
        _targetController.text == sampleTargets[AppLanguage.en];
  }

  void _setLanguage(AppLanguage next) {
    if (_language == next) {
      return;
    }

    final syncDraft = _shouldSyncDraftForLanguage;
    final syncTarget = _shouldSyncTargetForLanguage;

    setState(() {
      _language = next;
      _isSyncingControllers = true;

      if (syncDraft) {
        for (final field in DraftField.values) {
          _controllers[field]!.text = sampleDrafts[next]![field]!;
        }
      }

      if (syncTarget) {
        _targetController.text = sampleTargets[next]!;
      }

      _isSyncingControllers = false;
      _refreshGeneratedPanels();
    });
  }

  void _setScenario(ResumeScenario next) {
    if (_scenario == next) {
      return;
    }

    setState(() {
      _scenario = next;
      _refreshGeneratedPanels();
    });
  }

  void _setTemplate(ResumeTemplate next) {
    if (_template == next) {
      return;
    }
    setState(() {
      _template = next;
    });
  }

  void _setTheme(ResumeTheme next) {
    if (_theme == next) {
      return;
    }
    setState(() {
      _theme = next;
    });
  }

  void _enterWorkspace() {
    setState(() {
      _enteredWorkspace = true;
      _matchResult = _buildMatchResult();
      _adviceResult = _buildAdvice();
    });
  }

  void _backToEntry() {
    setState(() {
      _enteredWorkspace = false;
    });
  }

  void _runMatch() {
    setState(() {
      _matchResult = _buildMatchResult();
    });
  }

  void _runAdvice() {
    setState(() {
      _adviceResult = _buildAdvice();
    });
  }

  void _exportPdf() {
    final didTrigger = print_helper.triggerPrint();
    if (!didTrigger && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_copy.printUnavailable)));
    }
  }

  ScoreResult _buildScoreResult() {
    final draft = _draft;
    final tips = <String>[];
    var score = 0;

    if (draft[DraftField.name].isNotEmpty) {
      score += 8;
    } else {
      tips.add(
        _language == AppLanguage.zh ? '建议补充姓名。' : 'Add a candidate name.',
      );
    }

    if (draft[DraftField.title].length >= 8) {
      score += 10;
    } else {
      tips.add(
        _language == AppLanguage.zh
            ? '定位标题建议写清目标方向。'
            : 'Clarify the target direction in the title.',
      );
    }

    if (draft[DraftField.email].isNotEmpty &&
        draft[DraftField.phone].isNotEmpty) {
      score += 10;
    } else {
      tips.add(
        _language == AppLanguage.zh
            ? '联系方式需要完整，便于材料投递。'
            : 'Complete the contact information.',
      );
    }

    if (draft[DraftField.summary].length >= 60) {
      score += 18;
    } else {
      tips.add(
        _language == AppLanguage.zh
            ? '个人简介建议达到 60 字以上，并写出能力、经历和目标。'
            : 'Expand the summary with strengths, experience and goals.',
      );
    }

    if (draft[DraftField.school].isNotEmpty &&
        draft[DraftField.major].isNotEmpty) {
      score += 14;
    } else {
      tips.add(
        _language == AppLanguage.zh
            ? '教育背景需要包含学校和专业。'
            : 'Include school and major.',
      );
    }

    if (draft[DraftField.project].length >= 80) {
      score += 22;
    } else {
      tips.add(
        _language == AppLanguage.zh
            ? '项目经历建议补充背景、方法、角色和结果。'
            : 'Add project context, method, role and result.',
      );
    }

    final skills = splitKeywords(draft[DraftField.skills]);
    if (skills.length >= 6) {
      score += 12;
    } else {
      tips.add(
        _language == AppLanguage.zh
            ? '技能关键词建议不少于 6 个。'
            : 'Use at least six skill keywords.',
      );
    }

    if (draft[DraftField.awards].isNotEmpty) {
      score += 6;
    } else {
      tips.add(
        _language == AppLanguage.zh
            ? '可补充奖项、证书或课程成果作为佐证。'
            : 'Add awards or certificates as evidence.',
      );
    }

    final allText = draft.joinedText;
    if (RegExp(r'\d+|%|人|项|次|篇|个').hasMatch(allText)) {
      score += 8;
    } else {
      tips.add(
        _language == AppLanguage.zh
            ? '建议加入数字化结果，如模块数量、比例或项目规模。'
            : 'Add measurable results such as counts or percentages.',
      );
    }

    score = score.clamp(0, 100);

    final level = switch (_language) {
      AppLanguage.zh when score >= 85 => '优秀',
      AppLanguage.zh when score >= 70 => '良好',
      AppLanguage.zh when score >= 55 => '基本完整',
      AppLanguage.zh => '待完善',
      AppLanguage.en when score >= 85 => 'Strong',
      AppLanguage.en when score >= 70 => 'Good',
      AppLanguage.en when score >= 55 => 'Needs Proof',
      AppLanguage.en => 'Needs Work',
    };

    return ScoreResult(
      score: score,
      level: level,
      tips: tips.isEmpty
          ? <String>[_copy.scoreDefaultTip]
          : tips.take(5).toList(),
    );
  }

  MatchResult _buildMatchResult() {
    final draft = _draft;
    final target = _targetController.text.trim();
    final resumeText = draft.joinedText.toLowerCase();

    final extracted = {
      ...splitKeywords(target),
      ...extractLatinTokens(target),
      ...extractChineseTokens(target),
      ..._scenarioInfo.keywords,
    };

    final targetWords =
        extracted
            .where((word) => word.length >= 2)
            .where((word) => !englishStopWords.contains(word.toLowerCase()))
            .toList()
          ..sort();

    final matched = <String>[];
    final missing = <String>[];

    for (final word in targetWords) {
      if (resumeText.contains(word.toLowerCase())) {
        matched.add(word);
      } else {
        missing.add(word);
      }
    }

    final percent = targetWords.isEmpty
        ? 0
        : ((matched.length / targetWords.length) * 100).round();

    return MatchResult(
      percent: percent.clamp(0, 100),
      matched: matched.take(10).toList(),
      missing: missing.take(8).toList(),
    );
  }

  List<String> _buildAdvice() {
    final draft = _draft;
    final advice = <String>[];

    if (!RegExp(r'[。；;.]').hasMatch(draft[DraftField.project])) {
      advice.add(
        _language == AppLanguage.zh
            ? '项目经历可以拆成“背景-职责-方法-结果”四个短句。'
            : 'Split the project block into context, role, method and result.',
      );
    }

    if (!RegExp(r'\d+|%').hasMatch(draft[DraftField.project])) {
      advice.add(
        _language == AppLanguage.zh
            ? '项目成果建议加入数字，如模块数量、用户规模或效率提升。'
            : 'Add measurable numbers such as modules, scale or efficiency gain.',
      );
    }

    if (draft[DraftField.summary].length > 160) {
      advice.add(
        _language == AppLanguage.zh
            ? '个人简介略长，建议压缩到 80-120 字。'
            : 'The summary is long. Compress it to 80-120 words.',
      );
    } else {
      advice.add(
        _language == AppLanguage.zh
            ? '个人简介长度合适，可继续加入目标关键词。'
            : 'The summary length is fine. Add more target keywords.',
      );
    }

    advice.add(
      _language == AppLanguage.zh
          ? '当前场景为“${_scenarioInfo.title(_language)}”，建议优先突出：${_scenarioInfo.keywords.join('、')}。'
          : 'Current mode: ${_scenarioInfo.title(_language)}. Prioritize: ${_scenarioInfo.keywords.join(', ')}.',
    );

    return advice;
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette;
    final copy = _copy;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: _enteredWorkspace
              ? _buildWorkspace(palette, copy)
              : _buildEntryScreen(palette, copy),
        ),
      ),
    );
  }

  Widget _buildEntryScreen(WorkspacePalette palette, CopyDeck copy) {
    return Container(
      key: const ValueKey('entry'),
      decoration: BoxDecoration(gradient: palette.heroGradient),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(680, constraints.maxHeight - 48),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _buildEntryHero(copy, palette)),
                            const SizedBox(width: 40),
                            SizedBox(
                              width: 420,
                              child: _buildEntryPanel(copy, palette),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEntryHero(copy, palette),
                            const SizedBox(height: 28),
                            _buildEntryPanel(copy, palette),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEntryHero(CopyDeck copy, WorkspacePalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            copy.entryKicker,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          copy.appTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 46,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            copy.entryLead,
            style: TextStyle(
              color: const Color(0xFFCBD5E1).withValues(alpha: 0.94),
              fontSize: 16,
              height: 1.7,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _buildEntryPreviewMock(copy, palette),
      ],
    );
  }

  Widget _buildEntryPreviewMock(CopyDeck copy, WorkspacePalette palette) {
    final info = _scenarioInfo;
    final theme = themeMeta[_theme]!;
    final template = templateLibrary[_template]!;

    return Container(
      constraints: const BoxConstraints(maxWidth: 620),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 0.78,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x330F172A),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 12,
                        width: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 10,
                        width: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 18),
                      for (var i = 0; i < 4; i++) ...[
                        Container(
                          height: 11,
                          decoration: BoxDecoration(
                            color: i.isEven
                                ? const Color(0xFFDDE7F5)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const Spacer(),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List<Widget>.generate(
                          5,
                          (index) => Container(
                            width: 62,
                            height: 24,
                            decoration: BoxDecoration(
                              color: theme.soft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EntryMetaRow(
                  label: copy.entryScenarioHeading,
                  value: info.label(_language),
                ),
                const SizedBox(height: 10),
                EntryMetaRow(
                  label: copy.entryTemplateHeading,
                  value: template.label(_language),
                ),
                const SizedBox(height: 10),
                EntryMetaRow(
                  label: copy.entryThemeHeading,
                  value: theme.label(_language),
                ),
                const SizedBox(height: 10),
                EntryMetaRow(
                  label: copy.entryLanguageHeading,
                  value: _language == AppLanguage.zh ? '中文' : 'English',
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(info.icon, size: 18, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          info.title(_language),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryPanel(CopyDeck copy, WorkspacePalette palette) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEntrySectionTitle(copy.entryScenarioHeading),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ResumeScenario.values.map((scenario) {
              final info = scenarioLibrary[scenario]!;
              return SelectionButton(
                label: info.label(_language),
                icon: info.icon,
                selected: _scenario == scenario,
                onTap: () => _setScenario(scenario),
                activeColor: palette.primary,
                activeForeground: Colors.white,
                inactiveColor: Colors.white.withValues(alpha: 0.06),
                inactiveForeground: const Color(0xFFE2E8F0),
                borderColor: Colors.white.withValues(alpha: 0.10),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _buildEntrySectionTitle(copy.entryTemplateHeading),
          const SizedBox(height: 12),
          _buildDarkDropdown<ResumeTemplate>(
            label: copy.templateLabel,
            value: _template,
            items: ResumeTemplate.values.map((template) {
              return DropdownMenuItem(
                value: template,
                child: Text(templateLibrary[template]!.label(_language)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _setTemplate(value);
              }
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ResumeTheme.values.map((theme) {
              final meta = themeMeta[theme]!;
              return ThemeSwatchButton(
                label: meta.label(_language),
                swatch: meta.primary,
                selected: _theme == theme,
                onTap: () => _setTheme(theme),
                borderColor: Colors.white.withValues(alpha: 0.10),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _buildEntrySectionTitle(copy.entryLanguageHeading),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppLanguage.values.map((language) {
              return SelectionButton(
                label: language == AppLanguage.zh ? '中文' : 'English',
                icon: language == AppLanguage.zh
                    ? Icons.translate_rounded
                    : Icons.language_rounded,
                selected: _language == language,
                onTap: () => _setLanguage(language),
                activeColor: palette.primary,
                activeForeground: Colors.white,
                inactiveColor: Colors.white.withValues(alpha: 0.06),
                inactiveForeground: const Color(0xFFE2E8F0),
                borderColor: Colors.white.withValues(alpha: 0.10),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _enterWorkspace,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(copy.enterWorkspace),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntrySectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildWorkspace(WorkspacePalette palette, CopyDeck copy) {
    return LayoutBuilder(
      key: const ValueKey('workspace'),
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1220;

        if (desktop) {
          return Row(
            children: [
              SizedBox(width: 392, child: _buildControlPane(palette, copy)),
              Expanded(child: _buildPreviewPane(palette, copy)),
              SizedBox(width: 332, child: _buildAssistantPane(palette, copy)),
            ],
          );
        }

        final previewHeight = math.max(760.0, constraints.maxHeight * 0.95);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMobileTopBar(copy, palette),
              const SizedBox(height: 16),
              _buildControlPane(palette, copy, embedded: true),
              const SizedBox(height: 16),
              SizedBox(
                height: previewHeight,
                child: _buildPreviewPane(palette, copy, embedded: true),
              ),
              const SizedBox(height: 16),
              _buildAssistantPane(palette, copy, embedded: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileTopBar(CopyDeck copy, WorkspacePalette palette) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: _backToEntry,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.previewEyebrow,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _scenarioInfo.title(_language),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPane(
    WorkspacePalette palette,
    CopyDeck copy, {
    bool embedded = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: palette.nav,
        borderRadius: embedded ? BorderRadius.circular(8) : null,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!embedded) _buildBrandBlock(copy, palette),
            if (!embedded) const SizedBox(height: 18),
            _buildDemoNotice(copy, palette),
            const SizedBox(height: 16),
            PaneSection(
              badge: '01',
              title: copy.scenarioHeading,
              onDark: false,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ResumeScenario.values.map((scenario) {
                  final info = scenarioLibrary[scenario]!;
                  return SelectionButton(
                    label: info.label(_language),
                    icon: info.icon,
                    selected: _scenario == scenario,
                    onTap: () => _setScenario(scenario),
                    activeColor: palette.primary,
                    activeForeground: Colors.white,
                    inactiveColor: Colors.white,
                    inactiveForeground: const Color(0xFF0F172A),
                    borderColor: palette.border,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            PaneSection(
              badge: '02',
              title: copy.infoHeading,
              onDark: false,
              child: Column(
                children: [
                  for (final row in const [
                    [DraftField.name, DraftField.title],
                    [DraftField.email, DraftField.phone],
                    [DraftField.school, DraftField.major],
                  ]) ...[
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked = constraints.maxWidth < 280;
                        if (stacked) {
                          return Column(
                            children: row.map((field) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: field == row.last ? 0 : 12,
                                ),
                                child: _buildTextField(field, copy),
                              );
                            }).toList(),
                          );
                        }
                        return Row(
                          children: row.map((field) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: field == row.last ? 0 : 12,
                                ),
                                child: _buildTextField(field, copy),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildTextField(DraftField.summary, copy),
                  const SizedBox(height: 12),
                  _buildTextField(DraftField.project, copy),
                  const SizedBox(height: 12),
                  _buildTextField(DraftField.skills, copy),
                  const SizedBox(height: 12),
                  _buildTextField(DraftField.awards, copy),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandBlock(CopyDeck copy, WorkspacePalette palette) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            'CV',
            style: TextStyle(
              color: palette.nav,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.appTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                copy.workspaceSubtitle,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDemoNotice(CopyDeck copy, WorkspacePalette palette) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.demoBadge,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            copy.demoNote,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(DraftField field, CopyDeck copy) {
    final isLong = field == DraftField.summary || field == DraftField.project;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          copy.fieldLabels[field]!,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controllers[field],
          minLines: isLong ? 4 : 1,
          maxLines: isLong ? 6 : 1,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD8E0EA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _palette.primary, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewPane(
    WorkspacePalette palette,
    CopyDeck copy, {
    bool embedded = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: palette.stage,
        borderRadius: embedded ? BorderRadius.circular(8) : null,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              border: Border(bottom: BorderSide(color: palette.border)),
              borderRadius: embedded
                  ? const BorderRadius.vertical(top: Radius.circular(8))
                  : null,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wrap = constraints.maxWidth < 820;
                final leading = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy.previewEyebrow,
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _scenarioInfo.title(_language),
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                );

                final toolbar = Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 168,
                      child: _buildLightDropdown(
                        label: copy.templateLabel,
                        value: _template,
                        items: ResumeTemplate.values.map((template) {
                          return DropdownMenuItem(
                            value: template,
                            child: Text(
                              templateLibrary[template]!.label(_language),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _setTemplate(value);
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: _buildLightDropdown(
                        label: copy.themeLabel,
                        value: _theme,
                        items: ResumeTheme.values.map((theme) {
                          return DropdownMenuItem(
                            value: theme,
                            child: Text(themeMeta[theme]!.label(_language)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _setTheme(value);
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 132,
                      child: _buildLightDropdown(
                        label: copy.languageLabel,
                        value: _language,
                        items: AppLanguage.values.map((language) {
                          return DropdownMenuItem(
                            value: language,
                            child: Text(
                              language == AppLanguage.zh ? '中文' : 'English',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _setLanguage(value);
                          }
                        },
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _exportPdf,
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: Text(copy.exportPdf),
                    ),
                  ],
                );

                if (wrap) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (!embedded) ...[
                            IconButton.filledTonal(
                              onPressed: _backToEntry,
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(child: leading),
                        ],
                      ),
                      const SizedBox(height: 14),
                      toolbar,
                    ],
                  );
                }

                return Row(
                  children: [
                    if (!embedded) ...[
                      IconButton.filledTonal(
                        onPressed: _backToEntry,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(child: leading),
                    toolbar,
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final canvasWidth = math.min(constraints.maxWidth, 860.0);
                  return Center(
                    child: SizedBox(
                      width: canvasWidth,
                      child: AspectRatio(
                        aspectRatio: 794 / 1123,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x29101828),
                                blurRadius: 42,
                                offset: Offset(0, 18),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: FittedBox(
                              fit: BoxFit.contain,
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: 794,
                                height: 1123,
                                child: ResumePaper(
                                  draft: _draft,
                                  scenarioInfo: _scenarioInfo,
                                  language: _language,
                                  template: _template,
                                  palette: palette,
                                  copy: copy,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantPane(
    WorkspacePalette palette,
    CopyDeck copy, {
    bool embedded = false,
  }) {
    final score = _scoreResult;
    final match = _matchResult;
    final advice = _adviceResult;

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: embedded ? BorderRadius.circular(8) : null,
        border: embedded ? Border.all(color: palette.border) : null,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PaneSection(
              badge: '03',
              title: copy.localScoreHeading,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.localNote,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ScoreRing(
                      score: score.score,
                      label: score.level,
                      color: palette.primary,
                      trackColor: palette.primarySoft,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...score.tips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.check_circle_outline_rounded,
                              size: 16,
                              color: palette.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tip,
                              style: TextStyle(
                                color: const Color(0xFF334155),
                                fontSize: 13,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PaneSection(
              badge: '04',
              title: copy.localTargetHeading,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.targetLabel,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _targetController,
                    minLines: 5,
                    maxLines: 7,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: palette.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: palette.primary,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _runMatch,
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.travel_explore_rounded),
                      label: Text(copy.runMatch),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ResultPanel(
                    lines: match == null
                        ? [copy.waitingAnalysis]
                        : [
                            _language == AppLanguage.zh
                                ? '匹配度：${match.percent}/100'
                                : 'Match score: ${match.percent}/100',
                            _language == AppLanguage.zh
                                ? '已覆盖关键词：${match.matched.isEmpty ? "暂无明显覆盖" : match.matched.join("、")}'
                                : 'Covered terms: ${match.matched.isEmpty ? "No obvious coverage" : match.matched.join(", ")}',
                            _language == AppLanguage.zh
                                ? '建议补充关键词：${match.missing.isEmpty ? "暂无明显缺口" : match.missing.join("、")}'
                                : 'Missing terms: ${match.missing.isEmpty ? "No obvious gaps" : match.missing.join(", ")}',
                            _language == AppLanguage.zh
                                ? '说明：这是本地关键词匹配结果。'
                                : 'Note: this is a local keyword matcher.',
                          ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PaneSection(
              badge: '05',
              title: copy.localAdviceHeading,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _runAdvice,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.auto_fix_high_rounded),
                      label: Text(copy.generateAdvice),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ResultPanel(
                    lines: advice == null
                        ? [copy.waitingAnalysis]
                        : advice
                              .asMap()
                              .entries
                              .map(
                                (entry) => '${entry.key + 1}. ${entry.value}',
                              )
                              .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _palette.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          isDense: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _palette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _palette.primary, width: 1.2),
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDarkDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: const Color(0xFF1F2937),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFCBD5E1)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _palette.primary, width: 1.2),
        ),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      iconEnabledColor: Colors.white,
      items: items,
      onChanged: onChanged,
    );
  }
}

enum AppLanguage { zh, en }

enum ResumeScenario { job, postgraduate, recommendation, admission }

enum ResumeTemplate {
  modern,
  blue,
  sidebar,
  gray,
  classic,
  minimal,
  timeline,
  professional,
  compact,
}

enum ResumeTheme { aurora, forest, ember, violet }

enum DraftField {
  name,
  title,
  email,
  phone,
  school,
  major,
  summary,
  project,
  skills,
  awards,
}

class ResumeDraft {
  const ResumeDraft({required this.values});

  final Map<DraftField, String> values;

  String operator [](DraftField field) => values[field] ?? '';

  String get joinedText =>
      DraftField.values.map((field) => this[field]).join(' ');
}

class CopyDeck {
  const CopyDeck({
    required this.appTitle,
    required this.entryKicker,
    required this.entryLead,
    required this.entryScenarioHeading,
    required this.entryTemplateHeading,
    required this.entryThemeHeading,
    required this.entryLanguageHeading,
    required this.enterWorkspace,
    required this.workspaceSubtitle,
    required this.demoBadge,
    required this.demoNote,
    required this.scenarioHeading,
    required this.infoHeading,
    required this.previewEyebrow,
    required this.templateLabel,
    required this.themeLabel,
    required this.languageLabel,
    required this.exportPdf,
    required this.localScoreHeading,
    required this.localTargetHeading,
    required this.localAdviceHeading,
    required this.localNote,
    required this.targetLabel,
    required this.runMatch,
    required this.generateAdvice,
    required this.waitingAnalysis,
    required this.printUnavailable,
    required this.scoreDefaultTip,
    required this.fieldLabels,
    required this.resumeSections,
  });

  final String appTitle;
  final String entryKicker;
  final String entryLead;
  final String entryScenarioHeading;
  final String entryTemplateHeading;
  final String entryThemeHeading;
  final String entryLanguageHeading;
  final String enterWorkspace;
  final String workspaceSubtitle;
  final String demoBadge;
  final String demoNote;
  final String scenarioHeading;
  final String infoHeading;
  final String previewEyebrow;
  final String templateLabel;
  final String themeLabel;
  final String languageLabel;
  final String exportPdf;
  final String localScoreHeading;
  final String localTargetHeading;
  final String localAdviceHeading;
  final String localNote;
  final String targetLabel;
  final String runMatch;
  final String generateAdvice;
  final String waitingAnalysis;
  final String printUnavailable;
  final String scoreDefaultTip;
  final Map<DraftField, String> fieldLabels;
  final List<String> resumeSections;
}

class ScenarioInfo {
  const ScenarioInfo({
    required this.icon,
    required this.zhLabel,
    required this.enLabel,
    required this.zhTitle,
    required this.enTitle,
    required this.zhHint,
    required this.enHint,
    required this.keywords,
  });

  final IconData icon;
  final String zhLabel;
  final String enLabel;
  final String zhTitle;
  final String enTitle;
  final String zhHint;
  final String enHint;
  final List<String> keywords;

  String label(AppLanguage language) {
    return language == AppLanguage.zh ? zhLabel : enLabel;
  }

  String title(AppLanguage language) {
    return language == AppLanguage.zh ? zhTitle : enTitle;
  }

  String hint(AppLanguage language) {
    return language == AppLanguage.zh ? zhHint : enHint;
  }
}

class TemplateInfo {
  const TemplateInfo({required this.zhLabel, required this.enLabel});

  final String zhLabel;
  final String enLabel;

  String label(AppLanguage language) {
    return language == AppLanguage.zh ? zhLabel : enLabel;
  }
}

class ThemeMeta {
  const ThemeMeta({
    required this.primary,
    required this.soft,
    required this.zhLabel,
    required this.enLabel,
  });

  final Color primary;
  final Color soft;
  final String zhLabel;
  final String enLabel;

  String label(AppLanguage language) {
    return language == AppLanguage.zh ? zhLabel : enLabel;
  }
}

class WorkspacePalette {
  const WorkspacePalette({
    required this.background,
    required this.nav,
    required this.stage,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.muted,
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.heroGradient,
  });

  final Color background;
  final Color nav;
  final Color stage;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color muted;
  final Color primary;
  final Color primaryDark;
  final Color primarySoft;
  final Gradient heroGradient;

  static WorkspacePalette of(ResumeTheme theme) {
    switch (theme) {
      case ResumeTheme.aurora:
        return const WorkspacePalette(
          background: Color(0xFFF1F5F9),
          nav: Color(0xFF16202D),
          stage: Color(0xFFE6ECF3),
          surface: Color(0xFFFFFFFF),
          surfaceAlt: Color(0xFFF8FAFC),
          border: Color(0xFFD8E0EA),
          muted: Color(0xFF64748B),
          primary: Color(0xFF2563EB),
          primaryDark: Color(0xFF1D4ED8),
          primarySoft: Color(0xFFE8F0FF),
          heroGradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0B1220)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case ResumeTheme.forest:
        return const WorkspacePalette(
          background: Color(0xFFF1F5F2),
          nav: Color(0xFF112B28),
          stage: Color(0xFFE5F0EC),
          surface: Color(0xFFFFFFFF),
          surfaceAlt: Color(0xFFF7FBF9),
          border: Color(0xFFD2E2DB),
          muted: Color(0xFF5F746E),
          primary: Color(0xFF0F766E),
          primaryDark: Color(0xFF0B5D56),
          primarySoft: Color(0xFFE4F5F1),
          heroGradient: LinearGradient(
            colors: [Color(0xFF0B1F1D), Color(0xFF173B38), Color(0xFF112B28)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case ResumeTheme.ember:
        return const WorkspacePalette(
          background: Color(0xFFFFF7ED),
          nav: Color(0xFF24170C),
          stage: Color(0xFFF9EBDC),
          surface: Color(0xFFFFFFFF),
          surfaceAlt: Color(0xFFFFFBF5),
          border: Color(0xFFECD6BC),
          muted: Color(0xFF8C6A45),
          primary: Color(0xFFB7791F),
          primaryDark: Color(0xFF8A5B18),
          primarySoft: Color(0xFFFFF1D6),
          heroGradient: LinearGradient(
            colors: [Color(0xFF25160D), Color(0xFF583819), Color(0xFF8A5B18)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case ResumeTheme.violet:
        return const WorkspacePalette(
          background: Color(0xFFF5F3FF),
          nav: Color(0xFF241F35),
          stage: Color(0xFFECE9F7),
          surface: Color(0xFFFFFFFF),
          surfaceAlt: Color(0xFFF8F7FC),
          border: Color(0xFFDDD7EE),
          muted: Color(0xFF6E6690),
          primary: Color(0xFF66509A),
          primaryDark: Color(0xFF51407E),
          primarySoft: Color(0xFFEEE9FB),
          heroGradient: LinearGradient(
            colors: [Color(0xFF181424), Color(0xFF332B4C), Color(0xFF4A3D70)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
    }
  }
}

class ScoreResult {
  const ScoreResult({
    required this.score,
    required this.level,
    required this.tips,
  });

  final int score;
  final String level;
  final List<String> tips;
}

class MatchResult {
  const MatchResult({
    required this.percent,
    required this.matched,
    required this.missing,
  });

  final int percent;
  final List<String> matched;
  final List<String> missing;
}

class PaneSection extends StatelessWidget {
  const PaneSection({
    super.key,
    required this.badge,
    required this.title,
    required this.child,
    this.onDark = false,
  });

  final String badge;
  final String title;
  final Widget child;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8E0EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class SelectionButton extends StatelessWidget {
  const SelectionButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.activeColor,
    required this.activeForeground,
    required this.inactiveColor,
    required this.inactiveForeground,
    required this.borderColor,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;
  final Color activeForeground;
  final Color inactiveColor;
  final Color inactiveForeground;
  final Color borderColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? activeColor : borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? activeForeground : inactiveForeground,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? activeForeground : inactiveForeground,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThemeSwatchButton extends StatelessWidget {
  const ThemeSwatchButton({
    super.key,
    required this.label,
    required this.swatch,
    required this.selected,
    required this.onTap,
    required this.borderColor,
  });

  final String label;
  final Color swatch;
  final bool selected;
  final VoidCallback onTap;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: swatch,
              border: Border.all(
                color: selected ? Colors.white : borderColor,
                width: selected ? 3 : 1,
              ),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class EntryMetaRow extends StatelessWidget {
  const EntryMetaRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    required this.label,
    required this.color,
    required this.trackColor,
  });

  final int score;
  final String label;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 124,
          height: 124,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 124,
                height: 124,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 10,
                  backgroundColor: trackColor,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      color: color,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    '/100',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class ResultPanel extends StatelessWidget {
  const ResultPanel({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8E0EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 13,
                height: 1.65,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ResumePaper extends StatelessWidget {
  const ResumePaper({
    super.key,
    required this.draft,
    required this.scenarioInfo,
    required this.language,
    required this.template,
    required this.palette,
    required this.copy,
  });

  final ResumeDraft draft;
  final ScenarioInfo scenarioInfo;
  final AppLanguage language;
  final ResumeTemplate template;
  final WorkspacePalette palette;
  final CopyDeck copy;

  @override
  Widget build(BuildContext context) {
    final style = TemplateStyle.from(template, palette);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: style.borderColor),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: const Color(0xFF1F2937),
          fontSize: style.compact ? 13.5 : 14,
          height: 1.65,
          fontFamily: style.serif ? 'Times New Roman' : null,
        ),
        child: style.sidebar
            ? _buildSidebarPaper(style)
            : _buildStandardPaper(style),
      ),
    );
  }

  Widget _buildStandardPaper(TemplateStyle style) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        48,
        style.fullBleedHeader ? 0 : 44,
        48,
        style.compact ? 32 : 42,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (style.fullBleedHeader)
            _buildFilledHeader(style)
          else
            _buildSimpleHeader(style),
          SizedBox(height: style.compact ? 18 : 24),
          _buildSection(
            title: copy.resumeSections[0],
            style: style,
            child: Text(draft[DraftField.summary]),
          ),
          _buildSection(
            title: copy.resumeSections[1],
            style: style,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 14,
                      height: 1.65,
                    ),
                    children: [
                      TextSpan(
                        text: draft[DraftField.school],
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' · '),
                      TextSpan(text: draft[DraftField.major]),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  scenarioInfo.hint(language),
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: style.compact ? 12 : 13,
                  ),
                ),
              ],
            ),
          ),
          _buildSection(
            title: copy.resumeSections[2],
            style: style,
            child: Text(draft[DraftField.project]),
          ),
          _buildSection(
            title: copy.resumeSections[3],
            style: style,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: splitKeywords(draft[DraftField.skills]).map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: style.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(
                      color: style.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          _buildSection(
            title: copy.resumeSections[4],
            style: style,
            child: Text(draft[DraftField.awards]),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFilledHeader(TemplateStyle style) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: -48),
      padding: const EdgeInsets.fromLTRB(48, 42, 48, 26),
      color: style.headerBackground,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft[DraftField.name],
                  style: TextStyle(
                    color: style.headerForeground,
                    fontSize: template == ResumeTemplate.compact ? 28 : 36,
                    fontWeight: FontWeight.w800,
                    height: 1.04,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  draft[DraftField.title],
                  style: TextStyle(
                    color: style.headerForeground.withValues(alpha: 0.82),
                    fontSize: 16,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                draft[DraftField.email],
                style: TextStyle(
                  color: style.headerForeground.withValues(alpha: 0.82),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                draft[DraftField.phone],
                style: TextStyle(
                  color: style.headerForeground.withValues(alpha: 0.82),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleHeader(TemplateStyle style) {
    return Container(
      padding: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: style.accent, width: style.serif ? 2 : 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft[DraftField.name],
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontSize: style.compact ? 30 : 36,
                    fontWeight: FontWeight.w800,
                    height: 1.04,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  draft[DraftField.title],
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 16,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                draft[DraftField.email],
                style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                draft[DraftField.phone],
                style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarPaper(TemplateStyle style) {
    return Row(
      children: [
        Container(
          width: 238,
          color: style.headerBackground,
          padding: const EdgeInsets.fromLTRB(28, 42, 28, 42),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                draft[DraftField.name],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                draft[DraftField.title],
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              _buildSidebarBlock(
                title: language == AppLanguage.zh ? '联系方式' : 'Contact',
                lines: [draft[DraftField.email], draft[DraftField.phone]],
              ),
              const SizedBox(height: 18),
              _buildSidebarBlock(
                title: copy.resumeSections[3],
                lines: splitKeywords(draft[DraftField.skills]),
              ),
              const SizedBox(height: 18),
              _buildSidebarBlock(
                title: copy.resumeSections[4],
                lines: splitKeywords(draft[DraftField.awards]),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(38, 44, 40, 42),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  title: copy.resumeSections[0],
                  style: style,
                  child: Text(draft[DraftField.summary]),
                ),
                _buildSection(
                  title: copy.resumeSections[1],
                  style: style,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 14,
                            height: 1.65,
                          ),
                          children: [
                            TextSpan(
                              text: draft[DraftField.school],
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: ' · '),
                            TextSpan(text: draft[DraftField.major]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        scenarioInfo.hint(language),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSection(
                  title: copy.resumeSections[2],
                  style: style,
                  child: Text(draft[DraftField.project]),
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarBlock({
    required String title,
    required List<String> lines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...lines
            .where((line) => line.isNotEmpty)
            .map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  line,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required TemplateStyle style,
    required Widget child,
    bool isLast = false,
  }) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: style.accent,
            fontSize: style.compact ? 16 : 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );

    final sectionContent = style.timeline
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: style.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Container(width: 2, color: style.accentSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: body),
            ],
          )
        : body;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : (style.compact ? 18 : 26)),
      child: sectionContent,
    );
  }
}

class TemplateStyle {
  const TemplateStyle({
    required this.accent,
    required this.accentSoft,
    required this.borderColor,
    this.headerBackground = Colors.transparent,
    this.headerForeground = Colors.white,
    this.fullBleedHeader = false,
    this.sidebar = false,
    this.timeline = false,
    this.serif = false,
    this.compact = false,
  });

  final Color accent;
  final Color accentSoft;
  final Color borderColor;
  final Color headerBackground;
  final Color headerForeground;
  final bool fullBleedHeader;
  final bool sidebar;
  final bool timeline;
  final bool serif;
  final bool compact;

  static TemplateStyle from(ResumeTemplate template, WorkspacePalette palette) {
    switch (template) {
      case ResumeTemplate.modern:
        return TemplateStyle(
          accent: palette.primary,
          accentSoft: palette.primarySoft,
          borderColor: const Color(0xFFDDE5EF),
        );
      case ResumeTemplate.blue:
        return const TemplateStyle(
          accent: Color(0xFF132238),
          accentSoft: Color(0xFFFFF1CF),
          borderColor: Color(0xFFDDE5EF),
          headerBackground: Color(0xFF132238),
          headerForeground: Colors.white,
          fullBleedHeader: true,
        );
      case ResumeTemplate.sidebar:
        return const TemplateStyle(
          accent: Color(0xFF0F172A),
          accentSoft: Color(0xFFE7EEF8),
          borderColor: Color(0xFFDDE5EF),
          headerBackground: Color(0xFF16202D),
          headerForeground: Colors.white,
          sidebar: true,
        );
      case ResumeTemplate.gray:
        return const TemplateStyle(
          accent: Color(0xFF475569),
          accentSoft: Color(0xFFF1F5F9),
          borderColor: Color(0xFFD7DEE8),
        );
      case ResumeTemplate.classic:
        return const TemplateStyle(
          accent: Color(0xFF6B5F54),
          accentSoft: Color(0xFFF4EEE6),
          borderColor: Color(0xFF8B7D70),
          serif: true,
        );
      case ResumeTemplate.minimal:
        return const TemplateStyle(
          accent: Color(0xFF111827),
          accentSoft: Color(0xFFF3F4F6),
          borderColor: Color(0xFFD1D5DB),
        );
      case ResumeTemplate.timeline:
        return TemplateStyle(
          accent: palette.primary,
          accentSoft: palette.primarySoft,
          borderColor: const Color(0xFFDDE5EF),
          timeline: true,
        );
      case ResumeTemplate.professional:
        return const TemplateStyle(
          accent: Color(0xFF111827),
          accentSoft: Color(0xFFE5E7EB),
          borderColor: Color(0xFFDDE5EF),
          headerBackground: Color(0xFF111827),
          headerForeground: Colors.white,
          fullBleedHeader: true,
        );
      case ResumeTemplate.compact:
        return TemplateStyle(
          accent: palette.primary,
          accentSoft: palette.primarySoft,
          borderColor: const Color(0xFFDDE5EF),
          compact: true,
        );
    }
  }
}

const Map<AppLanguage, CopyDeck> copyDecks = {
  AppLanguage.zh: CopyDeck(
    appTitle: '简历生成与优化工作台',
    entryKicker: 'Flutter Web Studio',
    entryLead: '先选择材料场景、视觉模板、主题色和界面语言，再进入工作台。评分、匹配和建议都在本地完成，不依赖后端服务。',
    entryScenarioHeading: '材料场景',
    entryTemplateHeading: '模板与主题',
    entryThemeHeading: '主题',
    entryLanguageHeading: '语言',
    enterWorkspace: '进入工作台',
    workspaceSubtitle: 'Flutter Web · 本地规则建议',
    demoBadge: '演示数据',
    demoNote: '当前示例不使用真实个人信息，评分与关键词匹配都只在浏览器本地完成。',
    scenarioHeading: '选择材料场景',
    infoHeading: '填写核心信息',
    previewEyebrow: '实时预览',
    templateLabel: '模板',
    themeLabel: '主题',
    languageLabel: '语言',
    exportPdf: '导出 PDF',
    localScoreHeading: '本地规则评分',
    localTargetHeading: '本地目标匹配',
    localAdviceHeading: '本地优化建议',
    localNote: '所有评分与匹配均在浏览器本地完成。',
    targetLabel: '粘贴岗位 JD / 院校要求',
    runMatch: '运行本地匹配',
    generateAdvice: '生成优化建议',
    waitingAnalysis: '等待分析结果',
    printUnavailable: '当前平台不支持直接调用浏览器打印。',
    scoreDefaultTip: '材料结构完整，可继续根据目标补充关键词和量化成果。',
    fieldLabels: {
      DraftField.name: '姓名',
      DraftField.title: '定位',
      DraftField.email: '邮箱',
      DraftField.phone: '电话',
      DraftField.school: '学校',
      DraftField.major: '专业',
      DraftField.summary: '个人简介',
      DraftField.project: '项目经历',
      DraftField.skills: '技能关键词',
      DraftField.awards: '奖项证书',
    },
    resumeSections: ['个人简介', '教育背景', '项目经历', '技能关键词', '奖项证书'],
  ),
  AppLanguage.en: CopyDeck(
    appTitle: 'Resume Builder Workspace',
    entryKicker: 'Flutter Web Studio',
    entryLead:
        'Choose a scenario, template, theme color and interface language before entering the workspace. Scoring, matching and advice stay local with no backend dependency.',
    entryScenarioHeading: 'Scenario',
    entryTemplateHeading: 'Template & Theme',
    entryThemeHeading: 'Theme',
    entryLanguageHeading: 'Language',
    enterWorkspace: 'Enter Workspace',
    workspaceSubtitle: 'Flutter Web · local rule advice',
    demoBadge: 'Demo Data',
    demoNote:
        'The sample page uses neutral demo content. Scores and keyword matching run only in the browser.',
    scenarioHeading: 'Choose Scenario',
    infoHeading: 'Core Information',
    previewEyebrow: 'Live Preview',
    templateLabel: 'Template',
    themeLabel: 'Theme',
    languageLabel: 'Language',
    exportPdf: 'Export PDF',
    localScoreHeading: 'Local Rule Score',
    localTargetHeading: 'Local Target Match',
    localAdviceHeading: 'Local Advice',
    localNote: 'Scores and matching run locally in the browser.',
    targetLabel: 'Paste job JD / program requirements',
    runMatch: 'Run Local Match',
    generateAdvice: 'Generate Advice',
    waitingAnalysis: 'Waiting for analysis',
    printUnavailable: 'Direct browser print is not available on this platform.',
    scoreDefaultTip:
        'Structure is complete. Add more measurable outcomes and target keywords.',
    fieldLabels: {
      DraftField.name: 'Name',
      DraftField.title: 'Target',
      DraftField.email: 'Email',
      DraftField.phone: 'Phone',
      DraftField.school: 'School',
      DraftField.major: 'Major',
      DraftField.summary: 'Summary',
      DraftField.project: 'Project Experience',
      DraftField.skills: 'Skill Keywords',
      DraftField.awards: 'Awards',
    },
    resumeSections: [
      'Summary',
      'Education',
      'Project Experience',
      'Skill Keywords',
      'Awards',
    ],
  ),
};

const Map<ResumeScenario, ScenarioInfo> scenarioLibrary = {
  ResumeScenario.job: ScenarioInfo(
    icon: Icons.work_outline_rounded,
    zhLabel: '求职',
    enLabel: 'Job',
    zhTitle: '岗位投递版',
    enTitle: 'Job Application',
    zhHint: '重点呈现岗位相关课程、项目实践和可验证技能。',
    enHint:
        'Highlight position-related skills, projects and measurable outcomes.',
    keywords: ['HTML', 'CSS', 'JavaScript', '项目', '实习', '协作', '文档'],
  ),
  ResumeScenario.postgraduate: ScenarioInfo(
    icon: Icons.school_outlined,
    zhLabel: '考研',
    enLabel: 'Interview',
    zhTitle: '考研复试版',
    enTitle: 'Postgraduate Interview',
    zhHint: '重点呈现专业基础、核心课程、项目经历和复试表达能力。',
    enHint: 'Show coursework, research readiness and academic communication.',
    keywords: ['课程', '专业', '复试', '英语', '科研', '项目', '成绩'],
  ),
  ResumeScenario.recommendation: ScenarioInfo(
    icon: Icons.workspace_premium_outlined,
    zhLabel: '保研',
    enLabel: 'Recommendation',
    zhTitle: '保研申请版',
    enTitle: 'Recommendation Track',
    zhHint: '重点呈现排名、科研潜力、竞赛获奖和导师方向匹配。',
    enHint: 'Show rank, research potential, awards and advisor fit.',
    keywords: ['排名', '科研', '竞赛', '论文', '项目', '英语', '导师'],
  ),
  ResumeScenario.admission: ScenarioInfo(
    icon: Icons.menu_book_outlined,
    zhLabel: '升学',
    enLabel: 'Admission',
    zhTitle: '升学申请版',
    enTitle: 'Admission Portfolio',
    zhHint: '重点呈现学术经历、语言能力、项目作品和申请项目契合度。',
    enHint: 'Show academic work, language skills, projects and program fit.',
    keywords: ['GPA', '语言', '项目', '作品', '申请', '研究', '经历'],
  ),
};

const Map<ResumeTemplate, TemplateInfo> templateLibrary = {
  ResumeTemplate.modern: TemplateInfo(zhLabel: '现代通用', enLabel: 'General'),
  ResumeTemplate.blue: TemplateInfo(zhLabel: '蓝金正式', enLabel: 'Blue-Gold'),
  ResumeTemplate.sidebar: TemplateInfo(zhLabel: '侧栏信息', enLabel: 'Sidebar'),
  ResumeTemplate.gray: TemplateInfo(zhLabel: '蓝灰团队', enLabel: 'Blue-Gray'),
  ResumeTemplate.classic: TemplateInfo(zhLabel: '经典单栏', enLabel: 'Classic'),
  ResumeTemplate.minimal: TemplateInfo(zhLabel: '极简投递', enLabel: 'Minimal'),
  ResumeTemplate.timeline: TemplateInfo(zhLabel: '时间线项目', enLabel: 'Timeline'),
  ResumeTemplate.professional: TemplateInfo(
    zhLabel: '专业沉稳',
    enLabel: 'Professional',
  ),
  ResumeTemplate.compact: TemplateInfo(zhLabel: '紧凑信息', enLabel: 'Compact'),
};

const Map<ResumeTheme, ThemeMeta> themeMeta = {
  ResumeTheme.aurora: ThemeMeta(
    primary: Color(0xFF2563EB),
    soft: Color(0xFFE8F0FF),
    zhLabel: '极光蓝',
    enLabel: 'Aurora Blue',
  ),
  ResumeTheme.forest: ThemeMeta(
    primary: Color(0xFF0F766E),
    soft: Color(0xFFE4F5F1),
    zhLabel: '森林绿',
    enLabel: 'Forest Green',
  ),
  ResumeTheme.ember: ThemeMeta(
    primary: Color(0xFFB7791F),
    soft: Color(0xFFFFF1D6),
    zhLabel: '琥珀橙',
    enLabel: 'Amber',
  ),
  ResumeTheme.violet: ThemeMeta(
    primary: Color(0xFF66509A),
    soft: Color(0xFFEEE9FB),
    zhLabel: '学院紫',
    enLabel: 'Academic Purple',
  ),
};

const Map<AppLanguage, Map<DraftField, String>> sampleDrafts = {
  AppLanguage.zh: {
    DraftField.name: '示例学生',
    DraftField.title: '计算机方向申请者 / Web 项目实践者',
    DraftField.email: 'demo@example.com',
    DraftField.phone: '000-0000-0000',
    DraftField.school: '示例大学',
    DraftField.major: '计算机类专业',
    DraftField.summary:
        '具备 Web 前端、静态网站构建和项目文档整理基础，能够完成从需求分析、界面设计、交互实现到运行验证的完整实践流程。关注材料结构化表达、用户体验、隐私保护和可复现交付。',
    DraftField.project:
        'Jekyll 简历生成与优化工作台：基于静态网站技术重新实现简历生成器，完成场景选择、信息编辑、实时预览、模板切换、本地材料评分和目标匹配等模块，实现无需后端即可运行和部署的课程项目版本。',
    DraftField.skills: 'HTML, CSS, JavaScript, Jekyll, Git, 信息架构, 交互设计, 文档写作',
    DraftField.awards: '创新实验课程项目实践、Web 开发综合训练',
  },
  AppLanguage.en: {
    DraftField.name: 'Demo Student',
    DraftField.title: 'Computer Science Applicant / Web Project Builder',
    DraftField.email: 'demo@example.com',
    DraftField.phone: '000-0000-0000',
    DraftField.school: 'Demo University',
    DraftField.major: 'Computer Science',
    DraftField.summary:
        'Experienced in web front-end development, static site construction and project documentation. Able to complete requirement analysis, interface design, interaction implementation and reproducible delivery.',
    DraftField.project:
        'Jekyll Resume Builder Workspace: rebuilt a resume generator as a static website, including scenario selection, information editing, live preview, template switching, local scoring and target matching without a backend service.',
    DraftField.skills:
        'HTML, CSS, JavaScript, Jekyll, Git, Information Architecture, Interaction Design, Documentation',
    DraftField.awards:
        'Innovation experiment course project, Web development training',
  },
};

const Map<AppLanguage, String> sampleTargets = {
  AppLanguage.zh:
      '前端开发实习生，要求熟悉 HTML、CSS、JavaScript，了解 Vue 或静态网站开发，有项目实践、文档能力和良好的沟通协作能力。',
  AppLanguage.en:
      'Front-end intern role requiring HTML, CSS, JavaScript, Vue or static site experience, project practice, documentation ability and clear collaboration.',
};

const Set<String> englishStopWords = {
  'the',
  'and',
  'for',
  'with',
  'role',
  'good',
  'have',
  'has',
  'that',
  'this',
  'from',
  'into',
  'such',
  'their',
  'about',
  'clear',
  'ability',
  'required',
  'requiring',
  'would',
  'should',
  'could',
  'there',
  'been',
  'being',
  'your',
  'you',
};

List<String> splitKeywords(String value) {
  return value
      .split(RegExp(r'[,，、/\s;；]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

List<String> extractLatinTokens(String value) {
  return RegExp(
    r'[A-Za-z][A-Za-z0-9+.#-]{1,}',
  ).allMatches(value).map((match) => match.group(0)!).toList();
}

List<String> extractChineseTokens(String value) {
  return RegExp(
    r'[\u4E00-\u9FFF]{2,4}',
  ).allMatches(value).map((match) => match.group(0)!).toList();
}
