import 'package:fasthub/screens/important_info_upload_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_cubit.dart';
import '../theme/theme.dart';
import 'editor_screen.dart';
import 'package:fasthub/screens/camarade_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'package:fasthub/screens/document_upload_screen.dart';
import 'package:fasthub/screens/document_list_page.dart';
import 'package:fasthub/bloc/important_info_cubit.dart';
import 'package:fasthub/models/important_info_model.dart';
import 'package:fasthub/bloc/publication_cubit.dart';
import 'package:fasthub/models/publication_model.dart';
import 'package:fasthub/screens/publication_upload_screen.dart';
import 'package:fasthub/screens/info_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fasthub/screens/exam_results_screen.dart';
import 'package:fasthub/screens/fasthub_ai_chat.dart';
import 'package:fasthub/screens/important_info_list_screen.dart';
import 'package:fasthub/screens/publication_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    context.read<ImportantInfoCubit>().loadImportantInfo();
    context.read<PublicationCubit>().loadRecentPublications();
  }

  Widget _buildProfileLeadingWidget(BuildContext context, AppAuthState authState) {
    if (authState is Authenticated) {
      final userEmail = authState.user.email ?? 'Utilisateur';
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          },
          child: CircleAvatar(
            backgroundColor: FastHubTheme.accentColor,
            child: Text(
              userEmail.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.person, color: Colors.white, size: 28),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
        },
      );
    }
  }

  Widget _buildDrawerButton() {
    return IconButton(
      icon: const Icon(Icons.menu, color: Colors.white, size: 28),
      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
    );
  }

  Widget _buildDrawer(AppAuthState authState) {
    return Drawer(
      backgroundColor: FastHubTheme.surfaceColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              gradient: FastHubTheme.primaryGradient,
              image: (authState is Authenticated && authState.profile?.avatarUrl != null)
                  ? DecorationImage(
                      image: NetworkImage(authState.profile!.avatarUrl!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
                    )
                  : null,
            ),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    (authState is Authenticated && authState.user.email != null)
                        ? 'Bienvenue, ${authState.user.email!.split('@')[0]}'
                        : 'Bienvenue',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (authState is Authenticated && authState.profile != null)
                    Text(
                      'Filière: ${authState.profile!.filiere ?? 'N/A'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text('Profil', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.group, color: Colors.white),
            title: const Text('Camarades', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CamaradeScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: const Text('Paramètres', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen()));
            },
          ),
          if (authState is Authenticated)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                context.read<AuthCubit>().signOut();
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AppAuthState>(
      builder: (context, authState) {
        return Scaffold(
          key: _scaffoldKey,
          drawer: _buildDrawer(authState),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: FastHubTheme.surfaceColor,
                elevation: 0,
                leading: _buildProfileLeadingWidget(context, authState),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/fasthublogo.jpg',
                      height: 24,
                      width: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.school, color: Colors.white, size: 24);
                      },
                    ),
                    const SizedBox(width: 8),
                    Text('FastHub', style: FastHubTheme.appTitleStyle.copyWith(fontSize: 14)),
                  ],
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.upload_file),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DocumentUploadScreen()),
                      );
                    },
                    tooltip: 'Téléverser un nouveau document',
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      _showAddContentOptions(context);
                    },
                    tooltip: 'Ajouter',
                  ),
                  IconButton(
                    icon: const Icon(Icons.auto_awesome, color: Colors.orangeAccent),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FastHubAIChat()),
                      );
                    },
                    tooltip: 'FastHub AI',
                  ),
                  _buildDrawerButton(),
                ],
              ),
              
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildFiliereCards(),
                  _buildImportantInfoSection(),
                  _buildPublicationsSection(),
                  _buildGridButtons(),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExamResultsScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FastHubTheme.surfaceColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Résultats d\'Examen', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ]),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditorScreen()),
              );
            },
            label: const Text('Nuevo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            icon: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  Widget _buildFiliereCards() {
    final List<Map<String, String>> filieres = [
      {'name': 'MIA', 'icon': 'folder'},
      {'name': 'PC', 'icon': 'folder'},
      {'name': 'CBG', 'icon': 'folder'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filieres.length,
          itemBuilder: (context, index) {
            final filiere = filieres[index];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DocumentListPage(filiereName: filiere['name']!),
                  ),
                );
              },
              child: Container(
                width: 120,
                margin: EdgeInsets.only(
                  left: index == 0 ? 16.0 : 8.0,
                  right: index == filieres.length - 1 ? 16.0 : 8.0
                ),
                decoration: BoxDecoration(
                  color: FastHubTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 48,
                      color: FastHubTheme.accentColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      filiere['name']!,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImportantInfoSection() {
    return BlocBuilder<ImportantInfoCubit, ImportantInfoState>(
      builder: (context, state) {
        if (state is ImportantInfoLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ImportantInfoLoaded) {
          if (state.infos.isEmpty) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Informations importantes',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ImportantInfoListScreen()),
                        );
                      },
                      child: Text(
                        'Voir plus',
                        style: GoogleFonts.poppins(color: FastHubTheme.accentColor),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.infos.length,
                  itemBuilder: (context, index) {
                    final info = state.infos[index];
                    return GestureDetector(
                      onTap: () {
                        _showImportantInfoDetails(context, info);
                      },
                      child: Container(
                        width: 250,
                        margin: EdgeInsets.only(
                          left: index == 0 ? 16.0 : 8.0,
                          right: index == state.infos.length - 1 ? 16.0 : 8.0
                        ),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: FastHubTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.title,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Par ${info.author}',
                              style: GoogleFonts.poppins(
                                color: FastHubTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(info.publishedAt),
                              style: GoogleFonts.poppins(
                                color: FastHubTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Text(
                                info.content,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        } else if (state is ImportantInfoError) {
          return Center(child: Text('Erreur: ${state.message}', style: const TextStyle(color: Colors.red)));
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showImportantInfoDetails(BuildContext context, ImportantInfoModel info) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: FastHubTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  info.title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Par ${info.author} - ${DateFormat('dd/MM/yyyy HH:mm').format(info.publishedAt)}',
                  style: GoogleFonts.poppins(
                    color: FastHubTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const Divider(color: Colors.white30, height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      info.content,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Fermer',
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPublicationsSection() {
    return BlocBuilder<PublicationCubit, PublicationState>(
      builder: (context, state) {
        if (state is PublicationLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PublicationLoaded) {
          if (state.publications.isEmpty) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Publications',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PublicationListScreen()),
                        );
                      },
                      child: Text(
                        'Voir plus',
                        style: GoogleFonts.poppins(color: FastHubTheme.accentColor),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.publications.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PublicationUploadScreen())
                            );
                          },
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              color: FastHubTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: FastHubTheme.accentColor, width: 2),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline, color: FastHubTheme.accentColor, size: 40),
                                const SizedBox(height: 8),
                                Text(
                                  'Ajouter',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    final publication = state.publications[index - 1];
                    return GestureDetector(
                      onTap: () => _showPublicationDetails(context, publication),
                      child: Container(
                        width: 250,
                        margin: EdgeInsets.only(right: index == state.publications.length ? 16.0 : 8.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: FastHubTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(publication.authorAvatarUrl),
                                  radius: 20,
                                  onBackgroundImageError: (_, __) {},
                                  child: const Icon(Icons.person, size: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        publication.authorName,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${publication.authorFiliere} - ${publication.authorLevel}',
                                        style: GoogleFonts.poppins(
                                          color: FastHubTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getBadgeColor(publication.authorStatus),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    publication.authorStatus,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Text(
                                publication.content,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (publication.imageUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    publication.imageUrl!,
                                    height: 80,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 80,
                                      color: Colors.grey[800],
                                      child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 5),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(publication.publishedAt),
                                style: GoogleFonts.poppins(
                                  color: FastHubTheme.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        } else if (state is PublicationError) {
          return Center(child: Text('Erreur: ${state.message}', style: const TextStyle(color: Colors.red)));
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showPublicationDetails(BuildContext context, PublicationModel publication) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: FastHubTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(publication.authorAvatarUrl),
                            radius: 25,
                            onBackgroundImageError: (_, __) {},
                            child: const Icon(Icons.person, size: 25),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  publication.authorName,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${publication.authorFiliere} - ${publication.authorLevel}',
                                  style: GoogleFonts.poppins(
                                    color: FastHubTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _getBadgeColor(publication.authorStatus),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              publication.authorStatus,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(publication.publishedAt),
                        style: GoogleFonts.poppins(
                          color: FastHubTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Divider(color: Colors.white30, height: 30),
                      Text(
                        publication.content,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      if (publication.imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              publication.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                height: 200,
                                color: Colors.grey[800],
                                child: const Center(
                                    child: Icon(Icons.broken_image, color: Colors.white54, size: 50)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FastHubTheme.accentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Fermer',
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Color _getBadgeColor(String status) {
    switch(status.toLowerCase()) {
      case 'cam':
        return Colors.green;
      case 'res':
        return Colors.orange;
      case 'bue':
        return Colors.purple;
      case 'prof':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildGridButtons() {
    final List<Map<String, String>> buttons = [
      {'text': 'Comment réussir à la FAST', 'icon': 'lightbulb_outline'},
      {'text': 'Questions fréquentes', 'icon': 'quiz'},
      {'text': 'Comment composition', 'icon': 'edit_note'},
      {'text': 'Évènements à la FAST', 'icon': 'event'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 2.0,
        ),
        itemCount: buttons.length,
        itemBuilder: (context, index) {
          final button = buttons[index];
          IconData iconData;
          switch (button['icon']) {
            case 'lightbulb_outline':
              iconData = Icons.lightbulb_outline;
              break;
            case 'quiz':
              iconData = Icons.quiz;
              break;
            case 'edit_note':
              iconData = Icons.edit_note;
              break;
            case 'event':
              iconData = Icons.event;
              break;
            default:
              iconData = Icons.help_outline;
          }

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InfoScreen(
                    title: button['text']!,
                    content: 'Contenu détaillé pour "${button['text']!}" viendra ici.',
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: FastHubTheme.surfaceColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    iconData,
                    color: FastHubTheme.accentColor,
                    size: 30,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      button['text']!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddContentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FastHubTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.upload_file, color: Colors.white),
                title: Text('Ajouter un document', style: GoogleFonts.poppins(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(bc);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DocumentUploadScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.note_add, color: Colors.white),
                title: Text('Ajouter une publication', style: GoogleFonts.poppins(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(bc);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PublicationUploadScreen()),
                  );
                  if (result == true) {
                    context.read<PublicationCubit>().loadRecentPublications();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.white),
                title: Text('Ajouter une information importante', style: GoogleFonts.poppins(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(bc);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ImportantInfoUploadScreen()),
                  );
                  if (result == true) {
                    context.read<ImportantInfoCubit>().loadImportantInfo();
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
