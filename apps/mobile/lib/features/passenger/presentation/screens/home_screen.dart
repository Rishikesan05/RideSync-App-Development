import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/core/widgets/ai_assistant_fab.dart';
import 'package:ridesync/core/widgets/notification_tab.dart';
import 'package:ridesync/core/widgets/ridesync_ui.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:ridesync/features/passenger/data/models/route_models.dart';
import 'package:ridesync/features/passenger/presentation/providers/finder_provider.dart';
import 'package:ridesync/features/passenger/presentation/providers/home_provider.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().fetchHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/logo.jpeg',
                height: 36,
                width: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'RideSync',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        actions: const [
          NotificationTab(),
          SizedBox(width: 6),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: _HomeAccountButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroBlock(isDark: isDark),
              const SizedBox(height: AppStyles.sectionSpacing),
              _BookingPreviewCard(isDark: isDark),
              const SizedBox(height: AppStyles.sectionSpacing),
              _SearchPlannerCard(isDark: isDark),
              const SizedBox(height: 18),
              _TravelSquadCard(isDark: isDark),
              const SizedBox(height: AppStyles.sectionSpacing),
              _SectionWithRoutes(isDark: isDark),
              const SizedBox(height: AppStyles.sectionSpacing),
              _HubNetworkSection(isDark: isDark),
            ],
          ),
        ),
      ),
      floatingActionButton: const AIAssistantFAB(),
    );
  }
}

class _HeroBlock extends StatefulWidget {
  const _HeroBlock({required this.isDark});
  final bool isDark;

  @override
  State<_HeroBlock> createState() => _HeroBlockState();
}

class _HeroBlockState extends State<_HeroBlock> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Color?> _colorAnim1;
  late final Animation<Color?> _colorAnim2;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    
    final hour = DateTime.now().hour;
    Color c1, c2, c3, c4;
    
    if (hour < 12) {
      // Morning colors (warm yellow/orange)
      c1 = const Color(0xFFFFB74D); c2 = const Color(0xFFFF8A65);
      c3 = const Color(0xFFFFE082); c4 = const Color(0xFFFFCC80);
    } else if (hour < 17) {
      // Afternoon colors (bright blue/cyan)
      c1 = const Color(0xFF4FC3F7); c2 = const Color(0xFF4DD0E1);
      c3 = const Color(0xFF81D4FA); c4 = const Color(0xFF80DEEA);
    } else {
      // Evening/Night colors (deep purple/indigo)
      c1 = const Color(0xFF7E57C2); c2 = const Color(0xFF5C6BC0);
      c3 = const Color(0xFF9575CD); c4 = const Color(0xFF7986CB);
    }

    _colorAnim1 = ColorTween(begin: c1.withValues(alpha: 0.25), end: c3.withValues(alpha: 0.45)).animate(_animController);
    _colorAnim2 = ColorTween(begin: c2.withValues(alpha: 0.25), end: c4.withValues(alpha: 0.45)).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.name.split(' ').first ?? 'Rider';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Animated glowing background blob
        Positioned(
          top: -40,
          left: -20,
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Container(
                width: 250,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _colorAnim1.value ?? Colors.transparent,
                      (_colorAnim2.value ?? Colors.transparent).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()},\n$userName.',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: widget.isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Plan your route, coordinate with your travel squad, and move through the city with less friction.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: widget.isDark ? AppColors.textMutedDark : AppColors.textLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchPlannerCard extends StatefulWidget {
  const _SearchPlannerCard({required this.isDark});

  final bool isDark;

  @override
  State<_SearchPlannerCard> createState() => _SearchPlannerCardState();
}

