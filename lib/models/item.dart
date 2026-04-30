class Item {
  String id;
  String name;
  double price;
  String? photoUrl;
  bool done;

  Item({
    required this.id,
    required this.name,
    required this.price,
    required this.photoUrl,
    this.done = false,
  });

  Map<String, dynamic> toMap() {
    return {"name": name, "price": price, "done": done};
  }
}
