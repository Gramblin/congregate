import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/ads/data/ads_repository.dart';
import 'package:congregate/src/features/ads/domain/ad.dart';
import 'package:congregate/src/features/ads/presentation/view/ad_details_screen.dart';
import 'package:congregate/src/features/ads/presentation/view/create_ad_sheet.dart';
import 'package:congregate/src/features/stories/domain/story.dart';
import 'package:congregate/src/features/stories/presentation/create_story_sheet.dart';
import 'package:congregate/src/features/business/data/business_events_repository.dart';
import 'package:congregate/src/features/business/domain/business.dart';
import 'package:congregate/src/features/business/domain/business_event.dart';
import 'package:congregate/src/features/business/presentation/controller/business_controller.dart';
import 'package:congregate/src/features/business/presentation/controller/business_event_controller.dart';
import 'package:congregate/src/features/business/presentation/view/business_products_screen.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessDetailsScreen extends ConsumerStatefulWidget {
  const BusinessDetailsScreen({required this.business, super.key});
  final Business business;

  @override
  ConsumerState<BusinessDetailsScreen> createState() =>
      _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends ConsumerState<BusinessDetailsScreen> {
  bool _fabOpen = false;

  Business get business => widget.business;

  void _toggleFab() => setState(() => _fabOpen = !_fabOpen);
  void _closeFab() {
    if (_fabOpen) setState(() => _fabOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final userId = ref.watch(supabaseProvider).client.auth.currentUser?.id;
    final isOwner = userId == business.ownerId;
    final asyncEvents = ref.watch(businessEventsProvider(business.id));
    final followState = ref.watch(followProvider); // keeps notifier alive
    final asyncList = ref.watch(businessListProvider());
    final current = asyncList.when(
          data: (list) => list.where((b) => b.id == business.id).firstOrNull,
          loading: () => null,
          error: (_, __) => null,
        ) ??
        business;

    return Scaffold(
      appBar: AppBar(title: Text(business.name)),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(
              Sizes.p16,
              Sizes.p16,
              Sizes.p16,
              120,
            ),
            children: [
          // Header
          Row(
            children: [
              _ProfileImage(
                business: current,
                isOwner: isOwner,
                onTap: isOwner ? () => _pickProfileImage(context, ref) : null,
              ),
              gapW16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.name,
                      style: const TextStyle(
                        fontSize: Sizes.p20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(current.category,
                        style: const TextStyle(color: Colors.grey)),
                    if (current.city != null || current.country != null)
                      Text(
                        [
                          if (current.city != null) current.city!,
                          if (current.country != null) current.country!,
                        ].join(', '),
                        style: const TextStyle(fontSize: 12),
                      ),
                    gapH4,
                    Row(
                      children: [
                        const Icon(Icons.people_outline, size: 14),
                        gapW4,
                        Text('${current.followerCount} followers',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    asyncEvents.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (evs) {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        bool live(BusinessEvent e) {
                          final ref = e.endAt ?? e.startAt;
                          if (ref == null) return true;
                          return !ref.isBefore(today);
                        }
                        final products = evs
                            .where((e) => e.type == 'product' && live(e))
                            .length;
                        final events = evs
                            .where((e) => e.type == 'event' && live(e))
                            .length;
                        return Wrap(
                          spacing: 12,
                          children: [
                            if (products > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.storefront_outlined,
                                      size: 12),
                                  gapW4,
                                  Text(
                                    '$products product${products == 1 ? '' : 's'}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            if (events > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.event_outlined, size: 12),
                                  gapW4,
                                  Text(
                                    '$events event${events == 1 ? '' : 's'}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          gapH16,

          // Follow button
          if (!isOwner)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: followState.isLoading
                    ? null
                    : () => ref.read(followProvider.notifier).toggle(current),
                icon: followState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        current.isFollowing == true
                            ? Icons.notifications_off_outlined
                            : Icons.notifications_active_outlined,
                      ),
                label: Text(
                  current.isFollowing == true
                      ? 'Unfollow'.hardcoded
                      : 'Follow & get notified'.hardcoded,
                ),
              ),
            ),
          gapH16,

          // Description
          if (current.description != null && current.description!.isNotEmpty) ...[
            Text(current.description!),
            gapH16,
          ],

          // Contact
          if ((current.contactPublic || isOwner) &&
              (current.email != null ||
                  current.phone != null ||
                  current.website != null)) ...[
            const Divider(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showContactSheet(context, current),
                icon: const Icon(Icons.contact_page_outlined),
                label: Text('Contact details'.hardcoded),
              ),
            ),
            gapH8,
          ],

          // Products (horizontal)
          asyncEvents.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (events) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final products = events.where((e) {
                if (e.type != 'product') return false;
                final r = e.endAt ?? e.startAt;
                if (r == null) return true;
                return !r.isBefore(today);
              }).toList();
              if (products.isEmpty) return const SizedBox.shrink();
              final shown = products.take(10).toList();
              final hasMore = products.length > shown.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Products'.hardcoded,
                        style: const TextStyle(
                          fontSize: Sizes.p16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => BusinessProductsScreen(
                              business: current,
                            ),
                          ),
                        ),
                        child: Text('See all'.hardcoded),
                      ),
                    ],
                  ),
                  gapH8,
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: shown.length + (hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => gapW8,
                      itemBuilder: (context, i) {
                        if (i == shown.length) {
                          return _SeeAllTile(
                            onTap: () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => BusinessProductsScreen(
                                  business: current,
                                ),
                              ),
                            ),
                          );
                        }
                        return _ProductCard(product: shown[i]);
                      },
                    ),
                  ),
                  gapH8,
                ],
              );
            },
          ),

          // Owner ads
          if (isOwner) ...[
            const Divider(),
            _OwnerAdsSection(businessId: business.id),
          ],

          // Events
          const Divider(),
          Text(
            'Posts & Events'.hardcoded,
            style: const TextStyle(
              fontSize: Sizes.p16,
              fontWeight: FontWeight.bold,
            ),
          ),
          gapH8,
          asyncEvents.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (events) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final upcoming = events.where((e) {
                if (e.type == 'product') return false;
                final ref = e.endAt ?? e.startAt;
                if (ref == null) return true;
                return !ref.isBefore(today);
              }).toList();
              if (upcoming.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(Sizes.p16),
                  child: Text(
                    'No upcoming posts.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              return Column(
                children: upcoming
                    .map((e) => _EventCard(
                          event: e,
                          isOwner: isOwner,
                          ref: ref,
                        ))
                    .toList(),
              );
            },
          ),
        ],
          ),
          if (isOwner)
            Positioned(
              right: 16,
              bottom: 16,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.bottomRight,
                      child: _fabOpen
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                FloatingActionButton.extended(
                                  heroTag: 'post_event',
                                  onPressed: () {
                                    _closeFab();
                                    _showSheet(context, ref, type: 'event');
                                  },
                                  icon: const Icon(Icons.event_outlined),
                                  label: const Text('Create Event'),
                                ),
                                gapH8,
                                FloatingActionButton.extended(
                                  heroTag: 'post_product',
                                  onPressed: () {
                                    _closeFab();
                                    _showSheet(context, ref, type: 'product');
                                  },
                                  icon: const Icon(Icons.storefront_outlined),
                                  label: const Text('Create Product'),
                                ),
                                gapH8,
                                FloatingActionButton.extended(
                                  heroTag: 'post_ad',
                                  onPressed: () {
                                    _closeFab();
                                    _showAdSheet(context);
                                  },
                                  icon: const Icon(Icons.campaign_outlined),
                                  label: const Text('Post Ad'),
                                ),
                                gapH8,
                                FloatingActionButton.extended(
                                  heroTag: 'post_story',
                                  onPressed: () {
                                    _closeFab();
                                    _showStorySheet(context, current);
                                  },
                                  icon:
                                      const Icon(Icons.auto_stories_outlined),
                                  label: const Text('Post Story'),
                                ),
                                gapH8,
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                    FloatingActionButton(
                      heroTag: 'fab_toggle',
                      onPressed: _toggleFab,
                      child: AnimatedRotation(
                        turns: _fabOpen ? 0.125 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickProfileImage(BuildContext context, WidgetRef ref) async {
    final xfile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (xfile == null) return;
    await ref.read(businessFormProvider.notifier).updateImage(
          businessId: business.id,
          image: File(xfile.path),
        );
  }

  void _showAdSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => CreateAdSheet(businessId: business.id),
    );
  }

  void _showStorySheet(BuildContext context, Business current) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => CreateStorySheet(
        authorType: StoryAuthorType.business,
        authorId: current.id,
        authorName: current.name,
      ),
    );
  }

  void _showContactSheet(BuildContext context, Business current) {
    showModalSheet<void>(
      context: context,
      swipeDismissible: true,
      builder: (_) => Sheet(
        scrollConfiguration: const SheetScrollConfiguration(),
        decoration: const MaterialSheetDecoration(
          size: SheetSize.fit,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(Sizes.p32)),
          ),
        ),
        child: SheetContentScaffold(
          body: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Sizes.p16,
                Sizes.p12,
                Sizes.p16,
                Sizes.p16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  gapH16,
                  Text(
                    'Contact details'.hardcoded,
                    style: const TextStyle(
                      fontSize: Sizes.p20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  gapH8,
                  if (current.email != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined),
                      title: Text(current.email!),
                      onTap: () =>
                          launchUrl(Uri.parse('mailto:${current.email}')),
                    ),
                  if (current.phone != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.phone_outlined),
                      title: Text(current.phone!),
                      onTap: () =>
                          launchUrl(Uri.parse('tel:${current.phone}')),
                    ),
                  if (current.website != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.link),
                      title: Text(current.website!),
                      onTap: () => launchUrl(Uri.parse(current.website!)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSheet(BuildContext context, WidgetRef ref, {required String type}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => type == 'product'
          ? _CreateProductSheet(businessId: business.id)
          : _CreateEventSheet(businessId: business.id),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({
    required this.business,
    required this.isOwner,
    this.onTap,
  });
  final Business business;
  final bool isOwner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: business.profileImageUrl != null
                ? CachedNetworkImageProvider(business.profileImageUrl!)
                : null,
            child: business.profileImageUrl == null
                ? Text(
                    business.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 28),
                  )
                : null,
          ),
          if (isOwner)
            const Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 12,
                child: Icon(Icons.edit, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.isOwner,
    required this.ref,
  });
  final BusinessEvent event;
  final bool isOwner;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM y');

    return Card(
      margin: const EdgeInsets.only(bottom: Sizes.p8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.imageUrl != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: event.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(Sizes.p12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (event.type == 'product')
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Product',
                          style: TextStyle(fontSize: 10, color: Colors.orange),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: Sizes.p16,
                        ),
                      ),
                    ),
                    if (isOwner)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: () => ref
                            .read(businessEventProvider.notifier)
                            .delete(event.id, event.businessId),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                if (event.description != null) ...[
                  gapH4,
                  Text(event.description!),
                ],
                if (event.price != null) ...[
                  gapH4,
                  Text(
                    '\$${event.price!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Sizes.p16,
                      color: Colors.green,
                    ),
                  ),
                ],
                if (event.startAt != null) ...[
                  gapH4,
                  Row(
                    children: [
                      const Icon(Icons.event, size: 14),
                      gapW4,
                      Text(
                        fmt.format(event.startAt!.toLocal()),
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (event.endAt != null) ...[
                        const Text(' – '),
                        Text(
                          fmt.format(event.endAt!.toLocal()),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ],
                gapH4,
                Text(
                  fmt.format(event.createdAt.toLocal()),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateEventSheet extends ConsumerStatefulWidget {
  const _CreateEventSheet({required this.businessId});
  final String businessId;

  @override
  ConsumerState<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends ConsumerState<_CreateEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  File? _image;
  DateTime? _startAt;
  DateTime? _endAt;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xfile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (xfile != null) setState(() => _image = File(xfile.path));
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startAt = picked;
      } else {
        _endAt = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final event =
        await ref.read(businessEventProvider.notifier).create(
              businessId: widget.businessId,
              title: _titleCtrl.text.trim(),
              description: _descCtrl.text.trim().isEmpty
                  ? null
                  : _descCtrl.text.trim(),
              startAt: _startAt,
              endAt: _endAt,
              image: _image,
            );
    if (event != null && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(businessEventProvider);
    final fmt = DateFormat('d MMM y');

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      expand: false,
      builder: (_, scrollCtrl) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(Sizes.p16),
            children: [
              Text(
                'New Post / Event'.hardcoded,
                style: const TextStyle(
                  fontSize: Sizes.p20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              gapH16,

              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    image: _image != null
                        ? DecorationImage(
                            image: FileImage(_image!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _image == null
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 40),
                              Text('Add image (optional)'),
                            ],
                          ),
                        )
                      : null,
                ),
              ),
              gapH12,

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              gapH8,
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              gapH12,

              // Date pickers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(true),
                      icon: const Icon(Icons.event, size: 16),
                      label: Text(
                        _startAt != null
                            ? 'Start: ${fmt.format(_startAt!)}'
                            : 'Start date',
                      ),
                    ),
                  ),
                  gapW8,
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(false),
                      icon: const Icon(Icons.event_available, size: 16),
                      label: Text(
                        _endAt != null
                            ? 'End: ${fmt.format(_endAt!)}'
                            : 'End date',
                      ),
                    ),
                  ),
                ],
              ),
              gapH24,

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.isLoading ? null : _submit,
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Post'.hardcoded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Product creation sheet ────────────────────────────────────────

class _CreateProductSheet extends ConsumerStatefulWidget {
  const _CreateProductSheet({required this.businessId});
  final String businessId;

  @override
  ConsumerState<_CreateProductSheet> createState() =>
      _CreateProductSheetState();
}

class _CreateProductSheetState extends ConsumerState<_CreateProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  File? _image;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xfile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (xfile != null) setState(() => _image = File(xfile.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final priceText = _priceCtrl.text.trim();
    final price = priceText.isEmpty ? null : double.tryParse(priceText);
    final event =
        await ref.read(businessEventProvider.notifier).create(
              businessId: widget.businessId,
              title: _titleCtrl.text.trim(),
              type: 'product',
              description: _descCtrl.text.trim().isEmpty
                  ? null
                  : _descCtrl.text.trim(),
              price: price,
              image: _image,
            );
    if (event != null && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(businessEventProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      expand: false,
      builder: (_, scrollCtrl) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(Sizes.p16),
            children: [
              Text(
                'Add Product'.hardcoded,
                style: const TextStyle(
                  fontSize: Sizes.p20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              gapH16,
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    image: _image != null
                        ? DecorationImage(
                            image: FileImage(_image!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _image == null
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 40),
                              Text('Add image (optional)'),
                            ],
                          ),
                        )
                      : null,
                ),
              ),
              gapH12,
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Product name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              gapH8,
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              gapH8,
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Price (optional)',
                  hintText: 'e.g. 9.99',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              gapH24,
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.isLoading ? null : _submit,
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Post Product'.hardcoded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final BusinessEvent product;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.storefront_outlined, size: 32),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(Sizes.p8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (product.price != null) ...[
                    gapH4,
                    Text(
                      '\$${product.price!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeeAllTile extends StatelessWidget {
  const _SeeAllTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_forward, size: 32),
                gapH8,
                Text('See all'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerAdsSection extends ConsumerWidget {
  const _OwnerAdsSection({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAds = ref.watch(businessAdsProvider(businessId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Ads'.hardcoded,
          style: const TextStyle(
            fontSize: Sizes.p16,
            fontWeight: FontWeight.bold,
          ),
        ),
        gapH8,
        asyncAds.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (ads) {
            final now = DateTime.now();
            final live = ads.where((a) {
              if (!a.isActive) return false;
              if (a.endsAt != null && a.endsAt!.isBefore(now)) return false;
              return true;
            }).toList();
            if (live.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: Sizes.p8),
                child: Text(
                  'No live ads. Tap "Post Ad" to create one.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }
            return Column(
              children: live
                  .map((ad) => _OwnerAdTile(ad: ad, businessId: businessId))
                  .toList(),
            );
          },
        ),
        gapH8,
      ],
    );
  }
}

class _OwnerAdTile extends ConsumerWidget {
  const _OwnerAdTile({required this.ad, required this.businessId});
  final Ad ad;
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: Sizes.p8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CachedNetworkImage(
            imageUrl: ad.bannerImageUrl,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) =>
                const Icon(Icons.image_not_supported_outlined),
          ),
        ),
        title: Text(ad.title),
        subtitle: Text(ad.isActive ? 'Active' : 'Inactive'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => ref
              .read(adFormProvider.notifier)
              .delete(adId: ad.id, businessId: businessId),
        ),
        onTap: () => Navigator.of(context, rootNavigator: true).push<void>(
          MaterialPageRoute(builder: (_) => AdDetailsScreen(ad: ad)),
        ),
      ),
    );
  }
}