class _SearchPlannerCardState extends State<_SearchPlannerCard> {
  final _originController = TextEditingController();
  final _destController = TextEditingController();
  final _originFocus = FocusNode();
  final _destFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _originController.addListener(() {
      if (_originFocus.hasFocus && _originController.text.isNotEmpty) {
        context.read<FinderProvider>().fetchSuggestions(_originController.text, 'origin');
      }
    });
    _destController.addListener(() {
      if (_destFocus.hasFocus && _destController.text.isNotEmpty) {
        context.read<FinderProvider>().fetchSuggestions(_destController.text, 'destination');
      }
    });
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _originFocus.dispose();
    _destFocus.dispose();
    super.dispose();
  }

  void _handleSuggestionTap(Place place) {
    if (_originFocus.hasFocus) {
      _originController.text = place.name;
      _originFocus.unfocus();
    } else if (_destFocus.hasFocus) {
      _destController.text = place.name;
      _destFocus.unfocus();
    }
    context.read<FinderProvider>().fetchSuggestions('', ''); // Clear suggestions
  }

  void _handleOptimizeRoute() {
    final originText = _originController.text.trim();
    final destText = _destController.text.trim();

    if (originText.isEmpty || destText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both FROM and TO locations')),
      );
      return;
    }

    final finder = context.read<FinderProvider>();
    finder.searchFromRawStrings(originText, destText);

    Navigator.pushNamed(context, '/main', arguments: {'index': 3});
  }

  @override
  Widget build(BuildContext context) {
    final finder = context.watch<FinderProvider>();
    final showSuggestions = finder.suggestions.isNotEmpty && (_originFocus.hasFocus || _destFocus.hasFocus);

    return RideSyncSurfaceCard(
      child: Column(
        children: [
          _LocationField(
            label: 'FROM',
            hint: 'your current location',
            icon: Icons.gps_fixed_rounded,
            iconColor: AppColors.accentBlue,
            isDark: widget.isDark,
            controller: _originController,
            focusNode: _originFocus,
          ),
          const SizedBox(height: 14),
          _LocationField(
            label: 'TO',
            hint: 'Where to go today?',
            icon: Icons.location_on_outlined,
            iconColor: AppColors.primaryOrange,
            isDark: widget.isDark,
            controller: _destController,
            focusNode: _destFocus,
          ),
          if (showSuggestions) ...[
            const SizedBox(height: 14),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: finder.suggestions.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: widget.isDark ? Colors.white10 : Colors.black12),
                itemBuilder: (context, index) {
                  final place = finder.suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined, color: AppColors.primaryOrange, size: 20),
                    title: Text(place.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: widget.isDark ? Colors.white : AppColors.textDark)),
                    subtitle: Text(place.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.white60 : Colors.black54)),
                    onTap: () => _handleSuggestionTap(place),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 18),
          RideSyncPrimaryButton(
            label: 'OPTIMIZE ROUTE',
            icon: Icons.search_rounded,
            onPressed: _handleOptimizeRoute,
          ),
        ],
      ),
    );
  }
}

class _TravelSquadCard extends StatelessWidget {
  const _TravelSquadCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final members = [
      ('Add', Icons.add_rounded, null),
      ('Mom', null, const Color(0xFFE88A8A)),
      ('Brother', null, const Color(0xFF9CA3AF)),
      ('Sahan', null, const Color(0xFF6B7280)),
    ];

