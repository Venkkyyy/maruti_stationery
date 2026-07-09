enum Flavor {
  customer,
  admin,
}

class F {
  static late final Flavor appFlavor;

  static String get name => appFlavor.name;

  static String get title {
    switch (appFlavor) {
      case Flavor.customer:
        return 'Maruti Stationery';
      case Flavor.admin:
        return 'Maruti Admin';
    }
  }

}
