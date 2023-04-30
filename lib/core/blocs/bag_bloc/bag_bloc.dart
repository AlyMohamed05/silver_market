import 'package:bloc/bloc.dart';
import 'package:dartx/dartx.dart';
import 'package:equatable/equatable.dart';

import 'package:silver_market/core/model/models.dart';
part 'bag_event.dart';
part 'bag_state.dart';

class BagBloc extends Bloc<BagEvent, BagState> {
  BagBloc() : super(EmptyBag()) {
    on<AddProductToBagEvent>(_onAddProductToBagEvent);
    on<IncProductCountEvent>(_onIncProductCountEvent);
    on<DecProductCountEvent>(_onDecProductCountEvent);
    on<RemoveFromBagEvent>(_onRemoveFromBagEvent);
  }

  Future<void> _onAddProductToBagEvent(
    AddProductToBagEvent event,
    Emitter<BagState> emit,
  ) async {
    if (state is EmptyBag) {
      // Then we need to create a new bag and add the product to it
      final bag = Bag(
        bagItems: [BagItem(product: event.product)],
        total: event.product.price, // initially total will be product cost
      );
      emit(HasOrder(bag));
      return;
    }
    final currentBagItems = (state as HasOrder).bag.bagItems;
    // Then there is a bag already and we need to add order to it or increase it's number
    for (final bagItem in currentBagItems) {
      // search if product already is in the bag
      if (bagItem.product.id == event.product.id) {
        // then product already exists and we should inc it's count
        add(IncProductCountEvent(product: event.product));
        return;
      }
    }
    // Then product need to be added to the bag
    final List<BagItem> newBagItemsList = List.from(currentBagItems)
      ..add(BagItem(product: event.product));
    final newBag = Bag(
      bagItems: newBagItemsList,
      total: _calculateBagItemsTotal(newBagItemsList),
    );
    emit(HasOrder(newBag));
  }

  Future<void> _onIncProductCountEvent(
    IncProductCountEvent event,
    Emitter<BagState> emit,
  ) async {
    if (state is! HasOrder) {
      return;
    }
    final currentBag = (state as HasOrder).bag;
    final newBagItemsList = currentBag.bagItems.map(
      (bagItem) {
        if (bagItem.product.id != event.product.id) {
          return bagItem;
        }
        return bagItem.copy(count: bagItem.count + 1);
      },
    ).toList();
    if (newBagItemsList.isEmpty) {
      emit(EmptyBag());
      return;
    }
    final newBag = currentBag.copy(
      bagItems: newBagItemsList,
      total: _calculateBagItemsTotal(newBagItemsList),
    );
    emit(HasOrder(newBag));
  }

  Future<void> _onDecProductCountEvent(
    DecProductCountEvent event,
    Emitter<BagState> emit,
  ) async {
    if (state is! HasOrder) {
      return;
    }
    final currentBag = (state as HasOrder).bag;
    final newBagItemsList = currentBag.bagItems.mapNotNull(
      (bagItem) {
        if (bagItem.product.id != event.product.id) {
          return bagItem;
        }
        if (bagItem.count == 1) {
          return null; // remove it from the bag
        }
        return bagItem.copy(count: bagItem.count - 1);
      },
    ).toList();
    if (newBagItemsList.isEmpty) {
      emit(EmptyBag());
      return;
    }
    final newBag = currentBag.copy(
      bagItems: newBagItemsList,
      total: _calculateBagItemsTotal(newBagItemsList),
    );
    emit(HasOrder(newBag));
  }

  Future<void> _onRemoveFromBagEvent(
    RemoveFromBagEvent event,
    Emitter<BagState> emit,
  ) async {
    if (state is! HasOrder) {
      return;
    }
    final currentBag = (state as HasOrder).bag;
    final newBagItemsList = currentBag.bagItems.mapNotNull(
      (bagItem) {
        if (bagItem.product.id == event.product.id) {
          return null;
        }
        return bagItem;
      },
    ).toList();
    if (newBagItemsList.isEmpty) {
      emit(EmptyBag());
      return;
    }
    final newBag = currentBag.copy(
      bagItems: newBagItemsList,
      total: _calculateBagItemsTotal(newBagItemsList),
    );
    emit(HasOrder(newBag));
  }

  double _calculateBagItemsTotal(List<BagItem> items) {
    double total = 0.0;
    for (final bagItem in items) {
      total += bagItem.product.price * bagItem.count;
    }
    return total;
  }
}
