import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../models/models.dart';
import '../cubit/items_by_store_cubit.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../common_widgets/error_display.dart';
import '../../../common_widgets/empty_list_widget.dart';
import '../../../common_widgets/standard_list_item.dart';

class ItemsByStoreScreen extends StatelessWidget {
  final int storeId;
  const ItemsByStoreScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ItemsByStoreCubit(storeId: storeId),
      child: const ItemsByStoreView(),
    );
  }
}

class ItemsByStoreView extends StatelessWidget {
  const ItemsByStoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ItemsByStoreCubit, ItemsByStoreState>(
          builder: (context, state) {
            if (state is ItemsByStoreLoaded) {
              return Text('Items at ${state.store.name}');
            }
            return const Text('Items by Store');
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).pop(),
        ),
      ),
      body: BlocBuilder<ItemsByStoreCubit, ItemsByStoreState>(
        builder: (context, state) {
          if (state is ItemsByStoreLoading || state is ItemsByStoreInitial) {
            return const LoadingIndicator();
          }
          if (state is ItemsByStoreError) {
            return ErrorDisplay(message: state.message);
          }
          if (state is ItemsByStoreLoaded) {
            if (state.items.isEmpty) {
              return const EmptyListWidget(message: 'No items found for this store.');
            }
            return ListView.builder(
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return StandardListItem<ShoppingItem>(
                  item: item,
                  onToggleCompletion: (toggledItem) {
                    context.read<ItemsByStoreCubit>().toggleItemCompletion(toggledItem);
                  },
                  subtitleWidgets: [
                    buildDetailText('${item.quantity} ${item.unit} - ${item.category}'),
                  ],
                  // onItemTap: (tappedItem) {
                  //   // Handle item tap if needed in the future
                  // },
                );
              },
            );
          }
          return const EmptyListWidget(message: 'Something went wrong.');
        },
      ),
    );
  }
}
