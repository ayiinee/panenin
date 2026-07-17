import 'package:panenin/features/demands/data/demand_repository.dart';
import 'package:panenin/features/home/data/buyer_home_repository.dart';
import 'package:panenin/features/orders/data/order_repository.dart';
import 'package:panenin/features/profile/data/profile_repository.dart';
import 'package:panenin/features/stock/data/stock_repository.dart';
import 'package:panenin/features/whatsapp/data/whatsapp_repository.dart';

class AppRepositories {
  const AppRepositories({
    required this.profile,
    required this.stock,
    required this.orders,
    required this.demands,
    required this.buyerHome,
    required this.whatsapp,
  });

  factory AppRepositories.production() => AppRepositories(
    profile: ProfileRepository.create(),
    stock: StockRepository.create(),
    orders: OrderRepository.create(),
    demands: DemandRepository.create(),
    buyerHome: BuyerHomeRepository.create(),
    whatsapp: WhatsAppRepository.create(),
  );

  final ProfileRepository profile;
  final StockRepository stock;
  final OrderRepository orders;
  final DemandRepository demands;
  final BuyerHomeRepository buyerHome;
  final WhatsAppRepository whatsapp;
}
