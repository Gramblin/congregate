import 'package:cached_network_image/cached_network_image.dart';
import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/business/data/business_events_repository.dart';
import 'package:congregate/src/features/business/domain/business.dart';
import 'package:congregate/src/features/business/domain/business_event.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BusinessProductsScreen extends ConsumerWidget {
  const BusinessProductsScreen({required this.business, super.key});
  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEvents = ref.watch(businessEventsProvider(business.id));
    return Scaffold(
      appBar: AppBar(title: Text('${business.name} · Products'.hardcoded)),
      body: asyncEvents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (events) {
          final products =
              events.where((e) => e.type == 'product').toList();
          if (products.isEmpty) {
            return Center(
              child: Text(
                'No products yet.'.hardcoded,
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(Sizes.p16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: Sizes.p8,
              crossAxisSpacing: Sizes.p8,
              childAspectRatio: 0.62,
            ),
            itemCount: products.length,
            itemBuilder: (context, i) => _ProductGridItem(product: products[i]),
          );
        },
      ),
    );
  }
}

class _ProductGridItem extends StatelessWidget {
  const _ProductGridItem({required this.product});
  final BusinessEvent product;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: Icon(Icons.storefront_outlined, size: 40),
                    ),
                  ),
          ),
          Expanded(
            child: Padding(
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
                  if (product.description != null) ...[
                    gapH4,
                    Expanded(
                      child: Text(
                        product.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (product.price != null)
                    Text(
                      '\$${product.price!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
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
}
