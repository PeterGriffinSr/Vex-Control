import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_size/window_size.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('Vxctl');
    setWindowMaxSize(const Size(1280, 800));
  }
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vex Control',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF5E2BFF),
          secondary: Color(0xFFFDECEF),
          surface: Color(0xFFFDECEF),
          onPrimary: Colors.white,
          onSecondary: Colors.black87,
          onSurface: Colors.black87,
        ),
        scaffoldBackgroundColor: Color(0xFFFFFFFF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF5E2BFF),
          foregroundColor: Colors.white,
          elevation: 0.5,
        ),
        cardColor: Color(0xFFFDECEF),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF5E2BFF),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF5E2BFF),
          secondary: Color(0xFFFDECEF),
          surface: Color(0xFF121212),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white70,
        ),
        scaffoldBackgroundColor: Color(0xFF050505),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0.5,
        ),
        cardColor: Color(0xFF1A1A1A),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF5E2BFF),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      home: InstallerHomePage(
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class InstallerHomePage extends StatefulWidget {
  final ThemeMode themeMode;
  final void Function(bool isDark) onToggleTheme;

  const InstallerHomePage({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  // ignore: library_private_types_in_public_api
  _InstallerHomePageState createState() => _InstallerHomePageState();
}

class _InstallerHomePageState extends State<InstallerHomePage> {
  String? _expandedCommitSha;
  final Map<String, String> _commitDiffs = {};

  void _toggleChanges(String sha) async {
    if (_expandedCommitSha == sha) {
      setState(() {
        _expandedCommitSha = null;
      });
    } else {
      if (!_commitDiffs.containsKey(sha)) {
        final commitDetails = await GitHubService(
          owner: 'PeterGriffinSr',
          repo: 'Vex-Haskell',
        ).fetchCommitDetails(sha);

        final commitChanges = commitDetails['files']
            .map((file) => '${file['filename']}\n${file['patch'] ?? ''}')
            .join('\n\n');

        setState(() {
          _commitDiffs[sha] = commitChanges;
        });
      }

      setState(() {
        _expandedCommitSha = sha;
      });
    }
  }

  TextSpan _highlightDiff(String diff) {
    final lines = diff.split('\n');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextSpan(
      children:
          lines.map((line) {
            Color color;

            if (line.startsWith('+')) {
              color = isDark ? Colors.greenAccent : Colors.green[800]!;
            } else if (line.startsWith('-')) {
              color = isDark ? Colors.redAccent : Colors.red[800]!;
            } else if (line.startsWith('@@')) {
              color = isDark ? Colors.yellowAccent : Colors.amber[800]!;
            } else {
              color =
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
            }

            return TextSpan(text: '$line\n', style: TextStyle(color: color));
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDark ? 'assets/vex_light.png' : 'assets/vex_dark.png';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(logoAsset, height: 32),
            const SizedBox(width: 10),
            const Text('Vex Control'),
          ],
        ),
        actions: [
          TextButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DocsPage()),
                ),
            child: const Text('Docs', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GettingStartedPage()),
                ),
            child: const Text(
              'Getting Started',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed:
                () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => InstallerHomePage(
                          themeMode: widget.themeMode,
                          onToggleTheme: widget.onToggleTheme,
                        ),
                  ),
                ),
            child: const Text(
              'Installer',
              style: TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => SettingsPage(
                          isDark: widget.themeMode == ThemeMode.dark,
                          onToggleTheme: widget.onToggleTheme,
                        ),
                  ),
                ),
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([
          GitHubService(
            owner: 'PeterGriffinSr',
            repo: 'Vex-Haskell',
          ).fetchAllCommits(perPage: 10),
          GitHubService(
            owner: 'PeterGriffinSr',
            repo: 'Vex-Haskell',
          ).fetchWorkflowRuns(perPage: 5),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final commits = snapshot.data![0];
          final workflows = snapshot.data![1];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Text(
                        'Recent Commits',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      ...commits.map((commit) {
                        final shaFull = commit['sha'];
                        final sha = shaFull.substring(0, 7);
                        final message = commit['commit']['message'];
                        final author = commit['commit']['author']['name'];
                        final date = DateTime.parse(
                          commit['commit']['author']['date'],
                        );

                        return Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.commit),
                                title: Text(
                                  message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  'by $author • $sha • ${date.toLocal()}',
                                ),
                                onTap: () => _toggleChanges(shaFull),
                              ),
                              if (_expandedCommitSha == shaFull &&
                                  _commitDiffs.containsKey(shaFull))
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  color:
                                      isDark
                                          ? Colors.grey[900]
                                          : Colors.grey[100],
                                  child: SelectableText.rich(
                                    _highlightDiff(_commitDiffs[shaFull]!),
                                    style: const TextStyle(
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Workflows',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      ...workflows.map((workflow) {
                        final status =
                            workflow['conclusion'] ?? workflow['status'];
                        final createdAt = DateTime.parse(
                          workflow['created_at'],
                        );
                        final url = workflow['html_url'];

                        final statusColor =
                            {
                              'success': Colors.green,
                              'failure': Colors.red,
                              'in_progress': Colors.orange,
                              'queued': Colors.blue,
                            }[status] ??
                            Colors.grey;

                        final statusIcon =
                            {
                              'success': Icons.check_circle,
                              'failure': Icons.cancel,
                              'in_progress': Icons.hourglass_top,
                              'queued': Icons.schedule,
                            }[status] ??
                            Icons.help;

                        return Card(
                          child: ListTile(
                            leading: Icon(statusIcon, color: statusColor),
                            title: Text(
                              'Workflow: ${status.toString().toUpperCase()}',
                            ),
                            subtitle: Text('Created at ${createdAt.toLocal()}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.open_in_new),
                              onPressed: () => launchUrl(Uri.parse(url)),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      Text(
                        'Recent Versions',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),

                      Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.new_releases,
                            color: Colors.blue,
                          ),
                          title: const Text('v0.3.2-beta'),
                          subtitle: const Text('Released on April 28, 2025'),
                          trailing: IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () {
                              launchUrl(
                                Uri.parse(
                                  'https://github.com/PeterGriffinSr/Vex-Haskell/releases/download/v0.3.2-beta/vex-v0.3.2-beta.tar.xz',
                                ),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                          ),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.new_releases,
                            color: Colors.blue,
                          ),
                          title: const Text('v0.3.1-alpha'),
                          subtitle: const Text('Released on March 15, 2025'),
                          trailing: IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () {
                              launchUrl(
                                Uri.parse(
                                  'https://github.com/PeterGriffinSr/Vex-Haskell/releases/download/v0.3.1-alpha/vex-v0.3.1-alpha.tar.xz',
                                ),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final bool isDark;
  final void Function(bool) onToggleTheme;

  const SettingsPage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  void _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tokenController.text = prefs.getString('github_token') ?? '';
    });
  }

  void _saveToken() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('github_token', _tokenController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: widget.isDark,
            onChanged: widget.onToggleTheme,
          ),
          ListTile(
            title: const Text('GitHub Token'),
            subtitle: TextField(
              controller: _tokenController,
              decoration: const InputDecoration(hintText: 'Enter GitHub Token'),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveToken,
            ),
          ),
        ],
      ),
    );
  }
}

class DocsPage extends StatefulWidget {
  const DocsPage({super.key});

  @override
  State<DocsPage> createState() => _DocsPage();
}

class _DocsPage extends State<DocsPage> {
  late Future<String> _markdownData;

  @override
  void initState() {
    super.initState();
    _markdownData = rootBundle.loadString('assets/docs/syntax.md');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Syntax of Vex')),
      body: FutureBuilder<String>(
        future: _markdownData,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Markdown(
            data: snapshot.data!,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromTheme(
              Theme.of(context),
            ).copyWith(
              h1: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
              h2: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
              h3: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
              p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
              code: const TextStyle(fontFamily: 'monospace'),
              codeblockDecoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              blockSpacing: 24,
            ),
            builders: {'code': CodeElementBuilder(isDark)},
          );
        },
      ),
    );
  }
}

class GettingStartedPage extends StatefulWidget {
  const GettingStartedPage({super.key});

  @override
  State<GettingStartedPage> createState() => _GettingStartedPageState();
}

class _GettingStartedPageState extends State<GettingStartedPage> {
  late Future<String> _markdownData;

  @override
  void initState() {
    super.initState();
    _markdownData = rootBundle.loadString('assets/docs/getting_started.md');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Getting Started with Vex')),
      body: FutureBuilder<String>(
        future: _markdownData,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Markdown(
            data: snapshot.data!,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromTheme(
              Theme.of(context),
            ).copyWith(
              h1: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
              h2: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
              h3: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
              p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
              code: const TextStyle(fontFamily: 'monospace'),
              codeblockDecoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              blockSpacing: 24,
            ),
            builders: {'code': CodeElementBuilder(isDark)},
          );
        },
      ),
    );
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  final bool isDark;
  CodeElementBuilder(this.isDark);

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final code = element.textContent;
    final language = element.attributes['class']?.split('-').last;
    return Builder(
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: HighlightView(
            code,
            language: language ?? 'bash',
            theme: isDark ? monokaiSublimeTheme : githubTheme,
            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          ),
        );
      },
    );
  }
}

class GitHubService {
  final String owner;
  final String repo;
  final String branch;
  final String? token;

  GitHubService({
    required this.owner,
    required this.repo,
    this.branch = 'master',
    this.token = 'ADD TOKEN',
  });

  Future<List<dynamic>> fetchAllCommits({int perPage = 30}) async {
    final url =
        'https://api.github.com/repos/$owner/$repo/commits?sha=$branch&per_page=$perPage';
    final Map<String, String> headers =
        token != null ? {'Authorization': 'token $token'} : {};
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load commits');
    }
  }

  Future<Map<String, dynamic>> fetchCommitDetails(String sha) async {
    final url = 'https://api.github.com/repos/$owner/$repo/commits/$sha';
    final Map<String, String> headers =
        token != null ? {'Authorization': 'token $token'} : {};
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load commit details');
    }
  }

  Future<List<dynamic>> fetchWorkflowRuns({int perPage = 10}) async {
    final url =
        'https://api.github.com/repos/$owner/$repo/actions/runs?branch=$branch&per_page=$perPage';
    final Map<String, String> headers =
        token != null ? {'Authorization': 'token $token'} : {};
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['workflow_runs'] ?? [];
    } else {
      throw Exception('Failed to load workflow runs');
    }
  }
}
