import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:highlight/languages/ocaml.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:window_size/window_size.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? true;

    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);

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
      home: ProjectStatusPage(
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class ProjectStatusPage extends StatefulWidget {
  final ThemeMode themeMode;
  final void Function(bool isDark) onToggleTheme;

  const ProjectStatusPage({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ProjectStatusPageState createState() => _ProjectStatusPageState();
}

class _ProjectStatusPageState extends State<ProjectStatusPage> {
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
          TextButton.icon(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DocsPage()),
                ),
            icon: const Icon(Icons.book_rounded, color: Colors.white),
            label: const Text('Docs', style: TextStyle(color: Colors.white)),
          ),
          TextButton.icon(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlayGroundPage()),
                ),
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            label: const Text(
              'Playground',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton.icon(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InstallerPage()),
                ),
            icon: const Icon(
              Icons.install_desktop_rounded,
              color: Colors.white,
            ),
            label: const Text(
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
          ).fetchAllCommits(perPage: 5),
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
  final ValueChanged<bool> onToggleTheme;

  const SettingsPage({
    required this.isDark,
    required this.onToggleTheme,
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<String> _appVersion;
  String _selectedLanguage = 'English';

  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];

  @override
  void initState() {
    super.initState();
    _appVersion = _loadAppVersion();
  }

  Future<String> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 4,
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              value: widget.isDark,
              onChanged: widget.onToggleTheme,
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 4,
            child: FutureBuilder<String>(
              future: _appVersion,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    leading: Icon(Icons.info),
                    title: Text('App Version'),
                    subtitle: Text('Loading...'),
                  );
                } else if (snapshot.hasError) {
                  return ListTile(
                    leading: const Icon(Icons.error),
                    title: const Text('App Version'),
                    subtitle: Text('Error: ${snapshot.error}'),
                  );
                }

                return ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('App Version'),
                  subtitle: Text(snapshot.data ?? 'Unknown'),
                );
              },
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: Text(_selectedLanguage),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () {
                _showLanguageDialog();
              },
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationSettingsPage(),
                  ),
                );
              },
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Customization'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to customization settings
              },
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutPage()),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Terms & Conditions'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to Terms & Conditions page
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_languages[index]),
                  onTap: () {
                    setState(() {
                      _selectedLanguage = _languages[index];
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Vex Control',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'A Flutter-based setup application for the Vex Project, providing an intuitive interface for configuration, documentation, and installation.',
            ),
            SizedBox(height: 16),
            Text('Version: 0.1.0'),
            SizedBox(height: 16),
            Text('Developer: Codezz-ops'),
          ],
        ),
      ),
    );
  }
}

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NotificationSettingsPageState createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        centerTitle: true,
        elevation: 1,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _saveNotificationPreference(value);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'Notifications enabled' : 'Notifications disabled',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            secondary: const Icon(Icons.notifications_active),
          ),
        ],
      ),
    );
  }
}

class InstallerPage extends StatefulWidget {
  const InstallerPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _InstallerPageState createState() => _InstallerPageState();
}

class _InstallerPageState extends State<InstallerPage> {
  bool _isInstalling = false;
  String _statusMessage = 'Ready to install the latest version of Vex.';

  final Map<String, bool> _expandedSections = {
    'Vex': true,
    'LSP': false,
    'Misc': false,
  };

  Future<void> _startInstallation() async {
    setState(() {
      _isInstalling = true;
      _statusMessage = 'Downloading...';
    });

    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _statusMessage = 'Installing...';
    });

    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _isInstalling = false;
      _statusMessage = 'Installation complete!';
    });
  }

  Widget _buildSection(String title, Map<String, String> data) {
    final isExpanded = _expandedSections[title] ?? false;
    final color =
        Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap:
                () => setState(() {
                  _expandedSections[title] = !isExpanded;
                }),
            child: Text(
              '${isExpanded ? '[-]' : '[+]'} $title',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 2, top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    data.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${entry.key.padRight(25)}: ${entry.value}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: color,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black;

    final vexVersions = {
      'Installed Version': 'v1.2.0',
      'Available Version': 'v1.4.1',
      'Nightly Version': 'v1.5.0-dev',
      'Last Checked': '2025-05-04',
    };

    final lspVersions = {
      'Installed Version': 'v3.17.0',
      'Available Version': 'v3.17.4',
      'Protocol': 'LSP 3.17',
      'Implementation': 'vex-lsp v0.6.1',
    };

    final miscVersions = {
      'Syntax Highlighting': 'v0.9.2',
      'Formatter': 'v1.0.5',
      'Completion Engine': 'v0.4.3',
      'Themes Installed': 'Monokai, Dracula',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vex Installer'),
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: DefaultTextStyle(
          style: TextStyle(fontFamily: 'monospace', fontSize: 14, color: color),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _statusMessage,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              _buildSection('Vex', vexVersions),
              _buildSection('LSP', lspVersions),
              _buildSection('Misc', miscVersions),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: _isInstalling ? null : _startInstallation,
                  style: TextButton.styleFrom(
                    foregroundColor:
                        _isInstalling ? Colors.grey : Colors.indigo,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    _isInstalling ? 'Installing...' : 'Install',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              if (_isInstalling)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
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
      appBar: AppBar(
        title: const Text('Syntax of Vex'),
        centerTitle: true,
        elevation: 1,
      ),
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

class PlayGroundPage extends StatefulWidget {
  const PlayGroundPage({super.key});

  @override
  State<PlayGroundPage> createState() => _PlayGroundPageState();
}

class _PlayGroundPageState extends State<PlayGroundPage> {
  late CodeController _codeController;
  String _output = '';

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: ocaml,
      patternMap: {
        r'\b(fn|val|if|else|match)\b': const TextStyle(color: Colors.purple),
      },
    );
  }

  void _runCode() {
    setState(() {
      _output = 'Output:\n${_codeController.text}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputColor =
        isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF5F5F5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vex Playground'),
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Write your Vex code here:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              height: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: inputColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CodeField(
                controller: _codeController,
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _runCode,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run Code'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Output:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: inputColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _output,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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

  GitHubService({
    required this.owner,
    required this.repo,
    this.branch = 'master',
  });

  Future<List<dynamic>> fetchAllCommits({int perPage = 30}) async {
    final url =
        'https://api.github.com/repos/$owner/$repo/commits?sha=$branch&per_page=$perPage';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load commits');
    }
  }

  Future<Map<String, dynamic>> fetchCommitDetails(String sha) async {
    final url = 'https://api.github.com/repos/$owner/$repo/commits/$sha';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load commit details');
    }
  }

  Future<List<dynamic>> fetchWorkflowRuns({int perPage = 10}) async {
    final url =
        'https://api.github.com/repos/$owner/$repo/actions/runs?branch=$branch&per_page=$perPage';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['workflow_runs'] ?? [];
    } else {
      throw Exception('Failed to load workflow runs');
    }
  }
}
