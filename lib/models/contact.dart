import 'package:hive/hive.dart';
part 'contact.g.dart';

@HiveType(typeId: 0)
class BitsContact extends HiveObject{
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String phone;

  @HiveField(2)
  bool isAccount = false;

  BitsContact(this.name, this.phone);
}