    return RideSyncSurfaceCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RideSyncSectionHeader(title: 'Travel Squad'),
          const SizedBox(height: 16),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: members.length,
              separatorBuilder: (_, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final member = members[index];
                final icon = member.$2;
                final color = member.$3;
                return Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: color ??
                            (isDark
                                ? AppColors.surfaceMutedDark
                                : AppColors.surfaceMuted),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: index == 0
                              ? AppColors.textLight.withValues(alpha: 0.4)
                              : Colors.transparent,
                          style: index == 0
                              ? BorderStyle.solid
                              : BorderStyle.none,
                        ),
                      ),
                      child: icon != null
                          ? Icon(icon, color: AppColors.textLight)
                          : const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      member.$1,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionWithRoutes extends StatelessWidget {
  const _SectionWithRoutes({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final routes = homeProvider.quickRoutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RideSyncSectionHeader(
          title: 'Quick Routes',
          subtitle: 'Jump back into your regular commute.',
        ),
        const SizedBox(height: 4), // Reduced to balance the list view's new top padding
        SizedBox(
          height: 204, // 164 + 40 for shadow padding
          child: homeProvider.isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : ListView.separated(
            clipBehavior: Clip.none, // Prevent hard edge clipping on the left/right shadows
            padding: const EdgeInsets.symmetric(vertical: 20), // Provide space for bottom shadows
            scrollDirection: Axis.horizontal,
            itemCount: routes.length,
            separatorBuilder: (_, index) => const SizedBox(width: 18), // slightly wider gap for shadows
            itemBuilder: (context, index) {
              final route = routes[index];
              return SizedBox(
                width: 240, // Expanded width to prevent right-side text clipping
                child: RideSyncSurfaceCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Maximize internal space
                  onTap: () {
                    final finder = context.read<FinderProvider>();
                    finder.searchFromRawStrings(route.origin, route.destination);
                    Navigator.pushNamed(context, '/main', arguments: {'index': 3});
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              route.title.toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    letterSpacing: 0.9,
                                    color: AppColors.textLight,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          if (route.tag != null)
                            RideSyncPill(
                              label: route.tag!,
                              backgroundColor: AppColors.primaryOrange
                                  .withValues(alpha: 0.14),
                              foregroundColor: AppColors.primaryOrangeDeep,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _getTypeColor(route.routeType).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(_getTypeIcon(route.routeType), size: 14, color: _getTypeColor(route.routeType)),
                          ),
                          const SizedBox(width: 8),
                          Text(_getTypeLabel(route.routeType), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getTypeColor(route.routeType))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${route.origin} -> ${route.destination}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _InfoDot(
                            icon: Icons.schedule_rounded,
                            label: route.duration,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 14),
                          _InfoDot(
                            icon: Icons.confirmation_number_outlined,
                            label: route.fare,
                            isDark: isDark,
                          ),
                        ],
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
  }

  Color _getTypeColor(RecommendationType type) {
    switch (type) {
      case RecommendationType.express: return Colors.blue;
      case RecommendationType.intercity: return Colors.green;
      case RecommendationType.normal: return Colors.orange;
    }
  }

  IconData _getTypeIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.express: return Icons.electric_bolt;
      case RecommendationType.intercity: return Icons.location_city;
      case RecommendationType.normal: return Icons.directions_bus;
    }
  }

  String _getTypeLabel(RecommendationType type) {
    switch (type) {
      case RecommendationType.express: return 'EXPRESS';
      case RecommendationType.intercity: return 'INTERCITY';
      case RecommendationType.normal: return 'NORMAL';
    }
  }
}

class _BookingPreviewCard extends StatefulWidget {
  const _BookingPreviewCard({required this.isDark});
  final bool isDark;

  @override
  State<_BookingPreviewCard> createState() => _BookingPreviewCardState();
}

class _BookingPreviewCardState extends State<_BookingPreviewCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isDark ? Colors.black.withValues(alpha: 0.3) : AppColors.primaryOrange.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FadeTransition(
                      opacity: _pulseAnimation,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.redAccent, blurRadius: 8, spreadRadius: 2)
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'LIVE TRACKING',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.isDark ? Colors.black26 : Colors.black12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ETA: 12 mins',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Express 154 to Fort',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: widget.isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your bus is currently near Town Hall',
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.isDark ? Colors.white10 : Colors.black12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: 0.65,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryOrange, Colors.redAccent],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Borella', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white70 : Colors.black45)),
                    Text('Fort', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white70 : Colors.black45)),
                  ],
                ),
                const SizedBox(height: 20),
                RideSyncPrimaryButton(
                  label: 'View Live Map',
                  icon: Icons.map_rounded,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening live map...')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HubNetworkSection extends StatelessWidget {
  const _HubNetworkSection({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final hubs = homeProvider.hubs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RideSyncSectionHeader(
          title: 'Hub Network',
          subtitle: 'Board from the busiest touchpoints in the city.',
        ),
        const SizedBox(height: 16),
        homeProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: hubs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.12,
          ),
          itemBuilder: (context, index) {
            final hub = hubs[index];
            
            // Define a set of vibrant gradients
            final gradients = [
              const LinearGradient(colors: [Color(0xFFFFA726), Color(0xFFFF7043)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF5C6BC0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              const LinearGradient(colors: [Color(0xFF26A69A), Color(0xFF00897B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              const LinearGradient(colors: [Color(0xFFAB47BC), Color(0xFF7E57C2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ];
            final gradient = gradients[index % gradients.length];

            return GestureDetector(
              onTap: () {
                final finder = context.read<FinderProvider>();
                final cleanName = hub.title.replaceAll('\n', ' ');
                finder.searchFromRawStrings(cleanName, '');
                Navigator.pushNamed(context, '/main', arguments: {'index': 3});
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: gradient,
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Glassmorphism shine overlay
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -10,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.apartment_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            hub.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hub.subtitle.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.controller,
    required this.focusNode,
  });

  final String label;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      color: isDark ? Colors.white38 : AppColors.textLight,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoDot extends StatelessWidget {
  const _InfoDot({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.textMutedDark : AppColors.textLight,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isDark ? AppColors.textMutedDark : AppColors.textLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}


class _HomeAccountButton extends StatelessWidget {
  const _HomeAccountButton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showAccountCard(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? Colors.transparent : Colors.white,
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.person_outline_rounded,
            size: 20,
            color: isDark ? Colors.white : AppColors.primaryNavy,
          ),
        ),
      ),
    );
  }

  void _showAccountCard(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = auth.user;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.1),
                child: const Icon(Icons.person, color: AppColors.primaryOrange, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                user?.name ?? 'Guest User',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? 'Not signed in',
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/main', arguments: {'index': 4});
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : Colors.black,
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Settings'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (auth.isAuthenticated) {
                          auth.logout();
                          Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
                        } else {
                          Navigator.pushNamed(context, '/login');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: auth.isAuthenticated ? Colors.redAccent : AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(auth.isAuthenticated ? 'Sign Out' : 'Sign In'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
