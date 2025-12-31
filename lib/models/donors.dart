class Donor {
  final String name;
  final bool isActive;
  final double totalLifetimeGiving;
  final String phone;
  final String email;
  final String address;
  final List<Donation> donations;

  Donor({
    required this.name,
    required this.isActive,
    required this.totalLifetimeGiving,
    required this.phone,
    required this.email,
    required this.address,
    required this.donations,
  });
}

class Donation {
  final String title;
  final DateTime date;
  final double amount;
  final bool completed;

  Donation({
    required this.title,
    required this.date,
    required this.amount,
    required this.completed,
  });
}
