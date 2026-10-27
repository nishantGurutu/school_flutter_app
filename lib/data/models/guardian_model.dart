class GuardianModel {
  final String id, name, relation, phone, email, occupation, address, photo;

  const GuardianModel({
    required this.id,
    required this.name,
    required this.relation,
    required this.phone,
    required this.email,
    required this.occupation,
    required this.address,
    required this.photo,
  });

  factory GuardianModel.fromJson(Map<String, dynamic> json) {
    String text(String key) => json[key]?.toString().trim() ?? '';
    final relation = text('relation').isNotEmpty
        ? text('relation')
        : text('guardianType');
    return GuardianModel(
      id: text('id'),
      name: text('name'),
      relation: relation.isEmpty
          ? 'Guardian'
          : relation[0].toUpperCase() + relation.substring(1).toLowerCase(),
      phone: text('phone'),
      email: text('email'),
      occupation: text('occupation'),
      address: text('address'),
      photo: text('photo'),
    );
  }
}
