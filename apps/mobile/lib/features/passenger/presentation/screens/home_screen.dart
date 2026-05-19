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
              _SearchPlannerCard(isDark: isDark),
              const SizedBox(height: 18),
              _TravelSquadCard(isDark: isDark),
              const SizedBox(height: AppStyles.sectionSpacing),
              _BookingPreviewCard(isDark: isDark),
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

class _HeroBlock extends StatelessWidget {
  const _HeroBlock({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RideSyncPill(
          label: 'Optimized routes',
          icon: Icons.auto_awesome_rounded,
          backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.14),
          foregroundColor: AppColors.primaryOrangeDeep,
        ),
        const SizedBox(height: 16),
        Text(
          'Intelligent commute\nstarts here.',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.05,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Plan your route, coordinate with your travel squad, and move through the city with less friction.',
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: isDark ? AppColors.textMutedDark : AppColors.textLight,
          ),
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
}

class _BookingPreviewCard extends StatelessWidget {
  const _BookingPreviewCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return RideSyncSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TOTAL FARE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                'GROUP',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 30,
                height: 18,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark ? AppColors.strokeDark : AppColors.stroke,
                  ),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.all(2),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryNavy,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Rs. 450',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 18),
          const _BookingLineItem(
            icon: Icons.place_outlined,
            title: 'Pettah Main Terminal',
            subtitle: 'Boarding hub',
          ),
          const SizedBox(height: 14),
          const _BookingLineItem(
            icon: Icons.people_outline_rounded,
            title: '2 seats reserved for squad',
            subtitle: 'Mom + Brother',
          ),
          const SizedBox(height: 22),
          RideSyncPrimaryButton(
            label: 'Book seats',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              if (auth.isGuest) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Login Required'),
                    content: const Text('You need to be logged in to reserve seats and book rides.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
                        child: const Text('Login / Signup'),
                      ),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Proceeding to booking...'), backgroundColor: Colors.green),
                );
              }
            },
          ),
        ],
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
            return RideSyncSurfaceCard(
              padding: const EdgeInsets.all(18),
              onTap: () {
                final finder = context.read<FinderProvider>();
                final cleanName = hub.title.replaceAll('\n', ' ');
                finder.searchFromRawStrings(cleanName, '');
                Navigator.pushNamed(context, '/main', arguments: {'index': 3});
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.place_outlined,
                    color: AppColors.primaryOrange,
                    size: 18,
                  ),
                  const Spacer(),
                  Text(
                    hub.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hub.subtitle.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textLight,
                      letterSpacing: 0.9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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

class _BookingLineItem extends StatelessWidget {
  const _BookingLineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryOrange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isDark ? AppColors.textMutedDark : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryOrange),
      ],
    );
  }
}

class _HomeAccountButton extends StatelessWidget {
  const _HomeAccountButton();

  @override
  Widget build(BuildContext context) {
    return RideSyncIconCircleButton(
      icon: Icons.person_outline_rounded,
      onPressed: () => _showAccountCard(context),
    );
  }

  void _showAccountCard(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final name = (user?.name.isNotEmpty ?? false) ? user!.name : 'Guest User';
    final email =
        (user?.email.isNotEmpty ?? false) ? user!.email : 'Sign in to sync rides';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return RideSyncPopupShell(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RideSyncPopupHeader(
                  title: 'Account',
                  subtitle: auth.isAuthenticated
                      ? 'Manage your profile and session.'
                      : 'Sign in to sync your rides and profile.',
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceMutedDark : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.strokeDark : AppColors.stroke,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 34,
                        color: isDark ? Colors.white : AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toUpperCase(),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textDark,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              email.toUpperCase(),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textDark,
                                  ),
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(dialogContext).pop();
                                Navigator.pushNamed(context, '/main', arguments: {
                                  'index': 4,
                                });
                              },
                              child: Text(
                                'VIEW ACCOUNT',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                RideSyncPrimaryButton(
                  label: 'SIGN OUT',
                  onPressed: auth.isAuthenticated
                      ? () async {
                          await auth.logout();
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/splash',
                              (route) => false,
                            );
                          }
                        }
                      : () {
                          Navigator.of(dialogContext).pop();
                          Navigator.pushNamed(context, '/login');
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
